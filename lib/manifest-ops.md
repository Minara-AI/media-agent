# Manifest Operations

How to read, write, and validate content manifests.

## Manifest location

Each post has a manifest at `content/posts/<slug>/manifest.yaml`.

## Creating a new manifest

After writing `source.md` and generating variants, create `manifest.yaml` with this structure:

```yaml
title: "<post title>"
created: <ISO 8601 timestamp>
updated: <ISO 8601 timestamp>
source: source.md
tags: [<comma-separated tags>]
language: en
canonical_url: "<primary URL where this content lives>"

assets: []

variants:
  <adapter-name>:
    file: variants/<adapter-name>.md
    format: <article|thread>
    status: draft
    error: null
```

## Variant statuses

- `draft` — variant generated, not yet published
- `pending` — publish in progress
- `published` — successfully published (has `url` and `published_at`)
- `failed` — publish attempted, error recorded (has `error` field)
- `skipped` — user chose not to publish to this platform

## Atomic write pattern

IMPORTANT: Always write manifests atomically to prevent corruption.

1. Write to a temp file first:
   ```bash
   # Write YAML content to .manifest.yaml.tmp
   ```

2. Validate the temp file is valid YAML:
   ```bash
   python3 -c "import yaml; yaml.safe_load(open('.manifest.yaml.tmp'))" 2>&1
   ```

3. If valid, backup and replace:
   ```bash
   cp manifest.yaml manifest.yaml.bak 2>/dev/null || true
   mv .manifest.yaml.tmp manifest.yaml
   ```

4. If invalid, report error and keep original manifest intact.

## Updating publish status

After a successful publish:
```yaml
variants:
  devto:
    file: variants/devto.md
    format: article
    status: published
    published_at: <ISO 8601 timestamp>
    url: <published URL from publish.sh stdout>
    error: null
```

After a failed publish:
```yaml
variants:
  devto:
    file: variants/devto.md
    format: article
    status: failed
    error: "<error message from publish.sh stderr>"
```

## Pre-publish validation

Before publishing, verify:
1. `source.md` exists and is non-empty
2. Each variant file listed in the manifest exists and is non-empty
3. All asset files referenced in the manifest exist
4. Skip platforms with status `published` or `skipped`
5. Only attempt platforms with status `draft`, `pending`, or `failed`
