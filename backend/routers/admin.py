from __future__ import annotations

from datetime import date

from fastapi import APIRouter, Depends, Query, Request

from db import stats as db_stats
from routers.deps import require_admin

router = APIRouter(dependencies=[Depends(require_admin)])


@router.post("/admin/rollup")
def rollup(request: Request, day: date = Query()) -> dict:
    """Manual fallback for the pg_cron nightly job. ``rollup_daily`` is
    idempotent (delete-day-then-insert), so re-runs are safe."""
    db_stats.rollup_day(request.app.state.settings, day.isoformat())
    return {"ok": True, "day": day.isoformat()}
