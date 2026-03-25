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
