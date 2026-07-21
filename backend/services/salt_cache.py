"""In-process cache for the daily visitor-hash salt.

The salt itself is generated and stored in Postgres (``get_daily_salt()`` RPC)
so multiple instances agree; this cache avoids one DB round-trip per event.
Fetch-on-miss makes it cold-start safe, and the cache key is the UTC date so
the rotation happens exactly at midnight UTC without any scheduler.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Callable

_cached: dict = {"day": None, "salt": None}


def _today():
    return datetime.now(timezone.utc).date()


def get_salt(fetch: Callable[[], str]) -> str:
    today = _today()
    if _cached["day"] != today or not _cached["salt"]:
        _cached["salt"] = fetch()
        _cached["day"] = today
    return _cached["salt"]


def reset_for_tests() -> None:
    _cached.update(day=None, salt=None)
