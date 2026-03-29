#!/usr/bin/env bash
set -euo pipefail

# Hashnode adapter — publishes via the Hashnode GraphQL API
# Usage: publish.sh <variant-file> <assets-dir> [--dry-run]

VARIANT_FILE="${1:?Usage: publish.sh <variant-file> <assets-dir> [--dry-run]}"
ASSETS_DIR="${2:?Usage: publish.sh <variant-file> <assets-dir> [--dry-run]}"
DRY_RUN="${3:-}"

if [ -z "${HASHNODE_API_KEY:-}" ]; then
  echo "ERROR: HASHNODE_API_KEY not set" >&2
  exit 1
fi

if [ -z "${HASHNODE_PUBLICATION_ID:-}" ]; then
  echo "ERROR: HASHNODE_PUBLICATION_ID not set" >&2
  exit 1
fi

# Read manifest to get metadata
POST_DIR=$(dirname "$(dirname "$VARIANT_FILE")")
MANIFEST="$POST_DIR/manifest.yaml"

TITLE=$(python3 -c "
import yaml
with open('$MANIFEST') as f:
    m = yaml.safe_load(f)
print(m.get('title', ''))
")

TAGS=$(python3 -c "
import yaml, json
with open('$MANIFEST') as f:
    m = yaml.safe_load(f)
tags = m.get('tags', [])
print(json.dumps([{'name': t, 'slug': t.lower().replace(' ', '-')} for t in tags]))
")

CANONICAL=$(python3 -c "
import yaml
with open('$MANIFEST') as f:
    m = yaml.safe_load(f)
print(m.get('canonical_url', ''))
")

# Read article body (plain markdown, no frontmatter)
BODY=$(cat "$VARIANT_FILE")

if [ "$DRY_RUN" = "--dry-run" ]; then
  echo "{\"url\": \"https://hashnode.com/preview\", \"id\": \"dry-run\", \"status\": \"dry_run\", \"title\": \"$TITLE\"}"
  exit 0
fi

# Build GraphQL mutation
QUERY=$(python3 -c "
import json, sys

title = '''$TITLE'''
body = sys.stdin.read()
pub_id = '$HASHNODE_PUBLICATION_ID'
canonical = '$CANONICAL'
tags = $TAGS

mutation = '''mutation PublishPost(\$input: PublishPostInput!) {
  publishPost(input: \$input) {
    post {
      id
      url
      title
    }
  }
}'''

variables = {
    'input': {
        'title': title,
        'contentMarkdown': body,
        'publicationId': pub_id,
        'tags': tags
    }
}

if canonical:
    variables['input']['originalArticleURL'] = canonical

print(json.dumps({'query': mutation, 'variables': variables}))
" <<< "$BODY")

# Call Hashnode API
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "https://gql.hashnode.com" \
  -H "Authorization: $HASHNODE_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$QUERY")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY_RESP=$(echo "$RESPONSE" | sed '$d')

case "$HTTP_CODE" in
  200)
    # Check for GraphQL errors
    HAS_ERROR=$(python3 -c "
import json, sys
r = json.loads(sys.stdin.read())
print('yes' if 'errors' in r else 'no')
" <<< "$BODY_RESP")

    if [ "$HAS_ERROR" = "yes" ]; then
      ERROR_MSG=$(python3 -c "
import json, sys
r = json.loads(sys.stdin.read())
print(r['errors'][0]['message'])
" <<< "$BODY_RESP")
      echo "ERROR: Hashnode API error: $ERROR_MSG" >&2
      exit 3
    fi

    URL=$(python3 -c "
import json, sys
r = json.loads(sys.stdin.read())
print(r['data']['publishPost']['post']['url'])
" <<< "$BODY_RESP")

    ID=$(python3 -c "
import json, sys
r = json.loads(sys.stdin.read())
print(r['data']['publishPost']['post']['id'])
" <<< "$BODY_RESP")

    echo "{\"url\": \"$URL\", \"id\": \"$ID\", \"status\": \"published\"}"
    ;;
  401|403)
    echo "ERROR: Authentication failed. Check your HASHNODE_API_KEY." >&2
    exit 1
    ;;
  429)
    echo "ERROR: Rate limited by Hashnode. Try again later." >&2
    exit 2
    ;;
  *)
    echo "ERROR: Unexpected response ($HTTP_CODE): $BODY_RESP" >&2
    exit 4
    ;;
esac
