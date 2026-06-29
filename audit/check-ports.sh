#!/usr/bin/env bash
# Check for services listening on all interfaces (0.0.0.0 / :: / *).
# Flags any port bound to a network interface rather than loopback only.
#
# Excludes known system services (mDNS :5353, rapportd, Tailscale internals).

set -euo pipefail

IGNORED_PROCS="rapportd|mDNSResponder|launchd|configd"

# Ports bound to all interfaces
if command -v netstat &>/dev/null; then
    WIDE=$(netstat -an 2>/dev/null | grep LISTEN | grep -v '127\.0\.0\.1\|::1' | grep -E '^\s*tcp')
else
    WIDE=$(ss -tln 2>/dev/null | grep -v '127\.' | grep -v '\[::1\]' | tail -n +2)
fi

if [ -z "$WIDE" ]; then
    exit 0
fi

# Try to identify the owning process for each flagged port
echo "Services listening on all interfaces:"
echo "$WIDE"
echo ""

# Use lsof to get process names (best effort, may need sudo for all processes)
PORTS=$(echo "$WIDE" | grep -oE '\*\.[0-9]+|0\.0\.0\.0\.[0-9]+|::[0-9]+' | grep -oE '[0-9]+$' | sort -u)

SUSPICIOUS=0
for port in $PORTS; do
    owner=$(lsof -iTCP:"$port" -sTCP:LISTEN -n -P 2>/dev/null | awk 'NR>1 {print $1}' | head -1)
    if [ -z "$owner" ]; then
        owner="(unknown — try: sudo lsof -iTCP:$port)"
    fi
    if echo "$owner" | grep -qvE "$IGNORED_PROCS"; then
        echo "  Port $port — $owner"
        SUSPICIOUS=$((SUSPICIOUS + 1))
    fi
done

if [ "$SUSPICIOUS" -gt 0 ]; then
    echo ""
    echo "Consider binding these services to 127.0.0.1 unless remote access is required."
    exit 1
fi
