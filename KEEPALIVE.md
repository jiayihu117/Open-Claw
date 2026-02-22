# OpenClaw Codespace Keepalive

防止 GitHub Codespaces 因闲置而自动关闭的保活服务。

## 📋 功能

- **定时保活**: 每 5 分钟自动执行一次保活操作
- **自动重启**: 如果 OpenClaw Gateway 停止，会尝试重新启动
- **日志记录**: 所有操作都会记录到日志文件
- **开机自启**: 每次打开 Codespace 时自动启动

## 🚀 使用方法

### 启动保活服务

```bash
./scripts/start-keepalive.sh
```

### 停止保活服务

```bash
./scripts/stop-keepalive.sh
```

### 查看日志

```bash
# 查看保活日志
tail -f logs/keepalive-service.log

# 查看输出日志
tail -f logs/keepalive.out.log
```

## 📁 文件说明

| 文件 | 说明 |
|------|------|
| `scripts/keepalive-service.js` | Node.js 保活服务主程序 |
| `scripts/start-keepalive.sh` | 启动脚本 |
| `scripts/stop-keepalive.sh` | 停止脚本 |
| `scripts/setup-keepalive.sh` | 系统设置脚本（systemd） |
| `.github/workflows/codespace-keepalive.yml` | GitHub Actions 保活工作流 |
| `logs/keepalive-service.log` | 保活服务日志 |

## 🔧 GitHub Actions 保活

除了本地保活服务，还配置了 GitHub Actions 工作流，每 15 分钟运行一次，进一步确保 Codespace 保持活跃。

工作流位置：`.github/workflows/codespace-keepalive.yml`

## ⚙️ 自动启动

保活服务已配置为在每次打开 Codespace 时自动启动（通过 `.bashrc`）。

## 📊 监控

检查保活服务是否运行：

```bash
# 检查进程
ps aux | grep keepalive-service

# 查看 PID
cat .keepalive.pid
```

## 🛑 注意事项

1. **GitHub Codespaces 限制**: 免费用户每月有 60 小时的免费额度，保活会消耗额度
2. **闲置超时**: Codespaces 通常在 30 分钟无活动后自动关闭
3. **浏览器保活**: 保持浏览器标签页打开是最简单的保活方式

## 🔗 相关资源

- [GitHub Codespaces 文档](https://docs.github.com/en/codespaces)
- [Codespaces 闲置超时](https://docs.github.com/en/codespaces/developing-in-codespaces/setting-your-timeout-period-for-github-codespaces)
