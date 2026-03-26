alter table public.notifications
add column if not exists type text;

update public.notifications
set type = 'readiness'
where type is null;

alter table public.notifications
alter column type set default 'readiness';

alter table public.notifications
alter column type set not null;

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
