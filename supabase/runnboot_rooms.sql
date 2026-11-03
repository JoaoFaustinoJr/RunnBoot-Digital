-- RunnBoot Digital: isolated room storage in the existing Tangram X1 Supabase project
-- Run once in Supabase SQL Editor after the database connection is restored.
create table if not exists public.runnboot_rooms (
  code text primary key check (code ~ '^[A-HJ-NP-Z2-9]{6}$'),
  host_token uuid not null default gen_random_uuid(),
  game_state jsonb not null default '{}'::jsonb,
  revision bigint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '7 days')
);
alter table public.runnboot_rooms enable row level security;
revoke all on public.runnboot_rooms from anon, authenticated;
-- The public client can only use these restricted RPC functions.
create or replace function public.runnboot_create_room(p_code text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v public.runnboot_rooms;
begin
  if p_code !~ '^[A-HJ-NP-Z2-9]{6}$' then raise exception 'Invalid room code'; end if;
  insert into public.runnboot_rooms(code) values (p_code) returning * into v;
  return jsonb_build_object('code',v.code,'host_token',v.host_token,'revision',v.revision);
end $$;
create or replace function public.runnboot_read_room(p_code text)
returns jsonb language sql security definer set search_path = '' as $$
  select jsonb_build_object('code',code,'state',game_state,'revision',revision,'updated_at',updated_at)
  from public.runnboot_rooms where code=p_code and expires_at>now();
$$;
create or replace function public.runnboot_update_room(p_code text,p_host_token uuid,p_state jsonb,p_revision bigint)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v public.runnboot_rooms;
begin
  if pg_column_size(p_state)>150000 then raise exception 'State too large'; end if;
  update public.runnboot_rooms
  set game_state=p_state, revision=revision+1,updated_at=now()
  where code=p_code and host_token=p_host_token and revision=p_revision and expires_at>now()
  returning * into v;
  if not found then raise exception 'Room unavailable, unauthorized, or stale revision'; end if;
  return jsonb_build_object('code',v.code,'revision',v.revision);
end $$;
revoke all on function public.runnboot_create_room(text) from public;
revoke all on function public.runnboot_read_room(text) from public;
revoke all on function public.runnboot_update_room(text,uuid,jsonb,bigint) from public;
grant execute on function public.runnboot_create_room(text) to anon,authenticated;
grant execute on function public.runnboot_read_room(text) to anon,authenticated;
grant execute on function public.runnboot_update_room(text,uuid,jsonb,bigint) to anon,authenticated;
