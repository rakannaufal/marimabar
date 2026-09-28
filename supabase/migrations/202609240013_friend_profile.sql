-- Accepted friends can inspect all currently public game profiles and private contact fields.
create function public.friend_profile(p_other uuid)
returns table(
  user_id uuid,
  display_name text,
  avatar_url text,
  bio text,
  discord text,
  game_profile_id uuid,
  game_id uuid,
  game_name text,
  game_slug text,
  ign text,
  game_id_private text,
  rank text,
  role text,
  region text,
  ready boolean,
  attributes jsonb
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    p.user_id,
    p.display_name,
    p.avatar_url,
    p.bio,
    p.discord,
    gp.id,
    gp.game_id,
    g.name,
    g.slug,
    gp.ign,
    gp.game_id_private,
    rank.label,
    role.label,
    region.label,
    gp.availability_status = 'ready' and p.availability_status = 'ready',
    gp.attributes
  from public.profiles p
  join public.game_profiles gp on gp.user_id = p.user_id
  join public.games g on g.id = gp.game_id and g.active
  left join public.game_catalog_options rank on rank.id = gp.primary_rank_option_id
  left join public.game_catalog_options role on role.id = gp.primary_role_option_id
  left join public.game_catalog_options region on region.id = gp.region_option_id
  where auth.uid() is not null
    and p_other is not null
    and p_other <> auth.uid()
    and p.user_id = p_other
    and private.verified()
    and private.is_active(auth.uid())
    and private.is_active(p_other)
    and exists (
      select 1 from auth.users
      where id = p_other and email_confirmed_at is not null
    )
    and not private.blocked(auth.uid(), p_other)
    and p.visibility = 'public'
    and gp.status = 'active'
    and gp.visibility = 'public'
    and exists (
      select 1 from public.friend_requests f
      where f.status = 'accepted'
        and auth.uid() in (f.requester_id, f.recipient_id)
        and p_other in (f.requester_id, f.recipient_id)
    )
  order by g.name, gp.created_at;
$$;

revoke all on function public.friend_profile(uuid) from public,anon,authenticated;
grant execute on function public.friend_profile(uuid) to authenticated;
