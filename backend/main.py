"""Plainsight backend — app factory and wiring only.

All request handling lives in ``routers/``; pure logic in ``services/``;
Supabase access in ``db/``. This file stays thin by design (the one structural
departure from the UniMatch backend, whose main.py grew to ~1900 lines).
"""

from dotenv import load_dotenv

load_dotenv()

from fastapi import FastAPI  # noqa: E402
from fastapi.middleware.cors import CORSMiddleware  # noqa: E402

from config import Settings  # noqa: E402
from routers import admin, auth, collect, health, sites, snippet, stats  # noqa: E402


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or Settings.from_env()
    app = FastAPI(title="Plainsight", version="0.1.0")
    app.state.settings = settings

    # Locked to the dashboard origins. /collect and /js/script.js bypass CORS
    # ceremony on purpose: simple requests + explicit ACAO:* on their responses.
    app.add_middleware(
        CORSMiddleware,
        allow_origins=list(settings.allowed_origins),
        allow_origin_regex=settings.local_origin_regex,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(health.router)
    app.include_router(snippet.router)
    app.include_router(collect.router)
    app.include_router(auth.router)
    app.include_router(sites.router)
    app.include_router(stats.router)
    app.include_router(admin.router)
    return app


app = create_app()
