---
name: seed-demo-data
description: Generate realistic analytics traffic — live drip for verification or multi-day backfill for screenshots/demos. Use for "seed data", "demo traffic", or when screenshots need a populated dashboard.
---

# Seed demo data

Tool: `backend/scripts/seed_events.py` (lands in M1/PS-018). Two modes:

1. **Live drip** (E2E verification): `--live --target http://localhost:8000 --site <SITE_KEY>` — real HTTP POSTs to `/collect` at a few events/sec so charts and the live counter visibly move. Local/dev targets only.
2. **Backfill** (history for screenshots/demo): `--backfill --days 30 --site <SITE_KEY>` — inserts events directly via Supabase and calls `rollup_daily()` per day, so a demo site instantly has a month of history.

Realism requirements (built into the script — keep them if editing):
- weekday/weekend volume curve + hour-of-day curve (quiet nights, evening peak)
- weighted paths (a few heavy pages + long tail), weighted referrer hosts (google, twitter, direct…), weighted countries/devices/browsers
- stable visitor hashes within a day (so uniques < pageviews, realistically ~1:2.5)

Hard rules:
- **NEVER seed the real UniMatch site row** — its whole point is real traffic (M4 dogfood). Seed only a dedicated demo site (create one via the dashboard/API if missing).
- Backfill against production only for the demo site, and note it in progress.md.
- The `/collect` route drops bot UAs — the seeder sends a realistic browser UA on purpose; don't "fix" that.
