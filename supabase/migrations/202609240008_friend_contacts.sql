-- Friend approval is independent of invites/chat and explicit game-ID shares.
-- Contact values stay on owned tables; public discovery projects no IGN or contact fields.
alter table public.profiles add column discord text
  check (discord is null or char_length(discord) <= 100);
grant update(discord) on public.profiles to authenticated;

create table public.friend_requests (
 id uuid primary key default gen_random_uuid(),
 requester_id uuid not null references public.profiles(user_id) on delete cascade,
 recipient_id uuid not null references public.profiles(user_id) on delete cascade,
 status text not null default 'pending' check (status in ('pending','accepted','rejected')),
 created_at timestamptz not null default now(), responded_at timestamptz,
 check (requester_id <> recipient_id),
 check ((status='pending' and responded_at is null) or (status<>'pending' and responded_at is not null))
);
create unique index friend_requests_pair_unique on public.friend_requests
 (least(requester_id,recipient_id),greatest(requester_id,recipient_id));
create index friend_requests_recipient_idx on public.friend_requests(recipient_id,status);
alter table public.friend_requests enable row level security;
revoke all on public.friend_requests from public,anon,authenticated;
grant select on public.friend_requests to authenticated;
create policy friend_request_participants on public.friend_requests for select to authenticated
 using (auth.uid() in (requester_id,recipient_id) and private.is_active(auth.uid())
   and not private.blocked(requester_id,recipient_id));

create function public.request_friend(p_recipient uuid) returns public.friend_requests
language plpgsql security definer set search_path = '' as $$
declare v_me uuid:=auth.uid(); v_row public.friend_requests;
begin
 if v_me is null or p_recipient is null or v_me=p_recipient or not private.verified()
   or not private.is_active(v_me) or not private.is_active(p_recipient)
   or not exists(select 1 from auth.users where id=p_recipient and email_confirmed_at is not null)
   or private.blocked(v_me,p_recipient) then
   raise exception 'Permintaan teman tidak diizinkan' using errcode='P0001'; end if;
 -- Serialize reverse-direction requests, including the no-row case.
 perform 1 from public.profiles where user_id in (v_me,p_recipient) order by user_id for update;
 select * into v_row from public.friend_requests
 where least(requester_id,recipient_id)=least(v_me,p_recipient)
   and greatest(requester_id,recipient_id)=greatest(v_me,p_recipient) for update;
 if found and v_row.status<>'rejected' then
   raise exception 'Permintaan teman sudah ada' using errcode='P0001'; end if;
 if found then
   update public.friend_requests set requester_id=v_me,recipient_id=p_recipient,
     status='pending',created_at=now(),responded_at=null where id=v_row.id returning * into v_row;
 else
   insert into public.friend_requests(requester_id,recipient_id)
   values(v_me,p_recipient) returning * into v_row;
 end if;
 return v_row;
end $$;

create function public.respond_friend(p_id uuid,p_accept boolean) returns public.friend_requests
language plpgsql security definer set search_path = '' as $$
declare v_row public.friend_requests;
begin
 if auth.uid() is null or p_id is null or p_accept is null or not private.verified()
   or not private.is_active(auth.uid()) then
   raise exception 'Respons teman tidak diizinkan' using errcode='P0001'; end if;
 select * into v_row from public.friend_requests where id=p_id for update;
 if not found or v_row.recipient_id<>auth.uid() or v_row.status<>'pending'
   or not private.is_active(v_row.requester_id)
   or not exists(select 1 from auth.users where id=v_row.requester_id and email_confirmed_at is not null)
   or private.blocked(v_row.requester_id,v_row.recipient_id) then
   raise exception 'Respons teman tidak diizinkan' using errcode='P0001'; end if;
 update public.friend_requests set status=case when p_accept then 'accepted' else 'rejected' end,
   responded_at=now() where id=p_id returning * into v_row;
 return v_row;
end $$;

create function public.remove_friend(p_other uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
 if auth.uid() is null or p_other is null or p_other=auth.uid()
   or not private.verified() or not private.is_active(auth.uid()) then
   raise exception 'Penghapusan teman tidak diizinkan' using errcode='P0001'; end if;
 delete from public.friend_requests where status='accepted'
   and ((requester_id=auth.uid() and recipient_id=p_other)
     or (recipient_id=auth.uid() and requester_id=p_other));
 if not found then raise exception 'Pertemanan tidak ditemukan' using errcode='P0001'; end if;
end $$;

create function public.friend_contact(p_other uuid,p_game uuid)
returns table(ign text,game_id_private text,discord text)
language plpgsql stable security definer set search_path = '' as $$
begin
 if auth.uid() is null or p_other is null or p_game is null or p_other=auth.uid()
   or not private.verified() or not private.is_active(auth.uid())
   or not private.is_active(p_other)
   or not exists(select 1 from auth.users where id=p_other and email_confirmed_at is not null)
   or private.blocked(auth.uid(),p_other) then
   return; end if;
 return query select gp.ign,gp.game_id_private,p.discord
 from public.friend_requests f
 join public.profiles p on p.user_id=p_other
 join public.game_profiles gp on gp.user_id=p.user_id and gp.game_id=p_game
 join public.games g on g.id=gp.game_id
 where f.status='accepted' and auth.uid() in (f.requester_id,f.recipient_id)
   and p_other in (f.requester_id,f.recipient_id)
   and p.visibility='public' and gp.status='active' and gp.visibility='public' and g.active;
end $$;

-- Participant-only name and first public game profile for an actionable inbox.
create function public.friend_request_players()
returns table(user_id uuid,display_name text,game_profile_id uuid)
language sql stable security definer set search_path = '' as $$
 select p.user_id,p.display_name,(
   select gp.id from public.game_profiles gp join public.games g on g.id=gp.game_id
   where gp.user_id=p.user_id and gp.status='active' and gp.visibility='public' and g.active
   order by gp.created_at,gp.id limit 1)
 from public.profiles p
 where auth.uid() is not null and private.is_active(auth.uid())
   and exists(select 1 from public.friend_requests f
     where auth.uid() in (f.requester_id,f.recipient_id)
       and p.user_id in (f.requester_id,f.recipient_id) and p.user_id<>auth.uid()
       and f.status in ('pending','accepted')
       and not private.blocked(f.requester_id,f.recipient_id))
   and p.visibility='public' and private.is_active(p.user_id);
$$;
revoke all on function public.request_friend(uuid),public.respond_friend(uuid,boolean),
 public.remove_friend(uuid),public.friend_contact(uuid,uuid),public.friend_request_players() from public,anon,authenticated;
grant execute on function public.request_friend(uuid),public.respond_friend(uuid,boolean),
 public.remove_friend(uuid),public.friend_contact(uuid,uuid),public.friend_request_players() to authenticated;

-- Disable legacy conversation sharing; it bypasses explicit friendship approval.
revoke execute on function public.share_game_id(uuid,uuid),
 public.read_shared_game_id(uuid,uuid) from public,anon,authenticated;

-- Keep the existing RPC signatures/filter behavior intact; redact the previously public IGN
-- in every discovery/detail function, including the attributes wrapper.
do $$ declare f record; v_definition text;
begin
 for f in select p.oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.proname in
   ('search_game_profiles','search_game_profiles_by_attributes','public_profile_detail',
    'search_game_profiles_by_attributes_with_public_facts') loop
   v_definition:=pg_get_functiondef(f.oid);
   if position('gp.ign' in v_definition)>0 then
     execute replace(v_definition,'gp.ign','null::text');
   elsif position('s.ign' in v_definition)>0 then
     execute replace(v_definition,'s.ign','null::text');
   else
     raise exception 'Expected IGN projection missing in %',f.oid::regprocedure;
   end if;
 end loop;
end $$;
