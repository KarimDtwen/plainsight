from __future__ import annotations

from urllib.parse import urlparse

from fastapi import APIRouter, Depends, HTTPException, Request

from db import sites as db_sites
from routers.deps import require_admin
from schemas.sites import SiteCreate

router = APIRouter(dependencies=[Depends(require_admin)])


def _normalize_domain(value: str) -> str:
    value = value.strip().lower()
    if "//" in value:
        value = urlparse(value).netloc or value.split("//", 1)[1]
    return value.split("/")[0].split(":")[0]


def _install_line(request: Request, site_key: str) -> str:
    base = str(request.base_url).rstrip("/")
    return (
        f'<script defer src="{base}/js/script.js" data-site="{site_key}"></script>'
    )


@router.get("/sites")
def list_sites(request: Request) -> list[dict]:
    return db_sites.list_sites(request.app.state.settings)


@router.post("/sites", status_code=201)
def create_site(request: Request, body: SiteCreate) -> dict:
    domain = _normalize_domain(body.domain)
    if not domain or "." not in domain:
        raise HTTPException(status_code=422, detail="domain must be a hostname")
    site = db_sites.create_site(
        request.app.state.settings, body.name.strip(), domain
    )
    site["install_snippet"] = _install_line(request, site["site_key"])
    return site


@router.delete("/sites/{site_id}", status_code=204)
def delete_site(request: Request, site_id: str):
    # No return annotation: FastAPI 0.115 turns `-> None` into a response
    # model, which asserts against 204's no-body rule at route registration.
    db_sites.delete_site(request.app.state.settings, site_id)


@router.post("/sites/{site_id}/share-slug")
def create_share_slug(request: Request, site_id: str) -> dict:
    """(Re)generates the site's public share link, revoking any previous one."""
    slug = db_sites.set_share_slug(request.app.state.settings, site_id)
    return {"share_slug": slug}


@router.delete("/sites/{site_id}/share-slug", status_code=204)
def revoke_share_slug(request: Request, site_id: str):
    db_sites.clear_share_slug(request.app.state.settings, site_id)
