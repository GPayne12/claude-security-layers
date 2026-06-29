#!/usr/bin/env bash
# Check that git-secrets is installed and AI credential patterns are registered.

set -euo pipefail

REQUIRED_PATTERNS=(
    'sk-ant-'     # Anthropic
    'ghp_'        # GitHub
    'AKIA'        # AWS
    'AIza'        # Google
)

if ! command -v git-secrets &>/dev/null; then
    echo "git-secrets is not installed — run: brew install git-secrets"
    exit 1
fi

REGISTERED=$(git config --global --get-all secrets.patterns 2>/dev/null || echo "")

MISSING=()
for pat in "${REQUIRED_PATTERNS[@]}"; do
    echo "$REGISTERED" | grep -q "$pat" || MISSING+=("$pat")
done

if [ "${#MISSING[@]}" -gt 0 ]; then
    echo "Missing git-secrets patterns: ${MISSING[*]}"
    echo "Run: bash ../git/setup.sh"
    exit 1
fi

exit 0
