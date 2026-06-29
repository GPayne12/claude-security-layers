#!/usr/bin/env bash
# Verify Claude Code secret-scanner hook actually intercepts Write/Edit input.
#
# The canonical failure mode: hook uses `echo "$CLAUDE_TOOL_INPUT" | python3 ...`
# instead of `cat | python3 ...`. The env var is not set by Claude Code, so
# the hook receives empty stdin, the JSON parse fails, and it silently allows.
#
# This test sends a mock Write payload containing a known-bad credential pattern
# directly to the hook command and checks that it blocks.

set -euo pipefail

SETTINGS="$HOME/.claude/settings.json"

if [ ! -f "$SETTINGS" ]; then
    echo "No settings.json found at $SETTINGS"
    exit 1
fi

# Extract the Write|Edit hook command
HOOK_CMD=$(python3 -c "
import json, sys
with open('$SETTINGS') as f:
    s = json.load(f)
for group in s.get('hooks', {}).get('PreToolUse', []):
    if 'Write' in group.get('matcher', '') or 'Edit' in group.get('matcher', ''):
        for h in group.get('hooks', []):
            if h.get('type') == 'command':
                print(h['command'])
                sys.exit(0)
print('')
")

if [ -z "$HOOK_CMD" ]; then
    echo "No Write|Edit PreToolUse hook found in $SETTINGS"
    exit 1
fi

# Test payload: a Write with a fake Anthropic API key
PAYLOAD='{"tool_name":"Write","file_path":"/tmp/test.py","content":"key = \"sk-ant-test1234567890abcdefghijklmnopqrst\""}'

RESULT=$(echo "$PAYLOAD" | eval "$HOOK_CMD" 2>/dev/null)
DECISION=$(echo "$RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('decision',''))" 2>/dev/null)

if [ "$DECISION" = "block" ]; then
    exit 0   # Hook is working
else
    echo "Hook did not block a credential write (decision: '$DECISION')"
    echo "Hook command: $HOOK_CMD"
    echo "Check that the hook reads from stdin (cat |), not \$CLAUDE_TOOL_INPUT"
    exit 1
fi
