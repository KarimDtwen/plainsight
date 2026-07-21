"""Site lookups and CRUD. ``get_site_by_key`` is on the hot ingest path, so
results (including misses) are cached in-process for 60 s."""

from __future__ import annotations

import time

from config import Settings
from db import client as db_client

_CACHE_TTL_SECONDS = 60.0
_cache: dict[str, tuple[float, dict | None]] = {}


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


def reset_for_tests() -> None:
    _cache.clear()
