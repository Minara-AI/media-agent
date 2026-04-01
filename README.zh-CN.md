# media-agent

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/Minara-AI/media-agent/actions/workflows/test.yml/badge.svg)](https://github.com/Minara-AI/media-agent/actions)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Skills-blueviolet?logo=anthropic&logoColor=white)](https://claude.ai/claude-code)
[![Excalidraw Skill](https://img.shields.io/badge/Excalidraw-Diagrams-6965db?logo=excalidraw&logoColor=white)](https://github.com/Minara-AI/excalidraw-skill)
[![Twitter Bridge](https://img.shields.io/badge/Twitter-bb--browser-000000?logo=x&logoColor=white)](https://github.com/replica882/twitter-bridge-mcp)
[![bb-browser](https://img.shields.io/badge/bb--browser-Chrome_Automation-45ba4b)](https://github.com/epiral/bb-browser)

[English](README.md)

**写一次，发布到所有平台。** 开源的 Claude Code 技能包，面向开发者的内容创作和多平台发布工具。

在 Claude Code 中运行 `/media`，它会引导你构思选题、共同写作、生成配图、适配各平台格式，然后一键发布。你的内容保存在 Git 仓库里，仓库就是你的 CMS。

## 工作原理

```
你: "我想写一篇关于 AI Agent 的文章"

  /media-idea     →  构思选题、大纲、开头
  /media-write    →  逐节共同写作
  /media-image    →  生成架构图 + 封面图
  /media-publish  →  一键发布到所有平台
```

核心理念：一条 Twitter 线程**不是**博客文章的截断版。它是结构完全不同的作品。media-agent 不做复制粘贴，而是将你的内容**智能适配**成每个平台的最佳原生格式。

## 支持的平台

| 平台 | 状态 | 方式 |
|------|------|------|
| GitHub Pages / Jekyll | 已支持 | git push |
| Dev.to | 已支持 | API |
| Hashnode | 已支持 | GraphQL API |
| Twitter/X | 已支持 | bb-browser（零成本） |
| 微信公众号 | 开发中 | MP API |
| 小红书 | 计划中 | - |
| 知乎 | 计划中 | - |

## 技能列表

| 技能 | 用途 |
|------|------|
| `/media` | 完整引导式工作流（构思 → 写作 → 配图 → 发布） |
| `/media-setup` | 配置平台连接和 API 密钥 |
| `/media-idea` | 头脑风暴：选题、大纲、开头 |
| `/media-write` | 引导式写作 + 生成各平台变体 |
| `/media-image` | 用 [excalidraw-skill](https://github.com/Minara-AI/excalidraw-skill) 画图 + AI 生成封面 |
| `/media-publish` | 一键发布到所有已配置的平台 |

每个技能都可以独立使用。用 `/media` 走完整流程，或按需单独运行某个技能。

## 快速开始

### 方式一：一行命令安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/Minara-AI/media-agent/main/install.sh | bash
```

一行搞定。脚本会自动克隆仓库、安装所有技能，并引导你完成配置。

可以用 `--global` 或 `--local` 跳过选择提示：

```bash
# 全局安装（~/.claude/skills/）
curl -fsSL https://raw.githubusercontent.com/Minara-AI/media-agent/main/install.sh | bash -s -- --global

# 项目级安装（仅当前项目可用）
curl -fsSL https://raw.githubusercontent.com/Minara-AI/media-agent/main/install.sh | bash -s -- --local
```

### 方式二：一句话安装

在 Claude Code 中直接说：

```
帮我安装 media-agent，从 https://github.com/Minara-AI/media-agent 克隆，运行 install.sh，然后帮我配置平台。
```

Claude 会自动克隆仓库、运行安装脚本、引导你配置每个平台。

### 方式三：克隆安装

```bash
git clone https://github.com/Minara-AI/media-agent.git
cd media-agent
bash install.sh
```

安装脚本支持全局安装（`~/.claude/skills/`）和项目级安装（`.claude/skills/`）。还会引导安装可选依赖（excalidraw-skill、bb-browser、twitter-bridge-mcp）。

### 方式四：手动安装

```bash
git clone https://github.com/Minara-AI/media-agent.git ~/.claude/skills/media-agent
```

### 配置

```bash
cp .env.example .env
# 编辑 .env，填入你的 API 密钥
```

然后在 Claude Code 中运行：
```
/media-setup    # 交互式配置向导
```

### 开始写作

```
/media          # 完整引导式工作流
```

或单独使用某个技能：
```
/media-idea     # 只做头脑风暴
/media-write    # 只写作 + 生成变体
/media-publish  # 只发布已有内容
```

## 去 AI 味（人性化写作）

AI 生成的内容一看就是 AI 写的。media-agent 内置了去 AI 味系统：

- **29 种 AI 写作模式**自动检测和改写 — 意义膨胀、AI 高频词（"赋能"、"闭环"、"底层逻辑"）、废话填充、破折号滥用等（基于 [Wikipedia AI Cleanup 项目](https://en.wikipedia.org/wiki/Wikipedia:WikiProject_AI_Cleanup)）
- **中文专项规则** — 反成语堆砌、口语化表达、打破过于工整的结构
- **个人风格校准** — 在 `/media-setup` 中粘贴你以前写的文章，系统会匹配你的个人风格，而不是套用通用规则

两层防护：
1. **写作时** — `/media-write` 起草每个段落时就遵循去 AI 味规则
2. **审计时** — 全文完成后专门扫描一遍，逐条找出残留的 AI 模式并展示修改内容

## 图片生成

通过 `.env` 中的 `IMAGE_PROVIDER` 配置后端：

| 提供商 | 适合场景 | 价格 |
|--------|---------|------|
| OpenRouter（默认） | 一个 key 搞定 LLM + 图片 | 最便宜 |
| OpenAI | 通用 | $0.005-0.08/张 |
| Flux | 写实风格 | $0.015-0.055/张 |
| Ideogram | 图片上的文字（90-95% 准确率） | ~$0.04/张 |

架构图使用 [excalidraw-skill](https://github.com/Minara-AI/excalidraw-skill) 生成手绘风格输出。

## 内容结构

```
content/posts/2026-03-29-my-post/
├── source.md          # 你的文章（源文件）
├── manifest.yaml      # 追踪各平台发布状态
├── brief.yaml         # /media-idea 生成的选题简报
├── assets/            # 图片和架构图
└── variants/          # 各平台适配版本
    ├── devto.md
    ├── hashnode.md
    ├── github-pages.md
    └── twitter.md
```

内容保存在 Git 中。`manifest.yaml` 追踪每篇文章在每个平台的发布状态。仓库就是你的 CMS。

## 添加新平台

每个适配器是一个包含 3 个文件的目录：

```
adapters/my-platform/
├── adapter.yaml    # 平台配置（认证方式、图片尺寸）
├── format.md       # 内容适配规则（给 Claude 看的）
└── publish.sh      # 发布脚本（任何语言）
```

`publish.sh` 合约：
- 参数：`<variant-file> <assets-dir> [--dry-run]`
- 退出码：0=成功，1=认证失败，2=限流，3=内容被拒，4=其他
- 标准输出：`{"url": "...", "id": "...", "status": "published"}`

凭证通过 `env -i` 隔离传入，每个脚本只能访问它声明需要的那一个 API Key。详见 [SECURITY.md](SECURITY.md)。

## Twitter 零成本发布

Twitter 适配器使用 [bb-browser](https://github.com/epiral/bb-browser) 自动化控制 Chrome，不走官方 API。**零成本，不需要 API Key。** 只需在 Chrome 中登录 Twitter，适配器就能通过控制浏览器发布线程。

设置：
```bash
npm install -g bb-browser
# 启动带调试端口的 Chrome
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222 --user-data-dir=$HOME/chrome-mcp-profile
# 在 Chrome 窗口中登录 Twitter
```

## 配套技能

- [excalidraw-skill](https://github.com/Minara-AI/excalidraw-skill) — 用自然语言生成手绘风格架构图（已集成到 `/media-image`）
- [content-research-writer](https://github.com/ComposioHQ/awesome-claude-skills/tree/master/content-research-writer) — 长文写作的研究和引用工作流

## 运行测试

```bash
bash test/validate-adapters.sh    # 验证适配器合约
bash test/manifest-roundtrip.sh   # 测试 manifest YAML 操作
```

## 贡献

参见 [CONTRIBUTING.md](CONTRIBUTING.md)。最简单的贡献方式是添加新的平台适配器。

## 许可证

[MIT](LICENSE)
