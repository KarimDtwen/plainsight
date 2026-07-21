# Plainsight — Progress & Handoff

_Last updated: 2026-07-21_

## TL;DR

Portfolio SaaS: privacy-first web analytics (mini-Plausible) — ~50-line snippet + FastAPI ingestion + Flutter-web dashboard. M0 (scaffold, CI, docs, skills) is **done**. Signature demo hook: in M4 the snippet goes on the live UniMatch web app so the dashboard shows real traffic.

- Repo: https://github.com/KarimDtwen/plainsight · local `C:\flutter\projects\plainsight`
- Design system + glass kit ported from UniMatch v3 (`lib/theme/`, `lib/ui/`) + new `chartSeries` token
- Backend: FastAPI split into `routers/schemas/services/db` (NOT UniMatch's single-file shape), frozen `Settings`, hermetic pytest
- Roadmap of record: Notion page **Plainsight — Build Roadmap** (id `3a4f8878-4309-812c-a09d-e70751d94af8`)
- Plan file: `C:\Users\NTIC\.claude\plans\start-making-a-plan-giggly-crescent.md`

## Repo / environment facts

- Remote: `origin` → `https://github.com/KarimDtwen/plainsight.git`, branch `main`
- Flutter pinned 3.38.7 (matches local + CI) · Python 3.12.8 (`backend/runtime.txt`)
- Backend venv: `backend/.venv` (git-ignored) — `.venv/Scripts/python -m pytest -q`
- Supabase project: **not created yet** (M1, assisted)
- Render service / Firebase project: **not created yet** (M4, assisted)
- Secrets: none exist yet; template in `backend/.env.example`; prod values will live in Render dashboard only
- Work items: `PS-###` · commits: conventional types + PS tag

## Completed milestones (committed)

| M | Title | Status |
|---|---|---|
| 0 | Scaffold + repo + docs + CI + skills + Notion | ✅ `484587c` (+4 prior) — see 2026-07-21 section |
| 1 | Ingestion + snippet + stats API | ⬜ |
| 2 | Dashboard + charts | ⬜ |
| 3 | Live counter + share links | ⬜ |
| 4 | Deploy + dogfood on UniMatch | ⬜ |
| 5 | Polish (demo data, README, GIF) | ⬜ |

## Current state

- `main` @ `484587c`, working tree clean (progress.md commit pending)
- `flutter analyze` clean · 2 Flutter tests · 10 backend tests
- App renders a placeholder glass card on the aurora gradient; backend serves `/health` only

## 🏗️ M0 — Scaffold, CI, docs, skills (2026-07-21) — done

**Done & committed:**

- **`PS-001`** `530a30f` — flutter create (web) + UniMatch v3 theme/ui port (glass kit, tokens, fonts) + `chartSeries` token + placeholder home + 2 smoke tests
- **`PS-002`** `2a40b73` — backend skeleton: thin `main.py` factory, `routers/schemas/services/db` layout, `config.py` Settings port (repr=False secrets, prod fail-fast), hermetic conftest, 10 tests
- **`PS-003`** `7e0f6e1` — CI: two hermetic jobs (Flutter 3.38.7 analyze+test · Python 3.12.8 pytest), no secrets
- **`PS-004`** `4327f0b` — README (badges, Mermaid architecture, privacy design, status), DEPLOYMENT.md runbook stub, render.yaml, firebase.json
- **`PS-005`** `484587c` — `.claude/launch.json` (backend :8000 / flutter-web :5000 / static :8080) + 6 project skills (run-and-verify, deploy, design-tokens, progress-log, seed-demo-data, migrations)
- **`PS-006`** — Notion roadmap page created (`3a4f8878-4309-812c-a09d-e70751d94af8`); GitHub repo created via API

Left intentionally: no fl_chart dep yet (M2), no supabase/aiohttp deps yet (M1 — conftest grows Forbidden* fakes then), no `.firebaserc` (M4 creates the Firebase project).

✅ `flutter analyze` clean · 2 Flutter tests · 10 backend tests

## Next steps (in order)

1. ⬜ **PS-010 — Manual (Karim): create the Supabase project**, then apply migrations `0001–0003` in the SQL editor (I write them first)
2. ⬜ PS-011..015 — `/collect` ingestion, salt/hash service, geoip, UA parse, the snippet itself
3. ⬜ PS-016..018 — rollups + stats functions + pg_cron migration, `/stats/*` endpoints, `seed_events.py`
4. ⬜ M2 — ApiService + login + sites + dashboard charts (add `fl_chart`)
5. ⬜ M3 — live badge + share links
6. ⬜ **M4 — Manual (Karim): Render service + Firebase project**, then dogfood snippet into UniMatch `web/index.html`
7. ⬜ M5 — demo seed, screenshots, GIF, README final

## Gotchas / things to know

- **Never `pumpAndSettle` on gradient screens** — the aurora drift loops forever (same as UniMatch); pump fixed durations.
- Local Flutter reports "new version available" — stay on 3.38.7 to match CI's pin; upgrading changes the active lint set.
- The scaffold's newer lints (`unnecessary_underscores`, `use_null_aware_elements`) were fixed in the ported files — keep new code clean under both.
- Render free tier sleeps → anything scheduled must live in pg_cron (DB side), never APScheduler; the live counter polls, no WebSocket.
- Client IP on Render = first entry of `X-Forwarded-For` (proxy), fall back to `request.client.host`.
- `/collect` must stay a CORS *simple request* (text/plain body) — adding a JSON content-type would trigger preflights from every tracked site.
- Windows CRLF warnings on commit are cosmetic; don't "fix" line endings repo-wide.

## How to run / verify

```bash
# Backend
cd backend
.venv/Scripts/python -m pytest -q          # 10 tests
.venv/Scripts/python -m uvicorn main:app --reload --port 8000

# App
flutter analyze
flutter test                               # 2 tests
flutter run -d chrome --web-port 5000 --dart-define=API_BASE_URL=http://localhost:8000
```
