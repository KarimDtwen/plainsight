from __future__ import annotations

from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query, Request

from db import stats as db_stats
from routers.deps import require_admin

router = APIRouter(dependencies=[Depends(require_admin)])

BUCKETS = {"day", "week", "month"}
DIMENSIONS = {"page", "referrer", "country", "device", "browser"}
MAX_RANGE_DAYS = 400


def _validated_range(date_from: date, date_to: date) -> tuple[str, str]:
    if date_from > date_to:
        raise HTTPException(status_code=422, detail="from must be <= to")
    if (date_to - date_from).days > MAX_RANGE_DAYS:
        raise HTTPException(
            status_code=422, detail=f"range limited to {MAX_RANGE_DAYS} days"
        )
    return date_from.isoformat(), date_to.isoformat()


@router.get("/sites/{site_id}/stats/timeseries")
def timeseries(
    request: Request,
    site_id: str,
    date_from: date = Query(alias="from"),
    date_to: date = Query(alias="to"),
    bucket: str = Query(default="day"),
) -> list[dict]:
    if bucket not in BUCKETS:
        raise HTTPException(status_code=422, detail=f"bucket must be one of {sorted(BUCKETS)}")
    start, end = _validated_range(date_from, date_to)
    return db_stats.timeseries(
        request.app.state.settings, site_id, start, end, bucket
    )


@router.get("/sites/{site_id}/stats/breakdown")
def breakdown(
    request: Request,
    site_id: str,
    date_from: date = Query(alias="from"),
    date_to: date = Query(alias="to"),
    dim: str = Query(),
    limit: int = Query(default=10, ge=1, le=100),
) -> list[dict]:
    if dim not in DIMENSIONS:
        raise HTTPException(status_code=422, detail=f"dim must be one of {sorted(DIMENSIONS)}")
    start, end = _validated_range(date_from, date_to)
    return db_stats.breakdown(
        request.app.state.settings, site_id, start, end, dim, limit
    )


@router.get("/sites/{site_id}/stats/summary")
def summary(
    request: Request,
    site_id: str,
    date_from: date = Query(alias="from"),
    date_to: date = Query(alias="to"),
) -> dict:
    start, end = _validated_range(date_from, date_to)
    return db_stats.summary(request.app.state.settings, site_id, start, end)


@router.get("/sites/{site_id}/stats/live")
def live(request: Request, site_id: str) -> dict:
    return {"online": db_stats.live(request.app.state.settings, site_id)}
