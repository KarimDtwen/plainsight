# Supabase migrations

Applied **manually, in order**, in the Supabase SQL editor (assisted — see the `migrations` skill). Never edit an applied file; supersede with a new number.

| File | Task | Creates |
|---|---|---|
| `0001_sites.sql` | PS-010 | `pgcrypto` extension, `sites` table (site_key default, share_slug) |
| `0002_events.sql` | PS-010 | `events` table + `idx_events_site_ts` |
| `0003_daily_salts.sql` | PS-012 | `daily_salts` table, `get_daily_salt()`, `purge_old_salts()` |
| `0004_rollups.sql` | PS-016 | `daily_rollups` table, `rollup_daily(date)`, `purge_raw_events(tz)` |
| `0005_stats_functions.sql` | PS-017 | `stats_timeseries`, `stats_breakdown`, `stats_summary`, `stats_live` |
| `0006_pg_cron.sql` | PS-016 | `pg_cron` extension + `plainsight-nightly` schedule (02:10 UTC) — **enable pg_cron in Dashboard → Database → Extensions first** |

## Prerequisite

A Supabase project (free tier) with its URL + service-role key in `backend/.env` / Render env.

## Verify after applying

```sql
select tablename from pg_tables where schemaname = 'public'
  and tablename in ('sites','events','daily_salts','daily_rollups');   -- 4 rows

select proname from pg_proc
 where proname in ('get_daily_salt','purge_old_salts','rollup_daily',
                   'purge_raw_events','stats_timeseries','stats_breakdown',
                   'stats_summary','stats_live');                       -- 8 rows

select jobname, schedule from cron.job;   -- plainsight-nightly | 10 2 * * *
```

## Contract guaranteed by these objects

- Events carry **no IP and no raw user-agent** — only the salted `visitor_hash`.
- Salts live at most 2 days (`purge_old_salts`), making hashes permanently un-reidentifiable.
- `rollup_daily` is idempotent (delete-day-then-insert) — safe to re-run for any day.
- Historical stats never scan raw events; today is UNIONed in live by the `stats_*` functions.
