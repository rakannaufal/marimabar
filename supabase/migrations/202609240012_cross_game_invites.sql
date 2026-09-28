-- A sender may request mabar from a public game profile without owning that game.
-- The target game/profile still determines the invite context.
create or replace function public.create_invite(
  p_recipient uuid,
  p_game uuid,
  p_message text default null
)
returns public.invites
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
  v_row public.invites;
  v_low uuid;
  v_high uuid;
begin
  if v_me is null or v_me = p_recipient
    or not private.verified() or not private.is_active(v_me)
    or not private.is_active(p_recipient)
    or not exists (
      select 1 from auth.users
      where id = p_recipient and email_confirmed_at is not null
    )
    or private.blocked(v_me, p_recipient)
    or p_message is not null and char_length(p_message) > 500 then
    raise exception 'Ajakan tidak diizinkan';
  end if;

  if not exists (select 1 from public.games where id = p_game and active)
    or not exists (
      select 1
      from public.game_profiles gp
      join public.profiles p on p.user_id = gp.user_id
      where gp.user_id = p_recipient
        and gp.game_id = p_game
        and gp.status = 'active'
        and gp.visibility = 'public'
        and p.visibility = 'public'
    ) then
    raise exception 'Profil game tidak tersedia';
  end if;

  v_low := least(v_me, p_recipient);
  v_high := greatest(v_me, p_recipient);
  perform 1 from public.profiles
  where user_id in (v_low, v_high)
  order by user_id for update;

  update public.invites
  set status = 'expired', responded_at = now()
  where pair_low = v_low and pair_high = v_high and game_id = p_game
    and status = 'pending' and expires_at <= now();

  if exists (
    select 1 from public.invites
    where pair_low = v_low and pair_high = v_high and game_id = p_game
      and status = 'pending'
  ) then
    raise exception 'Ajakan masih tertunda';
  end if;

  insert into public.invites(sender_id, recipient_id, game_id, message)
  values(v_me, p_recipient, p_game, p_message)
  returning * into v_row;

  insert into public.notifications(user_id, kind, reference_type, reference_id)
  values(p_recipient, 'invite_status', 'invite', v_row.id);
  return v_row;
end
$$;
