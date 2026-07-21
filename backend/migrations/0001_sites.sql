-- PS-010 — sites registry. pgcrypto provides gen_random_bytes for site keys
-- and (later) daily salts.
create extension if not exists pgcrypto;

create table if not exists sites (
  id uuid primary key default gen_random_uuid(),
  site_key text unique not null default encode(gen_random_bytes(8), 'hex'),
  domain text not null,
  name text not null,
  share_slug text unique,          -- null = public sharing disabled (M3)
  created_at timestamptz not null default now()
);
