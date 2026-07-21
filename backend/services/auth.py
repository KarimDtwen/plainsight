"""Admin JWT: single-user auth, HS256, TTL from settings (default 7 days)."""

from __future__ import annotations

import time

import jwt

from config import Settings


def create_token(settings: Settings, now: float | None = None) -> str:
    issued = int(time.time() if now is None else now)
    payload = {
        "sub": "admin",
        "iat": issued,
        "exp": issued + settings.jwt_ttl_hours * 3600,
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm="HS256")


def verify_token(settings: Settings, token: str) -> bool:
    try:
        jwt.decode(token, settings.jwt_secret, algorithms=["HS256"])
        return True
    except jwt.InvalidTokenError:
        return False
