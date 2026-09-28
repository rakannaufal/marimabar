-- Expose verified status on public profile detail so that unverified accounts cannot be requested.
-- An account must verify email first in order to be requested by other players.

drop function if exists public.public_profile_detail(uuid);

create function public.public_profile_detail(p_id uuid)
returns table(
  id uuid,
  user_id uuid,
  game_id uuid,
  game_name text,
  display_name text,
  avatar_url text,
  ign text,
  rank text,
  role text,
  region text,
  ready boolean,
  updated_at timestamptz,
  bio text,
  verified boolean
)
language sql stable security definer set search_path = '' as $$
 select
   gp.id,
   gp.user_id,
   gp.game_id,
   g.name,
   p.display_name,
   p.avatar_url,
   null::text,
   case when g.slug='mlbb' then coalesce(gp.attributes->>'rank_current',r.label)
     when g.slug='pubg-mobile' then coalesce(gp.attributes->>'rank_tier',r.label)
     when g.slug='free-fire' then case gp.attributes->>'ranked_mode'
       when 'Battle Royale Ranked' then gp.attributes->>'rank_br'
       when 'Clash Squad Ranked' then gp.attributes->>'rank_cs'
       else coalesce(gp.attributes->>'rank',r.label) end
     when g.slug='valorant' then coalesce(gp.attributes->>'rank_current',r.label)
     else r.label end,
   case when g.slug='mlbb' then gp.attributes->>'position_main'
     when g.slug='pubg-mobile' then coalesce(gp.attributes->>'squad_role_main',ro.label)
     when g.slug='free-fire' then coalesce(gp.attributes->>'team_role_main',ro.label)
     when g.slug='valorant' then coalesce(gp.attributes->>'agent_role_main',ro.label)
     else ro.label end,
   reg.label,
   (gp.availability_status='ready' and p.availability_status='ready'),
   gp.data_updated_at,
   p.bio,
   exists(select 1 from auth.users u where u.id=gp.user_id and u.email_confirmed_at is not null) as verified
 from public.game_profiles gp
 join public.games g on g.id=gp.game_id and g.active
 join public.profiles p on p.user_id=gp.user_id
 left join public.game_catalog_options r on r.id=gp.primary_rank_option_id
 left join public.game_catalog_options ro on ro.id=gp.primary_role_option_id
 left join public.game_catalog_options reg on reg.id=gp.region_option_id
 where gp.id=p_id and gp.status='active' and gp.visibility='public'
 and p.visibility='public' and p.account_status='active' and p.adult_declared_at is not null
 and (auth.uid() is null or not private.blocked(auth.uid(),gp.user_id));
$$;

grant execute on function public.public_profile_detail(uuid) to anon,authenticated;

-- Ensure an account cannot be invited/requested unless its email is verified.
create or replace function public.create_invite(p_recipient uuid,p_game uuid,p_message text default null)
returns public.invites language plpgsql security definer set search_path = '' as $$
declare v_me uuid:=auth.uid(); v_row public.invites; v_low uuid; v_high uuid;
begin
 if v_me is null or v_me=p_recipient or not private.verified() or not private.is_active(v_me)
   or not private.is_active(p_recipient)
   or not exists(select 1 from auth.users where id=p_recipient and email_confirmed_at is not null)
   or private.blocked(v_me,p_recipient)
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
