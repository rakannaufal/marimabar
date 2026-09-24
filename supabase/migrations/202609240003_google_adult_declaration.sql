-- Record an authenticated user's 18+ self-declaration after Google OAuth consent.
-- This is self-reported, not identity or age verification.
create function public.declare_adult_account() returns void
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode = '28000'; end if;
  update public.profiles set adult_declared_at = coalesce(adult_declared_at, now())
  where user_id = auth.uid() and account_status = 'active';
  if not found then raise exception 'Active profile required' using errcode = 'P0001'; end if;
end $$;
revoke all on function public.declare_adult_account() from public, anon;
grant execute on function public.declare_adult_account() to authenticated;
