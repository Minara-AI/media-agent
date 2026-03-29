#!/usr/bin/env bash
set -euo pipefail

# Twitter/X adapter — publishes threads via Twitter API v2
# STATUS: v1.1 — not yet fully implemented
# Usage: publish.sh <variant-file> <assets-dir> [--dry-run]

VARIANT_FILE="${1:?Usage: publish.sh <variant-file> <assets-dir> [--dry-run]}"
ASSETS_DIR="${2:?Usage: publish.sh <variant-file> <assets-dir> [--dry-run]}"
DRY_RUN="${3:-}"

echo "ERROR: Twitter adapter is planned for v1.1. Not yet implemented." >&2
echo "Track progress: https://github.com/Minara-AI/media-agent/issues" >&2

if [ "$DRY_RUN" = "--dry-run" ]; then
  # Parse thread for preview
  TWEET_COUNT=$(grep -c "^---$" "$VARIANT_FILE" 2>/dev/null || echo "0")
  TWEET_COUNT=$((TWEET_COUNT + 1))
  echo "{\"url\": \"https://x.com/preview\", \"id\": \"dry-run\", \"status\": \"dry_run\", \"tweets\": $TWEET_COUNT, \"note\": \"Twitter adapter not yet implemented (v1.1)\"}"
  exit 0
fi

exit 4
