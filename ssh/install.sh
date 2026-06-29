#!/usr/bin/env bash
# Install SSH client hardening config.
# Merges security defaults into ~/.ssh/config without overwriting existing host blocks.

set -euo pipefail

SSH_CONFIG="$HOME/.ssh/config"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ -f "$SSH_CONFIG" ]; then
    echo "Existing ~/.ssh/config found — checking for conflicts"

    if grep -q "ForwardAgent no" "$SSH_CONFIG"; then
        echo "  ForwardAgent no already present — skipping"
    else
        echo ""
        echo "WARNING: ForwardAgent no is not set in your ~/.ssh/config."
        echo "This means SSH agent forwarding may be enabled, allowing a compromised"
        echo "remote machine to use your local SSH keys."
        echo ""
        echo "Add to your ~/.ssh/config:"
        echo "  Host *"
        echo "      ForwardAgent no"
        echo "      IdentitiesOnly yes"
        echo "      ServerAliveInterval 60"
        echo ""
        read -r -p "Append these defaults to ~/.ssh/config now? [y/N] " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            printf '\n# Security defaults added by claude-security-layers\nHost *\n    ForwardAgent no\n    IdentitiesOnly yes\n    ServerAliveInterval 60\n' >> "$SSH_CONFIG"
            echo "Appended."
        fi
    fi
else
    echo "No ~/.ssh/config found — creating from template"
    cp "$SCRIPT_DIR/config.template" "$SSH_CONFIG"
    echo "Created ~/.ssh/config"
fi

chmod 600 "$SSH_CONFIG"
echo "Permissions set: 600"
echo ""
echo "Current ForwardAgent settings:"
grep -n "ForwardAgent" "$SSH_CONFIG" || echo "  (none found — verify manually)"
