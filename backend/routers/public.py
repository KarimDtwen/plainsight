"""Read-only mirror of the stats API for a site's share link (PS-031).

No ``require_admin`` dependency by design — anyone with the slug can view.
Route shape deliberately parallels ``routers/stats.py`` (``/sites/{id}/stats/*``
-> ``/public/{slug}/stats/*``) resolving the site id from the slug first, so a
revoked or unknown slug always 404s before any query runs.
"""

from __future__ import annotations

from datetime import date

from fastapi import APIRouter, HTTPException, Query, Request

from db import sites as db_sites
from db import stats as db_stats
from services.stats_query import InvalidStatsQuery, validate_bucket, validate_dimension, validated_range

router = APIRouter(prefix="/public/{slug}")


def _resolve_site(request: Request, slug: str) -> dict:
    site = db_sites.get_site_by_slug(request.app.state.settings, slug)
    if site is None:
        raise HTTPException(status_code=404, detail="Unknown or revoked share link")
    return site


def _range_or_422(date_from: date, date_to: date) -> tuple[str, str]:
    try:
        return validated_range(date_from, date_to)
    except InvalidStatsQuery as e:
        raise HTTPException(status_code=422, detail=str(e)) from e


@router.get("/site")
def site(request: Request, slug: str) -> dict:
    row = _resolve_site(request, slug)
    return {"name": row["name"], "domain": row["domain"]}


@router.get("/stats/timeseries")
def timeseries(
    request: Request,
    slug: str,
    date_from: date = Query(alias="from"),
    date_to: date = Query(alias="to"),
    bucket: str = Query(default="day"),
) -> list[dict]:
    site_id = _resolve_site(request, slug)["id"]
    try:
        validate_bucket(bucket)
    except InvalidStatsQuery as e:
        raise HTTPException(status_code=422, detail=str(e)) from e
    start, end = _range_or_422(date_from, date_to)
    return db_stats.timeseries(request.app.state.settings, site_id, start, end, bucket)


@router.get("/stats/breakdown")
def breakdown(
    request: Request,
    slug: str,
    date_from: date = Query(alias="from"),
    date_to: date = Query(alias="to"),
    dim: str = Query(),
    limit: int = Query(default=10, ge=1, le=100),
) -> list[dict]:
    site_id = _resolve_site(request, slug)["id"]
    try:
        validate_dimension(dim)
    except InvalidStatsQuery as e:
        raise HTTPException(status_code=422, detail=str(e)) from e
    start, end = _range_or_422(date_from, date_to)
    return db_stats.breakdown(request.app.state.settings, site_id, start, end, dim, limit)


@router.get("/stats/summary")
def summary(
    request: Request,
    slug: str,
    date_from: date = Query(alias="from"),
    date_to: date = Query(alias="to"),
) -> dict:
    site_id = _resolve_site(request, slug)["id"]
    start, end = _range_or_422(date_from, date_to)
    return db_stats.summary(request.app.state.settings, site_id, start, end)


@router.get("/stats/live")
def live(request: Request, slug: str) -> dict:
    site_id = _resolve_site(request, slug)["id"]
    return {"online": db_stats.live(request.app.state.settings, site_id)}
