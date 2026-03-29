# Platform: Dev.to

## Conventions
- Articles use markdown with YAML frontmatter
- Code blocks are syntax-highlighted with language tags
- Max recommended length: ~3000 words
- Tags: max 4, lowercase, no spaces (use hyphens)
- Supports Liquid tags for embeds ({% embed url %})
- Images referenced by URL (Dev.to does not host images from markdown)

## Frontmatter Template
```yaml
---
title: "{title}"
published: false
tags: [{up to 4 tags, comma-separated}]
canonical_url: "{canonical_url}"
cover_image: "{cover_image_url}"
description: "{excerpt, max 100 chars}"
---
```

## Content Adaptation Rules
- Keep the full article structure (intro, body, conclusion)
- Convert relative image paths to absolute URLs (GitHub raw URLs or CDN)
- Wrap code examples in language-tagged fences
- Use h2 (##) for main sections, h3 (###) for subsections
- Add a brief "Connect with me" section at the end with relevant links
- Do NOT use h1 (#) in the body — the title is rendered as h1 by Dev.to
- For embedded content (YouTube, CodePen), use Liquid tags: `{% embed https://... %}`

## Example Output
```markdown
---
title: "Building AI Agents with Claude Code"
published: false
tags: [claude, ai, agents, tutorial]
canonical_url: "https://yourblog.github.io/building-ai-agents"
cover_image: "https://raw.githubusercontent.com/user/repo/main/content/posts/2026-03-29-ai-agents/assets/hero-devto.png"
description: "Learn how to build AI agents using Claude Code skills"
---

AI agents are changing how we build software. In this tutorial, I'll walk you through building your first agent using Claude Code skills.

## Why AI Agents Matter

Content here...

![Architecture diagram](https://raw.githubusercontent.com/user/repo/main/content/posts/2026-03-29-ai-agents/assets/diagram-1.png)

## Getting Started

More content...

---

*Found this helpful? Follow me for more AI engineering content.*
```
