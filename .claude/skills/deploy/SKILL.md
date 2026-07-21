---
name: deploy
description: Deploy Plainsight — backend to Render, dashboard to Firebase Hosting — in the safe order with smoke tests. Use for "deploy", "release", or "push to prod".
---

# Deploy Plainsight

Order matters: migrations → backend → web. Steps tagged **(assisted)** need Karim in a dashboard.

1. **Gates:** `flutter analyze` clean, `flutter test` green, backend pytest green, working tree committed.
2. **Migrations first (assisted):** if `backend/migrations/` gained a new `000N_*.sql`, apply it in the Supabase SQL editor BEFORE deploying code that needs it. Verify with the check query listed in `backend/migrations/README.md`.
3. **Backend:** `git push` → Render auto-deploys from `main` (`render.yaml`, rootDir `backend`). Watch https://plainsight-backend.onrender.com/health until 200. New env vars must be added in the Render dashboard first **(assisted)** — they are `sync: false` and never committed.
4. **Dashboard:** `flutter build web --dart-define=API_BASE_URL=https://plainsight-backend.onrender.com` then `firebase deploy --only hosting` (Firebase project created in M4/PS-041).
5. **Prod smoke, in order:**
   - GET `/health` → 200
   - GET `/js/script.js` → 200, `Access-Control-Allow-Origin: *`, `Cache-Control` 24 h
   - dashboard loads, login works
   - one manual `/collect` POST → 202, appears in today's timeseries
   - share-link page renders without auth
6. **Cold-start caveat:** Render free tier sleeps (~15 min idle). First request takes 30–60 s; the dashboard shows the server-waking banner. That is expected, not an outage.
7. Log the deploy in `progress.md` (progress-log skill).
