-- PS-010 — raw pageview events. Privacy invariant: NO ip, NO raw user-agent,
-- no cookie id — only the daily-salted visitor_hash (see 0003). Raw rows are
-- purged after 90 days (0004); rollups keep history forever.
create table if not exists events (
  id bigint generated always as identity primary key,
  site_id uuid not null references sites(id) on delete cascade,
  ts timestamptz not null default now(),
  path text not null,
  referrer_host text not null default '',   -- normalized host only; '' = direct
  country char(2) not null default '',      -- ISO 3166-1 alpha-2; '' = unknown
  device text not null,                     -- mobile | tablet | desktop
  browser text not null,                    -- chrome|firefox|safari|edge|other
  visitor_hash text not null                -- 32 hex chars
);

-- Serves both "today live from raw" stats and the 5-minute online-now query.
create index if not exists idx_events_site_ts on events (site_id, ts desc);
