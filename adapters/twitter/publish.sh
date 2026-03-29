#!/usr/bin/env bash
set -euo pipefail

# Twitter/X adapter — publishes threads via Twitter API v2
# Uses OAuth 1.0a (HMAC-SHA1) for authentication
# Requires: TWITTER_API_KEY, TWITTER_API_SECRET, TWITTER_ACCESS_TOKEN, TWITTER_ACCESS_TOKEN_SECRET
# Usage: publish.sh <variant-file> <assets-dir> [--dry-run]

VARIANT_FILE="${1:?Usage: publish.sh <variant-file> <assets-dir> [--dry-run]}"
ASSETS_DIR="${2:?Usage: publish.sh <variant-file> <assets-dir> [--dry-run]}"
DRY_RUN="${3:-}"

# Validate credentials
for var in TWITTER_API_KEY TWITTER_API_SECRET TWITTER_ACCESS_TOKEN TWITTER_ACCESS_TOKEN_SECRET; do
  if [ -z "${!var:-}" ]; then
    echo "ERROR: $var not set" >&2
    exit 1
  fi
done

# Check Python3 available
which python3 >/dev/null 2>&1 || { echo "ERROR: python3 required for Twitter adapter" >&2; exit 4; }

# Parse thread: split by --- separators
TWEETS=$(python3 -c "
import sys

content = open('$VARIANT_FILE').read().strip()
# Split by --- on its own line
parts = []
current = []
for line in content.split('\n'):
    if line.strip() == '---':
        if current:
            parts.append('\n'.join(current).strip())
            current = []
    else:
        current.append(line)
if current:
    parts.append('\n'.join(current).strip())

# Filter empty parts
parts = [p for p in parts if p]
import json
print(json.dumps(parts))
")

TWEET_COUNT=$(python3 -c "import json; print(len(json.loads('$( echo "$TWEETS" | sed "s/'/\\\\'/g" )')))" 2>/dev/null || python3 -c "
import json, sys
tweets = json.loads(sys.stdin.read())
print(len(tweets))
" <<< "$TWEETS")

echo "Thread: $TWEET_COUNT tweets" >&2

if [ "$DRY_RUN" = "--dry-run" ]; then
  python3 -c "
import json, sys
tweets = json.loads(sys.stdin.read())
print('=== Twitter Thread Preview ===', file=sys.stderr)
for i, tweet in enumerate(tweets, 1):
    chars = len(tweet)
    status = 'OK' if chars <= 280 else 'TOO LONG'
    print(f'  [{i}/{len(tweets)}] ({chars} chars) [{status}]', file=sys.stderr)
    print(f'  {tweet[:100]}...', file=sys.stderr) if len(tweet) > 100 else print(f'  {tweet}', file=sys.stderr)
    print(file=sys.stderr)

over = [i+1 for i, t in enumerate(tweets) if len(t) > 280]
if over:
    print(f'WARNING: Tweets {over} exceed 280 chars', file=sys.stderr)

result = {'url': 'https://x.com/preview', 'id': 'dry-run', 'status': 'dry_run', 'tweets': len(tweets)}
print(json.dumps(result))
" <<< "$TWEETS"
  exit 0
fi

# Post thread via Python (handles OAuth 1.0a signing)
python3 << 'PYEOF'
import json, sys, os, time, hmac, hashlib, base64, urllib.parse, uuid
import urllib.request

API_KEY = os.environ['TWITTER_API_KEY']
API_SECRET = os.environ['TWITTER_API_SECRET']
ACCESS_TOKEN = os.environ['TWITTER_ACCESS_TOKEN']
ACCESS_SECRET = os.environ['TWITTER_ACCESS_TOKEN_SECRET']

TWEET_URL = "https://api.x.com/2/tweets"

def oauth_sign(method, url, params, consumer_secret, token_secret):
    """Generate OAuth 1.0a HMAC-SHA1 signature."""
    sorted_params = "&".join(f"{urllib.parse.quote(k, safe='')}={urllib.parse.quote(v, safe='')}"
                            for k, v in sorted(params.items()))
    base_string = f"{method}&{urllib.parse.quote(url, safe='')}&{urllib.parse.quote(sorted_params, safe='')}"
    signing_key = f"{urllib.parse.quote(consumer_secret, safe='')}&{urllib.parse.quote(token_secret, safe='')}"
    signature = base64.b64encode(
        hmac.new(signing_key.encode(), base_string.encode(), hashlib.sha1).digest()
    ).decode()
    return signature

def post_tweet(text, reply_to_id=None):
    """Post a single tweet, optionally as a reply."""
    oauth_params = {
        "oauth_consumer_key": API_KEY,
        "oauth_nonce": uuid.uuid4().hex,
        "oauth_signature_method": "HMAC-SHA1",
        "oauth_timestamp": str(int(time.time())),
        "oauth_token": ACCESS_TOKEN,
        "oauth_version": "1.0",
    }

    signature = oauth_sign("POST", TWEET_URL, oauth_params, API_SECRET, ACCESS_SECRET)
    oauth_params["oauth_signature"] = signature

    auth_header = "OAuth " + ", ".join(
        f'{urllib.parse.quote(k, safe="")}="{urllib.parse.quote(v, safe="")}"'
        for k, v in sorted(oauth_params.items())
    )

    payload = {"text": text}
    if reply_to_id:
        payload["reply"] = {"in_reply_to_tweet_id": reply_to_id}

    data = json.dumps(payload).encode()
    req = urllib.request.Request(
        TWEET_URL,
        data=data,
        headers={
            "Authorization": auth_header,
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req) as resp:
            result = json.loads(resp.read())
            return result["data"]["id"], None
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        if e.code == 429:
            print(f"ERROR: Rate limited by Twitter. Try again later.", file=sys.stderr)
            return None, 2
        elif e.code in (401, 403):
            print(f"ERROR: Authentication failed ({e.code}): {body}", file=sys.stderr)
            return None, 1
        else:
            print(f"ERROR: Twitter API error ({e.code}): {body}", file=sys.stderr)
            return None, 4

# Read tweets from stdin
tweets = json.loads(sys.stdin.read())

print(f"Posting thread ({len(tweets)} tweets)...", file=sys.stderr)

first_tweet_id = None
prev_tweet_id = None
posted_count = 0

for i, tweet_text in enumerate(tweets):
    if len(tweet_text) > 280:
        print(f"WARNING: Tweet {i+1} is {len(tweet_text)} chars (max 280), truncating", file=sys.stderr)
        tweet_text = tweet_text[:277] + "..."

    tweet_id, error_code = post_tweet(tweet_text, reply_to_id=prev_tweet_id)

    if tweet_id is None:
        print(f"ERROR: Failed at tweet {i+1}/{len(tweets)}. {posted_count} tweets posted.", file=sys.stderr)
        if posted_count > 0 and first_tweet_id:
            # Partial success: report what was posted
            result = {
                "url": f"https://x.com/i/status/{first_tweet_id}",
                "id": first_tweet_id,
                "status": "partial",
                "tweets_posted": posted_count,
                "tweets_total": len(tweets),
            }
            print(json.dumps(result))
        sys.exit(error_code)

    if i == 0:
        first_tweet_id = tweet_id
    prev_tweet_id = tweet_id
    posted_count += 1
    print(f"  [{i+1}/{len(tweets)}] Posted: {tweet_id}", file=sys.stderr)

    # Rate limit safety: small delay between tweets
    if i < len(tweets) - 1:
        time.sleep(1)

# Success
result = {
    "url": f"https://x.com/i/status/{first_tweet_id}",
    "id": first_tweet_id,
    "status": "published",
    "tweets_posted": posted_count,
}
print(json.dumps(result))
PYEOF
RET=$?

exit $RET
