# Platform: Hashnode

## Conventions
- Articles use markdown (no frontmatter in body, metadata via API)
- Code blocks are syntax-highlighted with language tags
- No length limit (but 2000-4000 words performs best)
- Tags are passed via API, not in the markdown
- Hashnode renders markdown with its own processor
- Images referenced by URL

## Metadata (passed via API, not in markdown)
- title: string
- subtitle: string (optional, shown below title)
- tags: array of tag objects
- canonical_url: string
- cover_image_url: string
- publication_id: string (your blog's Hashnode ID)

## Content Adaptation Rules
- Write the article body as clean markdown, NO frontmatter
- Use h2 (##) for main sections, h3 (###) for subsections
- Convert relative image paths to absolute URLs
- Hashnode supports GitHub-flavored markdown including tables
- Add a brief closing section encouraging discussion
- Keep paragraphs concise, break up long blocks of text
- Use bold for key terms on first introduction

## Example Output
```markdown
AI agents are changing how we build software. In this tutorial, I'll walk you through building your first agent using Claude Code skills.

## Why AI Agents Matter

**AI agents** go beyond simple chat. They can read your codebase, execute commands, and make decisions autonomously...

![Architecture diagram](https://raw.githubusercontent.com/user/repo/main/assets/diagram-1.png)

## Getting Started

More content here...

## Wrapping Up

Content here...

---

*What's your experience with AI agents? Drop a comment below!*
```
