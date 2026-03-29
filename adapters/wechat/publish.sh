#!/usr/bin/env bash
set -euo pipefail

# WeChat Official Account adapter — publishes via WeChat MP API
# STATUS: v1.1 — not yet fully implemented
# Flow: get access_token → upload cover → create draft → submit publish
# Usage: publish.sh <variant-file> <assets-dir> [--dry-run]

VARIANT_FILE="${1:?Usage: publish.sh <variant-file> <assets-dir> [--dry-run]}"
ASSETS_DIR="${2:?Usage: publish.sh <variant-file> <assets-dir> [--dry-run]}"
DRY_RUN="${3:-}"

echo "ERROR: WeChat adapter is planned for v1.1. Not yet implemented." >&2
echo "Track progress: https://github.com/Minara-AI/media-agent/issues" >&2

if [ "$DRY_RUN" = "--dry-run" ]; then
  TITLE=$(python3 -c "
import sys
content = open('$VARIANT_FILE').read()
# Extract title from first h2 or first line
import re
m = re.search(r'<h2[^>]*>(.*?)</h2>', content)
print(m.group(1) if m else content[:50])
" 2>/dev/null || echo "untitled")
  echo "{\"url\": \"https://mp.weixin.qq.com/preview\", \"id\": \"dry-run\", \"status\": \"dry_run\", \"title\": \"$TITLE\", \"note\": \"WeChat adapter not yet implemented (v1.1)\"}"
  exit 0
fi

exit 4
