#!/usr/bin/env bash
# Register AI-ecosystem credential patterns in git-secrets (global).
#
# Requires: brew install git-secrets
# Run once per machine. Must be run from inside a git repo for --register-aws.
#
# Usage:
#   cd /any/git/repo
#   bash /path/to/setup.sh

set -euo pipefail

if ! command -v git-secrets &>/dev/null; then
    echo "git-secrets not found. Install with: brew install git-secrets"
    exit 1
fi

echo "Registering git-secrets patterns globally..."

# AWS patterns (built-in)
git secrets --register-aws --global 2>/dev/null || \
    git secrets --register-aws 2>/dev/null || \
    echo "  Note: --register-aws requires a git repo context; run from inside one"

add_pattern() {
    local label="$1"
    local pattern="$2"
    git config --global --get-all secrets.patterns 2>/dev/null | grep -qF "$pattern" && \
        echo "  Already registered: $label" || \
        { git config --global --add secrets.patterns "$pattern" && echo "  Added: $label"; }
}

# AI provider keys
add_pattern "Anthropic API key"    'sk-ant-[a-zA-Z0-9\-_]{20,}'
add_pattern "OpenAI API key"       'sk-[a-zA-Z0-9]{32,}'

# Source control
add_pattern "GitHub classic token" 'ghp_[a-zA-Z0-9]{36}'
add_pattern "GitHub fine-grained"  'github_pat_[a-zA-Z0-9_]{82}'

# Cloud providers
add_pattern "Google API key"       'AIza[0-9A-Za-z\-_]{35}'
add_pattern "Stripe secret key"    'sk_live_[0-9a-zA-Z]{24,}'

# Messaging / infra
add_pattern "Slack token"          'xox[baprs]-[0-9a-zA-Z\-]{10,}'

echo ""
echo "Current patterns:"
git config --global --get-all secrets.patterns 2>/dev/null || echo "  (none)"

echo ""
echo "To install the pre-commit hook in a repo:"
echo "  cd /your/repo && git secrets --install"
