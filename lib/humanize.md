# Humanize — De-AI Writing Guide

Shared library for removing AI-generated writing patterns. Read this file
before writing or revising any content.

Based on Wikipedia's WikiProject AI Cleanup patterns and Chinese content
de-AI techniques.

## Core Principle

LLMs produce text that trends toward the most statistically likely phrasing.
Human writing is specific, uneven, opinionated, and occasionally messy.
The goal is not to trick detectors — it is to write things a real person
would actually say.

## The 29 AI Writing Patterns to Avoid

### Content Patterns

| # | Pattern | Example | Fix |
|---|---------|---------|-----|
| 1 | Significance inflation | "marking a pivotal moment" | State the fact plainly |
| 2 | Notability name-dropping | "featured in Forbes, TechCrunch..." | Only cite if directly relevant |
| 3 | Superficial -ing analyses | "symbolizing, reflecting, showcasing" | Say what it actually does |
| 4 | Promotional language | "breathtaking", "game-changing" | Remove or replace with specifics |
| 5 | Vague attributions | "Experts believe", "Many developers say" | Name the source or drop it |
| 6 | Formulaic challenges | "Despite challenges... continues to" | Be specific about what went wrong |

### Language Patterns

| # | Pattern | Example | Fix |
|---|---------|---------|-----|
| 7 | AI vocabulary | "delve, leverage, landscape, utilize, foster, tapestry, multifaceted, nuanced, comprehensive, robust" | Use plain words: dig into, use, field, area |
| 8 | Copula avoidance | "serves as", "stands as", "features", "boasts" | Just say "is" or "has" |
| 9 | Negative parallelisms | "It's not just X, it's Y" | Pick one point and make it |
| 10 | Rule of three | Always listing exactly 3 items | Vary list lengths: 2, 4, 5 |
| 11 | Synonym cycling | Repeating ideas with different words | Say it once, move on |
| 12 | False ranges | "from architecture to deployment" | Be specific about what you cover |
| 13 | Passive voice / subjectless fragments | "No configuration needed" | Name the actor: "You don't need to configure anything" |

### Style Patterns

| # | Pattern | Example | Fix |
|---|---------|---------|-----|
| 14 | Em dash overuse | "the tool — which is free — works" | Use commas or split into two sentences |
| 15 | Boldface overuse | Random **emphasis** everywhere | Bold only for genuinely key terms |
| 16 | Inline-header lists | "**Label:** content" format | Use normal prose or plain lists |
| 17 | Title Case Headings | "How To Build A Great API" | Sentence case: "How to build a great API" |
| 18 | Decorative emojis | "Let's get started! :rocket:" | Remove unless platform convention |
| 19 | Curly quotes | Typographic quotes in code contexts | Use straight quotes |
| 20 | Hyphenated buzzwords | "cross-functional, data-driven, future-proof" | Unpack: say what you mean |
| 21 | Persuasive authority tropes | "At its core", "What truly matters" | Drop it; start with the point |
| 22 | Signposting announcements | "Let's dive in", "Here's what you need to know" | Just start |
| 23 | Fragmented headers | Headers that need body text to make sense | Headers should stand alone |

### Communication Patterns

| # | Pattern | Example | Fix |
|---|---------|---------|-----|
| 24 | Chatbot artifacts | "I hope this helps! Let me know if..." | Remove entirely |
| 25 | Cutoff disclaimers | "While details are limited..." | Remove or be specific about what's unknown |
| 26 | Sycophantic tone | "Great question!", "Absolutely!" | Don't grade the reader |

### Filler & Hedging

| # | Pattern | Example | Fix |
|---|---------|---------|-----|
| 27 | Filler phrases | "In order to", "It's worth noting that" | "To", or just state it |
| 28 | Excessive hedging | "could potentially possibly help" | One qualifier max |
| 29 | Generic conclusions | "The future looks bright", "Only time will tell" | End with a concrete point or don't conclude |

## Chinese Content (中文去AI味)

When writing in Chinese, also watch for these patterns:

### 结构问题
- **过度结构化**: 不要用"首先、其次、最后"、"第一、第二、第三"等机械排列。真人写作结构更松散，偶尔跳跃。
- **小标题 + emoji 排列**: 每段都带 emoji 小标题是典型 AI 格式，减少使用。
- **万能总结句**: "综上所述"、"总而言之"、"总的来说" — 删掉或换成具体观点。

### 词汇问题
- **成语堆砌**: AI 爱用四字成语显得"有文化"，真人日常写作成语密度低得多。
- **高频 AI 词**: "赋能、驱动、生态、闭环、底层逻辑、颗粒度、抓手" — 用大白话替代。
- **过度修饰**: "深入浅出地探讨"、"全方位多角度" — 删掉修饰，直说。
- **重复连接词**: "不仅……而且"、"无论……都" — 减少使用，换成口语转折。

### 语气问题
- **过于客观**: AI 写作缺少主观判断。加入"我觉得"、"说实话"、"有点意外的是"等个人视角。
- **过于流畅**: 真人写作有停顿、口语化表达、偶尔的不完整句。适当加入语气词。
- **缺少具体例子**: AI 喜欢泛泛而谈。用具体的数字、日期、项目名、个人经历替代概括性描述。

### 修复策略
1. 用第一人称，加入主观感受
2. 打破工整结构，允许段落长短不一
3. 用口语替代书面语（"搞定"代替"完成"，"踩坑"代替"遇到问题"）
4. 举具体例子，带时间和细节
5. 偶尔用反问、自嘲、吐槽增加真实感

## Voice Calibration

If `content/config/voice.yaml` exists, read it before writing. It contains:
- Writing samples from the user
- Extracted voice traits (sentence length, vocabulary level, humor style, etc.)
- Per-platform tone adjustments

When voice.yaml is present, match the user's natural style rather than
applying generic humanization. The user's own patterns take priority
over the rules above.

## How to Apply

This guide is used in two places:

### During drafting (per-section)
Apply these rules as you write each section. Don't draft in AI-speak
and fix later — write naturally from the start.

### Audit pass (after full draft)
After the complete source.md is written, do a dedicated scan:
1. Read the full text looking for each of the 29 patterns
2. Flag any instances found
3. Rewrite flagged passages
4. If the content is in Chinese, also apply the Chinese-specific checks
5. Show the user what changed and why
