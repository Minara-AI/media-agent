#!/usr/bin/env bash
set -euo pipefail

# Twitter/X adapter — publishes threads via bb-browser (Chrome automation)
# Zero cost, no API key needed.
# Requires: Chrome with --remote-debugging-port=9222, bb-browser CLI, logged-in Twitter.
# Usage: publish.sh <variant-file> <assets-dir> [--dry-run]

VARIANT_FILE="${1:?Usage: publish.sh <variant-file> <assets-dir> [--dry-run]}"
ASSETS_DIR="${2:?Usage: publish.sh <variant-file> <assets-dir> [--dry-run]}"
DRY_RUN="${3:-}"

CDP_PORT="${CDP_PORT:-9222}"
export NO_PROXY="*"
export no_proxy="*"

BB="bb-browser"
which $BB >/dev/null 2>&1 || { echo "ERROR: bb-browser not installed. Run: npm install -g bb-browser" >&2; exit 4; }

# Verify Chrome CDP (bypass proxy) — skip for dry-run
if [ "$DRY_RUN" != "--dry-run" ]; then
  curl -s --noproxy '*' "http://127.0.0.1:$CDP_PORT/json/version" >/dev/null 2>&1 || {
    echo "ERROR: Chrome not running with debugging port. Start Chrome with:" >&2
    echo '  /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222 --user-data-dir=$HOME/chrome-mcp-profile' >&2
    exit 4
  }
fi

# bb-browser wrapper: captures stdout only, tips/warnings go to /dev/null via stderr
bb_run() {
  $BB --port "$CDP_PORT" "$@" 2>/dev/null
}

# bb-browser wrapper for snapshot: need full stdout
bb_snap() {
  $BB --port "$CDP_PORT" snapshot "$@" 2>/dev/null
}

# bb-browser wrapper for eval: only the JS result matters
bb_eval() {
  $BB --port "$CDP_PORT" eval "$1" 2>/dev/null
}

# Extract ref number from snapshot line using sed (macOS compatible)
extract_ref() {
  sed 's/.*\[ref=\([0-9]*\)\].*/\1/'
}

# ── Parse thread from variant file ──
TWEETS_JSON=$(mktemp /tmp/media-agent-tweets-XXXXXX.json)
trap "rm -f $TWEETS_JSON" EXIT

python3 - "$VARIANT_FILE" "$TWEETS_JSON" << 'PYEOF'
import sys, json
content = open(sys.argv[1]).read().strip()
parts, current = [], []
for line in content.split('\n'):
    if line.strip() == '---':
        if current:
            parts.append('\n'.join(current).strip())
            current = []
    else:
        current.append(line)
if current:
    parts.append('\n'.join(current).strip())
parts = [p for p in parts if p]
with open(sys.argv[2], 'w') as f:
    json.dump(parts, f, ensure_ascii=False)
print(f"Thread: {len(parts)} tweets", file=sys.stderr)
PYEOF

TWEET_COUNT=$(python3 -c "import json; print(len(json.load(open('$TWEETS_JSON'))))")
get_tweet() { python3 -c "import json; print(json.load(open('$TWEETS_JSON'))[$1])"; }

# ── Dry run ──
if [ "$DRY_RUN" = "--dry-run" ]; then
  python3 - "$TWEETS_JSON" << 'DRYEOF'
import json, sys
tweets = json.load(open(sys.argv[1]))
print('=== Twitter Thread Preview (bb-browser) ===', file=sys.stderr)
for i, t in enumerate(tweets, 1):
    c = len(t)
    s = 'OK' if c <= 280 else 'TOO LONG'
    p = t[:100] + '...' if len(t) > 100 else t
    print(f'  [{i}/{len(tweets)}] ({c} chars) [{s}]\n  {p}\n', file=sys.stderr)
over = [i+1 for i, t in enumerate(tweets) if len(t) > 280]
if over: print(f'WARNING: Tweets {over} exceed 280 chars limit', file=sys.stderr)
print(json.dumps({'url':'https://x.com/preview','id':'dry-run','status':'dry_run','tweets':len(tweets)}))
DRYEOF
  exit 0
fi

echo "Publishing thread ($TWEET_COUNT tweets) via bb-browser..." >&2

# ── Helper: get screen name ──
get_screen_name() {
  bb_eval '(function(){ var el=document.querySelector("[data-testid=\"AppTabBar_Profile_Link\"]"); return el ? el.getAttribute("href").replace("/","") : ""; })()'
}

# ── Helper: find latest tweet URL on current page ──
get_latest_tweet_url() {
  local screen_name="$1"
  bb_eval "(function(){
    var links = document.querySelectorAll('a[href*=\"/status/\"]');
    for(var i=0; i<links.length; i++) {
      var h = links[i].getAttribute('href');
      if(h.match(/\\/${screen_name}\\/status\\/\\d+$/) ) return 'https://x.com' + h;
    }
    return '';
  })()"
}

# ── Helper: click the tweet/reply submit button ──
click_post_button() {
  bb_eval '(function(){ var b=document.querySelector("[data-testid=\"tweetButtonInline\"]"); if(!b||b.disabled)return "not ready"; b.click(); return "posted"; })()'
}

# ── Helper: find reply textbox on a tweet page (with retry) ──
find_reply_textbox() {
  local ref=""
  for attempt in 1 2 3 4; do
    local snap
    snap=$(bb_snap -i -c -d 8)
    ref=$(echo "$snap" | grep 'Post your reply' -A5 | grep 'textbox \[ref=' | head -1 | extract_ref)
    if [ -n "$ref" ]; then
      echo "$ref"
      return 0
    fi
    sleep 2
  done
  return 1
}

# ══════════════════════════════════════
# Step 1: Post first tweet via inline compose
# ══════════════════════════════════════
echo "  [1/$TWEET_COUNT] Posting first tweet..." >&2

bb_run open "https://x.com/home" >/dev/null
sleep 5

# Find inline compose textbox
SNAP=$(bb_snap -i -c -d 6)
TEXTBOX=$(echo "$SNAP" | grep 'textbox.*"Post text"' | head -1 | extract_ref)

if [ -z "$TEXTBOX" ]; then
  echo "ERROR: Could not find compose textbox on home page" >&2
  exit 4
fi

FIRST_TWEET=$(get_tweet 0)
bb_run type "$TEXTBOX" "$FIRST_TWEET" >/dev/null
sleep 1

RESULT=$(click_post_button)
if [ "$RESULT" != "posted" ]; then
  echo "ERROR: Could not post first tweet: $RESULT" >&2
  exit 4
fi
sleep 5
echo "  [1/$TWEET_COUNT] Posted" >&2

# Single tweet? Done.
if [ "$TWEET_COUNT" -eq 1 ]; then
  echo "Thread published (1 tweet)" >&2
  echo '{"url":"https://x.com","id":"single","status":"published","tweets_posted":1}'
  exit 0
fi

# ══════════════════════════════════════
# Step 2: Find the first tweet's URL
# ══════════════════════════════════════
SCREEN_NAME=$(get_screen_name)
if [ -z "$SCREEN_NAME" ]; then
  echo "ERROR: Could not determine screen name" >&2
  exit 4
fi

bb_run open "https://x.com/$SCREEN_NAME" >/dev/null
sleep 5

FIRST_TWEET_URL=$(get_latest_tweet_url "$SCREEN_NAME")
if [ -z "$FIRST_TWEET_URL" ]; then
  echo "ERROR: Could not find first tweet URL on profile page" >&2
  echo '{"url":"https://x.com","id":"partial","status":"partial","tweets_posted":1,"tweets_total":'"$TWEET_COUNT"'}'
  exit 4
fi

echo "  First tweet: $FIRST_TWEET_URL" >&2
REPLY_TO_URL="$FIRST_TWEET_URL"

# ══════════════════════════════════════
# Step 3: Post remaining tweets as replies
# ══════════════════════════════════════
for i in $(seq 1 $((TWEET_COUNT - 1))); do
  TWEET_NUM=$((i + 1))
  echo "  [$TWEET_NUM/$TWEET_COUNT] Replying..." >&2

  TWEET_TEXT=$(get_tweet "$i")

  # Open the tweet we're replying to
  bb_run open "$REPLY_TO_URL" >/dev/null
  sleep 5

  # Find reply textbox
  REPLY_REF=$(find_reply_textbox)
  if [ -z "$REPLY_REF" ]; then
    echo "ERROR: Could not find reply box for tweet $TWEET_NUM after 4 attempts" >&2
    echo "{\"url\":\"$FIRST_TWEET_URL\",\"id\":\"partial\",\"status\":\"partial\",\"tweets_posted\":$i,\"tweets_total\":$TWEET_COUNT}"
    exit 4
  fi

  bb_run type "$REPLY_REF" "$TWEET_TEXT" >/dev/null
  sleep 1

  RESULT=$(click_post_button)
  if [ "$RESULT" != "posted" ]; then
    echo "ERROR: Could not post reply $TWEET_NUM: $RESULT" >&2
    echo "{\"url\":\"$FIRST_TWEET_URL\",\"id\":\"partial\",\"status\":\"partial\",\"tweets_posted\":$i,\"tweets_total\":$TWEET_COUNT}"
    exit 4
  fi
  sleep 5

  # Get the URL of the reply we just posted for the next reply in chain
  # After posting a reply, the page shows the thread. Find the latest reply.
  NEW_URL=$(get_latest_tweet_url "$SCREEN_NAME")
  if [ -n "$NEW_URL" ] && [ "$NEW_URL" != "$REPLY_TO_URL" ]; then
    REPLY_TO_URL="$NEW_URL"
  fi
  # If URL didn't change (page not refreshed), navigate to profile to find it
  if [ "$NEW_URL" = "$REPLY_TO_URL" ] || [ -z "$NEW_URL" ]; then
    bb_run open "https://x.com/$SCREEN_NAME" >/dev/null
    sleep 4
    NEW_URL=$(get_latest_tweet_url "$SCREEN_NAME")
    [ -n "$NEW_URL" ] && REPLY_TO_URL="$NEW_URL"
  fi

  echo "  [$TWEET_NUM/$TWEET_COUNT] Posted" >&2
done

echo "Thread published ($TWEET_COUNT tweets)" >&2
echo "{\"url\":\"$FIRST_TWEET_URL\",\"id\":\"thread\",\"status\":\"published\",\"tweets_posted\":$TWEET_COUNT}"
