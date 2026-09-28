-- One profile action creates a mabar invite and ensures a friend approval request.
-- Existing friend requests are reused so requests made before this fix can be repaired.
create function public.create_mabar_request(
  p_recipient uuid,
  p_game uuid,
  p_message text default null
)
returns table(invite_id uuid, friend_request_id uuid)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
  v_invite public.invites;
  v_friend public.friend_requests;
begin
  if v_me is null or p_recipient is null or v_me = p_recipient
    or not private.verified() or not private.is_active(v_me)
    or not private.is_active(p_recipient)
    or not exists (
      select 1 from auth.users
      where id = p_recipient and email_confirmed_at is not null
    )
    or private.blocked(v_me, p_recipient) then
    raise exception 'Request mabar tidak diizinkan' using errcode = 'P0001';
  end if;

  perform 1 from public.profiles
  where user_id in (v_me, p_recipient)
  order by user_id for update;

  select * into v_friend
  from public.friend_requests
  where least(requester_id, recipient_id) = least(v_me, p_recipient)
    and greatest(requester_id, recipient_id) = greatest(v_me, p_recipient)
  for update;

  if not found or v_friend.status = 'rejected' then
    v_friend := public.request_friend(p_recipient);
  end if;

  v_invite := public.create_invite(p_recipient, p_game, p_message);
  return query select v_invite.id, v_friend.id;
end
$$;

revoke all on function public.create_mabar_request(uuid,uuid,text)
  from public,anon,authenticated;
grant execute on function public.create_mabar_request(uuid,uuid,text)
  to authenticated;
