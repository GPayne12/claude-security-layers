#!/usr/bin/env bash
# Check that sensitive config and log files are not world-readable.

set -euo pipefail

FAIL=0

check_file() {
    local path="$1"
    local label="$2"
    [ -f "$path" ] || return 0

    perms=$(stat -f "%A" "$path" 2>/dev/null || stat -c "%a" "$path" 2>/dev/null)
    # World-readable: last octet is 4, 5, 6, or 7
    last_digit="${perms: -1}"
    if [ "$last_digit" -ge 4 ] 2>/dev/null; then
        echo "  WARN: $label ($path) is world-readable (perms: $perms) — run: chmod 600 $path"
        FAIL=$((FAIL + 1))
    fi
}

# Claude Code config and state
check_file "$HOME/.claude/settings.json"     "Claude settings"
check_file "$HOME/.claude.json"              "Claude session state"

# Common audit and log files
check_file "$HOME/.claude/audit.log"         "Claude audit log"
check_file "$HOME/Claude/monitoring/audit.log" "Claude monitoring log"

# SSH
check_file "$HOME/.ssh/config"              "SSH config"
for key in "$HOME"/.ssh/id_*; do
    [ -f "$key" ] || continue
    [[ "$key" == *.pub ]] && continue
    check_file "$key" "SSH private key"
done

if [ "$FAIL" -eq 0 ]; then
    exit 0
else
    exit 1
fi
