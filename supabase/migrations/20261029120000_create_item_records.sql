create extension if not exists pgcrypto;

create table public.item_records (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null,
  location text not null,
  status text not null,
  created_at timestamptz not null default now(),
  constraint item_records_name_length check (char_length(name) <= 60),
  constraint item_records_description_length check (char_length(description) <= 200),
  constraint item_records_status_allowed check (status in ('lost', 'found'))
);

alter table public.item_records enable row level security;

revoke all on table public.item_records from anon, authenticated;
grant select on table public.item_records to anon;
grant insert (name, description, location, status) on table public.item_records to anon;

create policy "Anonymous users can list demonstration item records"
on public.item_records
for select
to anon
using (true);

create policy "Anonymous users can insert demonstration item records"
on public.item_records
for insert
to anon
with check (
  name is not null
  and char_length(name) <= 60
  and description is not null
  and char_length(description) <= 200
  and location is not null
  and status in ('lost', 'found')
  and id is not null
  and created_at is not null
);
