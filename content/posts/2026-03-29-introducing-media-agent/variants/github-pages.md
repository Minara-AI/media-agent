---
layout: post
title: "介绍 media-agent：写一次，发布到所有平台"
date: 2026-03-29 10:00:00 +0800
categories: [tools, open-source]
tags: [claude-code, media-agent, publishing, ai]
description: "开源 Claude Code Skill 套件，让开发者写一次内容，智能适配并发布到多个平台。"
---

如果你是一个喜欢写技术博客的开发者，你大概率经历过这样的流程：在编辑器里用 Markdown 写完一篇文章，然后开始漫长的"发布之旅"。先复制到 Dev.to，调格式、加 frontmatter、上传封面图。再打开 Hashnode，重新粘贴一遍，改一下标签格式。然后是 GitHub Pages 博客，要 commit 到 `_posts/` 目录。想发 Twitter 线程？得把 3000 字拆成 10 条推文……

<!--more-->

这不是写作，这是搬砖。内容只写了一次，但发布的体力活重复了五次。

## 什么是 media-agent

[media-agent](https://github.com/Minara-AI/media-agent) 是一套开源的 Claude Code Skills，让你在终端里完成从构思到发布的整个内容创作流程。

核心理念：**写一次，智能适配到每个平台**。不是简单地截断或复制粘贴，而是真正理解每个平台的特点，生成结构性不同的内容变体。

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

在 Claude Code 里输入 `/media`，Claude 会开始和你对话：

**第一步：构思** — 问你想写什么，帮你打磨选题和大纲。

**第二步：写作** — 逐节共创。Claude 提出每一节的初稿，你给反馈，确认后写入 `source.md`。

**第三步：生成图片** — 用 [excalidraw-skill](https://github.com/Minara-AI/excalidraw-skill) 生成手绘风格的架构图。封面图可以用 OpenAI、Flux 或 Ideogram 生成。

**第四步：发布** — 读取每个平台适配器的规则，生成平台特定的变体，通过 API 一键发布。

整个过程，你的内容和图片都保存在 Git 仓库里。你的仓库就是你的 CMS。

## 核心设计："适配"不是"截断"

这是 media-agent 和其他跨平台发布工具最大的区别。

一条 Twitter 线程不是把博客文章砍到 280 字。它是结构完全不同的作品。微信公众号需要内联样式的 HTML。Dev.to 支持 Liquid 标签嵌入。

每个平台适配器包含一个 `format.md` 文件，用自然语言描述该平台的内容规范。Claude 读这个文件，按照规则把源文件改写成平台原生的最佳格式。

### 三文件适配器合约

添加一个新平台只需要三个文件：

```
adapters/my-platform/
├── adapter.yaml    # 平台配置
├── format.md       # 内容适配规则
└── publish.sh      # 发布脚本
```

凭证通过环境变量隔离传入——每个脚本只能访问它声明需要的那一个 API Key。

## 开始使用

```bash
git clone https://github.com/Minara-AI/media-agent.git
cd media-agent
cp .env.example .env
# 编辑 .env，填入你的 API Key

# 在 Claude Code 中运行
/media-setup    # 配置平台
/media          # 开始写作
```

当前支持 GitHub Pages、Dev.to、Hashnode。Twitter/X 和微信公众号即将支持。

项目完全开源，欢迎贡献：[github.com/Minara-AI/media-agent](https://github.com/Minara-AI/media-agent)
