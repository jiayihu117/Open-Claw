#!/bin/bash
# OpenClaw Codespace Keepalive Setup Script
# 设置并启动保活服务

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="/home/codespace/.openclaw/workspace"
SERVICE_FILE="$SCRIPT_DIR/keepalive.service"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

echo "🔧 Setting up OpenClaw Keepalive Service..."

# 创建 systemd 用户目录
mkdir -p "$SYSTEMD_USER_DIR"

# 复制服务文件到 systemd 用户目录
cp "$SERVICE_FILE" "$SYSTEMD_USER_DIR/openclaw-keepalive.service"

# 重新加载 systemd 配置
systemctl --user daemon-reload

# 启用服务（开机自启）
systemctl --user enable openclaw-keepalive.service

# 启动服务
systemctl --user start openclaw-keepalive.service

# 检查服务状态
echo ""
echo "📊 Service Status:"
systemctl --user status openclaw-keepalive.service --no-pager

echo ""
echo "✅ Keepalive service setup complete!"
echo "📝 Logs: journalctl --user -u openclaw-keepalive -f"
