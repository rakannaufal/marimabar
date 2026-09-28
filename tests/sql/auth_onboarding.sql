-- Auth onboarding SQL behavior tests.
-- Runs inside PGlite after all migrations + seed.
begin;

-- Create test auth users with different providers
insert into auth.users(id,email,email_confirmed_at,raw_user_meta_data,raw_app_meta_data) values
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1','google-new@example.invalid',now(),'{}','{"provider":"google"}'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2','email-new@example.invalid',now(),'{"adult_declared":"true"}','{"provider":"email"}'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3','google-spoof@example.invalid',now(),'{"adult_declared":"true"}','{"provider":"google"}'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb4','google-legit@example.invalid',now(),'{}','{"provider":"google"}');

-- TEST 1: Google OAuth user has no adult_declared_at and is_active() returns false
do $$ begin
  if (select adult_declared_at from public.profiles where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1') is not null then
    raise exception 'TEST 1 FAIL: Google user should not have adult_declared_at';
  end if;
  if private.is_active('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1') then
    raise exception 'TEST 1 FAIL: Google user should not be active';
  end if;
  if (select registration_intent from public.profiles where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1') <> 'google' then
    raise exception 'TEST 1 FAIL: Google user should have google registration_intent';
  end if;
end $$;

-- TEST 2: Email user has adult_declared_at and is_active() returns true
do $$ begin
  if (select adult_declared_at from public.profiles where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2') is null then
    raise exception 'TEST 2 FAIL: Email user should have adult_declared_at';
  end if;
  if not private.is_active('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2') then
    raise exception 'TEST 2 FAIL: Email user should be active';
  end if;
  if (select registration_intent from public.profiles where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2') <> 'email' then
    raise exception 'TEST 2 FAIL: Email user should have email registration_intent';
  end if;
end $$;

-- TEST 3: Google metadata spoofing is ignored
do $$ begin
  if (select adult_declared_at from public.profiles where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3') is not null then
    raise exception 'TEST 3 FAIL: Google metadata spoof should be ignored';
  end if;
  if private.is_active('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3') then
    raise exception 'TEST 3 FAIL: Google spoofer should not be active';
  end if;
end $$;

-- TEST 4: complete_onboarding() fails without adult declaration
set local role authenticated;
select set_config('request.jwt.claim.sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',true);
do $$ declare denied boolean := false;
begin
  begin perform public.complete_onboarding(); exception when others then denied:=true; end;
  if not denied then raise exception 'TEST 4 FAIL: onboarding without adult declaration'; end if;
end $$;
reset role;

-- TEST 5: complete_onboarding() fails without game profile (even with adult declaration)
update public.profiles set adult_declared_at = now() where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb4';
set local role authenticated;
select set_config('request.jwt.claim.sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb4',true);
do $$ declare denied boolean := false;
begin
  begin perform public.complete_onboarding(); exception when others then denied:=true; end;
  if not denied then raise exception 'TEST 5 FAIL: onboarding without game profile'; end if;
end $$;
reset role;

-- TEST 6: complete_onboarding() succeeds with adult declaration + game profile
insert into public.game_profiles(user_id, game_id, ign)
values('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb4',
  (select id from public.games where slug='mlbb'), 'TestPlayer');
set local role authenticated;
select set_config('request.jwt.claim.sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb4',true);
do $$ begin
  perform public.complete_onboarding();
  if (select onboarding_completed_at from public.profiles where user_id=auth.uid()) is null then
    raise exception 'TEST 6 FAIL: onboarding_completed_at not set';
  end if;
end $$;

-- TEST 7: complete_onboarding() is idempotent
do $$ declare t1 timestamptz; t2 timestamptz;
begin
  select onboarding_completed_at into t1 from public.profiles where user_id=auth.uid();
  perform public.complete_onboarding();
  select onboarding_completed_at into t2 from public.profiles where user_id=auth.uid();
  if t1 <> t2 then raise exception 'TEST 7 FAIL: onboarding not idempotent'; end if;
end $$;
reset role;

-- TEST 8: is_onboarded() helper works
do $$ begin
  if not private.is_onboarded('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb4') then
    raise exception 'TEST 8 FAIL: completed user not onboarded';
  end if;
  if private.is_onboarded('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1') then
    raise exception 'TEST 8 FAIL: unregistered user should not be onboarded';
  end if;
end $$;

-- TEST 9: Email user has no onboarding_completed_at by default (new user, no game profile yet)
do $$ begin
  if (select onboarding_completed_at from public.profiles where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2') is not null then
    raise exception 'TEST 9 FAIL: new email user should not be auto-onboarded';
  end if;
end $$;

-- TEST 10: Email user can complete onboarding after adding game profile
insert into public.game_profiles(user_id, game_id, ign)
values('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',
  (select id from public.games where slug='mlbb'), 'EmailPlayer');
set local role authenticated;
select set_config('request.jwt.claim.sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',true);
do $$ begin
  perform public.complete_onboarding();
  if (select onboarding_completed_at from public.profiles where user_id=auth.uid()) is null then
    raise exception 'TEST 10 FAIL: email user onboarding failed';
  end if;
end $$;
reset role;

-- TEST 11: Google user without registration cannot create game profiles (RLS blocks via is_active)
set local role authenticated;
select set_config('request.jwt.claim.sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',true);
do $$ declare denied boolean := false;
begin
  begin
    insert into public.game_profiles(user_id, game_id, ign)
    values(auth.uid(), (select id from public.games where slug='mlbb'), 'Unauthorized');
  exception when others then denied:=true; end;
  if not denied then raise exception 'TEST 11 FAIL: unregistered Google user created game profile'; end if;
end $$;
reset role;

-- TEST 12: Google user without registration cannot send invites
set local role authenticated;
select set_config('request.jwt.claim.sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',true);
do $$ declare denied boolean := false;
begin
  begin
    perform public.create_invite('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb4',
      (select id from public.games where slug='mlbb'));
  exception when others then denied:=true; end;
  if not denied then raise exception 'TEST 12 FAIL: unregistered user sent invite'; end if;
end $$;
reset role;

-- TEST 13: declare_adult_account() still works for Google users
set local role authenticated;
select set_config('request.jwt.claim.sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',true);
do $$ begin
  perform public.declare_adult_account();
  if (select adult_declared_at from public.profiles where user_id=auth.uid()) is null then
    raise exception 'TEST 13 FAIL: declare_adult_account did not work';
  end if;
end $$;
reset role;

rollback;
