#!/usr/bin/env bash
# Install Claude Code security hooks into ~/.claude/settings.json.
#
# - Merges hook entries with any existing settings (does not overwrite)
# - Uses absolute paths so hooks work regardless of working directory
# - Backs up existing settings.json before modifying

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS="$HOME/.claude/settings.json"
BACKUP="$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"

echo "Claude Code hook installer"
echo "Hook scripts: $SCRIPT_DIR"
echo "Settings:     $SETTINGS"
echo ""

# Back up existing settings
if [ -f "$SETTINGS" ]; then
    cp "$SETTINGS" "$BACKUP"
    echo "Backed up existing settings → $BACKUP"
fi

# Ensure settings file exists
mkdir -p "$(dirname "$SETTINGS")"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

# Merge hooks via Python — preserves all existing settings keys
python3 - <<PYEOF
import json, sys

settings_path = "$SETTINGS"
hook_dir = "$SCRIPT_DIR"

with open(settings_path) as f:
    settings = json.load(f)

new_hooks = {
    "PreToolUse": [
        {
            "matcher": "Write|Edit",
            "hooks": [{"type": "command", "command": f"python3 {hook_dir}/secret-scanner.py"}]
        },
        {
            "matcher": "Bash",
            "hooks": [{"type": "command", "command": f"python3 {hook_dir}/dangerous-command-blocker.py"}]
        }
    ],
    "PostToolUse": [
        {
            "matcher": ".*",
            "hooks": [{"type": "command", "command": f"bash {hook_dir}/audit-logger.sh"}]
        }
    ]
}

# Merge: add only hook groups not already present (match by matcher)
existing = settings.get("hooks", {})
for event, groups in new_hooks.items():
    existing_matchers = {h["matcher"] for h in existing.get(event, [])}
    for group in groups:
        if group["matcher"] not in existing_matchers:
            existing.setdefault(event, []).append(group)
            print(f"  Added {event} hook: {group['matcher']}")
        else:
            print(f"  Skipped {event} hook (already present): {group['matcher']}")

settings["hooks"] = existing

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
PYEOF

echo ""
echo "Done. Run ./audit/check-hooks.sh to verify hooks are functional."
