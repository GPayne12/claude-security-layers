#!/usr/bin/env bash
# Check that SSH client config disables agent forwarding.

set -euo pipefail

SSH_CONFIG="$HOME/.ssh/config"

if [ ! -f "$SSH_CONFIG" ]; then
    echo "No ~/.ssh/config found — ForwardAgent defaults to no in most clients, but explicit config is safer"
    exit 1
fi

# Check that ForwardAgent no appears and is not overridden by ForwardAgent yes
YES_COUNT=$(grep -ci "ForwardAgent yes" "$SSH_CONFIG" 2>/dev/null) || YES_COUNT=0
NO_COUNT=$(grep -ci "ForwardAgent no"  "$SSH_CONFIG" 2>/dev/null) || NO_COUNT=0

if [ "$YES_COUNT" -gt 0 ]; then
    echo "ForwardAgent yes found in $SSH_CONFIG — this allows key relay if the remote is compromised"
    grep -n "ForwardAgent yes" "$SSH_CONFIG"
    exit 1
fi

if [ "$NO_COUNT" -eq 0 ]; then
    echo "ForwardAgent not explicitly set in $SSH_CONFIG — add 'ForwardAgent no' under 'Host *'"
    exit 1
fi

exit 0
