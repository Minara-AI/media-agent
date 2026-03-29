#!/usr/bin/env bash
set -euo pipefail

# GitHub Pages adapter — publishes by committing to a configured git repo
# Usage: publish.sh <variant-file> <assets-dir> [--dry-run]

VARIANT_FILE="${1:?Usage: publish.sh <variant-file> <assets-dir> [--dry-run]}"
ASSETS_DIR="${2:?Usage: publish.sh <variant-file> <assets-dir> [--dry-run]}"
DRY_RUN="${3:-}"

# Read config
CONFIG_FILE="content/config/platforms.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "ERROR: $CONFIG_FILE not found. Run /media-setup first." >&2
  exit 4
fi

# Extract GitHub Pages config (repo path and branch)
PAGES_REPO=$(python3 -c "
import yaml
with open('$CONFIG_FILE') as f:
    c = yaml.safe_load(f)
p = c.get('github_pages', {})
print(p.get('repo_path', ''))
" 2>/dev/null)

PAGES_BRANCH=$(python3 -c "
import yaml
with open('$CONFIG_FILE') as f:
    c = yaml.safe_load(f)
p = c.get('github_pages', {})
print(p.get('branch', 'main'))
" 2>/dev/null)

POSTS_DIR=$(python3 -c "
import yaml
with open('$CONFIG_FILE') as f:
    c = yaml.safe_load(f)
p = c.get('github_pages', {})
print(p.get('posts_dir', '_posts'))
" 2>/dev/null)

if [ -z "$PAGES_REPO" ]; then
  echo "ERROR: github_pages.repo_path not configured in $CONFIG_FILE" >&2
  exit 4
fi

# Extract date and title from variant frontmatter for filename
POST_DATE=$(python3 -c "
import yaml, sys
with open('$VARIANT_FILE') as f:
    content = f.read()
fm = content.split('---')[1] if '---' in content else ''
d = yaml.safe_load(fm) or {}
print(str(d.get('date', ''))[:10])
" 2>/dev/null)

POST_TITLE=$(python3 -c "
import yaml, re, sys
with open('$VARIANT_FILE') as f:
    content = f.read()
fm = content.split('---')[1] if '---' in content else ''
d = yaml.safe_load(fm) or {}
title = d.get('title', 'untitled')
slug = re.sub(r'[^a-z0-9]+', '-', title.lower()).strip('-')
print(slug)
" 2>/dev/null)

FILENAME="${POST_DATE}-${POST_TITLE}.md"

if [ "$DRY_RUN" = "--dry-run" ]; then
  echo "{\"url\": \"https://yourblog.github.io/${POST_TITLE}\", \"id\": \"$FILENAME\", \"status\": \"dry_run\", \"action\": \"would commit $FILENAME to $PAGES_REPO/$POSTS_DIR/\"}"
  exit 0
fi

# Copy variant and assets to the pages repo
DEST_POSTS="$PAGES_REPO/$POSTS_DIR"
DEST_ASSETS="$PAGES_REPO/assets/images"
mkdir -p "$DEST_POSTS" "$DEST_ASSETS"

cp "$VARIANT_FILE" "$DEST_POSTS/$FILENAME"

if [ -d "$ASSETS_DIR" ] && [ "$(ls -A "$ASSETS_DIR" 2>/dev/null)" ]; then
  cp "$ASSETS_DIR"/* "$DEST_ASSETS/" 2>/dev/null || true
fi

# Commit and push
cd "$PAGES_REPO"
git add "$POSTS_DIR/$FILENAME" "assets/images/" 2>/dev/null || true
git commit -m "Add post: $FILENAME" --quiet 2>/dev/null || {
  echo "ERROR: git commit failed" >&2
  exit 4
}
git push origin "$PAGES_BRANCH" --quiet 2>/dev/null || {
  echo "ERROR: git push failed" >&2
  exit 1
}

# Output result
SITE_URL=$(python3 -c "
import yaml
with open('$CONFIG_FILE') as f:
    c = yaml.safe_load(f)
print(c.get('github_pages', {}).get('site_url', 'https://yourblog.github.io'))
" 2>/dev/null)

echo "{\"url\": \"${SITE_URL}/${POST_TITLE}\", \"id\": \"$FILENAME\", \"status\": \"published\"}"
