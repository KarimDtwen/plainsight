"""Site lookups and CRUD. ``get_site_by_key`` is on the hot ingest path, so
results (including misses) are cached in-process for 60 s."""

from __future__ import annotations

import secrets
import time

from config import Settings
from db import client as db_client

_CACHE_TTL_SECONDS = 60.0
_cache: dict[str, tuple[float, dict | None]] = {}
_slug_cache: dict[str, tuple[float, dict | None]] = {}


def get_site_by_key(settings: Settings, site_key: str) -> dict | None:
    now = time.time()
    hit = _cache.get(site_key)
    if hit is not None and now - hit[0] < _CACHE_TTL_SECONDS:
        return hit[1]
    resp = (
        db_client.get_client(settings)
        .table("sites")
        .select("*")
        .eq("site_key", site_key)
        .limit(1)
        .execute()
    )
    row = resp.data[0] if resp.data else None
    _cache[site_key] = (now, row)
    return row


def list_sites(settings: Settings) -> list[dict]:
    resp = (
        db_client.get_client(settings)
        .table("sites")
        .select("*")
        .order("created_at")
        .execute()
    )
    return resp.data or []


def create_site(settings: Settings, name: str, domain: str) -> dict:
    resp = (
        db_client.get_client(settings)
        .table("sites")
        .insert({"name": name, "domain": domain})
        .execute()
    )
    return resp.data[0]


def delete_site(settings: Settings, site_id: str) -> None:
    db_client.get_client(settings).table("sites").delete().eq(
        "id", site_id
    ).execute()
    _cache.clear()
    _slug_cache.clear()


def get_site_by_slug(settings: Settings, slug: str) -> dict | None:
    """Resolve a share link. Same 60s cache as ``get_site_by_key`` — the
    public dashboard polls its own live counter every 10s per viewer."""
    now = time.time()
    hit = _slug_cache.get(slug)
    if hit is not None and now - hit[0] < _CACHE_TTL_SECONDS:
        return hit[1]
    resp = (
        db_client.get_client(settings)
        .table("sites")
        .select("*")
        .eq("share_slug", slug)
        .limit(1)
        .execute()
    )
    row = resp.data[0] if resp.data else None
    _slug_cache[slug] = (now, row)
    return row


def set_share_slug(settings: Settings, site_id: str) -> str | None:
    """(Re)generate a site's share link, invalidating any previous one."""
    slug = secrets.token_urlsafe(9)
    resp = (
        db_client.get_client(settings)
        .table("sites")
        .update({"share_slug": slug})
        .eq("id", site_id)
        .execute()
    )
    _cache.clear()
    _slug_cache.clear()
    return resp.data[0]["share_slug"] if resp.data else None


def clear_share_slug(settings: Settings, site_id: str) -> None:
    db_client.get_client(settings).table("sites").update(
        {"share_slug": None}
    ).eq("id", site_id).execute()
    _cache.clear()
    _slug_cache.clear()


def reset_for_tests() -> None:
    _cache.clear()
    _slug_cache.clear()
