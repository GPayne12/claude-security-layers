#!/usr/bin/env bash
# Check for non-system services listening on all interfaces (0.0.0.0 / *).
#
# Excludes:
#   - sshd (port 22) — expected to be network-accessible
#   - Tailscale network extension — system VPN, expected
#   - rapportd — Apple Continuity daemon, expected
#   - link-local IPv6 (fe80::) — not routable, not a threat
#   - mDNSResponder, launchd — system services

set -euo pipefail

IGNORED_PROCS="sshd|rapportd|mDNSResponder|launchd|configd|io.tailscale|com.apple"
IGNORED_PORTS="22"   # SSH — intentionally network-accessible

# Pull all listeners, strip loopback and link-local IPv6
if command -v netstat &>/dev/null; then
    WIDE=$(netstat -an 2>/dev/null \
        | grep LISTEN \
        | grep -v '127\.0\.0\.1\|::1\|fe80::' \
        | grep -E '^\s*tcp')
else
    WIDE=$(ss -tln 2>/dev/null \
        | grep -v '127\.' | grep -v '\[::1\]' | grep -v 'fe80' \
        | tail -n +2)
fi

if [ -z "$WIDE" ]; then
    exit 0
fi

# Extract port numbers from the listener lines
PORTS=$(echo "$WIDE" \
    | grep -oE '\*\.[0-9]+|0\.0\.0\.0\.[0-9]+|::[0-9]+|\*:[0-9]+' \
    | grep -oE '[0-9]+$' \
    | sort -un)

SUSPICIOUS=0
for port in $PORTS; do
    # Skip known-safe ports
    echo "$IGNORED_PORTS" | grep -qw "$port" && continue

    owner=$(lsof -iTCP:"$port" -sTCP:LISTEN -n -P 2>/dev/null \
        | awk 'NR>1 {print $1}' | head -1)

    [ -z "$owner" ] && owner="(unknown — try: sudo lsof -iTCP:$port -sTCP:LISTEN -n)"

    # Skip known-safe processes
    echo "$owner" | grep -qE "$IGNORED_PROCS" && continue

    echo "  Port $port — $owner (listening on all interfaces)"
    SUSPICIOUS=$((SUSPICIOUS + 1))
done

if [ "$SUSPICIOUS" -gt 0 ]; then
    echo ""
    echo "These services are reachable from any network interface, including Tailscale."
    echo "Consider binding to 127.0.0.1 unless remote access is required."
    exit 1
fi
