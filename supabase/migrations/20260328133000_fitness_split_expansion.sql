alter table public.fitness_profiles
drop constraint if exists fitness_profiles_workout_split_check;

alter table public.fitness_profiles
add constraint fitness_profiles_workout_split_check
check (
  workout_split in (
    'push_pull_legs',
    'upper_lower',
    'full_body',
    'bro_split',
    'hybrid_performance',
    'tactical_readiness',
    'custom'
  )
);
