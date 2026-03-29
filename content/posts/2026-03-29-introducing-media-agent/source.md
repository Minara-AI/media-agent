# 介绍 media-agent：写一次，发布到所有平台

## 开发者写博客的痛点

如果你是一个喜欢写技术博客的开发者，你大概率经历过这样的流程：

在编辑器里用 Markdown 写完一篇文章，然后开始漫长的"发布之旅"。先复制到 Dev.to，调格式、加 frontmatter、上传封面图。再打开 Hashnode，重新粘贴一遍，改一下标签格式。然后是 GitHub Pages 博客，要 commit 到 `_posts/` 目录，图片路径还得换成相对路径。想发一条 Twitter 线程？得把 3000 字的文章拆成 10 条 280 字以内的推文。微信公众号？Markdown 转 HTML，所有样式还得内联……

这不是写作，这是搬砖。

内容只写了一次，但发布的体力活重复了五次。更糟糕的是，大部分跨平台发布工具都是"傻管道"——它们只会把同一段文字复制粘贴到不同的地方，不会理解一条 Twitter 线程和一篇博客文章在结构上是完全不同的东西。

## 什么是 media-agent

[media-agent](https://github.com/Minara-AI/media-agent) 是一套开源的 Claude Code Skills，让你在终端里完成从构思到发布的整个内容创作流程。

它的核心理念是**写一次，智能适配到每个平台**。不是简单地截断或复制粘贴，而是真正理解每个平台的特点，生成结构性不同的内容变体。

media-agent 包含 6 个 Skill：

| Skill | 用途 |
|-------|------|
| `/media` | 主编排器——完整的引导式工作流 |
| `/media-setup` | 配置平台连接和 API 密钥 |
| `/media-idea` | 头脑风暴：话题、大纲、开头 |
| `/media-write` | 引导式写作 + 生成各平台变体 |
| `/media-image` | 用 Excalidraw 画图 + AI 生成封面 |
| `/media-publish` | 一键发布到所有已配置的平台 |

每个 Skill 都可以独立使用。你可以只用 `/media-publish` 来发布手写的 Markdown，也可以用 `/media` 走完整流程。

## 工作流程演示

假设你想写一篇关于 AI Agent 的文章。在 Claude Code 里输入：

```
/media
```

Claude 会开始和你对话：

**第一步：构思**——问你想写什么，帮你打磨选题和大纲。输出一个 `brief.yaml`。

**第二步：写作**——逐节共创。Claude 提出每一节的初稿，你给反馈（"再短一点"、"加个代码示例"），确认后写入 `source.md`。

**第三步：生成图片**——自动分析文章内容，用 [excalidraw-skill](https://github.com/Minara-AI/excalidraw-skill) 生成手绘风格的架构图和流程图。封面图可以用 OpenAI、Flux 或 Ideogram 生成。

**第四步：发布**——读取每个平台适配器的规则，生成平台特定的变体（Dev.to 带 frontmatter 的 Markdown、GitHub Pages 带 Jekyll 头的 Markdown、Twitter 线程……），然后通过各平台的 API 一键发布。

整个过程，你的内容和图片都保存在 Git 仓库里。`manifest.yaml` 追踪每篇文章在每个平台的发布状态。你的仓库就是你的 CMS。

## 核心设计决策

### "适配"不是"截断"

这是 media-agent 和其他跨平台发布工具最大的区别。

一条 Twitter 线程不是把博客文章砍到 280 字。它是一个结构完全不同的作品——每条推文都是一个独立的观点，有自己的节奏。一篇微信公众号文章需要内联样式的 HTML，因为微信会剥离所有外部 CSS。Dev.to 支持 Liquid 标签嵌入。

media-agent 的每个平台适配器包含一个 `format.md` 文件，用自然语言描述该平台的内容规范。Claude 读这个文件，按照规则把 `source.md` 改写成平台原生的最佳格式。

### 三文件适配器合约

添加一个新平台只需要创建一个目录，包含三个文件：

```
adapters/my-platform/
├── adapter.yaml    # 平台配置（认证方式、图片尺寸等）
├── format.md       # 内容适配规则（给 Claude 看的）
└── publish.sh      # 发布脚本（任何语言，可执行即可）
```

`publish.sh` 接收变体文件和资源目录作为参数，成功时输出 JSON（包含发布 URL），失败时返回对应的退出码。凭证通过环境变量隔离传入——每个脚本只能访问它声明需要的那一个 API Key。

### 图片生成可配置

media-agent 不绑死某个图片生成 API。通过 `.env` 中的 `IMAGE_PROVIDER` 配置：

- **OpenAI (GPT Image)** — 通用性强，适合大部分场景
- **Flux** — 写实风格最强，性价比高
- **Ideogram** — 文字渲染准确率 90-95%，适合封面带标题的场景

架构图和流程图则使用 [excalidraw-skill](https://github.com/Minara-AI/excalidraw-skill)，生成手绘风格的 Excalidraw 图片。

## 开始使用

```bash
# 克隆项目
git clone https://github.com/Minara-AI/media-agent.git
cd media-agent

# 复制环境变量模板
cp .env.example .env
# 编辑 .env，填入你的 API Key

# 在 Claude Code 中运行配置向导
/media-setup

# 开始你的第一篇文章
/media
```

### 当前支持的平台

- **GitHub Pages** — 纯 Git 操作，最简单
- **Dev.to** — API Key 即可，免费
- **Hashnode** — GraphQL API

Twitter/X 和微信公众号的适配器正在开发中。

项目完全开源，欢迎贡献新的平台适配器：[github.com/Minara-AI/media-agent](https://github.com/Minara-AI/media-agent)
