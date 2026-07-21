"""User-agent classification: bot filtering, browser family, device bucket.

Kept deliberately regex-simple — the goal is honest aggregate breakdowns, not
perfect UA science. Device comes from the viewport width the snippet reports,
which is more truthful than UA sniffing."""

from __future__ import annotations

import re

_BOT_RE = re.compile(
    r"bot|crawl|spider|slurp|headless|lighthouse|pingdom|monitor|preview"
    r"|python-requests|python-urllib|curl|wget|scrapy|httpx|go-http-client"
    r"|facebookexternalhit|whatsapp|telegram|discord|embedly",
    re.IGNORECASE,
)


def is_bot(user_agent: str) -> bool:
    """Empty UAs count as bots — every real browser sends one."""
    if not user_agent or not user_agent.strip():
        return True
    return bool(_BOT_RE.search(user_agent))


def browser(user_agent: str) -> str:
    """Family bucket: chrome | firefox | safari | edge | other.

    Order matters — Edge and Opera embed "Chrome/", and Chrome embeds
    "Safari/", so the more specific tokens are checked first."""
    ua = (user_agent or "").lower()
    if "edg/" in ua or "edge/" in ua:
        return "edge"
    if "opr/" in ua or "opera" in ua:
        return "other"
    if "firefox/" in ua:
        return "firefox"
    if "chrome/" in ua or "crios/" in ua:
        return "chrome"
    if "safari/" in ua:
        return "safari"
    return "other"


def device(viewport_width: int) -> str:
    """mobile < 768 <= tablet < 1024 <= desktop; unknown widths → desktop."""
    if viewport_width <= 0:
        return "desktop"
    if viewport_width < 768:
        return "mobile"
    if viewport_width < 1024:
        return "tablet"
    return "desktop"
