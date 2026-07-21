from __future__ import annotations

import secrets

from fastapi import APIRouter, HTTPException, Request

from schemas.auth import LoginRequest, LoginResponse
from services import auth as auth_service

router = APIRouter()


@router.post("/auth/login", response_model=LoginResponse)
def login(request: Request, body: LoginRequest) -> LoginResponse:
    settings = request.app.state.settings
    if not settings.admin_password or not secrets.compare_digest(
        body.password, settings.admin_password
    ):
        raise HTTPException(status_code=401, detail="Wrong password")
    return LoginResponse(
        token=auth_service.create_token(settings),
        expires_in_hours=settings.jwt_ttl_hours,
    )
