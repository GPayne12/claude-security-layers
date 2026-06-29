# Hooks

Claude Code runs hook scripts before and after tool use. The key detail that makes hooks silently fail: **Claude Code delivers input via stdin, not via `$CLAUDE_TOOL_INPUT`** (that env var is not set). Hooks that `echo "$CLAUDE_TOOL_INPUT" | python3 ...` read an empty string and pass everything unconditionally.

## Files

| File | Purpose |
|---|---|
| `secret-scanner.py` | PreToolUse: blocks Write/Edit if content contains API keys or tokens |
| `dangerous-command-blocker.py` | PreToolUse: blocks Bash commands matching destructive patterns |
| `audit-logger.sh` | PostToolUse: appends timestamped tool-use events to `~/.claude/audit.log` |
| `settings-template.json` | Drop-in settings snippet with all three hooks wired up |
| `install.sh` | Merges hooks into existing `~/.claude/settings.json` non-destructively |

## Install

```bash
./install.sh
```

Then verify:

```bash
../audit/check-hooks.sh
```

## Extend

Add patterns to `secret-scanner.py`'s `PATTERNS` list. Add commands to `dangerous-command-blocker.py`'s `DANGEROUS` list. The structure is `(label, *regex_patterns)` — any matching pattern triggers a block.

## Stdin contract

Every hook receives a JSON object on stdin. The schema differs by tool:

```jsonc
// Write / Edit
{ "tool_name": "Write", "content": "...", "new_string": "..." }

// Bash
{ "tool_name": "Bash", "command": "..." }
```

PostToolUse receives the same input plus a `"result"` key. Always use `cat | python3` or `cat | jq` — never `echo "$VAR" |`.
