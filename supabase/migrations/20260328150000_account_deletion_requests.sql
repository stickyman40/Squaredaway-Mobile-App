create table if not exists public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token_hash text not null unique,
  expires_at timestamptz not null,
  consumed_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists account_deletion_requests_user_id_idx
  on public.account_deletion_requests (user_id);

create index if not exists account_deletion_requests_expires_at_idx
  on public.account_deletion_requests (expires_at);

alter table public.account_deletion_requests enable row level security;

drop policy if exists "Service role manages account deletion requests" on public.account_deletion_requests;

create policy "Service role manages account deletion requests"
on public.account_deletion_requests
for all
using (auth.role() = 'service_role')
with check (auth.role() = 'service_role');
