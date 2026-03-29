# Platform: GitHub Pages (Jekyll)

## Conventions
- Articles use markdown with YAML frontmatter
- File naming: `YYYY-MM-DD-slug.md` in the `_posts/` directory
- Images are relative paths to an assets directory
- Code blocks use triple backticks with language tags
- No length limit

## Frontmatter Template
```yaml
---
layout: post
title: "{title}"
date: {YYYY-MM-DD HH:MM:SS +timezone}
categories: [{categories}]
tags: [{tags}]
image: /assets/images/{hero_image}
description: "{excerpt, max 160 chars}"
canonical_url: "{canonical_url}"
---
```

## Content Adaptation Rules
- Keep the full article structure (intro, body, conclusion)
- Use relative image paths: `![alt](/assets/images/filename.png)`
- Preserve all code blocks with language tags
- Add a `<!--more-->` tag after the first paragraph for excerpt generation
- Convert any HTML embeds to markdown equivalents where possible
- Keep heading hierarchy (h2 for sections, h3 for subsections, never h1 in body)

## Example Output
```markdown
---
layout: post
title: "Building AI Agents with Claude Code"
date: 2026-03-29 10:00:00 +0800
categories: [ai, tutorial]
tags: [claude-code, agents, ai]
image: /assets/images/hero.png
description: "Learn how to build AI agents using Claude Code skills."
---

AI agents are changing how we build software.

<!--more-->

## Why AI Agents Matter

Content here...

![Architecture diagram](/assets/images/diagram-1.png)
```
