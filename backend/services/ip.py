"""Client IP extraction behind Render's proxy.

Render (and most PaaS) terminate TLS at a proxy, so the real client address is
the FIRST entry of ``X-Forwarded-For``; ``request.client.host`` is only the
proxy. Falls back to the direct peer for local development.
"""

from __future__ import annotations

from typing import Mapping


def client_ip(headers: Mapping[str, str], fallback: str) -> str:
    forwarded = headers.get("x-forwarded-for", "")
    if forwarded:
        first = forwarded.split(",")[0].strip()
        if first:
            return first
    return fallback or ""
