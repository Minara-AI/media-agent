#!/usr/bin/env bash
set -euo pipefail

# WeChat Official Account adapter — publishes via WeChat MP API
# Flow: get access_token → upload cover → upload content images → create draft → submit publish
# Usage: publish.sh <variant-file> <assets-dir> [--dry-run]

VARIANT_FILE="${1:?Usage: publish.sh <variant-file> <assets-dir> [--dry-run]}"
ASSETS_DIR="${2:?Usage: publish.sh <variant-file> <assets-dir> [--dry-run]}"
DRY_RUN="${3:-}"

if [ -z "${WECHAT_APP_ID:-}" ]; then
  echo "ERROR: WECHAT_APP_ID not set" >&2
  exit 1
fi

if [ -z "${WECHAT_APP_SECRET:-}" ]; then
  echo "ERROR: WECHAT_APP_SECRET not set" >&2
  exit 1
fi

# Read manifest for metadata
POST_DIR=$(dirname "$(dirname "$VARIANT_FILE")")
MANIFEST="$POST_DIR/manifest.yaml"

export MANIFEST
METADATA=$(python3 << 'PYEOF'
import yaml, json, os
with open(os.environ["MANIFEST"]) as f:
    m = yaml.safe_load(f)
print(json.dumps({
    "title": m.get("title", "")[:64],
    "author": m.get("author", ""),
    "digest": m.get("excerpt", m.get("description", ""))[:120],
    "canonical_url": m.get("canonical_url", ""),
    "tags": m.get("tags", [])
}))
PYEOF
)
export METADATA

TITLE=$(echo "$METADATA" | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['title'])" 2>/dev/null || echo "")

if [ "$DRY_RUN" = "--dry-run" ]; then
  echo "{\"url\": \"https://mp.weixin.qq.com/preview\", \"id\": \"dry-run\", \"status\": \"dry_run\", \"title\": \"$TITLE\"}"
  exit 0
fi

# --- Step 1: Get access_token ---
TOKEN_RESP=$(curl -s -X POST "https://api.weixin.qq.com/cgi-bin/stable_token" \
  -H "Content-Type: application/json" \
  -d "{\"grant_type\":\"client_credential\",\"appid\":\"$WECHAT_APP_ID\",\"secret\":\"$WECHAT_APP_SECRET\"}")

ACCESS_TOKEN=$(echo "$TOKEN_RESP" | python3 -c "
import json,sys
r=json.loads(sys.stdin.read())
if 'access_token' in r:
    print(r['access_token'])
else:
    print('ERROR: '+r.get('errmsg','unknown'), file=sys.stderr); sys.exit(1)
") || { echo "ERROR: Failed to get access_token. Check WECHAT_APP_ID/WECHAT_APP_SECRET and IP whitelist." >&2; exit 1; }

export ACCESS_TOKEN

# --- Step 2: Upload cover image (thumb) ---
THUMB_FILE=""
for ext in png jpg jpeg; do
  for prefix in thumb cover header banner; do
    candidate="$ASSETS_DIR/${prefix}.$ext"
    if [ -f "$candidate" ]; then
      THUMB_FILE="$candidate"
      break 2
    fi
    candidate="$ASSETS_DIR/${prefix}-wechat.$ext"
    if [ -f "$candidate" ]; then
      THUMB_FILE="$candidate"
      break 2
    fi
  done
done

if [ -z "$THUMB_FILE" ]; then
  THUMB_FILE=$(find "$ASSETS_DIR" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | head -1 || true)
fi

if [ -z "$THUMB_FILE" ]; then
  echo "ERROR: No cover image found in $ASSETS_DIR. WeChat requires a thumb image." >&2
  exit 3
fi

THUMB_RESP=$(curl -s -X POST \
  "https://api.weixin.qq.com/cgi-bin/material/add_material?access_token=$ACCESS_TOKEN&type=thumb" \
  -F "media=@$THUMB_FILE")

THUMB_MEDIA_ID=$(echo "$THUMB_RESP" | python3 -c "
import json,sys
r=json.loads(sys.stdin.read())
if 'media_id' in r:
    print(r['media_id'])
else:
    print('ERROR: '+r.get('errmsg',str(r)), file=sys.stderr); sys.exit(1)
") || { echo "ERROR: Failed to upload cover image." >&2; exit 3; }

export THUMB_MEDIA_ID

# --- Step 3: Upload content images and replace src URLs ---
export VARIANT_FILE ASSETS_DIR

CONTENT=$(python3 << 'PYEOF'
import re, json, subprocess, sys, os

content = open(os.environ["VARIANT_FILE"]).read()
assets_dir = os.environ["ASSETS_DIR"]
access_token = os.environ["ACCESS_TOKEN"]

def upload_image(filepath):
    resp = subprocess.run(
        ["curl", "-s", "-X", "POST",
         "https://api.weixin.qq.com/cgi-bin/media/uploadimg?access_token=" + access_token,
         "-F", "media=@" + filepath],
        capture_output=True, text=True
    )
    try:
        r = json.loads(resp.stdout)
        if "url" in r:
            return r["url"]
        print("WARNING: image upload failed for " + filepath + ": " + r.get("errmsg", ""), file=sys.stderr)
    except json.JSONDecodeError:
        print("WARNING: image upload response not JSON for " + filepath, file=sys.stderr)
    return None

def replace_img(match):
    full = match.group(0)
    src = match.group(1)
    if src.startswith("http"):
        return full
    filepath = os.path.join(assets_dir, os.path.basename(src))
    if not os.path.isfile(filepath):
        filepath = src
    if os.path.isfile(filepath):
        wx_url = upload_image(filepath)
        if wx_url:
            return full.replace(src, wx_url)
    return full

img_pat = re.compile(r'<img[^>]+src=["\x27]([^"\x27]+)["\x27]')
content = re.sub(img_pat, replace_img, content)
print(content)
PYEOF
)

# --- Step 4: Create draft ---
export WX_CONTENT="$CONTENT"

DRAFT_PAYLOAD=$(python3 << 'PYEOF'
import json, os

metadata = json.loads(os.environ["METADATA"])
content = os.environ["WX_CONTENT"]
thumb_media_id = os.environ["THUMB_MEDIA_ID"]

article = {
    "title": metadata["title"],
    "author": metadata["author"],
    "digest": metadata["digest"],
    "content": content,
    "thumb_media_id": thumb_media_id,
    "need_open_comment": 1,
    "only_fans_can_comment": 0
}

if metadata.get("canonical_url"):
    article["content_source_url"] = metadata["canonical_url"]

print(json.dumps({"articles": [article]}, ensure_ascii=False))
PYEOF
)

DRAFT_RESP=$(echo "$DRAFT_PAYLOAD" | curl -s -X POST \
  "https://api.weixin.qq.com/cgi-bin/draft/add?access_token=$ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d @-)

DRAFT_MEDIA_ID=$(echo "$DRAFT_RESP" | python3 -c "
import json,sys
r=json.loads(sys.stdin.read())
if 'media_id' in r:
    print(r['media_id'])
else:
    print('ERROR: '+r.get('errmsg',str(r)), file=sys.stderr); sys.exit(1)
") || { echo "ERROR: Failed to create draft. Content may violate WeChat policies." >&2; exit 3; }

# --- Step 5: Submit for publish (requires verified service account) ---
PUBLISH_RESP=$(curl -s -X POST \
  "https://api.weixin.qq.com/cgi-bin/freepublish/submit?access_token=$ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"media_id\":\"$DRAFT_MEDIA_ID\"}")

PUBLISH_ID=$(echo "$PUBLISH_RESP" | python3 -c "
import json,sys
r=json.loads(sys.stdin.read())
if 'publish_id' in r:
    print(r['publish_id'])
elif 'errcode' in r and r['errcode'] == 0:
    print(r.get('publish_id', 'submitted'))
else:
    sys.exit(1)
" 2>/dev/null) || {
  # freepublish requires verified service account; draft was created successfully
  echo "{\"url\": \"https://mp.weixin.qq.com\", \"id\": \"$DRAFT_MEDIA_ID\", \"draft_media_id\": \"$DRAFT_MEDIA_ID\", \"status\": \"draft\", \"title\": \"$TITLE\", \"note\": \"Draft created. Auto-publish unavailable (requires verified service account). Please publish manually at mp.weixin.qq.com.\"}"
  exit 0
}

echo "{\"url\": \"https://mp.weixin.qq.com\", \"id\": \"$PUBLISH_ID\", \"draft_media_id\": \"$DRAFT_MEDIA_ID\", \"status\": \"submitted\", \"title\": \"$TITLE\", \"note\": \"Article submitted for WeChat review. Check mp.weixin.qq.com for publish status.\"}"
