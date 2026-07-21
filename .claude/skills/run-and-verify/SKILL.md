---
name: run-and-verify
description: Run Plainsight locally and prove a change works end-to-end — start both dev servers, seed live events, and watch the dashboard react. Use after any feature lands, or when asked to "run the app" or "verify it works".
---

# Run and verify Plainsight

1. **Start servers** via `.claude/launch.json` (preview_start, never raw Bash):
   - `backend-fastapi` → http://localhost:8000 (uvicorn --reload, uses `backend/.env`)
   - `flutter-web` → http://localhost:5000
2. **Health first:** GET `http://localhost:8000/health` must return `{"status":"ok"}`.
3. **Seed live traffic** (M1+): `backend/.venv/Scripts/python.exe backend/scripts/seed_events.py --target http://localhost:8000 --live --site <SITE_KEY>` — fires synthetic pageviews through `/collect` for a couple of minutes.
4. **Verify in the dashboard** at localhost:5000: log in with the dev `ADMIN_PASSWORD` from `backend/.env`, open the site, confirm:
   - the timeseries chart gains points within one refresh,
   - top pages / referrers reorder as seeded paths accumulate,
   - the live "online now" badge goes non-zero within ~10 s (its polling interval).
5. **Check logs:** uvicorn output should show `202` on `/collect` and no stack traces; browser console clean.
6. **Gates before calling anything done:** `flutter analyze` clean · `flutter test` green · `backend/.venv/Scripts/python.exe -m pytest -q` green (run from `backend/`).
7. Teardown: stop the seeder (Ctrl-C); dev servers can stay up between iterations — Flutter hot-reloads, uvicorn auto-reloads.

Never point the seeder at production or at the real UniMatch site row (see seed-demo-data skill).
