-- PS-016 — one generic rollup table covers every breakdown dimension, so one
-- idempotent function (delete-day-then-insert, atomic within the function's
-- transaction) maintains all of them. Historical queries never touch raw
-- events; raw rows older than 90 days are purged.
create table if not exists daily_rollups (
  site_id uuid not null references sites(id) on delete cascade,
  day date not null,
  dimension text not null,   -- 'total'|'page'|'referrer'|'country'|'device'|'browser'
  value text not null,       -- '' for 'total'
  pageviews int not null,
  visitors int not null,     -- count(distinct visitor_hash) within the group
  primary key (site_id, day, dimension, value)
);

create or replace function rollup_daily(p_day date) returns void
language sql as $$
  delete from daily_rollups where day = p_day;

  insert into daily_rollups (site_id, day, dimension, value, pageviews, visitors)
  select site_id, p_day, 'total', '',
         count(*), count(distinct visitor_hash)
    from events
   where ts >= p_day and ts < p_day + 1
   group by site_id
  union all
  select site_id, p_day, 'page', path,
         count(*), count(distinct visitor_hash)
    from events
   where ts >= p_day and ts < p_day + 1
   group by site_id, path
  union all
  select site_id, p_day, 'referrer', referrer_host,
         count(*), count(distinct visitor_hash)
    from events
   where ts >= p_day and ts < p_day + 1
   group by site_id, referrer_host
  union all
  select site_id, p_day, 'country', country,
         count(*), count(distinct visitor_hash)
    from events
   where ts >= p_day and ts < p_day + 1
   group by site_id, country
  union all
  select site_id, p_day, 'device', device,
         count(*), count(distinct visitor_hash)
    from events
   where ts >= p_day and ts < p_day + 1
   group by site_id, device
  union all
  select site_id, p_day, 'browser', browser,
         count(*), count(distinct visitor_hash)
    from events
   where ts >= p_day and ts < p_day + 1
   group by site_id, browser;
$$;

create or replace function purge_raw_events(p_before timestamptz) returns void
language sql as $$
  delete from events where ts < p_before;
$$;
