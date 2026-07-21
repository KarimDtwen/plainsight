"""Synthetic traffic generator (see the seed-demo-data skill).

Live mode — drip realistic pageviews through POST /collect so charts and the
live counter visibly move during local verification:

    python scripts/seed_events.py --live --target http://localhost:8000 \
        --site SITE_KEY --minutes 3

Backfill mode — insert N days of history directly via Supabase and roll each
day up (requires backend/.env creds; used to populate the demo site):

    python scripts/seed_events.py --backfill --days 30 --site SITE_KEY

Never run against the real UniMatch site — its dashboard must show only real
traffic. A hard guard below refuses any site whose domain contains "unimatch".
"""

from __future__ import annotations

import argparse
import json
import os
import random
import sys
import time
import urllib.request
from datetime import datetime, timedelta, timezone

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Weighted, deliberately realistic distributions (heavy head + long tail).
PATHS = [
    ("/", 30), ("/pricing", 12), ("/blog", 10), ("/blog/launch", 8),
    ("/docs", 8), ("/docs/install", 6), ("/about", 5), ("/changelog", 4),
    ("/blog/privacy-first-analytics", 4), ("/contact", 3), ("/careers", 2),
    ("/docs/api", 2), ("/terms", 1), ("/privacy", 1),
]
REFERRERS = [
    ("", 42), ("https://www.google.com/", 25), ("https://t.co/", 8),
    ("https://news.ycombinator.com/", 7), ("https://www.reddit.com/", 6),
    ("https://github.com/", 5), ("https://www.bing.com/", 4),
    ("https://duckduckgo.com/", 3),
]
# Real browser UAs — /collect drops bot-looking agents on purpose.
USER_AGENTS = [
    ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36", 40),
    ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15", 18),
    ("Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1", 16),
    ("Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:126.0) Gecko/20100101 Firefox/126.0", 10),
    ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36 Edg/126.0.0.0", 9),
    ("Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36", 7),
]
WIDTHS = [(390, 30), (414, 8), (768, 8), (834, 4), (1280, 20), (1440, 18), (1920, 12)]
# Public-IP samples spread across countries (geoip resolves them when the
# mmdb is present; hashes vary regardless).
IP_POOLS = [
    "8.8.8.{n}", "1.1.1.{n}", "82.65.112.{n}", "90.3.44.{n}", "154.121.5.{n}",
    "196.64.18.{n}", "41.111.7.{n}", "212.51.33.{n}", "78.94.140.{n}",
    "185.94.188.{n}", "102.129.65.{n}", "34.96.101.{n}",
]


def _pick(weighted):
    values, weights = zip(*weighted)
    return random.choices(values, weights=weights, k=1)[0]


def _hour_weight(hour: int) -> float:
    # Quiet nights, morning ramp, evening peak.
    return [0.2, 0.15, 0.1, 0.1, 0.15, 0.3, 0.5, 0.8, 1.0, 1.1, 1.2, 1.2,
            1.1, 1.0, 1.0, 1.1, 1.2, 1.3, 1.5, 1.6, 1.5, 1.2, 0.8, 0.4][hour]


class Visitor:
    def __init__(self) -> None:
        self.ip = _pick([(p, 1) for p in IP_POOLS]).format(n=random.randint(2, 250))
        self.ua = _pick(USER_AGENTS)
        self.width = _pick(WIDTHS)


def run_live(target: str, site_key: str, minutes: float, rate_per_sec: float) -> None:
    pool = [Visitor() for _ in range(24)]
    deadline = time.time() + minutes * 60
    sent = 0
    while time.time() < deadline:
        visitor = random.choice(pool)
        payload = json.dumps({
            "s": site_key,
            "u": _pick(PATHS),
            "r": _pick(REFERRERS),
            "w": visitor.width,
        }).encode()
        req = urllib.request.Request(
            target.rstrip("/") + "/collect",
            data=payload,
            headers={
                "Content-Type": "text/plain",
                "User-Agent": visitor.ua,
                "X-Forwarded-For": visitor.ip,
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                sent += 1
                if sent % 25 == 0:
                    print(f"[seed] {sent} events sent (last status {resp.status})")
        except Exception as exc:  # noqa: BLE001
            print(f"[seed] send failed: {exc}")
            time.sleep(2)
        time.sleep(random.expovariate(rate_per_sec))
    print(f"[seed] done — {sent} events")


def run_backfill(site_key: str, days: int) -> None:
    from config import Settings
    from db import client as db_client
    from services import hashing, ua as ua_service

    settings = Settings.from_env()
    sb = db_client.get_client(settings)

    resp = sb.table("sites").select("*").eq("site_key", site_key).limit(1).execute()
    if not resp.data:
        sys.exit(f"[seed] no site with key {site_key!r}")
    site = resp.data[0]
    if "unimatch" in (site.get("domain") or "").lower():
        sys.exit("[seed] REFUSED: never seed the UniMatch site — real traffic only.")

    today = datetime.now(timezone.utc).date()
    for offset in range(days, 0, -1):
        day = today - timedelta(days=offset)
        weekday_factor = 1.0 if day.weekday() < 5 else 0.62
        base = random.randint(140, 220)
        day_salt = f"backfill-{day.isoformat()}"
        visitors = [Visitor() for _ in range(max(8, int(base * weekday_factor / 2.6)))]
        rows = []
        for _ in range(int(base * weekday_factor)):
            hour = random.choices(range(24), weights=[_hour_weight(h) for h in range(24)], k=1)[0]
            ts = datetime(day.year, day.month, day.day, hour,
                          random.randint(0, 59), random.randint(0, 59),
                          tzinfo=timezone.utc)
            visitor = random.choice(visitors)
            referrer = _pick(REFERRERS)
            rows.append({
                "site_id": site["id"],
                "ts": ts.isoformat(),
                "path": _pick(PATHS),
                "referrer_host": referrer.split("/")[2] if referrer else "",
                "country": _pick([("US", 30), ("FR", 15), ("DZ", 12), ("DE", 10),
                                  ("GB", 8), ("MA", 6), ("CA", 6), ("IN", 5),
                                  ("BR", 4), ("", 4)]),
                "device": ua_service.device(visitor.width),
                "browser": ua_service.browser(visitor.ua),
                "visitor_hash": hashing.visitor_hash(day_salt, site["id"], visitor.ip, visitor.ua),
            })
        for start in range(0, len(rows), 500):
            sb.table("events").insert(rows[start:start + 500]).execute()
        sb.rpc("rollup_daily", {"p_day": day.isoformat()}).execute()
        print(f"[seed] {day} — {len(rows)} events, rolled up")
    print("[seed] backfill complete")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--live", action="store_true")
    mode.add_argument("--backfill", action="store_true")
    parser.add_argument("--site", required=True, help="site_key")
    parser.add_argument("--target", default="http://localhost:8000")
    parser.add_argument("--minutes", type=float, default=3.0)
    parser.add_argument("--rate", type=float, default=1.5, help="events/sec (live)")
    parser.add_argument("--days", type=int, default=30)
    args = parser.parse_args()

    if args.live:
        run_live(args.target, args.site, args.minutes, args.rate)
    else:
        run_backfill(args.site, args.days)


if __name__ == "__main__":
    main()
