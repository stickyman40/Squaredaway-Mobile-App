alter table public.users_profile add column if not exists discovery_source text;
alter table public.users_profile add column if not exists discovery_notes text;

create table if not exists public.tracker_data (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  current_duty_station text not null default '',
  duty_status text not null default '',
  next_milestone text not null default '',
  report_date timestamptz,
  notes text,
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.pcs_data (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  origin_location text not null default '',
  destination_location text not null default '',
  move_date timestamptz,
  shipment_booked boolean not null default false,
  lodging_secured boolean not null default false,
  travel_booked boolean not null default false,
  notes text,
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.benefits_data (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  va_health_enrolled boolean not null default false,
  gi_bill_ready boolean not null default false,
  tsp_contributing boolean not null default false,
  family_support_plan boolean not null default false,
  notes text,
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_tracker_data_user_id on public.tracker_data (user_id);
create index if not exists idx_pcs_data_user_id on public.pcs_data (user_id);
create index if not exists idx_benefits_data_user_id on public.benefits_data (user_id);

drop trigger if exists set_tracker_data_updated_at on public.tracker_data;
create trigger set_tracker_data_updated_at
before update on public.tracker_data
for each row execute function public.set_updated_at();

drop trigger if exists set_pcs_data_updated_at on public.pcs_data;
create trigger set_pcs_data_updated_at
before update on public.pcs_data
for each row execute function public.set_updated_at();

drop trigger if exists set_benefits_data_updated_at on public.benefits_data;
create trigger set_benefits_data_updated_at
before update on public.benefits_data
for each row execute function public.set_updated_at();

alter table public.tracker_data enable row level security;
alter table public.pcs_data enable row level security;
alter table public.benefits_data enable row level security;

drop policy if exists "Users manage own tracker data" on public.tracker_data;
create policy "Users manage own tracker data"
on public.tracker_data
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users manage own pcs data" on public.pcs_data;
create policy "Users manage own pcs data"
on public.pcs_data
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users manage own benefits data" on public.benefits_data;
create policy "Users manage own benefits data"
on public.benefits_data
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
