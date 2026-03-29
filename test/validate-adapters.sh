#!/usr/bin/env bash
set -euo pipefail

# Validates all adapter contracts
PASS=0
FAIL=0
WARN=0

fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }
pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
warn() { echo "  [WARN] $1"; WARN=$((WARN + 1)); }

echo "=== Adapter Contract Validation ==="
echo ""

for adapter in adapters/*/; do
  name=$(basename "$adapter")
  echo "Adapter: $name"

  # 1. adapter.yaml exists and is valid YAML
  if [ ! -f "$adapter/adapter.yaml" ]; then
    fail "missing adapter.yaml"
    continue
  fi
  python3 -c "import yaml; yaml.safe_load(open('${adapter}adapter.yaml'))" 2>/dev/null \
    && pass "adapter.yaml is valid YAML" \
    || { fail "adapter.yaml is invalid YAML"; continue; }

  # 2. Required fields present
  for field in name display_name auth_type content_format; do
    grep -q "^${field}:" "$adapter/adapter.yaml" \
      && pass "field: $field" \
      || fail "missing field: $field"
  done

  # 3. auth_env_var present for API-based adapters
  auth_type=$(python3 -c "import yaml; print(yaml.safe_load(open('${adapter}adapter.yaml'))['auth_type'])" 2>/dev/null)
  if [ "$auth_type" = "api_key" ] || [ "$auth_type" = "oauth" ]; then
    grep -q "^auth_env_var:" "$adapter/adapter.yaml" \
      && pass "auth_env_var declared" \
      || fail "auth_env_var missing for auth_type=$auth_type"
  fi

  # 4. publish.sh exists and is executable
  if [ -f "$adapter/publish.sh" ]; then
    [ -x "$adapter/publish.sh" ] \
      && pass "publish.sh is executable" \
      || fail "publish.sh is not executable"
  else
    fail "missing publish.sh"
  fi

  # 5. format.md exists and has required sections
  if [ -f "$adapter/format.md" ]; then
    grep -q "## Conventions" "$adapter/format.md" \
      && pass "format.md has Conventions" \
      || fail "format.md missing '## Conventions'"
    grep -q "## Content Adaptation Rules" "$adapter/format.md" \
      && pass "format.md has Content Adaptation Rules" \
      || fail "format.md missing '## Content Adaptation Rules'"
  else
    fail "missing format.md"
  fi

  # 6. publish.sh supports --dry-run
  if [ -f "$adapter/publish.sh" ]; then
    grep -q "dry.run\|dry_run\|DRY_RUN" "$adapter/publish.sh" \
      && pass "publish.sh supports --dry-run" \
      || warn "publish.sh has no --dry-run support detected"
  fi

  echo ""
done

echo "=== Results ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo "  WARN: $WARN"

[ "$FAIL" -gt 0 ] && exit 1 || exit 0
