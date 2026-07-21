-- PS-016 — nightly maintenance INSIDE the database. The Render free-tier
-- backend sleeps, so it can never be trusted with cron; pg_cron runs with the
-- DB itself. Manual fallback: POST /admin/rollup?day=YYYY-MM-DD.
--
-- ASSISTED PREREQUISITE: enable the pg_cron extension first in the Supabase
-- dashboard (Database -> Extensions -> pg_cron), then run this file.

create extension if not exists pg_cron;

-- Idempotent scheduling: drop an existing job with the same name first.
do $$
begin
  perform cron.unschedule('plainsight-nightly')
   where exists (select 1 from cron.job where jobname = 'plainsight-nightly');
end;
$$;

select cron.schedule(
  'plainsight-nightly',
  '10 2 * * *',   -- 02:10 UTC daily
  $job$
    select rollup_daily(current_date - 1);
    select purge_raw_events(now() - interval '90 days');
    select purge_old_salts();
  $job$
);
