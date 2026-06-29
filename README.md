# claude-security-layers

Security hardening toolkit for multi-device Claude Code / AI development ecosystems.

Extracted from a real security assessment of a two-machine + planned mobile setup. Every finding here was a silent failure — things that looked configured but weren't protecting anything.

---

## What this covers

| Layer | What it protects |
|---|---|
| [Hooks](#hooks) | Claude Code pre/post tool-use filters (secret scanning, dangerous command blocking, audit logging) |
| [SSH](#ssh) | Cross-device key handling, agent forwarding lockdown, mobile node restrictions |
| [API](#api) | Local service binding (localhost vs all interfaces), CORS hardening |
| [Git](#git) | Secret scanning with AI-specific credential patterns |
| [Audit](#audit) | Scripts to verify the above are actually working — not just configured |
| [Mobile](#mobile) | Phone/tablet as a third node: auth model, key scoping, hook gap |

---

## Quick start

```bash
# Audit your current state first
./audit/audit.sh

# Then apply what the audit flags
./hooks/install.sh      # Wire hooks into Claude Code settings
./ssh/install.sh        # Harden SSH client config
./git/setup.sh          # Register AI credential patterns in git-secrets
```

---

## The core lesson

**Configured ≠ working.** The original setup had secret scanning and dangerous command blocking that appeared functional but silently passed everything through, because Claude Code delivers hook input via stdin — not the `$CLAUDE_TOOL_INPUT` environment variable the hooks were reading.

The audit scripts here are designed to verify actual behavior, not just presence of configuration.

---

## Hooks

Claude Code hooks run shell commands before/after tool use. The critical detail: **input arrives on stdin**, not environment variables.

See [`hooks/`](hooks/) for:
- `secret-scanner.py` — blocks Write/Edit if content contains API keys or tokens
- `dangerous-command-blocker.py` — blocks Bash commands matching destructive patterns  
- `audit-logger.sh` — appends tool-use events to a local audit log
- `settings-template.json` — drop-in Claude Code settings with all three wired up
- `check-hooks.sh` — functional test that verifies hooks actually intercept (not just exist)

---

## SSH

See [`ssh/`](ssh/) for:
- `config.template` — SSH client config with `ForwardAgent no`, `IdentitiesOnly yes`
- `mobile-node.md` — how to scope a dedicated key for phone/tablet access using `command=` in `authorized_keys`

---

## API

See [`api/`](api/) for:
- `fastapi-secure-template.py` — local API server bound to `127.0.0.1`, CORS locked to localhost origins, optional bearer token auth
- `checklist.md` — binding, CORS, and auth decision tree

---

## Git

See [`git/`](git/) for:
- `setup.sh` — registers git-secrets patterns for Anthropic, OpenAI, GitHub, AWS, Google, Slack credentials
- `patterns/` — pattern files by credential family, importable separately
- `pre-push-hook.sh` — standalone pre-push hook if git-secrets isn't installed

---

## Audit

See [`audit/`](audit/) for:
- `audit.sh` — master script, runs all checks and prints a severity-ranked report
- `check-hooks.sh` — **sends real stdin** to your hooks and verifies they block/allow correctly
- `check-ports.sh` — lists all listening ports with owning process names
- `check-permissions.sh` — flags world-readable config and log files
- `check-mcp-servers.sh` — detects stale or unreachable MCP server entries in Claude Desktop config
- `check-backups.sh` — scans backup archives for credentials and session data

---

## Mobile

See [`mobile/`](mobile/) for architecture guidance on adding a phone or tablet as a third node without creating an auth chain: phone → primary key → all systems.

---

## Threat model

See [`docs/threat-model.md`](docs/threat-model.md) for the full threat model this toolkit is designed against.

---

## Contributing

Patterns, hook improvements, and audit checks for other AI coding tools (Cursor, Copilot, Aider, etc.) are welcome. Open an issue or PR.
