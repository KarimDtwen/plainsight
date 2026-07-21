from __future__ import annotations

import os
from dataclasses import dataclass, field
from typing import Mapping
from urllib.parse import urlparse


class ConfigurationError(RuntimeError):
    pass


def _required_url(name: str, value: str) -> str:
    parsed = urlparse(value)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        raise ConfigurationError(f"{name} must be an absolute HTTP(S) URL")
    return value.rstrip("/")


def _positive_int(name: str, value: str) -> int:
    try:
        parsed = int(value)
    except ValueError as exc:
        raise ConfigurationError(f"{name} must be a positive integer") from exc
    if parsed <= 0:
        raise ConfigurationError(f"{name} must be a positive integer")
    return parsed


def _origins(value: str) -> tuple[str, ...]:
    origins = tuple(
        origin.strip().rstrip("/")
        for origin in value.split(",")
        if origin.strip()
    )
    for origin in origins:
        _required_url("ALLOWED_ORIGINS", origin)
    return origins


@dataclass(frozen=True)
class Settings:
    """Environment-validated app settings.

    Secrets carry ``repr=False`` so they never leak into logs or tracebacks.
    Construction fails fast in production when a required variable is missing
    or still holds a ``YOUR_*`` placeholder — names are listed, never values.
    """

    environment: str
    supabase_url: str
    supabase_key: str = field(repr=False)
    admin_password: str = field(repr=False)
    jwt_secret: str = field(repr=False)
    allowed_origins: tuple[str, ...]
    jwt_ttl_hours: int

    @property
    def is_production(self) -> bool:
        return self.environment == "production"

    @property
    def local_origin_regex(self) -> str | None:
        # Localhost dashboards are auto-allowed outside production so local dev
        # needs no CORS configuration; production locks to explicit origins.
        if self.is_production:
            return None
        return r"http://(localhost|127\.0\.0\.1):\d+"

    @classmethod
    def from_env(cls, environ: Mapping[str, str] | None = None) -> "Settings":
        env = os.environ if environ is None else environ
        environment = env.get("APP_ENV", "development").strip().lower()
        if environment not in {"development", "test", "production"}:
            raise ConfigurationError(
                "APP_ENV must be development, test, or production"
            )

        supabase_url = env.get(
            "SUPABASE_URL",
            "https://tests.supabase.co"
            if environment == "test"
            else "https://YOUR_PROJECT.supabase.co",
        ).strip()
        supabase_key = (
            env.get("SUPABASE_SERVICE_ROLE_KEY")
            or env.get("SUPABASE_KEY")
            or ("test-key" if environment == "test" else "YOUR_SUPABASE_KEY")
        ).strip()
        admin_password = env.get(
            "ADMIN_PASSWORD",
            "test-password" if environment == "test" else "",
        ).strip()
        jwt_secret = env.get(
            "JWT_SECRET",
            "test-jwt-secret" if environment == "test" else "",
        ).strip()
        allowed_origins_raw = env.get("ALLOWED_ORIGINS", "").strip()

        if environment == "production":
            missing = []
            required = {
                "SUPABASE_URL": supabase_url,
                "SUPABASE_SERVICE_ROLE_KEY": (
                    "" if supabase_key == "YOUR_SUPABASE_KEY" else supabase_key
                ),
                "ADMIN_PASSWORD": admin_password,
                "JWT_SECRET": jwt_secret,
                "ALLOWED_ORIGINS": allowed_origins_raw,
            }
            for name, value in required.items():
                if not value or value.startswith("YOUR_"):
                    missing.append(name)
            if missing:
                raise ConfigurationError(
                    "Missing required production environment variables: "
                    + ", ".join(sorted(missing))
                )

        return cls(
            environment=environment,
            supabase_url=_required_url("SUPABASE_URL", supabase_url),
            supabase_key=supabase_key,
            admin_password=admin_password,
            jwt_secret=jwt_secret,
            allowed_origins=_origins(allowed_origins_raw),
            jwt_ttl_hours=_positive_int(
                "JWT_TTL_HOURS",
                env.get("JWT_TTL_HOURS", "168").strip(),
            ),
        )
