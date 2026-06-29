#!/usr/bin/env python3
"""
Claude Code PreToolUse hook — secret scanner.

Reads tool input from stdin (not $CLAUDE_TOOL_INPUT — that env var is not set by Claude Code).
Blocks Write and Edit operations if the content contains known credential patterns.

Wire up in ~/.claude/settings.json:
  "PreToolUse": [{ "matcher": "Write|Edit", "hooks": [{ "type": "command",
    "command": "python3 /path/to/secret-scanner.py" }] }]
"""

import sys
import json
import re

PATTERNS = [
    ("Anthropic API key",   r"sk-ant-[a-zA-Z0-9\-_]{20,}"),
    ("OpenAI API key",      r"sk-[a-zA-Z0-9]{32,}"),
    ("GitHub token",        r"ghp_[a-zA-Z0-9]{36}"),
    ("GitHub fine-grained", r"github_pat_[a-zA-Z0-9_]{82}"),
    ("AWS access key",      r"AKIA[0-9A-Z]{16}"),
    ("AWS secret key",      r"(?i)aws.{0,20}secret.{0,20}['\"][0-9a-zA-Z/+]{40}['\"]"),
    ("Google API key",      r"AIza[0-9A-Za-z\-_]{35}"),
    ("Slack token",         r"xox[baprs]-[0-9a-zA-Z\-]{10,}"),
    ("Stripe secret key",   r"sk_live_[0-9a-zA-Z]{24,}"),
    ("Generic bearer",      r"(?i)bearer\s+[a-zA-Z0-9\-_\.]{20,}"),
]

def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        print(json.dumps({"decision": "allow"}))
        return

    content = data.get("content", "") + data.get("new_string", "")

    found = [name for name, pat in PATTERNS if re.search(pat, content)]

    if found:
        print(json.dumps({
            "decision": "block",
            "reason": f"SECRET DETECTED: {', '.join(found)} — remove credentials before writing"
        }))
    else:
        print(json.dumps({"decision": "allow"}))

if __name__ == "__main__":
    main()
