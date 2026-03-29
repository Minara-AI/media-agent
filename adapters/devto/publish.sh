#!/usr/bin/env bash
set -euo pipefail

# Dev.to adapter — publishes via the Dev.to API
# Usage: publish.sh <variant-file> <assets-dir> [--dry-run]

VARIANT_FILE="${1:?Usage: publish.sh <variant-file> <assets-dir> [--dry-run]}"
ASSETS_DIR="${2:?Usage: publish.sh <variant-file> <assets-dir> [--dry-run]}"
DRY_RUN="${3:-}"

if [ -z "${DEVTO_API_KEY:-}" ]; then
  echo "ERROR: DEVTO_API_KEY not set" >&2
  exit 1
fi

# Read the variant file content
CONTENT=$(cat "$VARIANT_FILE")

# Extract frontmatter and body
TITLE=$(python3 -c "
import yaml, sys
content = sys.stdin.read()
parts = content.split('---')
if len(parts) >= 3:
    fm = yaml.safe_load(parts[1])
    print(fm.get('title', ''))
" <<< "$CONTENT")

TAGS=$(python3 -c "
import yaml, sys
content = sys.stdin.read()
parts = content.split('---')
if len(parts) >= 3:
    fm = yaml.safe_load(parts[1])
    tags = fm.get('tags', [])
    print(','.join(tags) if isinstance(tags, list) else str(tags))
" <<< "$CONTENT")

CANONICAL=$(python3 -c "
import yaml, sys
content = sys.stdin.read()
parts = content.split('---')
if len(parts) >= 3:
    fm = yaml.safe_load(parts[1])
    print(fm.get('canonical_url', ''))
" <<< "$CONTENT")

COVER=$(python3 -c "
import yaml, sys
content = sys.stdin.read()
parts = content.split('---')
if len(parts) >= 3:
    fm = yaml.safe_load(parts[1])
    print(fm.get('cover_image', ''))
" <<< "$CONTENT")

# Extract body (everything after second ---)
BODY=$(python3 -c "
import sys
content = sys.stdin.read()
parts = content.split('---', 2)
if len(parts) >= 3:
    print(parts[2].strip())
" <<< "$CONTENT")

if [ "$DRY_RUN" = "--dry-run" ]; then
  echo "{\"url\": \"https://dev.to/preview\", \"id\": \"dry-run\", \"status\": \"dry_run\", \"title\": \"$TITLE\", \"tags\": \"$TAGS\"}"
  exit 0
fi

# Build JSON payload
PAYLOAD=$(python3 -c "
import json, sys
title = '$TITLE'
tags_str = '$TAGS'
canonical = '$CANONICAL'
cover = '$COVER'
body = sys.stdin.read()
tags = [t.strip() for t in tags_str.split(',') if t.strip()][:4]
article = {
    'title': title,
    'body_markdown': body,
    'published': False,
    'tags': tags
}
if canonical:
    article['canonical_url'] = canonical
if cover:
    article['main_image'] = cover
print(json.dumps({'article': article}))
" <<< "$BODY")

# Create article via API
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "https://dev.to/api/articles" \
  -H "api-key: $DEVTO_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY_RESP=$(echo "$RESPONSE" | sed '$d')

case "$HTTP_CODE" in
  201)
    URL=$(python3 -c "import json,sys; print(json.loads(sys.stdin.read())['url'])" <<< "$BODY_RESP")
    ID=$(python3 -c "import json,sys; print(json.loads(sys.stdin.read())['id'])" <<< "$BODY_RESP")
    echo "{\"url\": \"$URL\", \"id\": \"$ID\", \"status\": \"published\"}"
    ;;
  401|403)
    echo "ERROR: Authentication failed. Check your DEVTO_API_KEY." >&2
    exit 1
    ;;
  422)
    echo "ERROR: Content rejected by Dev.to: $BODY_RESP" >&2
    exit 3
    ;;
  429)
    echo "ERROR: Rate limited by Dev.to. Try again later." >&2
    exit 2
    ;;
  *)
    echo "ERROR: Unexpected response ($HTTP_CODE): $BODY_RESP" >&2
    exit 4
    ;;
esac
