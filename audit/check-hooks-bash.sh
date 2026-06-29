#!/usr/bin/env bash
# Verify the Bash dangerous-command-blocker hook actually intercepts.
# Sends a mock Bash payload with a force-push command and expects a block.

set -euo pipefail

SETTINGS="$HOME/.claude/settings.json"

if [ ! -f "$SETTINGS" ]; then
    echo "No settings.json found at $SETTINGS"
    exit 1
fi

HOOK_CMD=$(python3 -c "
import json, sys
with open('$SETTINGS') as f:
    s = json.load(f)
for group in s.get('hooks', {}).get('PreToolUse', []):
    if 'Bash' in group.get('matcher', ''):
        for h in group.get('hooks', []):
            if h.get('type') == 'command':
                print(h['command'])
                sys.exit(0)
print('')
")

if [ -z "$HOOK_CMD" ]; then
    echo "No Bash PreToolUse hook found in $SETTINGS"
    exit 1
fi

PAYLOAD='{"tool_name":"Bash","command":"git push origin main --force"}'

RESULT=$(echo "$PAYLOAD" | eval "$HOOK_CMD" 2>/dev/null)
DECISION=$(echo "$RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('decision',''))" 2>/dev/null)

if [ "$DECISION" = "block" ]; then
    exit 0
else
    echo "Hook did not block a force-push command (decision: '$DECISION')"
    echo "Hook command: $HOOK_CMD"
    echo "Check that the hook reads from stdin (cat |), not \$CLAUDE_TOOL_INPUT"
    exit 1
fi
