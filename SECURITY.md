# Security: Adapter Trust Model

## How adapters execute

When you run `/media-publish`, Claude invokes each adapter's `publish.sh` via the Bash tool. These are real shell scripts that execute on your machine.

## Credential isolation

Each `publish.sh` is invoked with `env -i`, passing ONLY the env var declared in that adapter's `adapter.yaml` under `auth_env_var`. For example, the Dev.to adapter only receives `DEVTO_API_KEY`. It cannot access your `OPENAI_API_KEY`, `HASHNODE_API_KEY`, or any other credential.

Example invocation:
```bash
env -i PATH="$PATH" HOME="$HOME" \
  DEVTO_API_KEY="$DEVTO_API_KEY" \
  ./adapters/devto/publish.sh variants/devto.md assets/
```

## Community adapters

If you install a community-contributed adapter, review its `publish.sh` before use. A malicious script could:
- Exfiltrate the credential it receives to an external server
- Read files on your filesystem (it has PATH and HOME)
- Execute arbitrary commands

## Inspecting adapters

Before running any adapter for the first time, use `--dry-run` to see what it would do:
```bash
./adapters/devto/publish.sh variants/devto.md assets/ --dry-run
```

Or read the script directly:
```bash
cat adapters/devto/publish.sh
```

## Reporting vulnerabilities

If you find a security issue in a bundled adapter, open a GitHub issue with the `security` label.
