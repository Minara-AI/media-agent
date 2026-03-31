# Changelog

## [0.1.0] - 2026-03-31

### Added
- 6 Claude Code skills: `/media`, `/media-setup`, `/media-idea`, `/media-write`, `/media-image`, `/media-publish`
- 5 platform adapters: GitHub Pages, Dev.to, Hashnode, Twitter/X (bb-browser), WeChat (skeleton)
- 3 shared lib partials: adapter-discovery, manifest-ops, image-processing
- Configurable image generation: OpenRouter (recommended), OpenAI, Flux, Ideogram
- excalidraw-skill integration for hand-drawn diagrams
- Twitter/X thread publishing via bb-browser (zero-cost, no API key)
- Adapter contract: 3 files per platform (adapter.yaml, format.md, publish.sh)
- Credential isolation via `env -i` per adapter
- Content manifest (YAML) tracking publish status per platform
- One-command installer (install.sh) with global/local install support
- Test suite: adapter contract validation + manifest round-trip tests
- GitHub Actions CI pipeline
