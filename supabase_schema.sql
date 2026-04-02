-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
create extension if not exists pgcrypto;
create extension if not exists pg_trgm;

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

create or replace function public.enforce_branch_lock()
returns trigger
language plpgsql
as $$
begin
  if old.branch_locked = true and new.branch is distinct from old.branch then
    raise exception 'Branch is permanently locked for this account. Create a new account to change branches. (error: branch_immutable)';
  end if;

  if new.onboarding_complete = true and coalesce(old.onboarding_complete, false) = false then
    new.branch_locked = true;
  end if;

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
  branch_locked boolean not null default false,
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
alter table public.users_profile add column if not exists branch_locked boolean not null default false;

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
  branch text,
  current_rank text not null,
  target_rank text not null,
  points_current integer not null default 0,
  points_required integer not null default 0,
  board_date timestamptz,
  notes text,
  updated_at timestamptz not null default timezone('utc', now()),
  army_mil_ed_points integer,
  army_civ_ed_points integer,
  army_awards_points integer,
  army_mil_trg_points integer,
  army_aft_points integer,
  army_weapons_points integer,
  army_current_cutoff integer,
  army_mos text,
  waps_skt_score integer,
  waps_pfe_score integer,
  waps_epr_score integer,
  waps_decorations_points integer,
  waps_tis_points integer,
  waps_tig_points integer,
  waps_afadcons_points integer,
  waps_cutoff_score integer,
  navy_pma_score double precision,
  navy_exam_score integer,
  navy_awards_points integer,
  navy_sipg_points double precision,
  navy_pna_points double precision,
  navy_cycle_exam_date timestamptz,
  marine_pro_mark double precision,
  marine_con_mark double precision,
  marine_pft_score integer,
  marine_cft_score integer,
  marine_rifle_score integer,
  marine_mci_points integer,
  marine_cutting_score integer,
  cg_swe_score integer,
  cg_perf_factor double precision,
  cg_final_exam_score double precision,
  cg_advancement_cut integer,
  next_board_date timestamptz,
  board_cycle_year integer
);

alter table public.promotions_data add column if not exists branch text;
alter table public.promotions_data add column if not exists army_mil_ed_points integer;
alter table public.promotions_data add column if not exists army_civ_ed_points integer;
alter table public.promotions_data add column if not exists army_awards_points integer;
alter table public.promotions_data add column if not exists army_mil_trg_points integer;
alter table public.promotions_data add column if not exists army_aft_points integer;
alter table public.promotions_data add column if not exists army_weapons_points integer;
alter table public.promotions_data add column if not exists army_current_cutoff integer;
alter table public.promotions_data add column if not exists army_mos text;
alter table public.promotions_data add column if not exists waps_skt_score integer;
alter table public.promotions_data add column if not exists waps_pfe_score integer;
alter table public.promotions_data add column if not exists waps_epr_score integer;
alter table public.promotions_data add column if not exists waps_decorations_points integer;
alter table public.promotions_data add column if not exists waps_tis_points integer;
alter table public.promotions_data add column if not exists waps_tig_points integer;
alter table public.promotions_data add column if not exists waps_afadcons_points integer;
alter table public.promotions_data add column if not exists waps_cutoff_score integer;
alter table public.promotions_data add column if not exists navy_pma_score double precision;
alter table public.promotions_data add column if not exists navy_exam_score integer;
alter table public.promotions_data add column if not exists navy_awards_points integer;
alter table public.promotions_data add column if not exists navy_sipg_points double precision;
alter table public.promotions_data add column if not exists navy_pna_points double precision;
alter table public.promotions_data add column if not exists navy_cycle_exam_date timestamptz;
alter table public.promotions_data add column if not exists marine_pro_mark double precision;
alter table public.promotions_data add column if not exists marine_con_mark double precision;
alter table public.promotions_data add column if not exists marine_pft_score integer;
alter table public.promotions_data add column if not exists marine_cft_score integer;
alter table public.promotions_data add column if not exists marine_rifle_score integer;
alter table public.promotions_data add column if not exists marine_mci_points integer;
alter table public.promotions_data add column if not exists marine_cutting_score integer;
alter table public.promotions_data add column if not exists cg_swe_score integer;
alter table public.promotions_data add column if not exists cg_perf_factor double precision;
alter table public.promotions_data add column if not exists cg_final_exam_score double precision;
alter table public.promotions_data add column if not exists cg_advancement_cut integer;
alter table public.promotions_data add column if not exists next_board_date timestamptz;
alter table public.promotions_data add column if not exists board_cycle_year integer;

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

create table if not exists public.fuel_products (
  id uuid primary key default gen_random_uuid(),
  barcode text not null unique,
  name text not null,
  brand text,
  image_url text,
  category text not null default 'Other',
  serving_size text not null default '1 serving',
  serving_size_g numeric(8, 2),
  nutrition jsonb not null,
  flags jsonb not null default '[]'::jsonb,
  ingredients_text text,
  data_source text not null default 'openfoodfacts',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.fuel_product_scores (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.fuel_products(id) on delete cascade,
  overall integer not null check (overall between 0 and 100),
  fat_loss integer check (fat_loss between 0 and 100),
  muscle_gain integer check (muscle_gain between 0 and 100),
  performance integer check (performance between 0 and 100),
  convenience integer check (convenience between 0 and 100),
  fuel_rating text not null check (fuel_rating in ('green', 'yellow', 'orange', 'red')),
  primary_reason text,
  factors jsonb not null default '[]'::jsonb,
  goal_guidance jsonb not null default '[]'::jsonb,
  computed_at timestamptz not null default timezone('utc', now()),
  unique (product_id)
);

create table if not exists public.chow_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  meal_type text not null check (meal_type in ('Breakfast', 'Lunch', 'Dinner', 'Snack')),
  servings numeric(5, 2) not null default 1.0 check (servings > 0),
  source text not null check (source in ('scan', 'manual', 'favorite', 'recent', 'quick_add')),
  product_id uuid references public.fuel_products(id) on delete set null,
  manual_name text,
  manual_calories numeric(8, 2),
  manual_protein_g numeric(6, 2),
  manual_carbs_g numeric(6, 2),
  manual_fat_g numeric(6, 2),
  notes text,
  log_date date not null,
  logged_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint chow_entries_has_data check (
    product_id is not null or manual_name is not null
  )
);

create table if not exists public.fuel_scans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  barcode text not null,
  product_id uuid references public.fuel_products(id) on delete set null,
  was_logged boolean not null default false,
  chow_entry_id uuid references public.chow_entries(id) on delete set null,
  scanned_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.fuel_saved (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  product_id uuid not null references public.fuel_products(id) on delete cascade,
  saved_at timestamptz not null default timezone('utc', now()),
  unique (user_id, product_id)
);

create table if not exists public.user_nutrition_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  calorie_target integer not null default 2200 check (calorie_target > 0),
  protein_target integer not null default 150 check (protein_target >= 0),
  carb_target integer not null default 220 check (carb_target >= 0),
  fat_target integer not null default 70 check (fat_target >= 0),
  primary_goal text not null default 'maintenance'
    check (primary_goal in ('fat_loss', 'muscle_gain', 'maintenance', 'performance', 'high_protein', 'field_convenience')),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (user_id)
);

drop trigger if exists trg_fuel_products_updated_at on public.fuel_products;
create trigger trg_fuel_products_updated_at
before update on public.fuel_products
for each row execute function public.set_updated_at();

drop trigger if exists trg_chow_entries_updated_at on public.chow_entries;
create trigger trg_chow_entries_updated_at
before update on public.chow_entries
for each row execute function public.set_updated_at();

drop trigger if exists trg_user_nutrition_goals_updated_at on public.user_nutrition_goals;
create trigger trg_user_nutrition_goals_updated_at
before update on public.user_nutrition_goals
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Notification tables
-- ---------------------------------------------------------------------------
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  type text not null default 'readiness',
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
create index if not exists idx_fuel_products_barcode on public.fuel_products (barcode);
create index if not exists idx_fuel_products_name on public.fuel_products using gin (name gin_trgm_ops);
create index if not exists idx_fuel_products_category on public.fuel_products (category);
create index if not exists idx_fuel_scores_product_id on public.fuel_product_scores (product_id);
create index if not exists idx_fuel_scores_rating on public.fuel_product_scores (fuel_rating);
create index if not exists idx_fuel_scores_overall on public.fuel_product_scores (overall desc);
create index if not exists idx_chow_entries_user_date on public.chow_entries (user_id, log_date desc);
create index if not exists idx_chow_entries_product_id on public.chow_entries (product_id);
create index if not exists idx_chow_entries_source on public.chow_entries (source);
create index if not exists idx_fuel_scans_user_scanned_at on public.fuel_scans (user_id, scanned_at desc);
create index if not exists idx_fuel_scans_barcode on public.fuel_scans (barcode);
create index if not exists idx_fuel_saved_user_id on public.fuel_saved (user_id);
create index if not exists idx_user_nutrition_goals_user_id on public.user_nutrition_goals (user_id);
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

  insert into public.notifications (user_id, type, title, body)
  values (p_user_id, p_category, p_title, p_body);
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

  insert into public.notifications (user_id, type, title, body)
  values (auth.uid(), 'readiness', probe_title, probe_body)
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

drop trigger if exists enforce_users_profile_branch_lock on public.users_profile;
create trigger enforce_users_profile_branch_lock
before update on public.users_profile
for each row execute function public.enforce_branch_lock();

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
alter table public.fuel_products enable row level security;
alter table public.fuel_product_scores enable row level security;
alter table public.chow_entries enable row level security;
alter table public.fuel_scans enable row level security;
alter table public.fuel_saved enable row level security;
alter table public.user_nutrition_goals enable row level security;
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

drop policy if exists "Fuel products are publicly readable" on public.fuel_products;
create policy "Fuel products are publicly readable"
on public.fuel_products
for select
using (true);

drop policy if exists "Fuel product scores are publicly readable" on public.fuel_product_scores;
create policy "Fuel product scores are publicly readable"
on public.fuel_product_scores
for select
using (true);

drop policy if exists "Users manage own chow entries" on public.chow_entries;
create policy "Users manage own chow entries"
on public.chow_entries
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users manage own fuel scans" on public.fuel_scans;
create policy "Users manage own fuel scans"
on public.fuel_scans
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users manage own saved fuel products" on public.fuel_saved;
create policy "Users manage own saved fuel products"
on public.fuel_saved
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users manage own nutrition goals" on public.user_nutrition_goals;
create policy "Users manage own nutrition goals"
on public.user_nutrition_goals
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

-- ---------------------------------------------------------------------------
-- PT / Fitness module
-- ---------------------------------------------------------------------------
create table if not exists public.fitness_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  height_cm numeric(6, 2) not null,
  weight_kg numeric(6, 2) not null,
  goal_weight_kg numeric(6, 2),
  fitness_goal text not null default 'improve_pt_score'
    check (fitness_goal in ('lose_fat', 'build_muscle', 'maintain', 'improve_pt_score')),
  experience_level text not null default 'intermediate'
    check (experience_level in ('beginner', 'intermediate', 'advanced')),
  workout_split text not null default 'upper_lower'
    check (workout_split in ('push_pull_legs', 'upper_lower', 'full_body', 'bro_split', 'hybrid_performance', 'tactical_readiness', 'custom')),
  daily_calorie_target integer,
  weekly_workout_target integer not null default 4
    check (weekly_workout_target between 1 and 7),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (user_id)
);

create table if not exists public.weight_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  weight_kg numeric(6, 2) not null,
  notes text,
  logged_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.workout_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  workout_type text not null,
  split_day text,
  duration_seconds integer not null default 0,
  calories_burned integer,
  notes text,
  logged_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.pt_scores (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  branch text not null,
  test_name text not null,
  event_scores jsonb not null default '{}'::jsonb,
  total_score integer not null default 0,
  passed boolean not null default false,
  tier_name text,
  notes text,
  recorded_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.activity_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  steps integer not null default 0,
  active_calories numeric(8, 2) not null default 0,
  active_minutes integer not null default 0,
  heart_rate_avg numeric(5, 1),
  source text not null default 'manual'
    check (source in ('healthkit', 'manual')),
  log_date date not null,
  created_at timestamptz not null default timezone('utc', now()),
  unique (user_id, log_date)
);

create table if not exists public.ai_recommendations_cache (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  recommendations jsonb not null default '[]'::jsonb,
  generated_at timestamptz not null default timezone('utc', now()),
  expires_at timestamptz not null default timezone('utc', now()) + interval '24 hours',
  unique (user_id)
);

create index if not exists idx_fitness_profiles_user_id on public.fitness_profiles (user_id);
create index if not exists idx_weight_logs_user_id on public.weight_logs (user_id);
create index if not exists idx_weight_logs_logged_at on public.weight_logs (logged_at desc);
create index if not exists idx_workout_logs_user_id on public.workout_logs (user_id);
create index if not exists idx_workout_logs_logged_at on public.workout_logs (logged_at desc);
create index if not exists idx_pt_scores_user_id on public.pt_scores (user_id);
create index if not exists idx_pt_scores_recorded_at on public.pt_scores (recorded_at desc);
create index if not exists idx_pt_scores_branch on public.pt_scores (branch);
create index if not exists idx_activity_logs_user_id on public.activity_logs (user_id);
create index if not exists idx_activity_logs_log_date on public.activity_logs (log_date desc);
create index if not exists idx_ai_recommendations_cache_user_id on public.ai_recommendations_cache (user_id);

drop trigger if exists trg_fitness_profiles_updated_at on public.fitness_profiles;
create trigger trg_fitness_profiles_updated_at
before update on public.fitness_profiles
for each row execute function public.set_updated_at();

alter table public.fitness_profiles enable row level security;
alter table public.weight_logs enable row level security;
alter table public.workout_logs enable row level security;
alter table public.pt_scores enable row level security;
alter table public.activity_logs enable row level security;
alter table public.ai_recommendations_cache enable row level security;

drop policy if exists "Users manage own fitness profile" on public.fitness_profiles;
create policy "Users manage own fitness profile"
on public.fitness_profiles
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users manage own weight logs" on public.weight_logs;
create policy "Users manage own weight logs"
on public.weight_logs
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users manage own workout logs" on public.workout_logs;
create policy "Users manage own workout logs"
on public.workout_logs
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users manage own PT scores" on public.pt_scores;
create policy "Users manage own PT scores"
on public.pt_scores
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users manage own activity logs" on public.activity_logs;
create policy "Users manage own activity logs"
on public.activity_logs
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users read own recommendations" on public.ai_recommendations_cache;
create policy "Users read own recommendations"
on public.ai_recommendations_cache
for select
using (auth.uid() = user_id);

drop policy if exists "Service role manages recommendations" on public.ai_recommendations_cache;
create policy "Service role manages recommendations"
on public.ai_recommendations_cache
for all
using (auth.role() = 'service_role')
with check (auth.role() = 'service_role');

create or replace view public.pt_score_trends as
select
  p.user_id,
  u.branch,
  p.test_name,
  p.total_score,
  p.passed,
  p.tier_name,
  p.recorded_at,
  lag(p.total_score) over (partition by p.user_id order by p.recorded_at) as prev_score,
  p.total_score - lag(p.total_score) over (partition by p.user_id order by p.recorded_at) as score_delta
from public.pt_scores p
join public.users_profile u on u.id = p.user_id
order by p.user_id, p.recorded_at desc;

create or replace view public.workout_frequency as
select
  user_id,
  count(*) as total_workouts,
  count(distinct date(logged_at)) as active_days,
  round(avg(duration_seconds)::numeric / 60, 1) as avg_duration_mins,
  round(avg(coalesce(calories_burned, 0))::numeric, 0) as avg_calories
from public.workout_logs
where logged_at >= now() - interval '30 days'
group by user_id;

create or replace view public.weight_trends as
select
  user_id,
  min(weight_kg) as min_weight,
  max(weight_kg) as max_weight,
  first_value(weight_kg) over (partition by user_id order by logged_at desc) as latest_weight,
  last_value(weight_kg) over (
    partition by user_id
    order by logged_at desc
    rows between unbounded preceding and unbounded following
  ) as earliest_weight
from public.weight_logs
where logged_at >= now() - interval '60 days'
group by user_id, weight_kg, logged_at;
