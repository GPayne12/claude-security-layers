# Threat Model — Multi-Device AI Development Ecosystem

## Scope

A setup where one or more AI coding assistants (Claude Code, Cursor, Copilot, etc.) operate across multiple devices: a primary workstation, a secondary laptop, and optionally a mobile node (phone/tablet). Devices communicate over a private mesh network (Tailscale, ZeroTier, or similar).

---

## Assets

| Asset | Sensitivity | Notes |
|---|---|---|
| API keys (Anthropic, OpenAI, GitHub, cloud providers) | Critical | Loss = immediate billing fraud or data exfiltration |
| SSH private keys | Critical | Loss = unauthorized access to all reachable systems |
| Source code and project files | High | IP, credentials embedded in history |
| Claude session history (`~/.claude.json`, `sessions/`) | High | Contains tool call traces, file paths, fragments of processed content |
| Claude memory files | Medium | Persistent instructions loaded into every future session |
| Local service endpoints | Medium | APIs exposed on the private network |
| Audit logs | Low-Medium | Operational metadata; useful for attackers doing reconnaissance |

---

## Threat actors

**T1 — Compromised dependency**  
A malicious npm/pip/gem package runs code during install or at runtime. On a single-user Mac this runs as your user account, with full access to home directory files and environment.

**T2 — Prompt injection via external content**  
Claude reads a file, repo, web page, or document containing embedded instructions designed to redirect its behavior: write credentials to a temp file, add a backdoor, exfiltrate data via a tool call.

**T3 — Compromised secondary device**  
The mobile laptop (lower security posture, more exposure) is compromised. If SSH agent forwarding is enabled, an attacker can use the agent socket to impersonate the primary machine's key.

**T4 — Stale service endpoint hijack**  
An MCP server or API endpoint configured in Claude Desktop points to a domain you no longer control. If that domain is registered by someone else, Claude will connect to an attacker's server on startup.

**T5 — Malicious web page (CORS + local API)**  
A web page loaded in the browser makes cross-origin requests to `http://localhost:PORT` where a local API server is running with `allow_origins=["*"]`. The page can read arbitrary files exposed by that API.

**T6 — Memory poisoning**  
Claude is manipulated (via T2 or a direct session) into writing false or malicious instructions into its own memory files. These instructions persist and influence all future sessions.

**T7 — Mobile node as weak link**  
A phone added as a third node uses weaker auth (OAuth token, long-lived API key stored in a Shortcut variable) and bypasses the hook enforcement present on the primary machine.

**T8 — Backup exfiltration**  
Backup archives include session history, credentials, or config files. If backup storage has broader permissions than the source files, it becomes the easiest path to the sensitive content.

---

## Attack surfaces by device role

### Primary workstation (owns files, runs long-lived services)
- Local API servers listening on all interfaces
- Claude Code hooks that silently fail
- World-readable config files
- Session history in backup archives

### Secondary laptop (mobile, lower security posture)
- SSH agent forwarding enabling key relay
- git-secrets not configured (scans for nothing)
- Stale MCP server entries pointing at dead domains
- No `~/.ssh/config` to enforce defaults

### Mobile node (phone/tablet)
- API keys stored in plain-text automation variables
- iCloud backup of credential-holding apps
- Hook enforcement gap (Claude API calls don't fire local hooks)
- Auth chain: phone → secondary key → primary key → all systems

---

## Controls mapped to threats

| Control | Mitigates |
|---|---|
| Claude Code secret-scanner hook (stdin-based) | T1, T2 (credential write) |
| Claude Code dangerous-command-blocker hook | T2 (destructive commands) |
| Audit log (PostToolUse) | T2, T6 (detection) |
| `ForwardAgent no` in SSH config | T3 |
| Localhost-only API binding | T5 |
| Restricted CORS origins | T5 |
| Remove stale MCP entries | T4 |
| Memory file auditing | T6 |
| Dedicated mobile SSH key with `command=` restriction | T7 |
| Backup content exclusions (`sessions/`, `~/.claude.json`) | T8 |
| File permission hardening (600 on config/logs) | T1, T8 |
| git-secrets with AI credential patterns | T1 (pre-push) |

---

## What this toolkit does NOT cover

- Network-level isolation between devices (use Tailscale ACLs for that)
- Full disk encryption (enable FileVault / FileVault equivalent)
- Browser extension security
- Supply chain verification of AI tool binaries
- Claude's own model-level safety (out of scope for local infrastructure)
