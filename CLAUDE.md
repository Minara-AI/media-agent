# media-agent

Open-source Claude Code skill pack for developer content creation and multi-platform publishing.

## What this is

A set of Claude Code skills that let developers write content once and publish to multiple platforms with intelligent per-platform adaptation. Write in conversation, publish everywhere.

## Architecture

- `skills/` — Claude Code skills (SKILL.md format)
- `lib/` — Shared markdown partials that skills read at runtime via the Read tool
- `adapters/` — Platform adapters (adapter.yaml + format.md + publish.sh per platform)
- `content/` — User's content (posts, config, assets)
- `test/` — Adapter contract validation and manifest tests

## Skills

| Skill | Purpose |
|-------|---------|
| `/media` | Master orchestrator — full guided workflow |
| `/media-setup` | Configure platform connections and API keys |
| `/media-idea` | Brainstorm topics, outlines, hooks |
| `/media-write` | Guided co-creation writing + variant generation |
| `/media-image` | Generate and resize images for each platform |
| `/media-publish` | Publish to all configured platforms |

## Key conventions

- **Credentials** live in `.env` (gitignored), never in `platforms.yaml`
- **Manifest** (`manifest.yaml`) tracks publish status per platform. Always validate after writing. Use atomic writes (write to .tmp, then mv).
- **Adapters** are self-contained directories. Each has 3 files: `adapter.yaml`, `format.md`, `publish.sh`
- **publish.sh** is invoked with env var isolation: only the declared `auth_env_var` is passed
- **Sub-skills** must read `lib/*.md` partials at the start before proceeding
- **Orchestrator** (`/media`) is a thin sequencer (~500 lines). Sub-skills are the canonical implementations.

## Platform adapters

**v1.0 (ready):** GitHub Pages (git push), Dev.to (API key), Hashnode (API key + GraphQL)

**v1.1 (skeleton included):** Twitter/X (API v2 thread), 微信公众号 (WeChat MP API, HTML)

**v2 (planned):** 小红书, 知乎, Medium

## Image generation

Configurable backend via `IMAGE_PROVIDER` in `.env`:
- `openai` (default) — GPT Image, general-purpose
- `flux` — Replicate Flux 2, best photorealism
- `ideogram` — Ideogram v3, best text-in-image accuracy

Diagrams use [excalidraw-skill](https://github.com/Minara-AI/excalidraw-skill) (hand-drawn style).

## Running tests

```bash
bash test/validate-adapters.sh
bash test/manifest-roundtrip.sh
```
