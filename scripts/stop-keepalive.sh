#!/bin/bash
# OpenClaw Codespace Keepalive - Stop Script

PID_FILE="/home/codespace/.openclaw/workspace/.keepalive.pid"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "🛑 Stopping Keepalive Service (PID: $PID)..."
        kill "$PID"
        sleep 1
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "⚠️ Force killing..."
            kill -9 "$PID"
        fi
        rm -f "$PID_FILE"
        echo "✅ Keepalive service stopped"
    else
        echo "ℹ️ Process not running, removing stale PID file"
        rm -f "$PID_FILE"
    fi
else
    # 尝试通过进程名查找
    PID=$(pgrep -f "keepalive-service.js" | head -1)
    if [ -n "$PID" ]; then
        echo "🛑 Stopping Keepalive Service (PID: $PID)..."
        kill "$PID"
        echo "✅ Keepalive service stopped"
    else
        echo "ℹ️ No keepalive service found running"
    fi
fi
