#!/usr/bin/env python3
"""
Secure local API server template for multi-device AI dev setups.

Key differences from a default FastAPI scaffold:
  - Binds to 127.0.0.1, not 0.0.0.0 (no tailnet/LAN exposure)
  - CORS restricted to explicit localhost origins (no wildcard)
  - Optional bearer token auth for any endpoint that reads filesystem data
  - No reload=True in production (causes uvicorn startup failure in some versions)

Usage:
  pip install fastapi uvicorn
  CLAUDE_HUB_TOKEN=your-secret python3 fastapi-secure-template.py
"""

import os
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

app = FastAPI(title="Local AI Hub API", version="1.0.0")

# ── CORS ──────────────────────────────────────────────────────────────────────
# Only allow requests from localhost browser origins.
# Remove this middleware entirely if no browser client needs access.

ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://localhost:4321",
    "http://localhost:8000",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:4321",
    "http://127.0.0.1:8000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,   # never use ["*"] for a local API
    allow_credentials=False,          # True only if you need cookies/auth headers cross-origin
    allow_methods=["GET"],            # restrict to what you actually need
    allow_headers=["Authorization"],
)

# ── Auth ──────────────────────────────────────────────────────────────────────
# Optional. Set CLAUDE_HUB_TOKEN env var to enable bearer token auth.
# If not set, auth middleware is a no-op (suitable for purely localhost use).

_TOKEN = os.environ.get("CLAUDE_HUB_TOKEN", "")
_bearer = HTTPBearer(auto_error=bool(_TOKEN))

def require_auth(creds: HTTPAuthorizationCredentials = Depends(_bearer)):
    if _TOKEN and creds.credentials != _TOKEN:
        raise HTTPException(status_code=401, detail="Invalid token")

# ── Routes ────────────────────────────────────────────────────────────────────

@app.get("/api/health")
async def health():
    return {"status": "ok"}


@app.get("/api/protected", dependencies=[Depends(require_auth)])
async def protected_example():
    """Example of a route that requires the bearer token."""
    return {"message": "authenticated"}


# ── Entry point ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="127.0.0.1",   # never "0.0.0.0" for a local-only service
        port=8000,
        # no reload=True — causes startup failures when app is passed as instance
    )
