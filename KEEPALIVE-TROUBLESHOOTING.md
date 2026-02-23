# OpenClaw Codespace Keepalive - 故障排查

## ⚠️ 保活失败的可能原因

### 1. GitHub Codespace 自动关闭

GitHub Codespaces 会在以下情况自动关闭：

- **闲置 30 分钟** - 无浏览器活动或终端输入
- **达到月度配额** - 免费用户 60 小时/月
- **Codespace 配置超时** - 检查仓库的 Codespace 设置

**解决方案：**
- 保持浏览器标签页打开
- 使用多个保活机制（本地 + GitHub Actions）
- 检查配额：https://github.com/settings/billing

---

### 2. GitHub Actions 未触发

**检查项目：**

```bash
# 查看工作流状态
gh run list --workflow codespace-keepalive.yml

# 查看最近的运行
gh run watch
```

**可能原因：**
- Workflow 被禁用（检查 Actions 标签页）
- 权限不足
- Cron 表达式错误

**解决方案：**
1. 访问 https://github.com/jiayihu117/Open-Claw/actions
2. 确保工作流已启用
3. 手动触发一次测试

---

### 3. 本地保活服务停止

**检查状态：**

```bash
# 查看进程
ps aux | grep keepalive-service

# 查看日志
tail -f /home/codespace/.openclaw/workspace/logs/keepalive-service.log

# 重启服务
./scripts/stop-keepalive.sh
./scripts/start-keepalive.sh
```

---

### 4. 网络连接问题

**测试连接：**

```bash
# 测试 GitHub API
curl -I https://api.github.com

# 测试 Codespace URL
curl -I https://solid-eureka-5g6pvxg9697whx44-18789.app.github.dev/
```

---

## 🔧 快速修复命令

```bash
# 1. 重启保活服务
cd /home/codespace/.openclaw/workspace
./scripts/stop-keepalive.sh
./scripts/start-keepalive.sh

# 2. 手动触发 GitHub Actions
gh workflow run codespace-keepalive.yml

# 3. 检查服务状态
ps aux | grep -E "keepalive|openclaw"

# 4. 查看完整日志
tail -50 logs/keepalive-service.log
```

---

## 📊 当前配置

| 机制 | 频率 | 状态 |
|------|------|------|
| **本地 Node.js 服务** | 每 5 分钟 | ✅ |
| **GitHub Actions** | 每 10 分钟 | ✅ |
| **.bashrc 自启** | 每次会话 | ✅ |

---

## 🛡️ 预防措施

1. **保持浏览器标签打开** - 最简单有效的方法
2. **使用手机访问** - 定期打开 Codespace URL
3. **设置多个保活** - 本地 + GitHub Actions 双重保护
4. **监控配额** - 避免超出免费额度

---

## 📞 需要帮助？

如果保活持续失败：

1. 检查 GitHub Status: https://www.githubstatus.com/
2. 查看 Codespace 日志：https://github.com/codespaces
3. 联系 GitHub Support
