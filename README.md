# media-agent

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/Minara-AI/media-agent/actions/workflows/test.yml/badge.svg)](https://github.com/Minara-AI/media-agent/actions)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Skills-blueviolet?logo=anthropic&logoColor=white)](https://claude.ai/claude-code)

[中文文档](README.zh-CN.md)

**Write once, publish everywhere.** An open-source Claude Code skill pack for developer content creation and multi-platform publishing.

Run `/media` in Claude Code. It brainstorms your topic, co-writes the article, generates diagrams, adapts the content for each platform, and publishes everywhere in one session. Your content lives in Git. Your repo is your CMS.

## How It Works

```
You: "I want to write about building AI agents"

  /media-idea     →  Brainstorm topic, outline, hooks
  /media-write    →  Co-write section by section
  /media-image    →  Generate diagrams + cover images
  /media-publish  →  Publish to all platforms
```

The key insight: a Twitter thread is **not** a truncated blog post. It's a structurally different artifact. media-agent doesn't copy-paste. It **adapts** your content into each platform's native best format.

## Platforms

| Platform | Status | Method |
|----------|--------|--------|
| GitHub Pages / Jekyll | Ready | git push |
| Dev.to | Ready | API |
| Hashnode | Ready | GraphQL API |
| Twitter/X | Ready | bb-browser (zero cost) |
| WeChat Official Account | Planned | MP API |
| Xiaohongshu | Planned | - |
| Zhihu | Planned | - |

## Skills

| Skill | What it does |
|-------|-------------|
| `/media` | Full guided workflow (idea -> write -> image -> publish) |
| `/media-setup` | Configure platform connections and API keys |
| `/media-idea` | Brainstorm topics, outlines, and hooks |
| `/media-write` | Guided co-creation + platform variant generation |
| `/media-image` | Diagrams via [excalidraw-skill](https://github.com/Minara-AI/excalidraw-skill) + AI cover images |
| `/media-publish` | One-command publish to all configured platforms |

Each skill works independently. Use `/media` for the full workflow, or run individual skills as needed.

## Quick Start

### Install

```bash
git clone https://github.com/Minara-AI/media-agent.git
cd media-agent
bash install.sh
```

The installer lets you choose global (`~/.claude/skills/`) or local (`.claude/skills/`) install.

### Configure

```bash
cp .env.example .env
# Edit .env with your API keys
```

Then in Claude Code:
```
/media-setup    # Interactive configuration wizard
```

### Start Writing

```
/media          # Full guided workflow
```

Or use individual skills:
```
/media-idea     # Just brainstorm
/media-write    # Just write + generate variants
/media-publish  # Just publish existing content
```

## Image Generation

Configurable backend via `IMAGE_PROVIDER` in `.env`:

| Provider | Best for | Price |
|----------|----------|-------|
| OpenRouter (default) | One key for LLM + images | Cheapest |
| OpenAI | General purpose | $0.005-0.08/image |
| Flux | Photorealism | $0.015-0.055/image |
| Ideogram | Text on images (90-95% accuracy) | ~$0.04/image |

Architecture diagrams use [excalidraw-skill](https://github.com/Minara-AI/excalidraw-skill) for hand-drawn style output.

## Content Structure

```
content/posts/2026-03-29-my-post/
├── source.md          # Your article (canonical)
├── manifest.yaml      # Tracks publish status per platform
├── brief.yaml         # Topic brief from /media-idea
├── assets/            # Images and diagrams
└── variants/          # Platform-adapted versions
    ├── devto.md
    ├── hashnode.md
    ├── github-pages.md
    └── twitter.md
```

Your content lives in Git. `manifest.yaml` tracks what's published where. Your repo is your CMS.

## Adding a New Platform

Each adapter is a directory with 3 files:

```
adapters/my-platform/
├── adapter.yaml    # Platform config (auth type, image sizes)
├── format.md       # Content adaptation rules (for Claude)
└── publish.sh      # Publish script (any language)
```

`publish.sh` contract:
- Args: `<variant-file> <assets-dir> [--dry-run]`
- Exit codes: 0=success, 1=auth, 2=rate limit, 3=rejected, 4=other
- Stdout: `{"url": "...", "id": "...", "status": "published"}`

Credentials are isolated via `env -i`. Each script only receives the one API key it declares. See [SECURITY.md](SECURITY.md).

## Twitter via bb-browser

The Twitter adapter uses [bb-browser](https://github.com/epiral/bb-browser) to automate Chrome instead of the official API. **Zero cost, no API key needed.** Just log into Twitter in Chrome and the adapter posts threads by controlling the browser.

Setup:
```bash
npm install -g bb-browser
# Start Chrome with debugging port
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222 --user-data-dir=$HOME/chrome-mcp-profile
# Log into Twitter in the Chrome window
```

## Companion Skills

- [excalidraw-skill](https://github.com/Minara-AI/excalidraw-skill) - Hand-drawn diagrams from natural language (integrated into `/media-image`)
- [content-research-writer](https://github.com/ComposioHQ/awesome-claude-skills/tree/master/content-research-writer) - Research and citation workflow for long-form content

## Running Tests

```bash
bash test/validate-adapters.sh    # Validate adapter contracts
bash test/manifest-roundtrip.sh   # Test manifest YAML operations
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The easiest way to contribute is adding a new platform adapter.

## License

[MIT](LICENSE)
