"""Stats queries — thin wrappers over the Postgres functions (migration 0005).
All aggregation lives in SQL; the app just shapes parameters."""

from __future__ import annotations

from config import Settings
from db import client as db_client


def _rpc(settings: Settings, name: str, params: dict):
    return db_client.get_client(settings).rpc(name, params).execute().data


def timeseries(
    settings: Settings, site_id: str, date_from: str, date_to: str, bucket: str
) -> list[dict]:
    return _rpc(
        settings,
        "stats_timeseries",
        {"p_site": site_id, "p_from": date_from, "p_to": date_to, "p_bucket": bucket},
    )


def breakdown(
    settings: Settings,
    site_id: str,
    date_from: str,
    date_to: str,
    dimension: str,
    limit: int,
) -> list[dict]:
    return _rpc(
        settings,
        "stats_breakdown",
        {
            "p_site": site_id,
            "p_from": date_from,
            "p_to": date_to,
            "p_dimension": dimension,
            "p_limit": limit,
        },
    )


def summary(
    settings: Settings, site_id: str, date_from: str, date_to: str
) -> dict:
    data = _rpc(
        settings,
        "stats_summary",
        {"p_site": site_id, "p_from": date_from, "p_to": date_to},
    )
    return data[0] if isinstance(data, list) and data else data


def live(settings: Settings, site_id: str) -> int:
    return int(_rpc(settings, "stats_live", {"p_site": site_id}) or 0)


def rollup_day(settings: Settings, day: str) -> None:
    _rpc(settings, "rollup_daily", {"p_day": day})
