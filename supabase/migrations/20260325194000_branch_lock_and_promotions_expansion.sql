alter table public.users_profile
  add column if not exists branch_locked boolean not null default false;

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

drop trigger if exists enforce_users_profile_branch_lock on public.users_profile;
create trigger enforce_users_profile_branch_lock
before update on public.users_profile
for each row execute function public.enforce_branch_lock();

alter table public.promotions_data add column if not exists branch text;
alter table public.promotions_data add column if not exists army_mil_ed_points integer check (army_mil_ed_points between 0 and 220);
alter table public.promotions_data add column if not exists army_civ_ed_points integer check (army_civ_ed_points between 0 and 100);
alter table public.promotions_data add column if not exists army_awards_points integer check (army_awards_points between 0 and 125);
alter table public.promotions_data add column if not exists army_mil_trg_points integer check (army_mil_trg_points between 0 and 100);
alter table public.promotions_data add column if not exists army_acft_points integer check (army_acft_points in (0, 30, 40, 45, 50, 55, 60));
alter table public.promotions_data add column if not exists army_weapons_points integer check (army_weapons_points in (0, 10, 14, 20));
alter table public.promotions_data add column if not exists army_current_cutoff integer;
alter table public.promotions_data add column if not exists army_mos text;
alter table public.promotions_data add column if not exists waps_skt_score integer check (waps_skt_score between 0 and 100);
alter table public.promotions_data add column if not exists waps_pfe_score integer check (waps_pfe_score between 0 and 100);
alter table public.promotions_data add column if not exists waps_epr_score integer check (waps_epr_score between 0 and 135);
alter table public.promotions_data add column if not exists waps_decorations_points integer check (waps_decorations_points between 0 and 25);
alter table public.promotions_data add column if not exists waps_tis_points integer;
alter table public.promotions_data add column if not exists waps_tig_points integer;
alter table public.promotions_data add column if not exists waps_afadcons_points integer check (waps_afadcons_points between 0 and 25);
alter table public.promotions_data add column if not exists waps_cutoff_score integer;
alter table public.promotions_data add column if not exists navy_pma_score numeric(4,2) check (navy_pma_score between 1.0 and 5.0);
alter table public.promotions_data add column if not exists navy_exam_score integer check (navy_exam_score between 0 and 80);
alter table public.promotions_data add column if not exists navy_awards_points integer check (navy_awards_points between 0 and 25);
alter table public.promotions_data add column if not exists navy_sipg_points numeric(5,2);
alter table public.promotions_data add column if not exists navy_pna_points numeric(4,2) check (navy_pna_points between 0 and 1.5);
alter table public.promotions_data add column if not exists navy_cycle_exam_date timestamptz;
alter table public.promotions_data add column if not exists marine_pro_mark numeric(3,1) check (marine_pro_mark between 1.0 and 5.0);
alter table public.promotions_data add column if not exists marine_con_mark numeric(3,1) check (marine_con_mark between 1.0 and 5.0);
alter table public.promotions_data add column if not exists marine_pft_score integer check (marine_pft_score between 0 and 300);
alter table public.promotions_data add column if not exists marine_cft_score integer check (marine_cft_score between 0 and 300);
alter table public.promotions_data add column if not exists marine_rifle_score integer check (marine_rifle_score in (0, 3, 4, 5));
alter table public.promotions_data add column if not exists marine_mci_points integer;
alter table public.promotions_data add column if not exists marine_cutting_score integer;
alter table public.promotions_data add column if not exists cg_swe_score integer check (cg_swe_score between 0 and 100);
alter table public.promotions_data add column if not exists cg_perf_factor numeric(4,2) check (cg_perf_factor between 1.0 and 7.0);
alter table public.promotions_data add column if not exists cg_final_exam_score numeric(6,2);
alter table public.promotions_data add column if not exists cg_advancement_cut integer;
alter table public.promotions_data add column if not exists next_board_date timestamptz;
alter table public.promotions_data add column if not exists board_cycle_year integer;
