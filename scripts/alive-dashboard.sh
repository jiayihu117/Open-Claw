#!/bin/bash
#===============================================================================
# OpenClaw Alive Dashboard - 极客风格状态面板
#===============================================================================

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# ASCII Art
show_header() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║   █████╗ ██╗   ██╗████████╗ ██████╗██╗  ██╗███████╗██████╗     ║"
    echo "║  ██╔══██╗██║   ██║╚══██╔══╝██╔════╝██║  ██║██╔════╝██╔══██╗    ║"
    echo "║  ███████║██║   ██║   ██║   ██║     ███████║█████╗  ██████╔╝    ║"
    echo "║  ██╔══██║██║   ██║   ██║   ██║     ██╔══██║██╔══╝  ██╔══██╗    ║"
    echo "║  ██║  ██║╚██████╔╝   ██║   ╚██████╗██║  ██║███████╗██║  ██║    ║"
    echo "║  ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝    ║"
    echo "║                                                               ║"
    echo "║              🤖 Self-Healing Keepalive System 🤖              ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_status() {
    local name="$1"
    local pattern="$2"
    
    if pgrep -f "$pattern" > /dev/null 2>&1; then
        local pid=$(pgrep -f "$pattern" | head -1)
        local uptime=$(ps -o etime= -p "$pid" 2>/dev/null | xargs)
        echo -e "  ${GREEN}●${NC} $name ${GREEN}RUNNING${NC} (PID: $pid, Uptime: $uptime)"
        return 0
    else
        echo -e "  ${RED}●${NC} $name ${RED}STOPPED${NC}"
        return 1
    fi
}

check_http() {
    local url="$1"
    local name="$2"
    
    local start=$(date +%s%N)
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "$url" 2>/dev/null)
    local end=$(date +%s%N)
    local latency=$(( (end - start) / 1000000 ))
    
    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        echo -e "  ${GREEN}●${NC} $name ${GREEN}OK${NC} (${http_code}, ${latency}ms)"
        return 0
    else
        echo -e "  ${RED}●${NC} $name ${RED}FAIL${NC} (${http_code})"
        return 1
    fi
}

show_status() {
    show_header
    
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}  📊 SYSTEM STATUS${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # 进程状态
    check_status "OpenClaw Gateway" "openclaw-gateway"
    check_status "Keepalive Service" "keepalive-service.js"
    check_status "Self-Heal Watchdog" "self-heal.sh.*--watchdog-loop"
    
    echo ""
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}  🌐 NETWORK STATUS${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # 网络状态
    check_http "https://api.github.com" "GitHub API"
    check_http "https://www.google.com" "Google"
    check_http "https://cloudflare.com" "Cloudflare"
    
    echo ""
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}  📁 FILE STATUS${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # 文件状态
    local workspace="/home/codespace/.openclaw/workspace"
    
    if [ -f "$workspace/.keepalive.pid" ]; then
        local pid=$(cat "$workspace/.keepalive.pid")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo -e "  ${GREEN}●${NC} Keepalive PID file (PID: $pid)"
        else
            echo -e "  ${YELLOW}●${NC} Keepalive PID file (stale: $pid)"
        fi
    else
        echo -e "  ${YELLOW}●${NC} Keepalive PID file (not found)"
    fi
    
    if [ -f "$workspace/.watchdog.pid" ]; then
        local pid=$(cat "$workspace/.watchdog.pid")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo -e "  ${GREEN}●${NC} Watchdog PID file (PID: $pid)"
        else
            echo -e "  ${YELLOW}●${NC} Watchdog PID file (stale: $pid)"
        fi
    else
        echo -e "  ${YELLOW}●${NC} Watchdog PID file (not found)"
    fi
    
    if [ -f "$workspace/.health.json" ]; then
        local last_update=$(stat -c %y "$workspace/.health.json" 2>/dev/null | cut -d. -f1)
        echo -e "  ${GREEN}●${NC} Health file (updated: $last_update)"
    else
        echo -e "  ${YELLOW}●${NC} Health file (not found)"
    fi
    
    echo ""
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}  📝 RECENT LOGS${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # 最近日志
    if [ -f "$workspace/logs/self-heal.log" ]; then
        tail -5 "$workspace/logs/self-heal.log" | while read line; do
            if [[ "$line" == *"[INFO]"* ]]; then
                echo -e "  ${GREEN}$line${NC}"
            elif [[ "$line" == *"[WARN]"* ]]; then
                echo -e "  ${YELLOW}$line${NC}"
            elif [[ "$line" == *"[ERROR]"* ]]; then
                echo -e "  ${RED}$line${NC}"
            else
                echo "  $line"
            fi
        done
    else
        echo "  (no logs)"
    fi
    
    echo ""
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}  🎮 QUICK ACTIONS${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "  [1] Start Self-Heal    [2] Stop Self-Heal"
    echo "  [3] Restart All        [4] Force Heal"
    echo "  [5] View Full Logs     [0] Exit"
    echo ""
}

interactive_menu() {
    local workspace="/home/codespace/.openclaw/workspace"
    
    while true; do
        clear
        show_status
        
        read -p "  Select action [0-5]: " choice
        
        case $choice in
            1)
                echo -e "\n  ${CYAN}Starting Self-Heal...${NC}"
                "$workspace/scripts/self-heal.sh" start
                read -p "  Press Enter to continue..."
                ;;
            2)
                echo -e "\n  ${CYAN}Stopping Self-Heal...${NC}"
                "$workspace/scripts/self-heal.sh" stop
                read -p "  Press Enter to continue..."
                ;;
            3)
                echo -e "\n  ${CYAN}Restarting all services...${NC}"
                "$workspace/scripts/stop-keepalive.sh"
                "$workspace/scripts/self-heal.sh" stop
                sleep 2
                "$workspace/scripts/start-keepalive.sh"
                "$workspace/scripts/self-heal.sh" start
                read -p "  Press Enter to continue..."
                ;;
            4)
                echo -e "\n  ${CYAN}Forcing heal...${NC}"
                "$workspace/scripts/self-heal.sh" heal
                read -p "  Press Enter to continue..."
                ;;
            5)
                echo -e "\n  ${CYAN}Showing full logs...${NC}"
                tail -50 "$workspace/logs/self-heal.log"
                read -p "  Press Enter to continue..."
                ;;
            0)
                echo -e "\n  ${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "\n  ${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

# 主程序
case "${1:-}" in
    --interactive|-i)
        interactive_menu
        ;;
    --once|-o)
        show_status
        ;;
    *)
        # 如果没有终端，只显示一次状态
        if [ -t 0 ]; then
            interactive_menu
        else
            show_status
        fi
        ;;
esac
