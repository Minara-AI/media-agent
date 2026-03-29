# media-agent

Write once, publish everywhere. A Claude Code skill pack for developer content creation.

## What is this?

A set of Claude Code skills that let you write content in conversation and publish to multiple platforms with intelligent per-platform adaptation. Your content and images live in git. Your repo is your CMS.

Run `/media` and Claude Code will:
1. Brainstorm your topic and create an outline
2. Co-write the article section by section
3. Generate diagrams with [excalidraw-skill](https://github.com/Minara-AI/excalidraw-skill)
4. Adapt content for each platform (blog post, Dev.to article, Hashnode post)
5. Publish everywhere in one go

## Skills

| Skill | What it does |
|-------|-------------|
| `/media` | Full guided workflow (idea → write → image → publish) |
| `/media-setup` | Configure platform connections and API keys |
| `/media-idea` | Brainstorm topics, outlines, and hooks |
| `/media-write` | Guided co-creation writing + variant generation |
| `/media-image` | Generate diagrams (excalidraw) and hero images (OpenAI/Flux/Ideogram) |
| `/media-publish` | Publish to all configured platforms |

Each skill works independently. Use `/media` for the full workflow, or run individual skills as needed.

## Platforms

### v1.0 (ready)

| Platform | How it publishes |
|----------|-----------------|
| GitHub Pages / Jekyll | Commits markdown to your blog repo |
| Dev.to | Creates a draft via API |
| Hashnode | Creates a post via GraphQL API |

### v1.1 (adapter skeleton included, publish.sh not yet implemented)

| Platform | How it publishes | Notes |
|----------|-----------------|-------|
| Twitter/X | Thread via API v2 | Free tier: 17 tweets/day. Thread = chained replies. |
| 微信公众号 | Draft → publish via MP API | Requires appid+secret+IP whitelist. Content converted to HTML. |

### Planned (v2)

- 小红书 (Xiaohongshu/RED) — requires enterprise certification
- 知乎 (Zhihu) — no official publish API, needs workaround
- Medium — API frozen since 2017, community-contributed

## Quick Start

```bash
# Clone into your project
git clone https://github.com/Minara-AI/media-agent.git
cd media-agent

# Copy env template
cp .env.example .env

# Run setup wizard in Claude Code
/media-setup

# Start writing!
/media
```

### Install as a global Claude Code skill

```bash
git clone https://github.com/Minara-AI/media-agent.git ~/.claude/skills/media-agent
```

### Optional: Install excalidraw-skill for diagram generation

```bash
git clone https://github.com/Minara-AI/excalidraw-skill.git
cd your-project && bash /path/to/excalidraw-skill/install.sh
```

### Image generation providers

Configure in `.env`:

```bash
IMAGE_PROVIDER=openai   # default, GPT Image, $0.005-0.08/image
# IMAGE_PROVIDER=flux   # Replicate Flux 2, best photorealism, $0.015-0.055/image
# IMAGE_PROVIDER=ideogram # Ideogram v3, best text-in-image (90-95% accuracy), ~$0.04/image
```

## How it works

```
You: "I want to write about building AI agents"
                    │
            ┌───────▼───────┐
            │  /media-idea   │  Brainstorm topic, outline, hooks
            └───────┬───────┘
                    │ brief.yaml
            ┌───────▼───────┐
            │  /media-write  │  Co-write section by section
            └───────┬───────┘
                    │ source.md + variants/
            ┌───────▼───────┐
            │  /media-image  │  Generate diagrams & hero images
            └───────┬───────┘
                    │ assets/
            ┌───────▼───────┐
            │ /media-publish │  Publish to all platforms
            └───────┬───────┘
                    │
    ┌───────────────┼───────────────┐
    ▼               ▼               ▼
 Dev.to        GitHub Pages     Hashnode
```

Content lives in `content/posts/<date>-<slug>/`:
```
content/posts/2026-03-29-building-ai-agents/
├── source.md          # Your article (shared)
├── manifest.yaml      # Tracks publish status per platform
├── brief.yaml         # Topic brief from /media-idea
├── assets/            # Images and diagrams
│   ├── hero.png
│   └── architecture.png
└── variants/          # Platform-adapted versions
    ├── devto.md
    ├── hashnode.md
    └── github-pages.md
```

## Adding a new platform

Each platform adapter is a directory with 3 files:

```
adapters/my-platform/
├── adapter.yaml    # Platform config (auth type, image sizes, etc.)
├── format.md       # Content adaptation rules for Claude
└── publish.sh      # Publish script (any language, must be executable)
```

See [SECURITY.md](SECURITY.md) for the adapter trust model.

## Companion skills

These existing skills work well alongside media-agent:

- [excalidraw-skill](https://github.com/Minara-AI/excalidraw-skill) — Hand-drawn diagrams from natural language (integrated into `/media-image`)
- [content-research-writer](https://github.com/ComposioHQ/awesome-claude-skills/tree/master/content-research-writer) — Research and citation workflow for long-form content

## Running tests

```bash
bash test/validate-adapters.sh    # Validate adapter contracts
bash test/manifest-roundtrip.sh   # Test manifest YAML operations
```

## Security

API keys live in `.env` (gitignored, never committed). Each `publish.sh` is invoked with env var isolation, receiving only its declared credential. See [SECURITY.md](SECURITY.md).

## License

MIT
