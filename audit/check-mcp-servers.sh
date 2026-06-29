#!/usr/bin/env bash
# Check Claude Desktop config for stale or unreachable MCP server entries.
#
# A stale MCP entry pointing at a dead domain is a domain-squatting risk:
# if someone registers that domain, Claude Desktop will connect to their server.

set -euo pipefail

DESKTOP_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"

if [ ! -f "$DESKTOP_CONFIG" ]; then
    # Not macOS or Claude Desktop not installed — skip
    exit 0
fi

MCP_SERVERS=$(python3 -c "
import json
with open('$DESKTOP_CONFIG') as f:
    cfg = json.load(f)
servers = cfg.get('mcpServers', {})
print(len(servers))
for name, conf in servers.items():
    args = conf.get('args', [])
    # Print any arg that looks like a URL
    for arg in args:
        if arg.startswith('http://') or arg.startswith('https://'):
            print(f'{name} -> {arg}')
" 2>/dev/null)

count=$(echo "$MCP_SERVERS" | head -1)
urls=$(echo "$MCP_SERVERS" | tail -n +2)

if [ "$count" = "0" ]; then
    exit 0
fi

FAIL=0

# Check any URL-based MCP servers for reachability
while IFS= read -r line; do
    [ -z "$line" ] && continue
    name=$(echo "$line" | cut -d' ' -f1)
    url=$(echo "$line" | cut -d' ' -f3)

    if ! curl -sf --max-time 5 "$url" &>/dev/null; then
        echo "  Unreachable MCP server: $name -> $url"
        echo "  If this domain is no longer yours, remove the entry to prevent squatting."
        FAIL=$((FAIL + 1))
    fi
done <<< "$urls"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi

exit 0
