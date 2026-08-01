"""Build-time download of the DB-IP Country Lite database (CC BY 4.0).

Runs in Render's buildCommand. Tries the current month's file, falls back to
the previous month (DB-IP publishes early in the month). NEVER fails the
build — a missing database just means countries show as Unknown.

Attribution requirement (CC BY 4.0): "IP Geolocation by DB-IP"
(https://db-ip.com) — present in README.md and the dashboard footer.
"""

from __future__ import annotations

import gzip
import os
import shutil
import sys
import urllib.request
from datetime import date, timedelta

GEOIP_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "geoip"
)
URL_TEMPLATE = "https://download.db-ip.com/free/dbip-country-lite-{ym}.mmdb.gz"
# DB-IP's server 403s urllib's default "Python-urllib/x.y" User-Agent
# (confirmed live: Render's build logs showed HTTP 403 for both months,
# while the identical URL curled fine) — any non-empty, non-default UA works.
_REQUEST_HEADERS = {"User-Agent": "plainsight-geoip-fetch/1.0"}


def _write_status(text: str) -> None:
    # Read by services/geoip.py so a build-time download failure — otherwise
    # silent — shows up in /health's geoip_detail instead of just this log.
    with open(os.path.join(GEOIP_DIR, ".status"), "w") as f:
        f.write(text + "\n")


def main() -> int:
    os.makedirs(GEOIP_DIR, exist_ok=True)
    dest = os.path.join(GEOIP_DIR, "dbip-country-lite.mmdb")

    this_month = date.today().replace(day=1)
    previous_month = (this_month - timedelta(days=1)).replace(day=1)

    errors = []
    for month in (this_month, previous_month):
        url = URL_TEMPLATE.format(ym=month.strftime("%Y-%m"))
        archive = dest + ".gz"
        try:
            print(f"[geoip] fetching {url}")
            request = urllib.request.Request(url, headers=_REQUEST_HEADERS)
            with urllib.request.urlopen(request, timeout=60) as resp:
                with open(archive, "wb") as out:
                    shutil.copyfileobj(resp, out)
            with gzip.open(archive, "rb") as src, open(dest, "wb") as out:
                shutil.copyfileobj(src, out)
            os.remove(archive)
            size_kb = os.path.getsize(dest) // 1024
            print(f"[geoip] ok: {dest} ({size_kb} KiB)")
            _write_status(f"ok: {dest} ({size_kb} KiB)")
            return 0
        except Exception as exc:  # noqa: BLE001 — any failure = try fallback
            msg = f"{month:%Y-%m}: {type(exc).__name__}: {exc}"
            print(f"[geoip] {msg}")
            errors.append(msg)

    detail = "; ".join(errors) or "unknown failure"
    print(f"[geoip] WARNING: no database downloaded — countries will be Unknown ({detail})")
    _write_status(f"failed: {detail}")
    return 0  # never break the build


if __name__ == "__main__":
    sys.exit(main())
