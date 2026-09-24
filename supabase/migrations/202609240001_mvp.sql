-- Teman Mabar MVP. All client-facing private tables are default-deny.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to anon, authenticated;

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Pemain' check (char_length(trim(display_name)) between 1 and 60),
  avatar_url text check (avatar_url is null or char_length(avatar_url) <= 500),
  bio text check (bio is null or char_length(bio) <= 500),
  languages text[] not null default array['id']::text[],
  timezone text not null default 'Asia/Jakarta',
  voice_preference text not null default 'flexible' check (voice_preference in ('flexible','voice','text')),
  play_style text not null default 'casual' check (play_style in ('casual','competitive')),
  availability_status text not null default 'unavailable' check (availability_status in ('ready','unavailable')),
  visibility text not null default 'public' check (visibility in ('public','hidden')),
  account_status text not null default 'active' check (account_status in ('active','restricted','deletion_pending')),
  adult_declared_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.user_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'user' check (role in ('user','admin')),
  granted_by uuid references auth.users(id), granted_at timestamptz not null default now()
);
create table public.games (
  id uuid primary key default gen_random_uuid(), slug text not null unique check (slug ~ '^[a-z0-9-]{2,40}$'),
  name text not null check (char_length(name) between 2 and 80), active boolean not null default true
);
create table public.game_seasons (
  id uuid primary key default gen_random_uuid(), game_id uuid not null references public.games(id),
  code text not null, label text not null, active boolean not null default true,
  starts_at timestamptz, ends_at timestamptz, unique (game_id,code), unique(id,game_id),
  check (ends_at is null or starts_at is null or ends_at > starts_at)
);
create table public.game_catalog_options (
  id uuid primary key default gen_random_uuid(), game_id uuid not null references public.games(id),
  season_id uuid, kind text not null check (kind in ('rank','role','mode','region','server','map','hero','agent','perspective','team_size')),
  code text not null, label text not null, sort_order integer not null default 0, active boolean not null default true,
  rank_mode_option_id uuid references public.game_catalog_options(id),
  foreign key (season_id,game_id) references public.game_seasons(id,game_id),
  unique nulls not distinct (game_id,kind,season_id,code)
);
create table public.game_profiles (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(user_id) on delete cascade,
  game_id uuid not null references public.games(id), ign text not null check (char_length(trim(ign)) between 1 and 64),
  game_id_private text check (game_id_private is null or char_length(game_id_private) between 1 and 100),
  region_option_id uuid references public.game_catalog_options(id), server_option_id uuid references public.game_catalog_options(id),
  primary_rank_option_id uuid references public.game_catalog_options(id),
  primary_rank_mode_option_id uuid references public.game_catalog_options(id),
  primary_role_option_id uuid references public.game_catalog_options(id),
  play_goal text check (play_goal is null or char_length(play_goal) <= 120),
  availability_status text not null default 'ready' check (availability_status in ('ready','unavailable')),
  visibility text not null default 'public' check (visibility in ('public','hidden')),
  status text not null default 'active' check (status in ('active','hidden')),
  -- Non-indexed, non-sensitive game details only. Strict allowlist below.
  attributes jsonb not null default '{}'::jsonb,
  data_updated_at timestamptz not null default now(), created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(), unique (user_id,game_id)
);
create table public.game_profile_options (
  game_profile_id uuid not null references public.game_profiles(id) on delete cascade,
  option_id uuid not null references public.game_catalog_options(id),
  purpose text not null check (purpose in ('secondary_role','favorite_mode','favorite_map','favorite_hero','favorite_agent','secondary_rank')),
  rank_mode_option_id uuid references public.game_catalog_options(id),
  primary key (game_profile_id,option_id,purpose)
);
create table public.availability_slots (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(user_id) on delete cascade,
  day_of_week smallint not null check (day_of_week between 0 and 6),
  local_start time not null, local_end time not null, timezone text not null,
  check (local_start < local_end)
);
create table public.invites (
  id uuid primary key default gen_random_uuid(), sender_id uuid not null references public.profiles(user_id),
  recipient_id uuid not null references public.profiles(user_id), game_id uuid not null references public.games(id),
  message text check (message is null or char_length(message) <= 500),
  status text not null default 'pending' check (status in ('pending','accepted','rejected','cancelled','expired')),
  created_at timestamptz not null default now(), expires_at timestamptz not null default (now() + interval '7 days'),
  responded_at timestamptz, pair_low uuid generated always as (least(sender_id,recipient_id)) stored,
  pair_high uuid generated always as (greatest(sender_id,recipient_id)) stored,
  check (sender_id <> recipient_id)
);
create unique index invites_one_pending_pair on public.invites(pair_low,pair_high,game_id) where status='pending';
create index invites_recipient_idx on public.invites(recipient_id,status,created_at desc);
create table public.conversations (
  id uuid primary key default gen_random_uuid(), invite_id uuid not null unique references public.invites(id),
  participant_low uuid not null references public.profiles(user_id), participant_high uuid not null references public.profiles(user_id),
  status text not null default 'active' check (status in ('active','blocked','closed')),
  created_at timestamptz not null default now(), check (participant_low < participant_high)
);
create table public.messages (
  id uuid primary key default gen_random_uuid(), conversation_id uuid not null references public.conversations(id),
  sender_id uuid not null references public.profiles(user_id), body text not null check (char_length(trim(body)) between 1 and 2000),
  created_at timestamptz not null default now(), deleted_at timestamptz
);
create index messages_page_idx on public.messages(conversation_id,created_at desc,id desc);
create table public.game_id_shares (
  id uuid primary key default gen_random_uuid(), conversation_id uuid not null references public.conversations(id),
  owner_id uuid not null references public.profiles(user_id), game_profile_id uuid not null references public.game_profiles(id),
  shared_at timestamptz not null default now(), revoked_at timestamptz,
  unique(conversation_id,owner_id,game_profile_id)
);
create table public.blocks (
  blocker_id uuid not null references public.profiles(user_id), blocked_id uuid not null references public.profiles(user_id),
  created_at timestamptz not null default now(), primary key(blocker_id,blocked_id), check(blocker_id <> blocked_id)
);
create index blocks_reverse_idx on public.blocks(blocked_id,blocker_id);
create table public.reports (
  id uuid primary key default gen_random_uuid(), reporter_id uuid not null references public.profiles(user_id),
  reported_id uuid not null references public.profiles(user_id),
  category text not null check(category in ('harassment','spam','fraud','impersonation','inappropriate')),
  description text not null check(char_length(trim(description)) between 10 and 2000),
  target_type text not null check(target_type in ('profile','invite','message')),
  target_id uuid not null, evidence_path text,
  status text not null default 'new' check(status in ('new','reviewing','resolved','dismissed')),
  reviewed_by uuid references public.profiles(user_id), resolved_at timestamptz,
  created_at timestamptz not null default now(), check(reporter_id <> reported_id)
);
create table public.moderation_actions (
  id uuid primary key default gen_random_uuid(), admin_id uuid not null references public.profiles(user_id),
  subject_user_id uuid not null references public.profiles(user_id), report_id uuid references public.reports(id),
  action text not null check(action in ('hide_profile','restrict_account','restore_profile','restore_account')),
  reason text not null check(char_length(trim(reason)) between 10 and 1000), created_at timestamptz not null default now()
);
create table public.appeals (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(user_id),
  moderation_action_id uuid not null references public.moderation_actions(id),
  reason text not null check(char_length(trim(reason)) between 10 and 1000),
  status text not null default 'submitted' check(status in ('submitted','reviewing','resolved','rejected')),
  reviewed_by uuid references public.profiles(user_id), created_at timestamptz not null default now(), resolved_at timestamptz,
  unique(user_id,moderation_action_id)
);
create table public.notifications (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(user_id),
  kind text not null check(kind in ('invite_status','new_message','moderation')),
  reference_type text not null, reference_id uuid not null, read_at timestamptz,
  created_at timestamptz not null default now()
);
create index game_profiles_search_idx on public.game_profiles(game_id,data_updated_at desc,id) where status='active' and visibility='public';
create index game_profile_options_lookup_idx on public.game_profile_options(option_id,game_profile_id);
create index options_game_kind_idx on public.game_catalog_options(game_id,kind,code);

-- Auth trigger records the user's self-declaration at registration; metadata never confers role or independent age assurance.
create function private.on_auth_user() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  -- Self-declared 18+ is recorded once at registration, never as role authority.
  insert into public.profiles(user_id,adult_declared_at)
  values(new.id,case when new.raw_user_meta_data->>'adult_declared'='true' then now() else null end)
  on conflict do nothing;
  insert into public.user_roles(user_id) values(new.id) on conflict do nothing;
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function private.on_auth_user();

create function private.is_active(p_id uuid) returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.profiles p where p.user_id=p_id and p.account_status='active' and p.adult_declared_at is not null)
$$;
create function private.verified() returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from auth.users u where u.id=auth.uid() and u.email_confirmed_at is not null)
$$;
create function private.is_admin() returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.user_roles r join public.profiles p on p.user_id=r.user_id
    where r.user_id=auth.uid() and r.role='admin' and p.account_status='active')
$$;
create function private.blocked(p_a uuid,p_b uuid) returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.blocks b where (b.blocker_id=p_a and b.blocked_id=p_b)
    or (b.blocker_id=p_b and b.blocked_id=p_a))
$$;
create function private.chat_allowed(p_conversation uuid) returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.conversations c join public.invites i on i.id=c.invite_id
    where c.id=p_conversation and c.status='active' and i.status='accepted'
      and auth.uid() in (c.participant_low,c.participant_high)
      and private.is_active(c.participant_low) and private.is_active(c.participant_high)
      and not private.blocked(c.participant_low,c.participant_high))
$$;
-- Catalog references must belong to the same game and correct kind. Historical inactive options remain valid.
create function private.check_option(p_option uuid,p_game uuid,p_kind text) returns void language plpgsql security definer set search_path = '' as $$
begin
  if p_option is not null and not exists(select 1 from public.game_catalog_options o
    where o.id=p_option and o.game_id=p_game and o.kind=p_kind) then
    raise exception 'Opsi katalog tidak valid' using errcode='23514';
  end if;
end $$;
create function private.validate_game_profile() returns trigger language plpgsql security definer set search_path = '' as $$
declare v_slug text; v_keys text[];
begin
  if tg_op='UPDATE' and (new.user_id<>old.user_id or new.game_id<>old.game_id) then
    raise exception 'Pemilik/game tidak dapat diganti';
  end if;
  if tg_op='INSERT' or new.ign is distinct from old.ign or new.primary_rank_option_id is distinct from old.primary_rank_option_id then
    select slug into v_slug from public.games where id=new.game_id and active;
    if v_slug is null then raise exception 'Game tidak aktif'; end if;
  end if;
  perform private.check_option(new.region_option_id,new.game_id,'region');
  perform private.check_option(new.server_option_id,new.game_id,'server');
  perform private.check_option(new.primary_rank_option_id,new.game_id,'rank');
  perform private.check_option(new.primary_rank_mode_option_id,new.game_id,'mode');
  perform private.check_option(new.primary_role_option_id,new.game_id,'role');
  if new.primary_rank_option_id is not null and exists(
    select 1 from public.game_catalog_options o where o.id=new.primary_rank_option_id
    and o.rank_mode_option_id is distinct from new.primary_rank_mode_option_id) then
    raise exception 'Rank dan mode tidak cocok';
  end if;
  if jsonb_typeof(new.attributes)<>'object' or octet_length(new.attributes::text)>2048 then
    raise exception 'Atribut tidak valid';
  end if;
  select array_agg(key) into v_keys from jsonb_object_keys(new.attributes) key
    where key not in ('stars','tier','perspective','team_size','play_goal');
  if v_keys is not null then raise exception 'Atribut tidak diizinkan'; end if;
  new.updated_at=now();
  if tg_op='INSERT' or (new.ign,new.game_id_private,new.region_option_id,new.server_option_id,
      new.primary_rank_option_id,new.primary_rank_mode_option_id,new.primary_role_option_id,
      new.play_goal,new.availability_status,new.attributes) is distinct from
     (old.ign,old.game_id_private,old.region_option_id,old.server_option_id,
      old.primary_rank_option_id,old.primary_rank_mode_option_id,old.primary_role_option_id,
      old.play_goal,old.availability_status,old.attributes) then
    new.data_updated_at=now();
  else
    new.data_updated_at=old.data_updated_at;
  end if;
  return new;
end $$;
create trigger game_profile_validate before insert or update on public.game_profiles
  for each row execute function private.validate_game_profile();
create function private.validate_profile_option() returns trigger language plpgsql security definer set search_path = '' as $$
declare v_game uuid; v_kind text; v_mode uuid;
begin
  select game_id into v_game from public.game_profiles where id=new.game_profile_id;
  select kind,rank_mode_option_id into v_kind,v_mode from public.game_catalog_options
    where id=new.option_id and game_id=v_game;
  if v_kind is distinct from (case new.purpose when 'secondary_role' then 'role'
    when 'favorite_mode' then 'mode' when 'favorite_map' then 'map'
    when 'favorite_hero' then 'hero' when 'favorite_agent' then 'agent'
    when 'secondary_rank' then 'rank' end) then raise exception 'Jenis opsi tidak cocok'; end if;
  if new.purpose='secondary_rank' and v_mode is distinct from new.rank_mode_option_id then
    raise exception 'Mode rank tidak cocok';
  end if;
  return new;
end $$;
create trigger profile_option_validate before insert or update on public.game_profile_options
  for each row execute function private.validate_profile_option();

-- Default-deny + object grants: no SELECT on private columns except owner rows.
do $$ declare t text; begin
  foreach t in array array['profiles','user_roles','games','game_seasons','game_catalog_options','game_profiles',
    'game_profile_options','availability_slots','invites','conversations','messages','game_id_shares',
    'blocks','reports','moderation_actions','appeals','notifications'] loop
    execute format('alter table public.%I enable row level security',t);
    execute format('revoke all on public.%I from public, anon, authenticated',t);
  end loop;
end $$;
grant select on public.games, public.game_seasons, public.game_catalog_options to anon, authenticated;
grant select on public.profiles,public.user_roles,public.game_profiles,public.game_profile_options,
  public.availability_slots,public.invites,public.conversations,public.messages,
  public.game_id_shares,public.blocks,public.reports,public.moderation_actions,
  public.appeals,public.notifications to authenticated;
grant update(display_name,avatar_url,bio,languages,timezone,voice_preference,play_style,availability_status,visibility)
  on public.profiles to authenticated;
grant insert(user_id,game_id,ign,game_id_private,region_option_id,server_option_id,primary_rank_option_id,
  primary_rank_mode_option_id,primary_role_option_id,play_goal,availability_status,visibility,attributes)
  on public.game_profiles to authenticated;
grant update(ign,game_id_private,region_option_id,server_option_id,primary_rank_option_id,
  primary_rank_mode_option_id,primary_role_option_id,play_goal,availability_status,visibility,attributes)
  on public.game_profiles to authenticated;
grant insert,delete on public.availability_slots,public.game_profile_options,public.blocks to authenticated;
grant select,update(read_at) on public.notifications to authenticated;

create policy catalog_games on public.games for select to anon,authenticated using (active or private.is_admin());
create policy catalog_seasons on public.game_seasons for select to anon,authenticated using (active or private.is_admin());
create policy catalog_options on public.game_catalog_options for select to anon,authenticated using (active or private.is_admin());
create policy own_profile on public.profiles for select to authenticated using(user_id=auth.uid());
create policy edit_profile on public.profiles for update to authenticated
  using(user_id=auth.uid() and private.is_active(auth.uid())) with check(user_id=auth.uid());
create policy own_role on public.user_roles for select to authenticated using(user_id=auth.uid());
create policy own_game_profile on public.game_profiles for select to authenticated using(user_id=auth.uid());
create policy insert_game_profile on public.game_profiles for insert to authenticated
  with check(user_id=auth.uid() and private.is_active(auth.uid()));
create policy edit_game_profile on public.game_profiles for update to authenticated
  using(user_id=auth.uid() and private.is_active(auth.uid())) with check(user_id=auth.uid());
create policy own_options on public.game_profile_options for select to authenticated using(
  exists(select 1 from public.game_profiles gp where gp.id=game_profile_id and gp.user_id=auth.uid()));
create policy write_options on public.game_profile_options for insert to authenticated with check(
  private.is_active(auth.uid()) and exists(select 1 from public.game_profiles gp where gp.id=game_profile_id and gp.user_id=auth.uid()));
create policy delete_options on public.game_profile_options for delete to authenticated using(
  private.is_active(auth.uid()) and exists(select 1 from public.game_profiles gp where gp.id=game_profile_id and gp.user_id=auth.uid()));
create policy own_slots on public.availability_slots for select to authenticated using(user_id=auth.uid());
create policy insert_slots on public.availability_slots for insert to authenticated with check(user_id=auth.uid() and private.is_active(auth.uid()));
create policy delete_slots on public.availability_slots for delete to authenticated using(user_id=auth.uid() and private.is_active(auth.uid()));
create policy own_invites on public.invites for select to authenticated using(auth.uid() in(sender_id,recipient_id));
create policy own_conversations on public.conversations for select to authenticated using(private.chat_allowed(id));
create policy own_messages on public.messages for select to authenticated using(private.chat_allowed(conversation_id));
create policy own_shares on public.game_id_shares for select to authenticated using(owner_id=auth.uid() and private.chat_allowed(conversation_id));
create policy own_blocks on public.blocks for select to authenticated using(blocker_id=auth.uid());
create policy insert_blocks on public.blocks for insert to authenticated with check(blocker_id=auth.uid());
create policy delete_blocks on public.blocks for delete to authenticated using(blocker_id=auth.uid());
create policy own_reports on public.reports for select to authenticated using(reporter_id=auth.uid() or private.is_admin());
create policy own_actions on public.moderation_actions for select to authenticated using(subject_user_id=auth.uid() or private.is_admin());
create policy own_appeals on public.appeals for select to authenticated using(user_id=auth.uid() or private.is_admin());
create policy own_notifications on public.notifications for select to authenticated using(user_id=auth.uid());
create policy mark_notification on public.notifications for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());

-- Fixed-shape DTO; definer bypasses private-table RLS but predicates are mandatory.
create function public.search_game_profiles(
 p_game_slug text,p_rank text default null,p_roles text[] default null,p_mode text default null,
 p_region text default null,p_ready boolean default null,p_limit int default 20,p_offset int default 0)
returns table(id uuid,user_id uuid,game_id uuid,game_name text,display_name text,avatar_url text,
 ign text,rank text,role text,region text,ready boolean,updated_at timestamptz,bio text)
language plpgsql stable security definer set search_path = '' as $$
begin
 if p_limit is null or p_limit not between 1 and 50 or p_offset is null or p_offset not between 0 and 5000
    or p_game_slug is null then raise exception 'Filter pencarian tidak valid'; end if;
 return query
 select gp.id,gp.user_id,gp.game_id,g.name,p.display_name,p.avatar_url,gp.ign,
   r.label,ro.label,reg.label,
   (gp.availability_status='ready' and p.availability_status='ready'),gp.data_updated_at,p.bio
 from public.game_profiles gp join public.games g on g.id=gp.game_id
 join public.profiles p on p.user_id=gp.user_id
 left join public.game_catalog_options r on r.id=gp.primary_rank_option_id
 left join public.game_catalog_options ro on ro.id=gp.primary_role_option_id
 left join public.game_catalog_options reg on reg.id=gp.region_option_id
 left join public.game_catalog_options rm on rm.id=gp.primary_rank_mode_option_id
 where g.slug=p_game_slug and g.active and gp.status='active' and gp.visibility='public'
 and p.visibility='public' and p.account_status='active' and p.adult_declared_at is not null
 and (auth.uid() is null or not private.blocked(auth.uid(),gp.user_id))
 and (p_rank is null or
   ((r.code=p_rank or (g.slug='free-fire' and p_mode='clash-squad' and r.code=p_rank || '-cs'))
   and (g.slug not in ('free-fire','pubg-mobile') or p_mode is not null)
   and (p_mode is null or rm.code=p_mode)))
 and (p_roles is null or cardinality(p_roles)=0 or ro.code=any(p_roles))
 and (p_mode is null or rm.code=p_mode or exists(select 1 from public.game_profile_options po
   join public.game_catalog_options mo on mo.id=po.option_id
   where po.game_profile_id=gp.id and po.purpose='favorite_mode' and mo.code=p_mode))
 and (p_region is null or reg.code=p_region)
 and (p_ready is null or (gp.availability_status='ready' and p.availability_status='ready')=p_ready)
 order by (gp.data_updated_at < now()-interval '30 days') asc,gp.data_updated_at desc,gp.id
 limit p_limit offset p_offset;
end $$;
create function public.public_profile_detail(p_id uuid)
returns table(id uuid,user_id uuid,game_id uuid,game_name text,display_name text,avatar_url text,
 ign text,rank text,role text,region text,ready boolean,updated_at timestamptz,bio text)
language sql stable security definer set search_path = '' as $$
 select gp.id,gp.user_id,gp.game_id,g.name,p.display_name,p.avatar_url,gp.ign,
 r.label,ro.label,reg.label,(gp.availability_status='ready' and p.availability_status='ready'),gp.data_updated_at,p.bio
 from public.game_profiles gp join public.games g on g.id=gp.game_id and g.active
 join public.profiles p on p.user_id=gp.user_id
 left join public.game_catalog_options r on r.id=gp.primary_rank_option_id
 left join public.game_catalog_options ro on ro.id=gp.primary_role_option_id
 left join public.game_catalog_options reg on reg.id=gp.region_option_id
 where gp.id=p_id and gp.status='active' and gp.visibility='public'
 and p.visibility='public' and p.account_status='active' and p.adult_declared_at is not null
 and (auth.uid() is null or not private.blocked(auth.uid(),gp.user_id))
$$;

create function public.create_invite(p_recipient uuid,p_game uuid,p_message text default null)
returns public.invites language plpgsql security definer set search_path = '' as $$
declare v_me uuid:=auth.uid(); v_row public.invites; v_low uuid; v_high uuid;
begin
 if v_me is null or v_me=p_recipient or not private.verified() or not private.is_active(v_me)
   or not private.is_active(p_recipient) or private.blocked(v_me,p_recipient)
   or p_message is not null and char_length(p_message)>500 then raise exception 'Ajakan tidak diizinkan'; end if;
 if not exists(select 1 from public.games where id=p_game and active)
 or not exists(select 1 from public.game_profiles gp join public.profiles p on p.user_id=gp.user_id
   where gp.user_id=p_recipient and gp.game_id=p_game and gp.status='active' and gp.visibility='public' and p.visibility='public')
 or not exists(select 1 from public.game_profiles where user_id=v_me and game_id=p_game and status='active') then
   raise exception 'Profil game tidak tersedia'; end if;
 v_low:=least(v_me,p_recipient);v_high:=greatest(v_me,p_recipient);
 -- Serialize reversed directions even when no pending row exists.
 perform 1 from public.profiles where user_id in(v_low,v_high) order by user_id for update;
 update public.invites set status='expired',responded_at=now()
   where pair_low=v_low and pair_high=v_high and game_id=p_game and status='pending' and expires_at<=now();
 if exists(select 1 from public.invites where pair_low=v_low and pair_high=v_high and game_id=p_game and status='pending') then
   raise exception 'Ajakan masih tertunda'; end if;
 insert into public.invites(sender_id,recipient_id,game_id,message) values(v_me,p_recipient,p_game,p_message) returning * into v_row;
 insert into public.notifications(user_id,kind,reference_type,reference_id)
 values(p_recipient,'invite_status','invite',v_row.id);
 return v_row;
end $$;
create function public.respond_invite(p_id uuid,p_accept boolean)
returns public.invites language plpgsql security definer set search_path = '' as $$
declare v_row public.invites;
begin
 if not private.verified() or not private.is_active(auth.uid()) then raise exception 'Tidak diizinkan'; end if;
 select * into v_row from public.invites where id=p_id for update;
 if not found or v_row.recipient_id<>auth.uid() or v_row.status<>'pending' then raise exception 'Ajakan tidak tersedia'; end if;
 if v_row.expires_at<=now() then
   update public.invites set status='expired',responded_at=now() where id=p_id returning * into v_row;
   return v_row;
 end if;
 if not private.is_active(v_row.sender_id) or private.blocked(v_row.sender_id,v_row.recipient_id) then raise exception 'Ajakan tidak diizinkan'; end if;
 update public.invites set status=case when p_accept then 'accepted' else 'rejected' end,
   responded_at=now() where id=p_id returning * into v_row;
 if p_accept then
   insert into public.conversations(invite_id,participant_low,participant_high)
   values(p_id,v_row.pair_low,v_row.pair_high);
 end if;
 insert into public.notifications(user_id,kind,reference_type,reference_id)
 values(v_row.sender_id,'invite_status','invite',p_id);
 return v_row;
end $$;
create function public.cancel_invite(p_id uuid) returns public.invites
language plpgsql security definer set search_path = '' as $$
declare v_row public.invites;
begin
 update public.invites set status='cancelled',responded_at=now()
 where id=p_id and sender_id=auth.uid() and status='pending' returning * into v_row;
 if not found then raise exception 'Ajakan tidak tersedia'; end if;
 return v_row;
end $$;
create function public.send_message(p_conversation uuid,p_body text) returns public.messages
language plpgsql security definer set search_path = '' as $$
declare v_row public.messages; v_other uuid;
begin
 if p_body is null or char_length(trim(p_body)) not between 1 and 2000
 or not private.verified() or not private.chat_allowed(p_conversation) then raise exception 'Pesan tidak diizinkan'; end if;
 insert into public.messages(conversation_id,sender_id,body)
 values(p_conversation,auth.uid(),trim(p_body)) returning * into v_row;
 select case when participant_low=auth.uid() then participant_high else participant_low end into v_other
 from public.conversations where id=p_conversation;
 insert into public.notifications(user_id,kind,reference_type,reference_id)
 values(v_other,'new_message','conversation',p_conversation);
 return v_row;
end $$;
create function public.share_game_id(p_conversation uuid,p_game_profile uuid)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_id uuid; v_game uuid;
begin
 if not private.chat_allowed(p_conversation) or not private.verified() then raise exception 'Tidak diizinkan'; end if;
 select game_id into v_game from public.invites where id=(select invite_id from public.conversations where id=p_conversation);
 if not exists(select 1 from public.game_profiles where id=p_game_profile and user_id=auth.uid()
   and game_id=v_game and status='active' and game_id_private is not null) then raise exception 'ID game tidak tersedia'; end if;
 insert into public.game_id_shares(conversation_id,owner_id,game_profile_id)
 values(p_conversation,auth.uid(),p_game_profile)
 on conflict(conversation_id,owner_id,game_profile_id) do update set revoked_at=null,shared_at=now()
 returning id into v_id;
 return v_id;
end $$;
create function public.revoke_game_id_share(p_id uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
 update public.game_id_shares set revoked_at=now() where id=p_id and owner_id=auth.uid();
 if not found then raise exception 'Bagian tidak tersedia'; end if;
end $$;
create function public.read_shared_game_id(p_conversation uuid,p_owner uuid) returns text
language plpgsql stable security definer set search_path = '' as $$
declare v_id text;
begin
 if not private.chat_allowed(p_conversation) or auth.uid()=p_owner then return null; end if;
 select gp.game_id_private into v_id from public.game_id_shares s
 join public.game_profiles gp on gp.id=s.game_profile_id and gp.user_id=s.owner_id
 join public.invites i on i.id=(select invite_id from public.conversations where id=p_conversation)
 where s.conversation_id=p_conversation and s.owner_id=p_owner and s.revoked_at is null
 and gp.game_id=i.game_id and gp.status='active' limit 1;
 return v_id;
end $$;
create function public.create_report(p_reported uuid,p_category text,p_description text,p_target_type text,p_target_id uuid)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_id uuid; v_me uuid:=auth.uid();
begin
 if not private.is_active(v_me) or v_me=p_reported or p_target_id is null
 or p_category not in('harassment','spam','fraud','impersonation','inappropriate')
 or p_description is null or char_length(trim(p_description)) not between 10 and 2000 then raise exception 'Laporan tidak valid'; end if;
 if not (p_target_type='profile' and exists(select 1 from public.game_profiles where id=p_target_id and user_id=p_reported)
 or p_target_type='invite' and exists(select 1 from public.invites where id=p_target_id
   and p_reported in(sender_id,recipient_id) and v_me in(sender_id,recipient_id))
 or p_target_type='message' and exists(select 1 from public.messages m join public.conversations c on c.id=m.conversation_id
   where m.id=p_target_id and m.sender_id=p_reported and v_me in(c.participant_low,c.participant_high))) then
   raise exception 'Target laporan tidak valid'; end if;
 if exists(select 1 from public.reports where reporter_id=v_me and target_type=p_target_type
   and target_id=p_target_id and created_at>now()-interval '1 day') then raise exception 'Laporan duplikat'; end if;
 insert into public.reports(reporter_id,reported_id,category,description,target_type,target_id)
 values(v_me,p_reported,p_category,trim(p_description),p_target_type,p_target_id) returning id into v_id;
 return v_id;
end $$;
create function public.apply_moderation_action(p_subject uuid,p_action text,p_reason text,p_report uuid default null)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_id uuid;
begin
 if not private.is_admin() or p_subject=auth.uid() or p_action not in
 ('hide_profile','restrict_account','restore_profile','restore_account')
 or p_reason is null or char_length(trim(p_reason)) not between 10 and 1000
 or (p_report is not null and not exists(select 1 from public.reports where id=p_report and reported_id=p_subject)) then
 raise exception 'Tindakan tidak diizinkan'; end if;
 if p_action in ('restrict_account','restore_account') then
   update public.profiles set account_status=case when p_action='restrict_account' then 'restricted' else 'active' end
   where user_id=p_subject;
 else
   update public.game_profiles set status=case when p_action='hide_profile' then 'hidden' else 'active' end
   where user_id=p_subject;
 end if;
 if not found then raise exception 'Akun tidak tersedia'; end if;
 insert into public.moderation_actions(admin_id,subject_user_id,report_id,action,reason)
 values(auth.uid(),p_subject,p_report,p_action,trim(p_reason)) returning id into v_id;
 insert into public.notifications(user_id,kind,reference_type,reference_id)
 values(p_subject,'moderation','moderation_action',v_id);
 return v_id;
end $$;
-- Only server-controlled bootstrap may promote roles. Record changes via immutable audit rows.
create table public.role_audit (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(user_id),
 actor_id uuid references public.profiles(user_id), old_role text, new_role text not null,
 created_at timestamptz not null default now()
);
alter table public.role_audit enable row level security;
revoke all on public.role_audit from public,anon,authenticated;
create function private.audit_role() returns trigger language plpgsql security definer set search_path = '' as $$
begin
 if tg_op='UPDATE' and old.role is distinct from new.role then
 insert into public.role_audit(user_id,actor_id,old_role,new_role)
 values(new.user_id,auth.uid(),old.role,new.role);
 end if;
 return new;
end $$;
create trigger role_audit_change after update on public.user_roles for each row execute function private.audit_role();
-- Admin catalog mutation: validate kind and prohibit rank mode cross-game references.
create function public.add_catalog_option(p_game uuid,p_kind text,p_code text,p_label text,p_rank_mode uuid default null)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_id uuid;
begin
 if not private.is_admin() or p_kind not in ('rank','role','mode','region','server','map','hero','agent','perspective','team_size')
 or p_code is null or p_code !~ '^[a-z0-9-]{2,50}$'
 or p_label is null or char_length(trim(p_label)) not between 2 and 80
 or not exists(select 1 from public.games where id=p_game)
 then raise exception 'Opsi katalog tidak valid'; end if;
 if p_rank_mode is not null then
   if p_kind<>'rank' then raise exception 'Mode hanya berlaku untuk rank'; end if;
   perform private.check_option(p_rank_mode,p_game,'mode');
 end if;
 insert into public.game_catalog_options(game_id,kind,code,label,rank_mode_option_id)
 values(p_game,p_kind,p_code,trim(p_label),p_rank_mode) returning id into v_id;
 return v_id;
end $$;
-- PostgreSQL grants EXECUTE to PUBLIC on new functions by default: revoke every helper and RPC.
do $$ declare f record; begin
 for f in select p.oid::regprocedure as signature from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname in ('private','public') and p.proname in
 ('on_auth_user','is_active','verified','is_admin','blocked','chat_allowed','check_option',
 'validate_game_profile','validate_profile_option','search_game_profiles','public_profile_detail',
 'create_invite','respond_invite','cancel_invite','send_message','share_game_id',
 'revoke_game_id_share','read_shared_game_id','create_report','apply_moderation_action','audit_role','add_catalog_option') loop
 execute format('revoke all on function %s from public,anon,authenticated',f.signature);
 end loop;
end $$;
grant execute on function public.search_game_profiles(text,text,text[],text,text,boolean,int,int),
 public.public_profile_detail(uuid) to anon,authenticated;
grant execute on function public.create_invite(uuid,uuid,text),public.respond_invite(uuid,boolean),
 public.cancel_invite(uuid),public.send_message(uuid,text),public.share_game_id(uuid,uuid),
 public.revoke_game_id_share(uuid),public.read_shared_game_id(uuid,uuid),
 public.create_report(uuid,text,text,text,uuid),public.apply_moderation_action(uuid,text,text,uuid),
 public.add_catalog_option(uuid,text,text,text,uuid) to authenticated;
-- RLS policies call helpers under the caller role; no API access to private schema.
grant execute on function private.is_active(uuid),private.verified(),private.is_admin(),private.blocked(uuid,uuid),
 private.chat_allowed(uuid),private.validate_game_profile(),private.validate_profile_option() to authenticated;
grant execute on function private.is_admin() to anon;
