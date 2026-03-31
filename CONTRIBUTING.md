# Contributing to media-agent

Thanks for your interest in contributing! media-agent is an open-source project and we welcome contributions of all kinds.

## Ways to Contribute

### Add a New Platform Adapter

This is the most impactful contribution. Each adapter is a self-contained directory with 3 files:

```
adapters/my-platform/
├── adapter.yaml    # Platform config (auth type, image sizes, etc.)
├── format.md       # Content adaptation rules (for Claude to read)
└── publish.sh      # Publish script (any language, must be executable)
```

See [adapters/devto/](adapters/devto/) for a complete example.

**Adapter contract:**
- `publish.sh` accepts: `<variant-file> <assets-dir> [--dry-run]`
- Exit codes: 0=success, 1=auth failure, 2=rate limit, 3=content rejected, 4=other
- Stdout on success: `{"url": "...", "id": "...", "status": "published"}`
- Must support `--dry-run` flag

### Improve Existing Skills

Skills are markdown files in `skills/*/SKILL.md`. If you find a workflow that could be smoother, a prompt that could be clearer, or an edge case that's not handled, submit a PR.

### Report Bugs

Open an issue with:
- What you were trying to do
- What happened instead
- Steps to reproduce
- Your platform (macOS/Linux) and Claude Code version

### Improve Documentation

README, CLAUDE.md, adapter format.md files, and lib/ partials all benefit from clearer writing.

## Development Setup

```bash
git clone https://github.com/Minara-AI/media-agent.git
cd media-agent
cp .env.example .env
# Edit .env with your API keys

# Run tests
bash test/validate-adapters.sh
bash test/manifest-roundtrip.sh
```

## Pull Request Process

1. Fork the repo and create a branch from `main`
2. Make your changes
3. Ensure tests pass: `bash test/validate-adapters.sh`
4. If adding an adapter, verify `--dry-run` works
5. Update README.md if adding new features or platforms
6. Submit a PR with a clear description of what changed and why

## Code Style

- Shell scripts: use `set -euo pipefail`, quote variables
- SKILL.md files: follow the existing structure (frontmatter + sections)
- Adapter `format.md`: must include `## Conventions` and `## Content Adaptation Rules` sections
- Keep it simple. Fewer dependencies is better.

## Security

- Never commit API keys or tokens
- Adapters use `env -i` credential isolation. New adapters must follow this pattern.
- See [SECURITY.md](SECURITY.md) for the adapter trust model

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
