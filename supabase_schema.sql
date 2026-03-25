-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Shared helper functions
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Core tables
-- ---------------------------------------------------------------------------
create table if not exists public.users_profile (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  branch text,
  rank text,
  mos text,
  discovery_source text,
  discovery_notes text,
  first_name text default '' not null,
  last_name text default '' not null,
  height_cm double precision,
  weight_kg double precision,
  fitness_goal text,
  onboarding_complete boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.users_profile add column if not exists discovery_source text;
alter table public.users_profile add column if not exists discovery_notes text;

-- ---------------------------------------------------------------------------
-- Feature tables
-- ---------------------------------------------------------------------------
create table if not exists public.fitness_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  exercise_type text not null,
  duration integer not null default 0,
  score double precision,
  notes text,
  logged_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.nutrition_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  meal_type text not null,
  calories integer not null default 0,
  protein double precision not null default 0,
  carbs double precision not null default 0,
  fat double precision not null default 0,
  notes text,
  logged_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.promotions_data (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  current_rank text not null,
  target_rank text not null,
  points_current integer not null default 0,
  points_required integer not null default 0,
  board_date timestamptz,
  notes text,
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.pay_data (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  pay_grade text not null,
  base_pay numeric(10, 2) not null default 0,
  bah numeric(10, 2) not null default 0,
  bas numeric(10, 2) not null default 0,
  updated_at timestamptz not null default timezone('utc', now())
);

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

-- ---------------------------------------------------------------------------
-- Notification tables
-- ---------------------------------------------------------------------------
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  title text not null,
  body text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.notification_preferences (
  user_id uuid primary key references public.users_profile(id) on delete cascade,
  milestones_enabled boolean not null default true,
  readiness_enabled boolean not null default true,
  activity_enabled boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
create index if not exists idx_fitness_logs_user_logged_at on public.fitness_logs (user_id, logged_at desc);
create index if not exists idx_nutrition_logs_user_logged_at on public.nutrition_logs (user_id, logged_at desc);
create index if not exists idx_promotions_data_user_id on public.promotions_data (user_id);
create index if not exists idx_pay_data_user_id on public.pay_data (user_id);
create index if not exists idx_tracker_data_user_id on public.tracker_data (user_id);
create index if not exists idx_pcs_data_user_id on public.pcs_data (user_id);
create index if not exists idx_benefits_data_user_id on public.benefits_data (user_id);
create index if not exists idx_notifications_user_created_at on public.notifications (user_id, created_at desc);
create index if not exists idx_notification_preferences_user_id on public.notification_preferences (user_id);

-- ---------------------------------------------------------------------------
-- Backfill rows for existing users
-- ---------------------------------------------------------------------------
insert into public.notification_preferences (user_id)
select id
from public.users_profile
on conflict (user_id) do nothing;

-- ---------------------------------------------------------------------------
-- Auth lifecycle functions
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users_profile (id, email)
  values (new.id, coalesce(new.email, ''))
  on conflict (id) do nothing;

  insert into public.notification_preferences (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  delete from auth.users
  where id = auth.uid();
end;
$$;

-- ---------------------------------------------------------------------------
-- Notification pipeline helpers
-- ---------------------------------------------------------------------------
create or replace function public.notification_category_enabled(
  p_user_id uuid,
  p_category text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  prefs public.notification_preferences%rowtype;
begin
  select *
  into prefs
  from public.notification_preferences
  where user_id = p_user_id;

  if not found then
    return true;
  end if;

  case p_category
    when 'milestones' then
      return prefs.milestones_enabled;
    when 'readiness' then
      return prefs.readiness_enabled;
    when 'activity' then
      return prefs.activity_enabled;
    else
      return true;
  end case;
end;
$$;

create or replace function public.create_system_notification(
  p_user_id uuid,
  p_category text,
  p_title text,
  p_body text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.notification_category_enabled(p_user_id, p_category) then
    return;
  end if;

  insert into public.notifications (user_id, title, body)
  values (p_user_id, p_title, p_body);
end;
$$;

create or replace function public.run_notification_pipeline_probe()
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  probe_id uuid;
  probe_title text;
  probe_body text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if not public.notification_category_enabled(auth.uid(), 'readiness') then
    return jsonb_build_object(
      'status', 'skipped',
      'message', 'Readiness notifications are disabled for this account.'
    );
  end if;

  probe_title := 'Notification pipeline probe';
  probe_body := format(
    'Server-side probe succeeded at %s UTC.',
    to_char(timezone('utc', now()), 'YYYY-MM-DD HH24:MI:SS')
  );

  insert into public.notifications (user_id, title, body)
  values (auth.uid(), probe_title, probe_body)
  returning id into probe_id;

  return jsonb_build_object(
    'status', 'created',
    'notification_id', probe_id,
    'message', 'Probe notification created through the database pipeline.'
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Notification trigger handlers
-- ---------------------------------------------------------------------------
create or replace function public.handle_onboarding_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.onboarding_complete is true
     and coalesce(old.onboarding_complete, false) is false then
    perform public.create_system_notification(
      new.id,
      'milestones',
      'Welcome to SquaredAway',
      'Your onboarding is complete. Your dashboard and readiness tools are now unlocked.'
    );
  end if;

  return new;
end;
$$;

create or replace function public.handle_promotion_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_user_id uuid;
  title text;
  body text;
begin
  if tg_op = 'DELETE' then
    target_user_id := old.user_id;
    title := 'Promotion tracker deleted';
    body := 'Your saved promotion readiness data was removed.';
  elsif tg_op = 'INSERT' then
    target_user_id := new.user_id;
    title := 'Promotion tracker created';
    body := format(
      'Targeting %s with %s of %s points logged.',
      new.target_rank,
      new.points_current,
      new.points_required
    );
  else
    target_user_id := new.user_id;
    title := 'Promotion tracker updated';
    body := format(
      'Targeting %s with %s of %s points logged.',
      new.target_rank,
      new.points_current,
      new.points_required
    );
  end if;

  perform public.create_system_notification(target_user_id, 'readiness', title, body);

  return coalesce(new, old);
end;
$$;

create or replace function public.handle_pay_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_user_id uuid;
  title text;
  body text;
  total numeric(10, 2);
begin
  if tg_op = 'DELETE' then
    target_user_id := old.user_id;
    title := 'Pay details deleted';
    body := 'Your saved pay snapshot was removed.';
  else
    target_user_id := new.user_id;
    total := coalesce(new.base_pay, 0) + coalesce(new.bah, 0) + coalesce(new.bas, 0);
    title := case when tg_op = 'INSERT' then 'Pay details saved' else 'Pay details updated' end;
    body := format(
      '%s compensation updated. Estimated monthly total: $%s.',
      new.pay_grade,
      to_char(total, 'FM999999990.00')
    );
  end if;

  perform public.create_system_notification(target_user_id, 'readiness', title, body);

  return coalesce(new, old);
end;
$$;

create or replace function public.handle_fitness_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_user_id uuid;
  title text;
  body text;
  duration_minutes integer;
  formatted_score text;
begin
  if tg_op = 'DELETE' then
    target_user_id := old.user_id;
    title := 'Workout deleted';
    body := 'A workout entry was removed from your fitness log.';
  else
    target_user_id := new.user_id;
    duration_minutes := greatest(coalesce(new.duration, 0) / 60, 0);
    formatted_score := case
      when new.score is null then null
      when trunc(new.score) = new.score then trunc(new.score)::text
      else to_char(new.score, 'FM999999990.0')
    end;
    title := case
      when tg_op = 'INSERT' then 'Workout logged'
      else 'Workout updated'
    end;
    body := case
      when formatted_score is null then
        format('%s for %s min.', new.exercise_type, duration_minutes)
      else
        format('%s for %s min. Score: %s.', new.exercise_type, duration_minutes, formatted_score)
    end;
  end if;

  perform public.create_system_notification(target_user_id, 'activity', title, body);

  return coalesce(new, old);
end;
$$;

create or replace function public.handle_nutrition_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_user_id uuid;
  title text;
  body text;
begin
  if tg_op = 'DELETE' then
    target_user_id := old.user_id;
    title := 'Chow entry deleted';
    body := 'A chow entry was removed from your log.';
  else
    target_user_id := new.user_id;
    title := case
      when tg_op = 'INSERT' then 'Chow entry logged'
      else 'Chow entry updated'
    end;
    body := format(
      '%s: %s cal, %sg protein, %sg carbs, %sg fat.',
      new.meal_type,
      new.calories,
      trim(to_char(new.protein, 'FM999999990.0')),
      trim(to_char(new.carbs, 'FM999999990.0')),
      trim(to_char(new.fat, 'FM999999990.0'))
    );
  end if;

  perform public.create_system_notification(target_user_id, 'activity', title, body);

  return coalesce(new, old);
end;
$$;

create or replace function public.handle_tracker_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_user_id uuid;
  title text;
  body text;
begin
  if tg_op = 'DELETE' then
    target_user_id := old.user_id;
    title := 'Tracker deleted';
    body := 'Your assignment tracker snapshot was removed.';
  else
    target_user_id := new.user_id;
    title := case
      when tg_op = 'INSERT' then 'Tracker saved'
      else 'Tracker updated'
    end;
    body := format(
      '%s status at %s. Next milestone: %s.',
      coalesce(nullif(new.duty_status, ''), 'Status TBD'),
      coalesce(nullif(new.current_duty_station, ''), 'current assignment'),
      coalesce(nullif(new.next_milestone, ''), 'not set')
    );
  end if;

  perform public.create_system_notification(target_user_id, 'readiness', title, body);

  return coalesce(new, old);
end;
$$;

create or replace function public.handle_pcs_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_user_id uuid;
  title text;
  body text;
  checklist_count integer;
begin
  if tg_op = 'DELETE' then
    target_user_id := old.user_id;
    title := 'PCS plan deleted';
    body := 'Your PCS planning snapshot was removed.';
  else
    target_user_id := new.user_id;
    checklist_count := (
      case when new.shipment_booked then 1 else 0 end +
      case when new.lodging_secured then 1 else 0 end +
      case when new.travel_booked then 1 else 0 end
    );
    title := case
      when tg_op = 'INSERT' then 'PCS plan saved'
      else 'PCS plan updated'
    end;
    body := format(
      '%s to %s. %s of 3 move tasks complete.',
      coalesce(nullif(new.origin_location, ''), 'Origin TBD'),
      coalesce(nullif(new.destination_location, ''), 'destination TBD'),
      checklist_count
    );
  end if;

  perform public.create_system_notification(target_user_id, 'readiness', title, body);

  return coalesce(new, old);
end;
$$;

create or replace function public.handle_benefits_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_user_id uuid;
  title text;
  body text;
  completed_count integer;
begin
  if tg_op = 'DELETE' then
    target_user_id := old.user_id;
    title := 'Benefits snapshot deleted';
    body := 'Your benefits readiness snapshot was removed.';
  else
    target_user_id := new.user_id;
    completed_count := (
      case when new.va_health_enrolled then 1 else 0 end +
      case when new.gi_bill_ready then 1 else 0 end +
      case when new.tsp_contributing then 1 else 0 end +
      case when new.family_support_plan then 1 else 0 end
    );
    title := case
      when tg_op = 'INSERT' then 'Benefits snapshot saved'
      else 'Benefits snapshot updated'
    end;
    body := format(
      '%s of 4 tracked benefits are marked ready.',
      completed_count
    );
  end if;

  perform public.create_system_notification(target_user_id, 'readiness', title, body);

  return coalesce(new, old);
end;
$$;

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Updated-at triggers
drop trigger if exists set_users_profile_updated_at on public.users_profile;
create trigger set_users_profile_updated_at
before update on public.users_profile
for each row execute function public.set_updated_at();

drop trigger if exists set_promotions_data_updated_at on public.promotions_data;
create trigger set_promotions_data_updated_at
before update on public.promotions_data
for each row execute function public.set_updated_at();

drop trigger if exists set_pay_data_updated_at on public.pay_data;
create trigger set_pay_data_updated_at
before update on public.pay_data
for each row execute function public.set_updated_at();

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

drop trigger if exists set_notification_preferences_updated_at on public.notification_preferences;
create trigger set_notification_preferences_updated_at
before update on public.notification_preferences
for each row execute function public.set_updated_at();

-- Notification triggers
drop trigger if exists notify_onboarding_complete on public.users_profile;
create trigger notify_onboarding_complete
after update on public.users_profile
for each row execute function public.handle_onboarding_notification();

drop trigger if exists notify_promotion_changes on public.promotions_data;
create trigger notify_promotion_changes
after insert or update or delete on public.promotions_data
for each row execute function public.handle_promotion_notification();

drop trigger if exists notify_pay_changes on public.pay_data;
create trigger notify_pay_changes
after insert or update or delete on public.pay_data
for each row execute function public.handle_pay_notification();

drop trigger if exists notify_fitness_changes on public.fitness_logs;
create trigger notify_fitness_changes
after insert or update or delete on public.fitness_logs
for each row execute function public.handle_fitness_notification();

drop trigger if exists notify_nutrition_changes on public.nutrition_logs;
create trigger notify_nutrition_changes
after insert or update or delete on public.nutrition_logs
for each row execute function public.handle_nutrition_notification();

drop trigger if exists notify_tracker_changes on public.tracker_data;
create trigger notify_tracker_changes
after insert or update or delete on public.tracker_data
for each row execute function public.handle_tracker_notification();

drop trigger if exists notify_pcs_changes on public.pcs_data;
create trigger notify_pcs_changes
after insert or update or delete on public.pcs_data
for each row execute function public.handle_pcs_notification();

drop trigger if exists notify_benefits_changes on public.benefits_data;
create trigger notify_benefits_changes
after insert or update or delete on public.benefits_data
for each row execute function public.handle_benefits_notification();

-- ---------------------------------------------------------------------------
-- Function execution grants
-- ---------------------------------------------------------------------------
revoke all on function public.delete_my_account() from public;
grant execute on function public.delete_my_account() to authenticated;
revoke all on function public.run_notification_pipeline_probe() from public;
grant execute on function public.run_notification_pipeline_probe() to authenticated;

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------
alter table public.users_profile enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.fitness_logs enable row level security;
alter table public.nutrition_logs enable row level security;
alter table public.promotions_data enable row level security;
alter table public.pay_data enable row level security;
alter table public.tracker_data enable row level security;
alter table public.pcs_data enable row level security;
alter table public.benefits_data enable row level security;
alter table public.notifications enable row level security;

-- Profile policies
drop policy if exists "Users can view own profile" on public.users_profile;
create policy "Users can view own profile"
on public.users_profile
for select
using (auth.uid() = id);

drop policy if exists "Users can insert own profile" on public.users_profile;
create policy "Users can insert own profile"
on public.users_profile
for insert
with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.users_profile;
create policy "Users can update own profile"
on public.users_profile
for update
using (auth.uid() = id)
with check (auth.uid() = id);

-- Notification preference policies
drop policy if exists "Users manage own notification preferences" on public.notification_preferences;
create policy "Users manage own notification preferences"
on public.notification_preferences
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Feature data policies
drop policy if exists "Users manage own fitness logs" on public.fitness_logs;
create policy "Users manage own fitness logs"
on public.fitness_logs
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users manage own nutrition logs" on public.nutrition_logs;
create policy "Users manage own nutrition logs"
on public.nutrition_logs
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users manage own promotion data" on public.promotions_data;
create policy "Users manage own promotion data"
on public.promotions_data
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users manage own pay data" on public.pay_data;
create policy "Users manage own pay data"
on public.pay_data
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

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

-- Notification policies
drop policy if exists "Users manage own notifications" on public.notifications;
create policy "Users manage own notifications"
on public.notifications
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Storage buckets
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('attachments', 'attachments', false)
on conflict (id) do nothing;

-- Avatar storage policies
drop policy if exists "Avatar images are publicly readable" on storage.objects;
create policy "Avatar images are publicly readable"
on storage.objects
for select
using (bucket_id = 'avatars');

drop policy if exists "Users can upload own avatar" on storage.objects;
create policy "Users can upload own avatar"
on storage.objects
for insert
with check (
  bucket_id = 'avatars'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "Users can update own avatar" on storage.objects;
create policy "Users can update own avatar"
on storage.objects
for update
using (
  bucket_id = 'avatars'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "Users can delete own avatar" on storage.objects;
create policy "Users can delete own avatar"
on storage.objects
for delete
using (
  bucket_id = 'avatars'
  and auth.uid()::text = (storage.foldername(name))[1]
);

-- Attachment storage policies
drop policy if exists "Users manage own attachments" on storage.objects;
create policy "Users manage own attachments"
on storage.objects
for all
using (
  bucket_id = 'attachments'
  and auth.uid()::text = (storage.foldername(name))[1]
)
with check (
  bucket_id = 'attachments'
  and auth.uid()::text = (storage.foldername(name))[1]
);
