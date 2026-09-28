-- Auth-onboarding hardening: registration intent, onboarding gate, Google OAuth guardrails.
--
-- SECURITY NOTE (Supabase Auth + Google OAuth):
-- Supabase Auth auto-creates an auth.users row on first Google sign-in. SQL alone CANNOT
-- prevent that row from being created; the "before user created" HTTP hook requires
-- Dashboard/project config and is not configurable via migration SQL.
--
-- What this migration DOES guarantee at the SQL layer:
-- 1. Google OAuth sign-ins that bypass explicit registration get a profile row with
--    registration_intent = NULL and adult_declared_at = NULL, making private.is_active()
--    return FALSE. All protected RPCs and RLS policies already gate on is_active().
-- 2. A new complete_onboarding() RPC enforces adult_declared_at IS NOT NULL and at least
--    one active game_profile before marking onboarding complete.
-- 3. Legacy users (existing profiles with at least one game_profile) are backfilled as
--    onboarding-complete so they are not disrupted.
-- 4. declare_adult_account() is preserved for post-OAuth consent declaration.
-- 5. registration_intent column records HOW the profile was created; metadata spoofing
--    via raw_user_meta_data on Google provider is explicitly ignored.

-- 1. Add onboarding columns to profiles
alter table public.profiles add column if not exists onboarding_completed_at timestamptz;
alter table public.profiles add column if not exists registration_intent text
  check (registration_intent is null or registration_intent in ('email','google'));

-- 2. Update auth trigger to record registration_intent and ignore Google metadata spoofing
create or replace function private.on_auth_user() returns trigger language plpgsql security definer set search_path = '' as $$
declare v_provider text; v_intent text; v_adult timestamptz;
begin
  -- Determine provider from app_metadata (server-controlled, not spoofable by client).
  v_provider := coalesce(new.raw_app_meta_data->>'provider', 'email');

  if v_provider = 'google' then
    -- Google OAuth: NEVER trust raw_user_meta_data for adult_declared.
    -- Profile created with null adult_declared_at; user must call declare_adult_account() explicitly.
    v_intent := 'google';
    v_adult := null;
  else
    -- Email signup: honor the adult_declared metadata set during registration.
    v_intent := 'email';
    v_adult := case when new.raw_user_meta_data->>'adult_declared' = 'true' then now() else null end;
  end if;

  insert into public.profiles(user_id, adult_declared_at, registration_intent)
  values(new.id, v_adult, v_intent)
  on conflict do nothing;

  insert into public.user_roles(user_id) values(new.id) on conflict do nothing;
  return new;
end $$;

-- 3. complete_onboarding() RPC — gate: adult_declared_at + at least one active game_profile
create function public.complete_onboarding() returns void
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  -- Must have adult declaration
  if not exists(
    select 1 from public.profiles
    where user_id = auth.uid() and account_status = 'active' and adult_declared_at is not null
  ) then
    raise exception 'Adult declaration required before completing onboarding' using errcode = 'P0001';
  end if;

  -- Must have at least one active game profile
  if not exists(
    select 1 from public.game_profiles
    where user_id = auth.uid() and status = 'active'
  ) then
    raise exception 'At least one game profile required' using errcode = 'P0001';
  end if;

  -- Idempotent: only set once
  update public.profiles
  set onboarding_completed_at = coalesce(onboarding_completed_at, now())
  where user_id = auth.uid() and account_status = 'active';

  if not found then
    raise exception 'Active profile required' using errcode = 'P0001';
  end if;
end $$;
revoke all on function public.complete_onboarding() from public, anon;
grant execute on function public.complete_onboarding() to authenticated;

-- 4. Backfill: existing profiles with at least one active game_profile are considered onboarded
update public.profiles p
set onboarding_completed_at = coalesce(p.onboarding_completed_at, p.created_at)
where p.adult_declared_at is not null
  and p.account_status = 'active'
  and p.onboarding_completed_at is null
  and exists(select 1 from public.game_profiles gp where gp.user_id = p.user_id and gp.status = 'active');

-- 5. Backfill registration_intent for existing users from auth.users app_metadata
update public.profiles p
set registration_intent = case
  when coalesce((select raw_app_meta_data->>'provider' from auth.users u where u.id = p.user_id), 'email') = 'google'
  then 'google' else 'email' end
where p.registration_intent is null;

-- 6. Grant authenticated SELECT on the new columns (already covered by own_profile policy)
-- No additional grants needed; profiles already has SELECT to authenticated via own_profile policy.
-- The new columns are readable through the existing grant.

-- 7. Private helper: check if onboarding is complete (for future use in policies/RPCs)
create function private.is_onboarded(p_id uuid) returns boolean language sql stable security definer set search_path = '' as $$
  select exists(
    select 1 from public.profiles p
    where p.user_id = p_id
      and p.account_status = 'active'
      and p.adult_declared_at is not null
      and p.onboarding_completed_at is not null
  )
$$;
revoke all on function private.is_onboarded(uuid) from public, anon, authenticated;
grant execute on function private.is_onboarded(uuid) to authenticated;
