# Local API Security Checklist

## Binding

- [ ] Server binds to `127.0.0.1`, not `0.0.0.0` or `::` (all interfaces)
- [ ] Verify after start: `netstat -an | grep YOUR_PORT` — should show `127.0.0.1.PORT`, not `*.PORT`
- [ ] If remote access is needed, use SSH port forwarding (`ssh -L 8000:127.0.0.1:8000 primary`) rather than binding to a network interface

## CORS

- [ ] `allow_origins` is an explicit list of localhost origins, not `["*"]`
- [ ] `allow_methods` is restricted to what the client actually uses
- [ ] `allow_credentials=False` unless cookies or auth headers are required cross-origin

## Authentication

- [ ] If any endpoint reads filesystem data or executes commands, it requires authentication
- [ ] Token is not hardcoded — read from environment variable or keychain
- [ ] Token is not stored in a file that ends up in version control or backups

## Filesystem access

- [ ] File-reading endpoints are scoped to a specific base directory
- [ ] Path traversal is prevented (reject paths containing `..`)
- [ ] Endpoints return only what the caller actually needs (no directory browsing of sensitive paths)

## Startup

- [ ] Do not use `reload=True` in production — it requires the app to be passed as an import string
- [ ] Log startup binding address so it's visible in process output

## Example: verify binding after start

```bash
# Shows 127.0.0.1 only (good)
netstat -an | grep 8000
# tcp4   0   0  127.0.0.1.8000   *.*   LISTEN

# Also verify it's NOT reachable from a remote IP
# (run from another device on the network)
curl http://YOUR_PRIMARY_IP:8000/api/health   # should fail
curl http://127.0.0.1:8000/api/health         # should succeed (from primary only)
```
