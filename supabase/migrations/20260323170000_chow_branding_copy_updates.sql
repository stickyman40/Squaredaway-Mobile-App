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
