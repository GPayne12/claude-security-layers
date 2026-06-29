#!/usr/bin/env python3
"""
Claude Code PreToolUse hook — dangerous command blocker.

Reads Bash tool input from stdin. Blocks commands matching destructive patterns
and requires explicit user confirmation before proceeding.

Wire up in ~/.claude/settings.json:
  "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command",
    "command": "python3 /path/to/dangerous-command-blocker.py" }] }]
"""

import sys
import json
import re

# (label, *patterns) — any matching pattern triggers a block
DANGEROUS = [
    ("force push",           r"git push.*--force", r"git push.*\s-f\b"),
    ("recursive delete /",   r"rm\s+-rf\s+/"),
    ("wipe home",            r"rm\s+-rf\s+~/"),
    ("drop table",           r"DROP\s+TABLE"),
    ("drop database",        r"DROP\s+DATABASE"),
    ("truncate table",       r"TRUNCATE\s+TABLE"),
    ("fork bomb",            r":\(\)\{.*\|.*&"),
    ("chmod 777 recursive",  r"chmod\s+-R\s+777"),
    ("overwrite /etc",       r">\s*/etc/"),
    ("kill all processes",   r"kill\s+-9\s+-1"),
]

def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        print(json.dumps({"decision": "allow"}))
        return

    cmd = data.get("command", "")

    found = [
        label
        for label, *pats in DANGEROUS
        if any(re.search(p, cmd, re.IGNORECASE) for p in pats)
    ]

    if found:
        print(json.dumps({
            "decision": "block",
            "reason": f"DANGEROUS COMMAND [{', '.join(found)}] — confirm explicitly before running"
        }))
    else:
        print(json.dumps({"decision": "allow"}))

if __name__ == "__main__":
    main()
