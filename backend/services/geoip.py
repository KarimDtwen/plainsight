"""Country-only IP geolocation via a local DB-IP Lite mmdb file.

The database (~10 MB, CC BY 4.0 — "IP Geolocation by DB-IP", https://db-ip.com)
is downloaded at build time by ``scripts/fetch_geoip.py`` into ``backend/geoip/``
(git-ignored). When absent — local dev, CI, tests — every lookup returns ""
(shown as "Unknown"), never an error. The IP is used for this lookup + the
visitor hash, then discarded; only the 2-letter country code is stored.
"""

from __future__ import annotations

import glob
import os

import maxminddb

GEOIP_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "geoip"
)

_reader = None
_load_attempted = False
_load_detail = "not attempted yet"


def _load():
    global _reader, _load_attempted, _load_detail
    if _load_attempted:
        return _reader
    _load_attempted = True
    try:
        paths = sorted(glob.glob(os.path.join(GEOIP_DIR, "*.mmdb")))
        if not paths:
            status_path = os.path.join(GEOIP_DIR, ".status")
            if os.path.exists(status_path):
                with open(status_path) as f:
                    _load_detail = f"no mmdb; build status: {f.read().strip()}"
            else:
                _load_detail = f"no *.mmdb file in {GEOIP_DIR} (no build status recorded)"
        else:
            _reader = maxminddb.open_database(paths[-1])
            _load_detail = f"loaded {paths[-1]}"
    except Exception as exc:  # noqa: BLE001 — surfaced via is_loaded_detail()
        _reader = None
        _load_detail = f"{type(exc).__name__}: {exc}"
    return _reader


def country(ip: str) -> str:
    """ISO 3166-1 alpha-2 code, or "" when unknown/unavailable."""
    reader = _load()
    if reader is None or not ip:
        return ""
    try:
        record = reader.get(ip) or {}
        return (record.get("country") or {}).get("iso_code", "") or ""
    except Exception:
        return ""


def is_loaded() -> bool:
    """Whether the mmdb database is present and opened — surfaced on /health
    since a build-time download failure is otherwise silent."""
    return _load() is not None


def load_detail() -> str:
    """One-line diagnostic: which file loaded, or why nothing did."""
    _load()
    return _load_detail


def reset_for_tests() -> None:
    global _reader, _load_attempted, _load_detail
    if _reader is not None:
        try:
            _reader.close()
        except Exception:
            pass
    _reader = None
    _load_attempted = False
    _load_detail = "not attempted yet"
