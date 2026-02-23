#!/bin/bash
#===============================================================================
# OpenClaw Self-Healing Keepalive System
# 极客版自救活系统 - 多层防护，自动修复
#===============================================================================

set -u

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$SCRIPT_DIR/.."
LOG_DIR="$WORKSPACE_DIR/logs"
PID_FILE="$WORKSPACE_DIR/.keepalive.pid"
WATCHDOG_PID_FILE="$WORKSPACE_DIR/.watchdog.pid"
HEALTH_FILE="$WORKSPACE_DIR/.health.json"

# 日志配置
LOG_FILE="$LOG_DIR/self-heal.log"
mkdir -p "$LOG_DIR"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#-------------------------------------------------------------------------------
# 日志函数
#-------------------------------------------------------------------------------
log() {
    local level="$1"
    local msg="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color="$NC"
    
    case "$level" in
        INFO)  color="$GREEN" ;;
        WARN)  color="$YELLOW" ;;
        ERROR) color="$RED" ;;
        DEBUG) color="$BLUE" ;;
    esac
    
    echo -e "${timestamp} ${color}[${level}]${NC} ${msg}" | tee -a "$LOG_FILE"
}

#-------------------------------------------------------------------------------
# 健康检查
#-------------------------------------------------------------------------------
check_process() {
    local name="$1"
    local pattern="$2"
    
    if pgrep -f "$pattern" > /dev/null 2>&1; then
        local pid=$(pgrep -f "$pattern" | head -1)
        log "INFO" "✅ $name 运行中 (PID: $pid)"
        return 0
    else
        log "ERROR" "❌ $name 未运行"
        return 1
    fi
}

check_gateway() {
    check_process "OpenClaw Gateway" "openclaw-gateway"
}

check_keepalive() {
    check_process "Keepalive Service" "keepalive-service.js"
}

check_http() {
    local url="$1"
    local name="$2"
    local timeout="${3:-5}"
    
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "$timeout" "$url" 2>/dev/null)
    
    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        log "INFO" "✅ $name 可达 (HTTP $http_code)"
        return 0
    else
        log "ERROR" "❌ $name 不可达 (HTTP $http_code)"
        return 1
    fi
}

#-------------------------------------------------------------------------------
# 自动修复
#-------------------------------------------------------------------------------
restart_keepalive() {
    log "WARN" "🔄 重启保活服务..."
    
    # 停止旧进程
    if [ -f "$PID_FILE" ]; then
        local old_pid=$(cat "$PID_FILE")
        if ps -p "$old_pid" > /dev/null 2>&1; then
            kill "$old_pid" 2>/dev/null
            sleep 1
        fi
        rm -f "$PID_FILE"
    fi
    
    # 清理残留进程
    pkill -f "keepalive-service.js" 2>/dev/null || true
    sleep 1
    
    # 启动新进程
    if [ -x "$SCRIPT_DIR/start-keepalive.sh" ]; then
        "$SCRIPT_DIR/start-keepalive.sh" > /dev/null 2>&1
        sleep 2
        
        if check_keepalive; then
            log "INFO" "🎉 保活服务重启成功"
            return 0
        fi
    fi
    
    log "ERROR" "❌ 保活服务重启失败"
    return 1
}

restart_gateway() {
    log "WARN" "🔄 重启 OpenClaw Gateway..."
    
    # 尝试通过 openclaw 命令重启
    if command -v openclaw &> /dev/null; then
        pkill -f "openclaw-gateway" 2>/dev/null || true
        sleep 2
        
        cd "$WORKSPACE_DIR" && npm exec openclaw gateway --verbose > "$LOG_DIR/gateway.log" 2>&1 &
        sleep 3
        
        if check_gateway; then
            log "INFO" "🎉 Gateway 重启成功"
            return 0
        fi
    fi
    
    log "ERROR" "❌ Gateway 重启失败"
    return 1
}

#-------------------------------------------------------------------------------
# 网络心跳
#-------------------------------------------------------------------------------
send_network_heartbeat() {
    log "DEBUG" "💓 发送网络心跳..."
    
    # 多个端点确保至少有一个可达
    local endpoints=(
        "https://api.github.com"
        "https://www.google.com"
        "https://cloudflare.com"
        "https://1.1.1.1"
    )
    
    for endpoint in "${endpoints[@]}"; do
        if curl -s -o /dev/null --connect-timeout 3 "$endpoint" 2>/dev/null; then
            log "DEBUG" "✅ 心跳成功：$endpoint"
            return 0
        fi
    done
    
    log "WARN" "⚠️ 所有心跳端点失败"
    return 1
}

#-------------------------------------------------------------------------------
# 终端活动模拟
#-------------------------------------------------------------------------------
simulate_terminal_activity() {
    # 更新健康文件时间戳（创造文件系统活动）
    echo "{\"timestamp\":\"$(date -Iseconds)\",\"status\":\"alive\"}" > "$HEALTH_FILE"
    
    # 访问 Codespace 端口
    local codespace_port="${CODESPACE_PORT:-18789}"
    curl -s -o /dev/null --connect-timeout 2 "http://localhost:$codespace_port" 2>/dev/null || true
    
    log "DEBUG" "📝 终端活动已模拟"
}

#-------------------------------------------------------------------------------
# 看门狗主循环
#-------------------------------------------------------------------------------
watchdog_loop() {
    log "INFO" "🐕 看门狗启动 (PID: $$)"
    echo $$ > "$WATCHDOG_PID_FILE"
    
    local check_interval=30      # 每 30 秒检查一次
    local heartbeat_interval=60  # 每 60 秒发送心跳
    local heal_threshold=2       # 连续失败 2 次后修复
    
    local fail_count=0
    local heartbeat_count=0
    
    while true; do
        local has_failure=0
        
        # 检查关键进程
        check_gateway || has_failure=1
        check_keepalive || has_failure=1
        
        # 网络心跳
        if (( heartbeat_count >= heartbeat_interval / check_interval )); then
            send_network_heartbeat || has_failure=1
            simulate_terminal_activity
            heartbeat_count=0
        else
            ((heartbeat_count++))
        fi
        
        # 失败计数和修复
        if [ $has_failure -eq 1 ]; then
            ((fail_count++))
            log "WARN" "⚠️ 失败计数：$fail_count"
            
            if [ $fail_count -ge $heal_threshold ]; then
                log "ERROR" "🚨 触发自动修复！"
                
                # 尝试修复
                restart_keepalive || true
                restart_gateway || true
                
                fail_count=0
            fi
        else
            fail_count=0
        fi
        
        # 等待下次检查
        sleep $check_interval
    done
}

#-------------------------------------------------------------------------------
# 启动函数
#-------------------------------------------------------------------------------
start_watchdog() {
    log "INFO" "🚀 启动自救活系统..."
    
    # 检查是否已经在运行
    if [ -f "$WATCHDOG_PID_FILE" ]; then
        local old_pid=$(cat "$WATCHDOG_PID_FILE")
        if ps -p "$old_pid" > /dev/null 2>&1; then
            log "INFO" "ℹ️ 看门狗已在运行 (PID: $old_pid)"
            return 0
        fi
        rm -f "$WATCHDOG_PID_FILE"
    fi
    
    # 启动看门狗
    nohup bash "$0" --watchdog-loop > "$LOG_DIR/watchdog.out.log" 2>&1 &
    local watchdog_pid=$!
    
    sleep 2
    
    if ps -p "$watchdog_pid" > /dev/null 2>&1; then
        log "INFO" "✅ 看门狗已启动 (PID: $watchdog_pid)"
        return 0
    else
        log "ERROR" "❌ 看门狗启动失败"
        return 1
    fi
}

stop_watchdog() {
    log "INFO" "🛑 停止看门狗..."
    
    if [ -f "$WATCHDOG_PID_FILE" ]; then
        local pid=$(cat "$WATCHDOG_PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            kill "$pid" 2>/dev/null
            sleep 1
            kill -9 "$pid" 2>/dev/null || true
            log "INFO" "✅ 看门狗已停止"
        fi
        rm -f "$WATCHDOG_PID_FILE"
    fi
    
    # 清理残留
    pkill -f "self-heal.sh.*--watchdog-loop" 2>/dev/null || true
}

status_watchdog() {
    echo "═══════════════════════════════════════════════════"
    echo "  🤖 OpenClaw Self-Heal System Status"
    echo "═══════════════════════════════════════════════════"
    
    # 看门狗状态
    if [ -f "$WATCHDOG_PID_FILE" ]; then
        local pid=$(cat "$WATCHDOG_PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo -e "  看门狗：  ${GREEN}✅ 运行中${NC} (PID: $pid)"
        else
            echo -e "  看门狗：  ${RED}❌ 已停止${NC} ( stale PID)"
        fi
    else
        echo -e "  看门狗：  ${YELLOW}⚠️ 未启动${NC}"
    fi
    
    # 保活服务状态
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo -e "  保活服务：${GREEN}✅ 运行中${NC} (PID: $pid)"
        else
            echo -e "  保活服务：${RED}❌ 已停止${NC}"
        fi
    else
        echo -e "  保活服务：${YELLOW}⚠️ 未启动${NC}"
    fi
    
    # Gateway 状态
    if pgrep -f "openclaw-gateway" > /dev/null 2>&1; then
        local pid=$(pgrep -f "openclaw-gateway" | head -1)
        echo -e "  Gateway:  ${GREEN}✅ 运行中${NC} (PID: $pid)"
    else
        echo -e "  Gateway:  ${RED}❌ 未运行${NC}"
    fi
    
    echo "═══════════════════════════════════════════════════"
    
    # 最近日志
    echo ""
    echo "📝 最近日志:"
    tail -5 "$LOG_FILE" 2>/dev/null || echo "  (无日志)"
}

#-------------------------------------------------------------------------------
# 主程序
#-------------------------------------------------------------------------------
case "${1:-}" in
    --watchdog-loop)
        watchdog_loop
        ;;
    start)
        start_watchdog
        ;;
    stop)
        stop_watchdog
        ;;
    restart)
        stop_watchdog
        sleep 1
        start_watchdog
        ;;
    status)
        status_watchdog
        ;;
    check)
        check_gateway
        check_keepalive
        send_network_heartbeat
        ;;
    heal)
        restart_keepalive
        restart_gateway
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|check|heal|--watchdog-loop}"
        echo ""
        echo "Commands:"
        echo "  start   - 启动看门狗"
        echo "  stop    - 停止看门狗"
        echo "  restart - 重启看门狗"
        echo "  status  - 显示状态"
        echo "  check   - 执行一次健康检查"
        echo "  heal    - 手动触发修复"
        exit 1
        ;;
esac
