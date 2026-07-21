-- PS-012 — daily visitor-hash salts, generated inside Postgres so every
-- backend instance agrees. Salts older than yesterday are destroyed nightly
-- (0004 schedule) which makes stored visitor hashes permanently
-- un-reidentifiable — the core of the privacy design.
create table if not exists daily_salts (
  day date primary key,
  salt text not null
);

create or replace function get_daily_salt() returns text
language plpgsql as $$
declare
  v text;
begin
  insert into daily_salts (day, salt)
  values (current_date, encode(gen_random_bytes(32), 'hex'))
  on conflict (day) do nothing;
  select salt into v from daily_salts where day = current_date;
  return v;
end;
$$;

create or replace function purge_old_salts() returns void
language sql as $$
  delete from daily_salts where day < current_date - 1;
$$;
