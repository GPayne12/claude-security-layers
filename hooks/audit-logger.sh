#!/usr/bin/env bash
# Claude Code PostToolUse hook — audit logger.
#
# Appends a timestamped record of every tool use to $AUDIT_LOG.
# Reads tool metadata from stdin (standard Claude hook input).
#
# Wire up in ~/.claude/settings.json:
#   "PostToolUse": [{ "matcher": ".*", "hooks": [{ "type": "command",
#     "command": "bash /path/to/audit-logger.sh" }] }]

AUDIT_LOG="${AUDIT_LOG:-$HOME/.claude/audit.log}"
umask 077
mkdir -p "$(dirname "$AUDIT_LOG")"

TOOL=$(cat | /usr/bin/jq -r '.tool_name // "unknown"' 2>/dev/null)
printf '[%s] TOOL=%s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$TOOL" >> "$AUDIT_LOG"

# Keep the log from growing unboundedly — rotate at ~10k lines
line_count=$(wc -l < "$AUDIT_LOG" 2>/dev/null || echo 0)
if [ "$line_count" -gt 10000 ]; then
    tail -5000 "$AUDIT_LOG" > "${AUDIT_LOG}.tmp" && mv "${AUDIT_LOG}.tmp" "$AUDIT_LOG"
fi
