from fastapi import APIRouter

from services import geoip

router = APIRouter()


@router.get("/health")
def health() -> dict:
    """Liveness probe — Render's healthCheckPath and the deploy smoke test.

    ``geoip`` reports whether the DB-IP database loaded, since a build-time
    download failure is otherwise silent (see fetch_geoip.py) and nothing
    else in production surfaces it.
    """
    return {"status": "ok", "geoip": geoip.is_loaded()}
