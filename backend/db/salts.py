from __future__ import annotations

from config import Settings
from db import client as db_client


def get_daily_salt(settings: Settings) -> str:
    """Upserts + returns today's salt via the ``get_daily_salt()`` Postgres
    function, so every backend instance agrees on the same value."""
    resp = db_client.get_client(settings).rpc("get_daily_salt", {}).execute()
    return resp.data
