from __future__ import annotations

from fastapi import HTTPException, Request

from services import auth as auth_service


def require_admin(request: Request) -> None:
    """FastAPI dependency guarding every private endpoint with the admin JWT."""
    settings = request.app.state.settings
    header = request.headers.get("authorization", "")
    if not header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    if not auth_service.verify_token(settings, header[7:].strip()):
        raise HTTPException(status_code=401, detail="Invalid or expired token")
