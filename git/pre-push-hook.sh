#!/usr/bin/env bash
# Standalone git pre-push hook — scans staged content for credentials.
# Use this if git-secrets is not installed.
#
# Install:
#   cp pre-push-hook.sh /your/repo/.git/hooks/pre-push
#   chmod +x /your/repo/.git/hooks/pre-push

set -euo pipefail

PATTERNS=(
    'sk-ant-[a-zA-Z0-9\-_]{20,}'           # Anthropic
    'sk-[a-zA-Z0-9]{32,}'                   # OpenAI
    'ghp_[a-zA-Z0-9]{36}'                   # GitHub classic
    'github_pat_[a-zA-Z0-9_]{82}'           # GitHub fine-grained
    'AKIA[0-9A-Z]{16}'                      # AWS access key
    'AIza[0-9A-Za-z\-_]{35}'               # Google API key
    'xox[baprs]-[0-9a-zA-Z\-]{10,}'        # Slack token
    'sk_live_[0-9a-zA-Z]{24,}'             # Stripe
)

remote="$1"
url="$2"

while read -r local_ref local_sha remote_ref remote_sha; do
    [ "$local_sha" = "0000000000000000000000000000000000000000" ] && continue

    range="${remote_sha}..${local_sha}"
    [ "$remote_sha" = "0000000000000000000000000000000000000000" ] && range="$local_sha"

    diff_content=$(git diff "$range" 2>/dev/null || git show "$local_sha" 2>/dev/null)

    for pattern in "${PATTERNS[@]}"; do
        if echo "$diff_content" | grep -qE "$pattern"; then
            echo "ERROR: Credential pattern detected in push to $remote ($url)"
            echo "Pattern: $pattern"
            echo "Remove the credential and rewrite history before pushing."
            exit 1
        fi
    done
done

exit 0
