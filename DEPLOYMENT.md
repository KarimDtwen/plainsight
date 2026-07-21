# Plainsight — Deployment runbook

> Stub written in M0; sections are completed as their milestones land (M1 database, M4 deploy). Steps tagged **(assisted)** need a human in a dashboard — everything else is scriptable.

## 1. Supabase project — PS-010 (assisted)

Create a free Supabase project, then apply `backend/migrations/000N_*.sql` in order in the SQL editor. Enable the `pg_cron` extension (Dashboard → Database → Extensions) before applying `0006`. Verification queries per file: see [`backend/migrations/README.md`](backend/migrations/README.md).

## 2. Render service — PS-040 (assisted: secrets)

Blueprint deploy from [`render.yaml`](render.yaml) (service `plainsight-backend`, rootDir `backend`, free plan, health check `/health`, auto-deploy on `main`).

| Variable | Notes |
|---|---|
| `APP_ENV` | `production` (literal in render.yaml) |
| `PYTHON_VERSION` | `3.12.8` (literal) |
| `JWT_TTL_HOURS` | `168` (literal) |
| `SUPABASE_URL` | dashboard, `sync: false` |
| `SUPABASE_SERVICE_ROLE_KEY` | dashboard, `sync: false` |
| `ADMIN_PASSWORD` | dashboard, `sync: false` |
| `JWT_SECRET` | dashboard, `sync: false` — long random string |
| `ALLOWED_ORIGINS` | dashboard — the Firebase Hosting origin(s) |

## 3. Firebase Hosting — PS-041 (assisted: project creation)

Create a Firebase project for the dashboard, `firebase use --add`, then:

```bash
flutter build web --dart-define=API_BASE_URL=https://plainsight-backend.onrender.com
firebase deploy --only hosting
```

## 4. Deploy + smoke test — PS-040/043

1. `/health` → 200
2. `/js/script.js` → 200 with `Access-Control-Allow-Origin: *` and 24 h `Cache-Control`
3. Dashboard login with `ADMIN_PASSWORD`
4. One `/collect` round-trip appears in today's timeseries
5. Share link renders read-only without auth

> Cold starts: the free Render instance sleeps after ~15 min idle; the first request takes 30–60 s. The dashboard's server-waking banner covers this — it is expected behavior, not an outage.

## 5. Dogfood on UniMatch — PS-042

Register `unimatch-a095f.web.app` as a site, add the snippet line to UniMatch's `web/index.html`, rebuild and `firebase deploy` **in the UniMatch repo**, then verify real pageviews arrive in the Plainsight dashboard.
