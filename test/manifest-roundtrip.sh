#!/usr/bin/env bash
set -euo pipefail

# Tests manifest YAML round-trip: create → read → update → validate

PASS=0
FAIL=0
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "=== Manifest Round-Trip Tests ==="
echo ""

# Test 1: Create a valid manifest
cat > "$TMPDIR/manifest.yaml" << 'EOF'
title: "Test Post"
created: 2026-03-29T00:00:00Z
updated: 2026-03-29T00:00:00Z
source: source.md
tags: [test, ci]
language: en
canonical_url: "https://example.com/test"

assets: []

variants:
  devto:
    file: variants/devto.md
    format: article
    status: draft
    error: null
  hashnode:
    file: variants/hashnode.md
    format: article
    status: draft
    error: null
EOF

python3 -c "import yaml; yaml.safe_load(open('$TMPDIR/manifest.yaml'))" 2>/dev/null \
  && pass "Create valid manifest" \
  || fail "Create valid manifest"

# Test 2: Read and verify fields
python3 -c "
import yaml
with open('$TMPDIR/manifest.yaml') as f:
    d = yaml.safe_load(f)
assert d['title'] == 'Test Post', 'title mismatch'
assert d['variants']['devto']['status'] == 'draft', 'status mismatch'
assert d['variants']['hashnode']['format'] == 'article', 'format mismatch'
" 2>/dev/null \
  && pass "Read and verify fields" \
  || fail "Read and verify fields"

# Test 3: Update publish status (simulate successful publish)
python3 -c "
import yaml
with open('$TMPDIR/manifest.yaml') as f:
    d = yaml.safe_load(f)
d['variants']['devto']['status'] = 'published'
d['variants']['devto']['url'] = 'https://dev.to/test/post'
d['variants']['devto']['published_at'] = '2026-03-29T01:00:00Z'
d['variants']['devto']['error'] = None
with open('$TMPDIR/manifest.yaml.tmp', 'w') as f:
    yaml.dump(d, f, default_flow_style=False, allow_unicode=True)
" 2>/dev/null

# Test 4: Validate temp file before atomic rename
python3 -c "import yaml; yaml.safe_load(open('$TMPDIR/manifest.yaml.tmp'))" 2>/dev/null \
  && pass "Validate temp file" \
  || fail "Validate temp file"

# Test 5: Atomic rename
cp "$TMPDIR/manifest.yaml" "$TMPDIR/manifest.yaml.bak"
mv "$TMPDIR/manifest.yaml.tmp" "$TMPDIR/manifest.yaml"
[ -f "$TMPDIR/manifest.yaml" ] \
  && pass "Atomic rename" \
  || fail "Atomic rename"

# Test 6: Verify updated fields
python3 -c "
import yaml
with open('$TMPDIR/manifest.yaml') as f:
    d = yaml.safe_load(f)
assert d['variants']['devto']['status'] == 'published', 'publish status not updated'
assert d['variants']['devto']['url'] == 'https://dev.to/test/post', 'url not set'
assert d['variants']['hashnode']['status'] == 'draft', 'hashnode should still be draft'
" 2>/dev/null \
  && pass "Verify updated fields" \
  || fail "Verify updated fields"

# Test 7: Simulate failed publish
python3 -c "
import yaml
with open('$TMPDIR/manifest.yaml') as f:
    d = yaml.safe_load(f)
d['variants']['hashnode']['status'] = 'failed'
d['variants']['hashnode']['error'] = 'Authentication failed'
with open('$TMPDIR/manifest.yaml.tmp', 'w') as f:
    yaml.dump(d, f, default_flow_style=False, allow_unicode=True)
mv('$TMPDIR/manifest.yaml.tmp', '$TMPDIR/manifest.yaml')
" 2>/dev/null || true

python3 -c "
import yaml, shutil
with open('$TMPDIR/manifest.yaml') as f:
    d = yaml.safe_load(f)
d['variants']['hashnode']['status'] = 'failed'
d['variants']['hashnode']['error'] = 'Authentication failed'
with open('$TMPDIR/manifest.yaml', 'w') as f:
    yaml.dump(d, f, default_flow_style=False, allow_unicode=True)
" 2>/dev/null

python3 -c "
import yaml
with open('$TMPDIR/manifest.yaml') as f:
    d = yaml.safe_load(f)
assert d['variants']['hashnode']['status'] == 'failed'
assert d['variants']['hashnode']['error'] == 'Authentication failed'
" 2>/dev/null \
  && pass "Failed publish status recorded" \
  || fail "Failed publish status recorded"

# Test 8: Backup exists
[ -f "$TMPDIR/manifest.yaml.bak" ] \
  && pass "Backup file preserved" \
  || fail "Backup file preserved"

echo ""
echo "=== Results ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"

[ "$FAIL" -gt 0 ] && exit 1 || exit 0
