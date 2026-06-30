#!/usr/bin/env bash
# Check for non-system services listening on all interfaces (0.0.0.0 / *).
#
# Ports with unidentifiable owners (requires sudo for root processes) are
# reported as warnings, not failures. Only positively-identified non-system
# services cause a failure exit.
#
# Known-safe to skip:
#   - Port 22 (sshd) — intentionally network-accessible
#   - Tailscale internal ports (varies; identified by process name)
#   - rapportd (Apple Continuity), mDNSResponder, launchd

IGNORED_PROCS="sshd|rapportd|mDNSResponder|launchd|configd|io\.tailscale|com\.apple|UserEventAgent"
IGNORED_PORTS="22"

# Pull all listeners, strip loopback and link-local IPv6
WIDE=$(netstat -an 2>/dev/null \
    | grep LISTEN \
    | grep -v '127\.0\.0\.1\|::1\|fe80::' \
    | grep -E '^\s*tcp' || true)

[ -z "$WIDE" ] && exit 0

# Extract unique port numbers
PORTS=$(echo "$WIDE" \
    | grep -oE '\*\.[0-9]+|0\.0\.0\.0\.[0-9]+|\*:[0-9]+' \
    | grep -oE '[0-9]+$' \
    | sort -un || true)

[ -z "$PORTS" ] && exit 0

SUSPICIOUS=0
UNKNOWN=0

for port in $PORTS; do
    # Skip known-safe ports
    echo "$IGNORED_PORTS" | grep -qw "$port" && continue

    owner=$(lsof -iTCP:"$port" -sTCP:LISTEN -n -P 2>/dev/null \
        | awk 'NR>1 {print $1}' | head -1 || true)

    if [ -z "$owner" ]; then
        # Can't identify without sudo — warn but don't fail
        UNKNOWN=$((UNKNOWN + 1))
        echo "  WARN port $port — owner unknown (run with sudo for full visibility)"
        continue
    fi

    # Skip known-safe processes
    echo "$owner" | grep -qE "$IGNORED_PROCS" && continue

    echo "  FAIL port $port — $owner is listening on all interfaces"
    SUSPICIOUS=$((SUSPICIOUS + 1))
done

if [ "$UNKNOWN" -gt 0 ]; then
    echo "  ($UNKNOWN port(s) could not be identified — re-run as sudo for complete results)"
fi

if [ "$SUSPICIOUS" -gt 0 ]; then
    echo ""
    echo "These services are reachable from any network interface, including Tailscale."
    echo "Consider binding to 127.0.0.1 unless remote access is required."
    exit 1
fi
