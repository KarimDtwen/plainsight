-- PS-017 — all stats queries as SQL functions called via supabase.rpc().
-- Shape: full past days come from daily_rollups; the current (partial) day is
-- computed live from raw events and UNIONed in. Week/month "visitors" is the
-- sum of daily uniques — a stated approximation (exact cross-day uniques
-- would require keeping per-visitor state past the salt lifetime).

create or replace function stats_timeseries(
  p_site uuid, p_from date, p_to date, p_bucket text
) returns table (bucket date, pageviews bigint, visitors bigint)
language sql stable as $$
  with daily as (
    select day, pageviews::bigint as pageviews, visitors::bigint as visitors
      from daily_rollups
     where site_id = p_site and dimension = 'total'
       and day >= p_from and day <= p_to and day < current_date
    union all
    select current_date as day,
           count(*)::bigint, count(distinct visitor_hash)::bigint
      from events
     where site_id = p_site and ts >= current_date
       and current_date >= p_from and current_date <= p_to
     group by 1
    having count(*) > 0
  )
  select date_trunc(
           case when p_bucket in ('week', 'month') then p_bucket else 'day' end,
           day
         )::date as bucket,
         sum(pageviews)::bigint as pageviews,
         sum(visitors)::bigint as visitors
    from daily
   group by 1
   order by 1;
$$;

create or replace function stats_breakdown(
  p_site uuid, p_from date, p_to date, p_dimension text, p_limit int
) returns table (value text, pageviews bigint, visitors bigint)
language sql stable as $$
  with merged as (
    select value, pageviews::bigint as pageviews, visitors::bigint as visitors
      from daily_rollups
     where site_id = p_site and dimension = p_dimension
       and day >= p_from and day <= p_to and day < current_date
    union all
    select case p_dimension
             when 'page' then path
             when 'referrer' then referrer_host
             when 'country' then country
             when 'device' then device
             when 'browser' then browser
           end as value,
           count(*)::bigint, count(distinct visitor_hash)::bigint
      from events
     where site_id = p_site and ts >= current_date
       and current_date >= p_from and current_date <= p_to
     group by 1
  )
  select value,
         sum(pageviews)::bigint as pageviews,
         sum(visitors)::bigint as visitors
    from merged
   group by value
   order by 2 desc, value
   limit p_limit;
$$;

create or replace function stats_summary(
  p_site uuid, p_from date, p_to date
) returns table (pageviews bigint, visitors bigint)
language sql stable as $$
  select coalesce(sum(t.pageviews), 0)::bigint,
         coalesce(sum(t.visitors), 0)::bigint
    from stats_timeseries(p_site, p_from, p_to, 'day') as t;
$$;

create or replace function stats_live(p_site uuid) returns bigint
language sql stable as $$
  select count(distinct visitor_hash)
    from events
   where site_id = p_site and ts > now() - interval '5 minutes';
$$;
