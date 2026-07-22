"""Stats query validation — shared by the authed ``stats`` router and the
no-auth ``public`` share-link mirror (PS-031), so the two never drift."""

from __future__ import annotations

from datetime import date

BUCKETS = {"day", "week", "month"}
DIMENSIONS = {"page", "referrer", "country", "device", "browser"}
MAX_RANGE_DAYS = 400


class InvalidStatsQuery(ValueError):
    """Bad bucket/dimension/range — routers turn this into a 422."""


def validate_bucket(bucket: str) -> None:
    if bucket not in BUCKETS:
        raise InvalidStatsQuery(f"bucket must be one of {sorted(BUCKETS)}")


def validate_dimension(dim: str) -> None:
    if dim not in DIMENSIONS:
        raise InvalidStatsQuery(f"dim must be one of {sorted(DIMENSIONS)}")


def validated_range(date_from: date, date_to: date) -> tuple[str, str]:
    if date_from > date_to:
        raise InvalidStatsQuery("from must be <= to")
    if (date_to - date_from).days > MAX_RANGE_DAYS:
        raise InvalidStatsQuery(f"range limited to {MAX_RANGE_DAYS} days")
    return date_from.isoformat(), date_to.isoformat()
