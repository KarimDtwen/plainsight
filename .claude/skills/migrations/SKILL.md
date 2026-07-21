---
name: migrations
description: How to change the Plainsight database schema — numbered SQL files, README index, assisted apply in Supabase. Load before ANY schema, Postgres function, or pg_cron change.
---

# Migrations

Hand-numbered raw SQL in `backend/migrations/`, applied manually in the Supabase SQL editor (same convention as UniMatch). No ORM, no auto-migrate.

1. New change → new file `backend/migrations/000N_short_name.sql` (next free number). **Never edit an already-applied file** — supersede it with a new number.
2. Write idempotently where possible (`CREATE TABLE IF NOT EXISTS`, `CREATE OR REPLACE FUNCTION`, guarded `DO $$` blocks) so re-runs are safe.
3. Heavy lifting belongs in Postgres functions called via `supabase.rpc()` — rollups, stats queries, salt generation. Transactional integrity lives in the DB, not the app.
4. Update the index table in `backend/migrations/README.md`: `| File | Task | Creates |` row with the PS-### item and the objects created.
5. **Applying is assisted:** Karim pastes the file into the Supabase SQL editor. Provide the file path and the verification query (e.g. `select proname from pg_proc where proname like 'stats_%';`) and wait for confirmation before shipping code that depends on it.
6. pg_cron jobs (0006): the extension must be enabled once in Dashboard → Database → Extensions **(assisted)** before the schedule migration runs.
7. Keep app-code fallbacks: anything pg_cron does nightly must also be triggerable via the JWT-guarded `POST /admin/rollup?day=` for manual recovery.
