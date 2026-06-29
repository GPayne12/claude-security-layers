# Mobile Node SSH Setup

When adding a phone or tablet as a third device, **do not reuse your existing SSH key**. A separate key with a `command=` restriction in `authorized_keys` limits the blast radius if the mobile credential is compromised.

## Generate a dedicated key on the primary machine

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_mobile -C "mobile-node-$(date +%Y%m)"
```

Keep the private key on the primary machine only. Export the public key to wherever the mobile invocation originates (a proxy server, a Shortcuts-triggered API, etc.).

## Restrict the key in authorized_keys

On the primary machine, add the mobile public key with a `command=` prefix:

```
command="/usr/local/bin/claude-mobile-handler.sh",no-agent-forwarding,no-pty,no-port-forwarding,no-X11-forwarding ssh-ed25519 AAAA... mobile-node-key
```

`claude-mobile-handler.sh` is a wrapper that:
- Validates the incoming request (allowlisted commands only)
- Runs the permitted operation
- Logs the invocation

## Example handler

```bash
#!/usr/bin/env bash
# /usr/local/bin/claude-mobile-handler.sh
# Called by SSH when the mobile key is used.
# $SSH_ORIGINAL_COMMAND contains what the client tried to run.

ALLOWED=(
    "claude --print 'status'"
    "health-check"
)

cmd="${SSH_ORIGINAL_COMMAND:-}"

for allowed in "${ALLOWED[@]}"; do
    if [ "$cmd" = "$allowed" ]; then
        exec bash -c "$cmd"
    fi
done

echo "Command not permitted: $cmd" >&2
exit 1
```

## What NOT to do

- Do not add the mobile key without `command=` — it grants full shell access
- Do not enable `ForwardAgent` for the mobile connection — it chains mobile → primary key → everything
- Do not store the private key in iCloud, a Shortcut variable, or a plain-text config file
- Do not reuse the same key across devices — rotating one device's key should not affect others

## Recommended mobile architecture

```
iOS Shortcut (no inline secrets)
    ↓  HTTPS
Anthropic API (key in iOS Keychain)
    ↓  Scheduled remote agent (sandboxed)
    ↓  SSH (mobile-specific ed25519 key)
Primary machine — command= handler fires
    → Claude Code runs → hooks fire normally
```

This keeps hook enforcement on the primary machine where Claude Code runs, rather than trying to replicate it in the mobile invocation path.
