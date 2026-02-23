#!/bin/bash
# OpenClaw Codespace Keepalive - Browser-based Keepalive
# 使用浏览器自动刷新来防止 Codespace 闲置关闭

LOG_FILE="/home/codespace/.openclaw/workspace/logs/browser-keepalive.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

mkdir -p "$(dirname "$LOG_FILE")"

echo "[$TIMESTAMP] 🌐 Browser keepalive triggered" >> "$LOG_FILE"

# 如果安装了 playwright 或 puppeteer，可以用它来访问页面
# 这里使用简单的 curl 来模拟访问
CODESPACE_URL="https://solid-eureka-5g6pvxg9697whx44-18789.app.github.dev/"

# 访问 Codespace 公网 URL
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$CODESPACE_URL" 2>/dev/null)

echo "[$TIMESTAMP] 📍 Codespace URL Status: $HTTP_CODE" >> "$LOG_FILE"

# 访问 GitHub API
GH_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://api.github.com" 2>/dev/null)
echo "[$TIMESTAMP] 📍 GitHub API Status: $GH_CODE" >> "$LOG_FILE"

echo "[$TIMESTAMP] ✨ Browser keepalive completed" >> "$LOG_FILE"
