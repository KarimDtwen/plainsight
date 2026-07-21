from fastapi import APIRouter

router = APIRouter()


@router.get("/health")
def health() -> dict[str, str]:
    """Liveness probe — Render's healthCheckPath and the deploy smoke test."""
    return {"status": "ok"}
