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


def main() -> int:
    os.makedirs(GEOIP_DIR, exist_ok=True)
    dest = os.path.join(GEOIP_DIR, "dbip-country-lite.mmdb")

    this_month = date.today().replace(day=1)
    previous_month = (this_month - timedelta(days=1)).replace(day=1)

    for month in (this_month, previous_month):
        url = URL_TEMPLATE.format(ym=month.strftime("%Y-%m"))
        archive = dest + ".gz"
        try:
            print(f"[geoip] fetching {url}")
            with urllib.request.urlopen(url, timeout=60) as resp:
                with open(archive, "wb") as out:
                    shutil.copyfileobj(resp, out)
            with gzip.open(archive, "rb") as src, open(dest, "wb") as out:
                shutil.copyfileobj(src, out)
            os.remove(archive)
            print(f"[geoip] ok: {dest} ({os.path.getsize(dest) // 1024} KiB)")
            return 0
        except Exception as exc:  # noqa: BLE001 — any failure = try fallback
            print(f"[geoip] {month:%Y-%m} failed: {exc}")

    print("[geoip] WARNING: no database downloaded — countries will be Unknown")
    return 0  # never break the build


if __name__ == "__main__":
    sys.exit(main())
