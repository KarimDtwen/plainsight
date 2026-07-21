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


def _load():
    global _reader, _load_attempted
    if _load_attempted:
        return _reader
    _load_attempted = True
    try:
        paths = sorted(glob.glob(os.path.join(GEOIP_DIR, "*.mmdb")))
        if paths:
            _reader = maxminddb.open_database(paths[-1])
    except Exception:
        _reader = None
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


def reset_for_tests() -> None:
    global _reader, _load_attempted
    if _reader is not None:
        try:
            _reader.close()
        except Exception:
            pass
    _reader = None
    _load_attempted = False
