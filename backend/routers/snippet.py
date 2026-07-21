from __future__ import annotations

import os

from fastapi import APIRouter
from fastapi.responses import FileResponse

router = APIRouter()

SNIPPET_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "static",
    "plainsight.js",
)


@router.get("/js/script.js")
def script() -> FileResponse:
    """The one-line-install tracking snippet. Cacheable for a day; ACAO:* so
    any site can load it. The snippet derives the /collect endpoint from this
    file's own URL (document.currentScript.src)."""
    return FileResponse(
        SNIPPET_PATH,
        media_type="application/javascript",
        headers={
            "Access-Control-Allow-Origin": "*",
            "Cache-Control": "public, max-age=86400",
        },
    )
