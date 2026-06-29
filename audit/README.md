# Audit Scripts

These scripts verify that security controls are **actually working**, not just present in config files.

## Run all checks

```bash
# This machine
./audit.sh

# Remote machine (via SSH)
./audit.sh --remote george@primary
```

## Individual checks

| Script | What it tests |
|---|---|
| `check-hooks.sh` | Sends a real credential payload to your Write/Edit hook and verifies it blocks |
| `check-hooks-bash.sh` | Sends a real force-push command to your Bash hook and verifies it blocks |
| `check-ports.sh` | Lists all services bound to `0.0.0.0` / `::` with owning process names |
| `check-ssh.sh` | Verifies `ForwardAgent no` is set in `~/.ssh/config` |
| `check-permissions.sh` | Flags world-readable config files, logs, and SSH keys |
| `check-git-secrets.sh` | Verifies git-secrets is installed with AI credential patterns |
| `check-mcp-servers.sh` | Pings URL-based MCP server entries and flags unreachable ones |

## Why functional tests matter

A hook that exists in `settings.json` but reads from `$CLAUDE_TOOL_INPUT` (not stdin) will silently pass every call. A git-secrets install with no patterns registered will scan for nothing. These scripts test the actual behavior, not the configuration.

## Exit codes

All scripts exit 0 on pass, 1 on failure. `audit.sh` exits 1 if any CRITICAL or HIGH check fails.

## Adding checks

Each check script is standalone bash. Add new checks by:
1. Creating `check-<name>.sh` in this directory
2. Adding a `check` line in `audit.sh`
