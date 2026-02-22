# OpenClaw Skills

本目录包含已安装的 OpenClaw Skills，可以直接在 OpenClaw 中使用。

## 📦 已安装的技能 (21 个)

### ✅ 核心技能 (已就绪)

| 技能 | 描述 |
|------|------|
| **blogwatcher** | 监控博客和 RSS/Atom 订阅源更新 |
| **coding-agent** | 委托编码任务给 Codex/Claude/Pi 代理 |
| **gh-issues** | 自动获取 GitHub Issues 并创建 PR 修复 |
| **github** | GitHub 操作 (issues, PRs, CI, code review) |
| **healthcheck** | 主机安全审计和加固 |
| **skill-creator** | 创建/更新 AgentSkills |
| **weather** | 天气查询 (wttr.in/Open-Meteo) |

### 💬 通讯技能

| 技能 | 描述 |
|------|------|
| **discord** | Discord 消息集成 |
| **slack** | Slack 消息集成 |

### 📝 笔记技能

| 技能 | 描述 |
|------|------|
| **notion** | Notion API 集成 (页面、数据库、块) |
| **obsidian** | Obsidian 笔记集成 |

### 🎵 媒体技能

| 技能 | 描述 |
|------|------|
| **spotify-player** | Spotify 播放器集成 |
| **sag** | ElevenLabs TTS 语音合成 |
| **gemini** | Google Gemini 集成 |
| **openai-image-gen** | OpenAI 图像生成 |

### 🛠️ 工具技能

| 技能 | 描述 |
|------|------|
| **canvas** | Canvas UI 呈现/评估 |
| **session-logs** | 会话日志搜索和分析 |
| **summarize** | 文本摘要 |
| **trello** | Trello 看板管理 |

---

## 🔧 使用方法

### 在 OpenClaw 中使用

技能会自动被 OpenClaw 加载，无需额外配置。在对话中直接提及相关功能即可触发对应技能。

### 添加新技能

1. 从 ClawHub 下载技能：
   ```bash
   clawhub install <skill-name>
   ```

2. 或者从 openclaw 内置技能复制：
   ```bash
   cp -r ~/.npm/_npx/*/node_modules/openclaw/skills/<skill-name> ./skills/
   ```

3. 提交到仓库：
   ```bash
   git add skills/<skill-name>
   git commit -m "feat: add <skill-name> skill"
   git push
   ```

---

## 📋 技能结构

每个技能目录包含：
- `SKILL.md` - 技能描述和使用说明
- `package.json` - 技能配置（如果有）
- 其他资源文件

---

## 🔗 相关资源

- [ClawHub](https://clawhub.ai/) - 技能市场
- [OpenClaw 文档](https://docs.openclaw.ai)
- [技能开发指南](https://docs.openclaw.ai/skills/creating)
