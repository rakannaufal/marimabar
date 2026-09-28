-- Synthetic identities, transaction-scoped JWT claims, real grants/RLS.
begin;
insert into auth.users(id,email_confirmed_at,raw_user_meta_data) values
 ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',now(),'{"adult_declared":true}'),
 ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',now(),'{"adult_declared":true}'),
 ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3',now(),'{"adult_declared":true}');
update public.profiles set discord='secret#123' where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2';
insert into public.game_profiles(user_id,game_id,ign,game_id_private) values
 ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2','11111111-1111-4111-8111-111111111111','SecretIGN','SecretGameID');
set local role anon;
do $$ begin
 if has_table_privilege('anon','public.friend_requests','SELECT')
   or has_function_privilege('anon','public.friend_contact(uuid,uuid)','EXECUTE')
 then raise exception 'anon friend privilege'; end if;
end $$;
set local role authenticated;
select set_config('request.jwt.claim.sub','',true);
do $$ begin
 if exists(select 1 from public.friend_contact('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2','11111111-1111-4111-8111-111111111111'))
 then raise exception 'unauth contact'; end if;
 begin perform public.request_friend('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2');
  raise exception 'unauth request accepted';
 exception when sqlstate 'P0001' then null; end;
end $$;
select set_config('request.jwt.claim.sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',true);
do $$ declare f public.friend_requests; g uuid:='11111111-1111-4111-8111-111111111111'; begin
 if exists(select 1 from public.friend_contact('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',g))
 then raise exception 'contact before friendship'; end if;
 if exists(select 1 from public.friend_profile('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2'))
 then raise exception 'friend profile before friendship'; end if;
 if exists(select 1 from public.search_game_profiles('mlbb') where ign is not null)
 or exists(select 1 from public.search_game_profiles_by_attributes('mlbb') where ign is not null)
 or exists(select 1 from public.search_game_profiles_by_attributes_with_public_facts('mlbb') where ign is not null)
 or exists(select 1 from public.public_profile_detail((select id from public.search_game_profiles('mlbb') where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2')) where ign is not null)
 then raise exception 'public IGN disclosed'; end if;
 if exists(select 1 from public.profiles where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2')
 or exists(select 1 from public.game_profiles where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2')
 then raise exception 'cross-owner private table'; end if;
 if has_function_privilege('authenticated','public.share_game_id(uuid,uuid)','EXECUTE')
 or has_function_privilege('authenticated','public.read_shared_game_id(uuid,uuid)','EXECUTE')
 then raise exception 'legacy share still executable'; end if;
 if has_function_privilege('anon','public.friend_request_players()','EXECUTE')
 then raise exception 'anon names privilege'; end if;
 if exists(select 1 from public.friend_request_players()) then raise exception 'names before friendship'; end if;
 if has_table_privilege('authenticated','public.friend_requests','INSERT')
 or has_table_privilege('authenticated','public.friend_requests','UPDATE')
 or has_table_privilege('authenticated','public.friend_requests','DELETE')
 then raise exception 'friend table mutation grant'; end if;
 if not has_column_privilege('authenticated','public.profiles','discord','UPDATE')
 then raise exception 'discord update grant'; end if;
 begin update public.profiles set discord='stolen' where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2';
  if found then raise exception 'cross-owner discord update'; end if;
 end;
 f:=public.request_friend('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2');
 if (select count(*) from public.friend_request_players() where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2' and display_name is not null and game_profile_id is not null)<>1
 then raise exception 'participant names missing'; end if;
 if f.status<>'pending' or f.responded_at is not null then raise exception 'pending status'; end if;
 if exists(select 1 from public.friend_contact('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',g))
 then raise exception 'pending contact'; end if;
 begin perform public.request_friend('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2');
  raise exception 'duplicate accepted';
 exception when sqlstate 'P0001' then null; end;
 perform set_config('request.jwt.claim.sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3',true);
 if exists(select 1 from public.friend_requests where id=f.id) or exists(select 1 from public.friend_request_players()) then raise exception 'outsider read'; end if;
 begin perform public.respond_friend(f.id,true); raise exception 'outsider response accepted';
 exception when sqlstate 'P0001' then null; end;
 perform set_config('request.jwt.claim.sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',true);
 if (select count(*) from public.friend_requests where id=f.id)<>1 then raise exception 'recipient read'; end if;
 begin perform public.request_friend('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1');
  raise exception 'reverse duplicate accepted'; exception when sqlstate 'P0001' then null; end;
 perform public.respond_friend(f.id,false);
 if exists(select 1 from public.friend_contact('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',g))
 then raise exception 'rejected contact'; end if;
 perform set_config('request.jwt.claim.sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',true);
 f:=public.request_friend('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2');
 perform set_config('request.jwt.claim.sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',true);
 perform public.respond_friend(f.id,true);
 if (select count(*) from public.friend_contact('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',g))<>0
 then raise exception 'self contact'; end if;
 perform set_config('request.jwt.claim.sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',true);
 if (select count(*) from public.friend_contact('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',g)
     where ign='SecretIGN' and game_id_private='SecretGameID' and discord='secret#123')<>1
 then raise exception 'approved contact'; end if;
 if (select count(*) from public.friend_profile('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2')
     where display_name is not null and game_name='Mobile Legends: Bang Bang'
       and ign='SecretIGN' and game_id_private='SecretGameID' and discord='secret#123')<>1
 then raise exception 'approved friend profile'; end if;
 if exists(select 1 from public.friend_contact('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2','22222222-2222-4222-8222-222222222222'))
 then raise exception 'wrong game'; end if;
 perform public.remove_friend('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2');
 if exists(select 1 from public.friend_contact('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',g))
 then raise exception 'removed contact'; end if;
 f:=public.request_friend('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2');
 perform set_config('request.jwt.claim.sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',true);
 perform public.respond_friend(f.id,true);
 insert into public.blocks(blocker_id,blocked_id) values(auth.uid(),'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1');
 if exists(select 1 from public.friend_contact('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',g))
 or exists(select 1 from public.friend_requests where id=f.id) then raise exception 'block did not revoke access'; end if;
 perform set_config('request.jwt.claim.sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',true);
 if exists(select 1 from public.friend_contact('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',g))
 then raise exception 'reverse block contact'; end if;
end $$;
-- Contact visibility and account gates must remain live after acceptance.
reset role;
delete from public.blocks where blocker_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2';
update public.profiles set visibility='hidden' where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2';
set local role authenticated;
select set_config('request.jwt.claim.sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',true);
do $$ declare g uuid:='11111111-1111-4111-8111-111111111111'; begin
if exists(select 1 from public.friend_contact('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',g))
then raise exception 'hidden profile contact'; end if;
end $$;
reset role;
update public.profiles set visibility='public' where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2';
update public.game_profiles set visibility='hidden' where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2';
set local role authenticated;
do $$ begin
if exists(select 1 from public.friend_contact('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2','11111111-1111-4111-8111-111111111111'))
then raise exception 'hidden game profile contact'; end if;
end $$;
reset role;
update public.game_profiles set visibility='public' where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2';
update public.profiles set account_status='restricted' where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2';
set local role authenticated;
do $$ begin
if exists(select 1 from public.friend_contact('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2','11111111-1111-4111-8111-111111111111'))
then raise exception 'restricted contact'; end if;
end $$;
reset role;
rollback;
