#!/bin/bash
# OpenClaw Codespace Keepalive Script
# 用于防止 GitHub Codespaces 因闲置而自动关闭

LOG_FILE="/home/codespace/.openclaw/workspace/logs/keepalive.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 创建日志目录
mkdir -p "$(dirname "$LOG_FILE")"

# 记录保活日志
echo "[$TIMESTAMP] 🔥 Keepalive triggered" >> "$LOG_FILE"

# 检查 OpenClaw Gateway 是否运行
if pgrep -f "openclaw-gateway" > /dev/null; then
    echo "[$TIMESTAMP] ✅ OpenClaw Gateway is running" >> "$LOG_FILE"
else
    echo "[$TIMESTAMP] ⚠️ OpenClaw Gateway not found, attempting to start..." >> "$LOG_FILE"
    cd /home/codespace/.openclaw/workspace && npm exec openclaw gateway --verbose >> "$LOG_FILE" 2>&1 &
fi

# 访问 GitHub API 保持 Codespace 活跃
curl -s -o /dev/null -w "GitHub API Status: %{http_code}\n" "https://api.github.com" >> "$LOG_FILE" 2>&1

# 输出当前时间到终端（防止终端闲置）
echo "[$TIMESTAMP] 📍 Keepalive ping sent"

# 清理旧日志（保留最近 100 行）
tail -n 100 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
