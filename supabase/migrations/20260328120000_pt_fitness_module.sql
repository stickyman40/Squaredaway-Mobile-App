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
    check (workout_split in ('push_pull_legs', 'upper_lower', 'full_body', 'custom')),
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
