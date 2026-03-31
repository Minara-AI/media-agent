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

# Verify Chrome CDP
curl -s --noproxy '*' "http://127.0.0.1:$CDP_PORT/json/version" >/dev/null 2>&1 || {
  echo "ERROR: Chrome not running with debugging port." >&2
  exit 4
}

bb() { $BB --port "$CDP_PORT" "$@" 2>/dev/null; }

# Parse thread from variant file
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
print(json.dumps({'url':'https://x.com/preview','id':'dry-run','status':'dry_run','tweets':len(tweets)}))
DRYEOF
  exit 0
fi

echo "Publishing thread ($TWEET_COUNT tweets) via bb-browser..." >&2

get_tweet() { python3 -c "import json; print(json.load(open('$TWEETS_JSON'))[$1])"; }

# === Post first tweet via inline compose ===
echo "  [1/$TWEET_COUNT] Posting first tweet..." >&2

bb open "https://x.com/home"
sleep 4

# Find inline compose textbox
SNAP=$(bb snapshot -i -c -d 6)
TEXTBOX=$(echo "$SNAP" | grep -o 'textbox \[ref=[0-9]*\] "Post text"' | head -1 | sed 's/.*ref=\([0-9]*\).*/\1/')

if [ -z "$TEXTBOX" ]; then
  echo "ERROR: Could not find compose textbox on home page" >&2
  exit 4
fi

FIRST_TWEET=$(get_tweet 0)
bb type "$TEXTBOX" "$FIRST_TWEET"
sleep 1

# Click post button via JS (data-testid is reliable)
RESULT=$(bb eval '(function(){ var b=document.querySelector("[data-testid=\"tweetButtonInline\"]"); if(!b||b.disabled)return "not ready"; b.click(); return "posted"; })()')

if [ "$RESULT" != "posted" ]; then
  echo "ERROR: Could not post first tweet: $RESULT" >&2
  exit 4
fi

sleep 4
echo "  [1/$TWEET_COUNT] Posted" >&2

# === Get the URL of the tweet we just posted ===
# Navigate to profile and find the latest tweet
SCREEN_NAME=$(bb eval '(function(){ var el=document.querySelector("[data-testid=\"AppTabBar_Profile_Link\"]"); return el ? el.getAttribute("href").replace("/","") : ""; })()')

if [ -z "$SCREEN_NAME" ]; then
  echo "ERROR: Could not determine screen name" >&2
  # If only 1 tweet, still success
  if [ "$TWEET_COUNT" -eq 1 ]; then
    echo "{\"url\":\"https://x.com\",\"id\":\"single\",\"status\":\"published\",\"tweets_posted\":1}"
    exit 0
  fi
  exit 4
fi

bb open "https://x.com/$SCREEN_NAME"
sleep 4

# Find the latest tweet URL
LATEST_TWEET_URL=$(bb eval "(function(){
  var articles = document.querySelectorAll('article[data-testid=\"tweet\"]');
  if (!articles.length) return '';
  var a = articles[0].querySelector('a[href*=\"/status/\"]');
  return a ? 'https://x.com' + a.getAttribute('href') : '';
})()")

if [ -z "$LATEST_TWEET_URL" ]; then
  echo "WARN: Could not find tweet URL. Thread may be incomplete." >&2
  if [ "$TWEET_COUNT" -eq 1 ]; then
    echo "{\"url\":\"https://x.com/$SCREEN_NAME\",\"id\":\"posted\",\"status\":\"published\",\"tweets_posted\":1}"
    exit 0
  fi
fi

FIRST_TWEET_URL="$LATEST_TWEET_URL"
REPLY_TO_URL="$LATEST_TWEET_URL"
echo "  First tweet: $FIRST_TWEET_URL" >&2

# === Post remaining tweets as replies ===
for i in $(seq 1 $((TWEET_COUNT - 1))); do
  TWEET_NUM=$((i + 1))
  echo "  [$TWEET_NUM/$TWEET_COUNT] Replying..." >&2

  TWEET_TEXT=$(get_tweet $i)

  # Open the tweet to reply to
  bb open "$REPLY_TO_URL"
  sleep 4

  # Find reply textbox (retry up to 3 times)
  REPLY_REF=""
  for attempt in 1 2 3; do
    SNAP=$(bb snapshot -i -c -d 8)
    REPLY_REF=$(echo "$SNAP" | grep -o 'Post your reply.*textbox \[ref=[0-9]*\]' | head -1 | sed 's/.*ref=\([0-9]*\).*/\1/')
    [ -n "$REPLY_REF" ] && break
    sleep 2
  done

  if [ -z "$REPLY_REF" ]; then
    echo "ERROR: Could not find reply box for tweet $TWEET_NUM" >&2
    echo "{\"url\":\"$FIRST_TWEET_URL\",\"id\":\"partial\",\"status\":\"partial\",\"tweets_posted\":$i,\"tweets_total\":$TWEET_COUNT}"
    exit 4
  fi

  bb type "$REPLY_REF" "$TWEET_TEXT"
  sleep 1

  # Click reply button
  RESULT=$(bb eval '(function(){ var b=document.querySelector("[data-testid=\"tweetButtonInline\"]"); if(!b||b.disabled)return "not ready"; b.click(); return "replied"; })()')

  if [ "$RESULT" != "replied" ]; then
    echo "ERROR: Could not post reply $TWEET_NUM: $RESULT" >&2
    echo "{\"url\":\"$FIRST_TWEET_URL\",\"id\":\"partial\",\"status\":\"partial\",\"tweets_posted\":$i,\"tweets_total\":$TWEET_COUNT}"
    exit 4
  fi

  sleep 4

  # Get URL of the reply we just posted (for next reply in chain)
  REPLY_TO_URL=$(bb eval "(function(){
    var articles = document.querySelectorAll('article[data-testid=\"tweet\"]');
    var last = articles[articles.length - 1];
    if (!last) return '';
    var a = last.querySelector('a[href*=\"/status/\"]');
    return a ? 'https://x.com' + a.getAttribute('href') : '';
  })()")

  [ -z "$REPLY_TO_URL" ] && REPLY_TO_URL="$LATEST_TWEET_URL"

  echo "  [$TWEET_NUM/$TWEET_COUNT] Posted" >&2
done

echo "Thread published ($TWEET_COUNT tweets)" >&2
echo "{\"url\":\"$FIRST_TWEET_URL\",\"id\":\"thread\",\"status\":\"published\",\"tweets_posted\":$TWEET_COUNT}"
