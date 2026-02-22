#!/bin/bash
# OpenClaw Codespace Keepalive - Manual Start Script
# 使用 nohup 启动保活服务

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../logs"
PID_FILE="$SCRIPT_DIR/../.keepalive.pid"

# 确保日志目录存在
mkdir -p "$LOG_DIR"

# 检查是否已经在运行
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "ℹ️ Keepalive service already running (PID: $OLD_PID)"
        echo "📝 To stop: kill $OLD_PID"
        exit 0
    else
        echo "⚠️ Stale PID file found, removing..."
        rm -f "$PID_FILE"
    fi
fi

echo "🚀 Starting OpenClaw Keepalive Service..."

# 使用 nohup 后台运行
nohup node "$SCRIPT_DIR/keepalive-service.js" > "$LOG_DIR/keepalive.out.log" 2>&1 &
NEW_PID=$!

# 保存 PID
echo "$NEW_PID" > "$PID_FILE"

# 等待一秒检查是否启动成功
sleep 1

if ps -p "$NEW_PID" > /dev/null 2>&1; then
    echo "✅ Keepalive service started successfully!"
    echo "📊 PID: $NEW_PID"
    echo "📝 Logs: tail -f $LOG_DIR/keepalive-service.log"
    echo "📝 Output: tail -f $LOG_DIR/keepalive.out.log"
    echo "🛑 To stop: kill $NEW_PID"
else
    echo "❌ Failed to start keepalive service"
    rm -f "$PID_FILE"
    exit 1
fi
