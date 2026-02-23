#!/bin/bash
#===============================================================================
# OpenClaw Timed Notification - 定时通知服务
#===============================================================================

LOG_FILE="/home/codespace/.openclaw/workspace/logs/timer-notification.log"
PID_FILE="/home/codespace/.openclaw/workspace/.timer.pid"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

start_timer() {
    local minutes="${1:-10}"
    local seconds=$((minutes * 60))
    
    log "⏰ 启动 ${minutes}分钟定时器..."
    
    # 后台等待
    (
        sleep $seconds
        
        log "⏰ 时间到！发送通知..."
        
        # 检查系统状态
        local status="✅ 我还活着！\n\n"
        status+="系统状态:\n"
        
        if pgrep -f "openclaw-gateway" > /dev/null 2>&1; then
            status+="  ● Gateway: 运行中\n"
        else
            status+="  ● Gateway: 已停止\n"
        fi
        
        if pgrep -f "keepalive-service.js" > /dev/null 2>&1; then
            status+="  ● Keepalive: 运行中\n"
        else
            status+="  ● Keepalive: 已停止\n"
        fi
        
        if pgrep -f "self-heal.sh.*--watchdog-loop" > /dev/null 2>&1; then
            status+="  ● Watchdog: 运行中\n"
        else
            status+="  ● Watchdog: 已停止\n"
        fi
        
        status+="\n🔥 自救活系统运行正常！"
        
        log "$status"
        
        # 发送通知（通过 message 工具或其他方式）
        echo "$status"
        
    ) &
    
    local timer_pid=$!
    echo "$timer_pid" > "$PID_FILE"
    
    log "✅ 定时器已启动 (PID: $timer_pid)"
    echo "定时器已启动，${minutes}分钟后通知你"
}

stop_timer() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            kill "$pid" 2>/dev/null
            log "🛑 定时器已停止"
            echo "定时器已停止"
        fi
        rm -f "$PID_FILE"
    else
        echo "没有运行中的定时器"
    fi
}

status_timer() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo "⏰ 定时器运行中 (PID: $pid)"
            return 0
        fi
    fi
    echo "⚠️ 定时器未运行"
    return 1
}

case "${1:-}" in
    start)
        start_timer "${2:-10}"
        ;;
    stop)
        stop_timer
        ;;
    status)
        status_timer
        ;;
    *)
        echo "Usage: $0 {start [minutes]|stop|status}"
        echo ""
        echo "Examples:"
        echo "  $0 start 10    # 10 分钟后通知"
        echo "  $0 start 5     # 5 分钟后通知"
        echo "  $0 stop        # 停止定时器"
        echo "  $0 status      # 查看状态"
        ;;
esac
