# Adapter Discovery

How to find and load platform adapters.

## Discovery procedure

1. List all directories under `adapters/`:
   ```bash
   ls -d adapters/*/
   ```

2. For each adapter directory, read `adapter.yaml` to get platform config:
   ```bash
   cat adapters/<name>/adapter.yaml
   ```

3. Check if the adapter's required env var is set:
   ```bash
   grep <auth_env_var> .env | cut -d= -f2-
   ```
   If empty or missing, skip this adapter (not configured).

4. For `auth_type: git_push`, no env var check is needed. Just verify the git remote is configured in `content/config/platforms.yaml`.

## Loading adapter format rules

Before generating a variant for a platform, read its `format.md`:
```bash
cat adapters/<name>/format.md
```
Follow the instructions in that file to adapt the content.

## Invoking publish.sh with credential isolation

IMPORTANT: Always use `env -i` to isolate credentials. Only pass the env var declared in `adapter.yaml`:

```bash
# Read the required env var name from adapter.yaml
AUTH_VAR=$(grep 'auth_env_var:' adapters/<name>/adapter.yaml | awk '{print $2}')
AUTH_VAL=$(grep "^${AUTH_VAR}=" .env | cut -d= -f2-)

# Invoke with isolation
env -i PATH="$PATH" HOME="$HOME" \
  "${AUTH_VAR}=${AUTH_VAL}" \
  ./adapters/<name>/publish.sh <variant-file> <assets-dir> [--dry-run]
```

For `auth_type: git_push` adapters, no credential env var is needed:
```bash
env -i PATH="$PATH" HOME="$HOME" GIT_DIR="$(git rev-parse --git-dir)" \
  ./adapters/<name>/publish.sh <variant-file> <assets-dir> [--dry-run]
```

## publish.sh exit codes

| Code | Meaning | Action |
|------|---------|--------|
| 0 | Success | Update manifest status to `published`, record URL from stdout JSON |
| 1 | Auth failure | Report to user, suggest re-running `/media-setup` |
| 2 | Rate limit | Report to user, suggest retrying later |
| 3 | Content rejected | Report rejection reason from stderr |
| 4 | Other error | Report stderr to user |
