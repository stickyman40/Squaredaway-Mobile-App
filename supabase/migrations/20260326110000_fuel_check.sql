create extension if not exists pg_trgm;

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

alter table public.fuel_products enable row level security;
alter table public.fuel_product_scores enable row level security;
alter table public.chow_entries enable row level security;
alter table public.fuel_scans enable row level security;
alter table public.fuel_saved enable row level security;
alter table public.user_nutrition_goals enable row level security;

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
