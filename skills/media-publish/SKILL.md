---
name: media-publish
description: |
  Publish content to all configured platforms. Reads the content manifest,
  validates files, and invokes each platform's publish.sh with credential
  isolation. Supports --dry-run. Handles partial failures gracefully.
  Works independently — you can write markdown by hand and just use this skill.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - AskUserQuestion
  - Grep
  - Glob
---

# /media-publish — Multi-Platform Publishing

Publish your content to all configured platforms in one go.

## Prerequisites

Before starting, read these shared library files:
- Read `lib/adapter-discovery.md` for adapter invocation patterns
- Read `lib/manifest-ops.md` for manifest format and validation

## Step 1: Locate the Post

If the user specifies a post path, use it. Otherwise, find the most recent post:

```bash
ls -dt content/posts/*/ 2>/dev/null | head -1
```

Verify the post directory contains:
- `source.md` (canonical content)
- `manifest.yaml` (content manifest)
- `variants/` directory with at least one variant file

If any are missing, report what's missing and stop.

## Step 2: Pre-Publish Validation

Read `manifest.yaml` and validate:

1. **Source exists and is non-empty:**
   ```bash
   [ -s "<post_dir>/source.md" ] || echo "ERROR: source.md is empty or missing"
   ```

2. **Each variant file exists and is non-empty:**
   For each variant in the manifest, check the file exists:
   ```bash
   [ -s "<post_dir>/<variant_file>" ] || echo "ERROR: <variant_file> missing"
   ```

3. **Asset files exist** (if referenced in manifest):
   ```bash
   [ -f "<post_dir>/<asset>" ] || echo "WARN: asset <asset> missing"
   ```

4. **Filter publishable variants:**
   Only attempt platforms with status: `draft`, `pending`, or `failed`.
   Skip: `published`, `skipped`.

If no platforms are publishable, tell the user: "All platforms are already published or skipped. Nothing to do."

## Step 3: Check Platform Configuration

For each publishable platform, verify:

1. The adapter directory exists: `adapters/<name>/`
2. The adapter's `publish.sh` is executable
3. The required env var is set in `.env` (for API-based adapters)
4. For git-push adapters, the configured repo path exists

Report any missing configuration and offer to run `/media-setup`.

## Step 4: Confirm with User

Show what will be published:

```
Ready to publish "<title>":

  [PUBLISH] Dev.to — variants/devto.md (draft)
  [PUBLISH] Hashnode — variants/hashnode.md (draft)
  [SKIP]    GitHub Pages — already published
```

Use AskUserQuestion to confirm. Options:
- A) Publish all
- B) Dry run first (preview without publishing)
- C) Select specific platforms
- D) Cancel

## Step 5: Publish

For each platform, invoke the adapter's `publish.sh` with credential isolation.

Read the adapter's `auth_env_var` from `adapter.yaml`, then invoke:

```bash
AUTH_VAR=$(python3 -c "import yaml; print(yaml.safe_load(open('adapters/<name>/adapter.yaml')).get('auth_env_var', ''))")
AUTH_VAL=$(grep "^${AUTH_VAR}=" .env | cut -d= -f2-)

env -i PATH="$PATH" HOME="$HOME" \
  "${AUTH_VAR}=${AUTH_VAL}" \
  ./adapters/<name>/publish.sh "<post_dir>/variants/<name>.md" "<post_dir>/assets" [--dry-run]
```

For git-push adapters (no auth_env_var):
```bash
env -i PATH="$PATH" HOME="$HOME" GIT_DIR="$(git rev-parse --git-dir)" \
  ./adapters/<name>/publish.sh "<post_dir>/variants/<name>.md" "<post_dir>/assets" [--dry-run]
```

## Step 6: Update Manifest

After each platform publish attempt, update the manifest atomically:

**On success (exit 0):**
Parse the JSON stdout to get `url` and `id`. Update the variant:
```yaml
status: published
published_at: <current ISO timestamp>
url: <url from stdout>
id: <id from stdout>
error: null
```

**On failure (exit 1-4):**
```yaml
status: failed
error: "<stderr output>"
```

Use the atomic write pattern from `lib/manifest-ops.md`:
1. Write to `.manifest.yaml.tmp`
2. Validate YAML
3. Backup original, then `mv` temp to `manifest.yaml`

## Step 7: Report Results

After all platforms are attempted, report:

```
Published "<title>":

  [OK]   Dev.to → https://dev.to/user/post-slug
  [OK]   Hashnode → https://hashnode.com/post/xyz
  [FAIL] GitHub Pages — git push failed (exit 1)

2/3 platforms succeeded. Run /media-publish again to retry failed platforms.
```

If all succeeded:
```
All platforms published successfully!
```

If `--dry-run` was used:
```
Dry run complete. No content was actually published.
Run /media-publish again without --dry-run to publish for real.
```
