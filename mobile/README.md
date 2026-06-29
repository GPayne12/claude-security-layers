# Mobile Node Security

Adding a phone or tablet as a third node introduces threats that don't exist in the two-machine setup. The main risks are auth model mismatch, hook enforcement gaps, and credential storage on a device with weaker physical and iCloud security.

## The hook gap

Claude Code hooks (secret scanning, dangerous command blocking) only fire when Claude Code runs **locally on the machine where hooks are configured**. If the phone calls the Anthropic API directly, no hooks fire. You are relying entirely on the model's own judgment for that session.

**Mitigation:** Route phone-initiated Claude sessions through your primary machine via SSH, so Claude Code runs there with hooks active. See [../ssh/mobile-node.md](../ssh/mobile-node.md) for the key restriction setup.

## Recommended architecture

```
iOS Shortcut (no inline secrets)
    │
    │  HTTPS to Anthropic API
    │  API key stored in iOS Keychain (not a Shortcut variable)
    ▼
Anthropic API (cloud, sandboxed)
    │
    │  SSH (mobile-specific ed25519 key)
    │  command= restriction in authorized_keys
    ▼
Primary machine
    └─ Claude Code runs here
       └─ Hooks fire normally (secret scanner, command blocker, audit log)
```

## Credential storage checklist

- [ ] Anthropic API key stored in iOS Keychain, not in a Shortcut variable or plain text file
- [ ] No secrets stored in iCloud Drive, Notes, or any iCloud-backed location
- [ ] The mobile SSH key (private half) lives only on your primary machine or a secure proxy — not on the phone
- [ ] Audit which apps have iCloud backup enabled: Settings → Apple ID → iCloud → Show All

## Mobile SSH key setup

See [../ssh/mobile-node.md](../ssh/mobile-node.md) for:
- Generating a dedicated key for mobile access
- Restricting it with `command=` in `authorized_keys`
- Writing a handler that allowlists specific commands

## What not to do

| Pattern | Risk |
|---|---|
| Reuse primary SSH key on mobile | Compromising the phone grants full shell access |
| Store API key in Shortcut variable | Visible to anyone with physical phone access; may sync to iCloud |
| Enable agent forwarding from phone | Creates chain: phone → mobile key → primary key → all systems |
| Call Anthropic API directly from phone | Bypasses all local hooks |
| Use same auth token across all devices | Rotating one device forces rotating all |
