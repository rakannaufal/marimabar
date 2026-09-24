-- Run with psql -v ON_ERROR_STOP=1 -f tests/sql/mvp.sql after migrations + seed.
-- Transaction rolls back synthetic Auth users; requires Supabase local DB and postgres privileges.
begin;
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,email_confirmed_at)
select '00000000-0000-0000-0000-000000000000'::uuid,
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa' || n)::uuid,'authenticated','authenticated',
 'backend-test-' || n || '@example.invalid','!never-login',now()
from generate_series(1,4) n;
update public.profiles set adult_declared_at=now(),availability_status='ready'
where user_id::text like 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa%';
insert into public.game_profiles(user_id,game_id,ign,game_id_private)
values
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1','11111111-1111-4111-8111-111111111111','Alpha','private-alpha'),
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2','11111111-1111-4111-8111-111111111111','Beta','private-beta'),
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa3','11111111-1111-4111-8111-111111111111','Gamma','private-gamma');
-- Transaction-scoped JWT claims simulate PostgREST auth.uid().
set local role anon;
do $$ begin
 if (select count(*) from public.search_game_profiles('mlbb'))<>3 then raise exception 'anon public search'; end if;
 if has_table_privilege('anon','public.game_profiles','SELECT') then raise exception 'anon private table access'; end if;
 raise notice 'PASS: anon public DTO, private table denied';
end $$;
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1',true);
do $$ declare v_inv public.invites; v_conv uuid; v_profile uuid; v_error boolean;
begin
 if (select count(*) from public.search_game_profiles('mlbb'))<>3 then raise exception 'search count'; end if;
 if (select count(*) from public.search_game_profiles('mlbb',p_limit=>1,p_offset=>1))<>1 then raise exception 'pagination'; end if;
 select id into v_profile from public.search_game_profiles('mlbb') where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
 if (select count(*) from public.public_profile_detail(v_profile))<>1 then raise exception 'detail absent'; end if;
 if exists(select 1 from public.public_profile_detail(v_profile) d
   where to_jsonb(d) ? 'game_id_private' or to_jsonb(d) ? 'email') then
   raise exception 'private field leaked'; end if;
 -- Another user's underlying private row is invisible.
 if exists(select 1 from public.game_profiles where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2') then
   raise exception 'cross-owner game profile SELECT'; end if;
 v_error:=false;
 begin update public.user_roles set role='admin' where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
 exception when insufficient_privilege then v_error:=true; end;
 if not v_error then raise exception 'role escalation'; end if;
 v_error:=false;
 begin insert into public.messages(conversation_id,sender_id,body)
 values(gen_random_uuid(),auth.uid(),'early'); exception when insufficient_privilege then v_error:=true; end;
 if not v_error then raise exception 'direct message write'; end if;
 v_inv:=public.create_invite('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2','11111111-1111-4111-8111-111111111111');
 v_error:=false;
 begin perform public.send_message(gen_random_uuid(),'early'); exception when others then v_error:=true; end;
 if not v_error then raise exception 'pre-accept chat'; end if;
 v_error:=false;
 begin perform public.create_invite('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2','11111111-1111-4111-8111-111111111111');
 exception when others then v_error:=true; end;
 if not v_error then raise exception 'duplicate pending invite'; end if;
 perform set_config('request.jwt.claim.sub','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2',true);
 v_error:=false;
 begin perform public.create_invite('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1','11111111-1111-4111-8111-111111111111');
 exception when others then v_error:=true; end;
 if not v_error then raise exception 'reverse pending invite'; end if;
 perform public.respond_invite(v_inv.id,true);
 select id into v_conv from public.conversations where invite_id=v_inv.id;
 if v_conv is null then raise exception 'conversation missing'; end if;
 if public.read_shared_game_id(v_conv,'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1') is not null then
   raise exception 'ID opened automatically'; end if;
 perform set_config('request.jwt.claim.sub','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1',true);
 perform public.share_game_id(v_conv,(select id from public.game_profiles where user_id=auth.uid()));
 perform set_config('request.jwt.claim.sub','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2',true);
 if public.read_shared_game_id(v_conv,'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1')<>'private-alpha' then
   raise exception 'explicit share unavailable'; end if;
 perform public.send_message(v_conv,'hello');
 insert into public.blocks(blocker_id,blocked_id) values(auth.uid(),'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1');
 if public.read_shared_game_id(v_conv,'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1') is not null then
   raise exception 'block did not revoke ID'; end if;
 v_error:=false;
 begin perform public.send_message(v_conv,'blocked'); exception when others then v_error:=true; end;
 if not v_error then raise exception 'block did not stop chat'; end if;
 perform set_config('request.jwt.claim.sub','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1',true);
 if exists(select 1 from public.search_game_profiles('mlbb') where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2')
 then raise exception 'block did not hide search'; end if;
 raise notice 'PASS: projection, owner RLS, role, pending both ways, chat, explicit ID, block';
end $$;
reset role;
rollback;
