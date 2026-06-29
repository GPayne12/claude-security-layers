#!/usr/bin/env bash
# Master audit script — runs all checks and prints a severity-ranked report.
#
# Usage:
#   ./audit.sh                   # audit this machine
#   ./audit.sh --remote user@host  # audit a remote machine via SSH

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE=""

if [ "${1:-}" = "--remote" ] && [ -n "${2:-}" ]; then
    REMOTE="$2"
    echo "Auditing remote: $REMOTE"
    echo ""
fi

run() {
    local script="$1"
    if [ -n "$REMOTE" ]; then
        # Ship script to remote and execute
        ssh "$REMOTE" "bash -s" < "$SCRIPT_DIR/$script" 2>/dev/null
    else
        bash "$SCRIPT_DIR/$script" 2>/dev/null
    fi
}

PASS=0; WARN=0; FAIL=0

check() {
    local severity="$1"   # CRITICAL HIGH MEDIUM LOW
    local label="$2"
    local script="$3"

    printf "  %-12s %s ... " "[$severity]" "$label"
    if output=$(run "$script" 2>&1); then
        echo "OK"
        PASS=$((PASS + 1))
    else
        echo "FAIL"
        echo "$output" | sed 's/^/              /'
        case "$severity" in
            CRITICAL|HIGH) FAIL=$((FAIL + 1)) ;;
            *)             WARN=$((WARN + 1)) ;;
        esac
    fi
}

echo "════════════════════════════════════════════════"
echo " claude-security-layers audit"
echo " $(date)"
echo "════════════════════════════════════════════════"
echo ""

echo "── Hooks ────────────────────────────────────────"
check CRITICAL "hook stdin (secret scanner)"    "check-hooks.sh"
check HIGH     "hook stdin (command blocker)"   "check-hooks-bash.sh"

echo ""
echo "── Services ─────────────────────────────────────"
check HIGH   "no services on 0.0.0.0"          "check-ports.sh"

echo ""
echo "── SSH ──────────────────────────────────────────"
check HIGH   "ForwardAgent disabled"            "check-ssh.sh"

echo ""
echo "── File permissions ─────────────────────────────"
check MEDIUM "config files not world-readable"  "check-permissions.sh"

echo ""
echo "── Git ──────────────────────────────────────────"
check MEDIUM "git-secrets patterns registered"  "check-git-secrets.sh"

echo ""
echo "── MCP servers ──────────────────────────────────"
check MEDIUM "no stale MCP server entries"      "check-mcp-servers.sh"

echo ""
echo "════════════════════════════════════════════════"
printf " Results: %d passed, %d warnings, %d failures\n" "$PASS" "$WARN" "$FAIL"
echo "════════════════════════════════════════════════"

[ "$FAIL" -eq 0 ]   # exit 1 if any critical/high failures
