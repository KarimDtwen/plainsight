"""Ingestion. Contract with the snippet:

- CORS *simple request*: ``sendBeacon`` posts a ``text/plain`` JSON body, so
  browsers never send a preflight. The response carries ``ACAO: *``.
- **Always 202, always fast.** Unknown site keys, bots, malformed bodies, and
  even DB failures return the same 202 — a tracking endpoint must never teach
  the public how to probe it, and must never break a host page.
- The client IP is read (XFF-first), used for the country lookup + visitor
  hash, and discarded — it is never stored or logged.
"""

from __future__ import annotations

import json
import logging
from urllib.parse import urlparse

from fastapi import APIRouter, Request, Response

from db import events as db_events
from db import salts as db_salts
from db import sites as db_sites
from services import geoip, hashing
from services import ip as ip_service
from services import salt_cache
from services import ua as ua_service

logger = logging.getLogger(__name__)
router = APIRouter()

MAX_BODY_BYTES = 4096
_ACAO = {"Access-Control-Allow-Origin": "*"}


def _accepted() -> Response:
    return Response(status_code=202, content="ok", headers=_ACAO)


def _referrer_host(referrer: str, site_domain: str) -> str:
    """Normalized referrer host; '' for direct or self-referrals."""
    if not referrer:
        return ""
    try:
        host = (urlparse(referrer).netloc or "").lower().split(":")[0]
    except ValueError:
        return ""
    if not host or host == site_domain.lower():
        return ""
    return host[:253]


def _origin_ok(origin: str, site_domain: str) -> bool:
    """Soft check (production only): a present Origin must match the site's
    registered domain. Absent Origin passes — not every sender includes it."""
    if not origin:
        return True
    try:
        host = (urlparse(origin).netloc or "").lower().split(":")[0]
    except ValueError:
        return False
    return host == site_domain.lower()


@router.post("/collect")
async def collect(request: Request) -> Response:
    try:
        raw = await request.body()
        if not raw or len(raw) > MAX_BODY_BYTES:
            return _accepted()
        try:
            data = json.loads(raw)
        except (ValueError, UnicodeDecodeError):
            return _accepted()
        if not isinstance(data, dict):
            return _accepted()

        settings = request.app.state.settings
        site_key = str(data.get("s") or "")[:64]
        if not site_key:
            return _accepted()

        user_agent = request.headers.get("user-agent", "")
        if ua_service.is_bot(user_agent):
            return _accepted()

        site = db_sites.get_site_by_key(settings, site_key)
        if site is None:
            return _accepted()

        if settings.is_production and not _origin_ok(
            request.headers.get("origin", ""), site.get("domain", "")
        ):
            return _accepted()

        path = str(data.get("u") or "/")[:512]
        if not path.startswith("/"):
            path = "/" + path
        try:
            width = int(data.get("w") or 0)
        except (TypeError, ValueError):
            width = 0

        fallback_ip = request.client.host if request.client else ""
        ip_addr = ip_service.client_ip(request.headers, fallback_ip)
        salt = salt_cache.get_salt(lambda: db_salts.get_daily_salt(settings))

        db_events.insert_event(
            settings,
            {
                "site_id": site["id"],
                "path": path,
                "referrer_host": _referrer_host(
                    str(data.get("r") or "")[:1024], site.get("domain", "")
                ),
                "country": geoip.country(ip_addr),
                "device": ua_service.device(width),
                "browser": ua_service.browser(user_agent),
                "visitor_hash": hashing.visitor_hash(
                    salt, str(site["id"]), ip_addr, user_agent
                ),
            },
        )
    except Exception:
        # Ingestion never 5xxes at snippets; failures are logged server-side.
        logger.exception("collect failed")
    return _accepted()
