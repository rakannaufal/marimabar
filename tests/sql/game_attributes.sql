-- Runs after migrations + seed, isolated transaction recommended.
do $$ declare n integer; begin
 select count(*) into n from public.game_attribute_definitions;
 if n<>54 then raise exception 'Expected 54 definitions, got %',n; end if;
 if exists(select 1 from public.game_attribute_definitions where key in
  ('mabar_rating','successful_mabar_count','account_verified','last_active')) then
  raise exception 'Untrusted global attribute exposed'; end if;
end $$;
insert into auth.users(id,raw_user_meta_data) values
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','{"adult_declared":true}');
update public.profiles set adult_declared_at=now(),languages=array['id','en']
 where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
insert into public.game_profiles(user_id,game_id,ign,attributes) values
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','11111111-1111-4111-8111-111111111111','tester',
 '{"rank_current":"Epic","role":["Tank","Mage"],"win_rate":52,"voice_chat":"Aktif - Discord","hero_pool":["Gusion"]}');
do $$ declare n integer; begin
 select count(*) into n from public.search_game_profiles_by_attributes('mlbb',
 '{"rank_current":{"min":"Grandmaster","max":"Legend"},"role":["Mage"],"win_rate":{"min":50},"voice_chat":"Aktif - Discord","hero_pool":["Gusion"],"language":["en"]}');
 if n<>1 then raise exception 'Combined search failed'; end if;
 select count(*) into n from public.search_game_profiles_by_attributes('mlbb','{"win_rate":{"min":53}}');
 if n<>0 then raise exception 'Numeric bound failed'; end if;
 select count(*) into n from public.search_game_profiles_by_attributes('pubg-mobile','{}');
 if n<>0 then raise exception 'Cross-game search leaked'; end if;
end $$;
do $$ begin
 begin
  update public.game_profiles set attributes='{"win_rate":101}'
   where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  raise exception 'Out-of-range accepted';
 exception when check_violation then null; end;
 begin
  update public.game_profiles set attributes='{"role":["Not a role"]}'
   where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  raise exception 'Invalid option accepted';
 exception when check_violation then null; end;
 begin
  update public.game_profiles set attributes='{"hero_pool":["x","x"]}'
   where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  raise exception 'Duplicate tag accepted';
 exception when check_violation then null; end;
 begin
  update public.game_attribute_definitions set options='["Warrior"]'
   where game_id='11111111-1111-4111-8111-111111111111' and key='rank_current';
  raise exception 'Destructive option edit accepted';
 exception when check_violation then null; end;
 begin
  perform public.search_game_profiles_by_attributes('mlbb','{"bogus":true}');
  raise exception 'Unknown filter accepted';
 exception when invalid_parameter_value then null; end;
 begin
  perform public.search_game_profiles_by_attributes('mlbb','{"rank_current":{"min":"Legend","max":"Epic"}}');
  raise exception 'Reversed tier range accepted';
 exception when invalid_parameter_value then null; end;
end $$;
insert into auth.users(id,raw_user_meta_data) values
 ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','{"adult_declared":true}');
insert into public.game_profiles(user_id,game_id,ign,attributes) values
 ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','22222222-2222-4222-8222-222222222222','pubg',
 '{"voice_chat":true,"kd_ratio":2.5,"squad_role":["Sniper"]}');
do $$ declare n integer; begin
 select count(*) into n from public.search_game_profiles_by_attributes('pubg-mobile',
 '{"voice_chat":true,"kd_ratio":{"min":2.0,"max":3},"squad_role":["Sniper"]}');
 if n<>1 then raise exception 'Boolean/decimal search failed'; end if;
end $$; 
-- RLS checks under caller role, not table-owner bypass.
set local role authenticated;
do $$ begin
 begin
  insert into public.game_attribute_definitions(game_id,key,label,category,value_type,filter_type)
  values('11111111-1111-4111-8111-111111111111','hijack','Hijack','kompetensi','boolean','toggle');
  raise exception 'Non-admin definition insert accepted';
 exception when insufficient_privilege then null; end;
 begin
  update public.game_attribute_definitions set label='Hijack'
   where game_id='11111111-1111-4111-8111-111111111111' and key='rank_current';
  if found then raise exception 'Non-admin definition update accepted'; end if;
 exception when insufficient_privilege then null; end;
end $$;
reset role;
-- Runtime privileges, not only policy text.
do $$ begin
 if has_table_privilege('anon','public.game_attribute_definitions','INSERT')
 or has_table_privilege('authenticated','public.game_attribute_definitions','DELETE')
 or has_function_privilege('anon','private.attribute_value_valid(public.game_attribute_definitions,jsonb)','EXECUTE') then
 raise exception 'Definition privilege leak'; end if;
end $$;
