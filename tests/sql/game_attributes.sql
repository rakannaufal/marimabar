-- Runs after migrations + seed, isolated transaction recommended.
-- Owners may create multiple profiles for one game and delete only their own profile.
do $$ declare v_game uuid; v_user uuid := 'ffffffff-ffff-4fff-8fff-ffffffffffff'; begin
 select id into v_game from public.games where slug='mlbb';
 insert into auth.users(id,raw_user_meta_data,email_confirmed_at) values(v_user,'{"adult_declared":true}',now());
 if exists(select 1 from pg_constraint where conrelid='public.game_profiles'::regclass and contype='u'
   and pg_get_constraintdef(oid) like 'UNIQUE (user_id, game_id)%') then
   raise exception 'One-profile-per-game constraint still active'; end if;
 if not has_table_privilege('authenticated','public.game_profiles','DELETE') then
   raise exception 'Authenticated role cannot delete game profiles'; end if;
 if not exists(select 1 from pg_policies where schemaname='public' and tablename='game_profiles'
   and cmd='DELETE' and policyname='delete_game_profile') then
   raise exception 'Owner delete policy missing'; end if;
 insert into public.game_profiles(user_id,game_id,ign) values
   (v_user,v_game,'duplicate-profile-one'),
   (v_user,v_game,'duplicate-profile-two');
 if (select count(*) from public.game_profiles where user_id=v_user and game_id=v_game)<>2 then
   raise exception 'Multiple profiles for the same game rejected'; end if;
 delete from auth.users where id=v_user;
end $$;
do $$ declare n integer; begin
 select count(*) into n from public.game_attribute_definitions;
 if n<>69 then raise exception 'Expected 69 definitions, got %',n; end if;
 if exists(select 1 from public.game_attribute_definitions where key in
  ('mabar_rating','successful_mabar_count','account_verified','last_active')) then
  raise exception 'Untrusted global attribute exposed'; end if;
end $$;
-- MLBB stars depend on selected Glory/Immortal rank; other games have no star input.
do $$ declare n integer; begin
 select count(*) into n from public.game_attribute_definitions d join public.games g on g.id=d.game_id
 where g.slug='mlbb' and d.key='rank_stars' and d.value_type='number'
   and d.range_min=50 and d.range_max=1000000 and d.unit='bintang';
 if n<>1 then raise exception 'MLBB star definition missing'; end if;
end $$;
-- Reject mismatched rank/star combinations at the database boundary.
do $$ declare v_user uuid := 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'; v_game uuid; begin
 select id into v_game from public.games where slug='mlbb';
 insert into auth.users(id,raw_user_meta_data) values(v_user,'{"adult_declared":true}');
 insert into public.game_profiles(user_id,game_id,ign,attributes)
 values(v_user,v_game,'star-test','{"rank_current":"Mythic Glory","rank_stars":75}');
 begin
  update public.game_profiles set attributes='{"rank_current":"Epic","rank_stars":75}' where user_id=v_user;
  raise exception 'Stars accepted for Epic';
 exception when check_violation then null; end;
 begin
  update public.game_profiles set attributes='{"rank_current":"Mythic Immortal","rank_stars":99}' where user_id=v_user;
  raise exception 'Immortal accepted below 100';
 exception when check_violation then null; end;
 update public.game_profiles set attributes='{"rank_current":"Mythic Immortal","rank_stars":100}' where user_id=v_user;
 delete from public.game_profiles where user_id=v_user;
 delete from auth.users where id=v_user;
end $$;
-- Canonical taxonomy; legacy keys/options remain queryable.
do $$ declare n int; begin
 select count(*) into n from public.game_attribute_definitions d join public.games g on g.id=d.game_id
 where (g.slug='mlbb' and d.key in ('position_main','position_secondary','play_goal'))
    or (g.slug='pubg-mobile' and d.key in ('squad_role_main','queue_mode','play_goal'))
    or (g.slug='free-fire' and d.key in ('ranked_mode','rank_br','rank_cs','team_role_main','play_goal'))
    or (g.slug='valorant' and d.key in ('agent_role_main','game_mode','play_goal'));
 if n<>14 then raise exception 'Canonical definitions missing: %',n; end if;
 if not exists(select 1 from pg_trigger where tgname='seed_canonical_game_attribute_definitions' and not tgisinternal)
 then raise exception 'Future-game canonical seed trigger missing'; end if;
 if (select count(*) from public.game_attribute_definitions d join public.games g on g.id=d.game_id
     where g.slug in ('mlbb','pubg-mobile','free-fire','valorant') and d.key in ('active_hours','voice_chat'))<>8
 then raise exception 'Common existing definitions missing'; end if;
 if not exists(select 1 from public.game_attribute_definitions d join public.games g on g.id=d.game_id
   where g.slug='mlbb' and d.key='position_secondary' and d.value_type='multi_select'
   and d.options='["EXP Lane","Jungle","Mid Lane","Gold Lane","Roam"]'::jsonb)
 or not exists(select 1 from public.game_attribute_definitions d join public.games g on g.id=d.game_id
   where g.slug='pubg-mobile' and d.key='squad_role_main' and d.value_type='single_select'
   and d.options='["IGL","Entry","Support","Scout","Sniper","Driver"]'::jsonb)
 or not exists(select 1 from public.game_attribute_definitions d join public.games g on g.id=d.game_id
   where g.slug='pubg-mobile' and d.key='queue_mode' and d.value_type='single_select'
   and d.options='["Classic Ranked","Classic Unranked"]'::jsonb)
 or not exists(select 1 from public.game_attribute_definitions d join public.games g on g.id=d.game_id
   where g.slug='free-fire' and d.key='team_role_main' and d.value_type='single_select'
   and d.options='["IGL","Rusher","Support","Sniper"]'::jsonb)
 or not exists(select 1 from public.game_attribute_definitions d join public.games g on g.id=d.game_id
   where g.slug='valorant' and d.key='agent_role_main' and d.value_type='single_select'
   and d.options='["Duelist","Initiator","Controller","Sentinel"]'::jsonb)
 or not exists(select 1 from public.game_attribute_definitions d join public.games g on g.id=d.game_id
   where g.slug='valorant' and d.key='game_mode' and d.value_type='single_select'
   and d.options='["Competitive","Unrated","Swiftplay"]'::jsonb)
 or (select count(*) from public.game_attribute_definitions d join public.games g on g.id=d.game_id
   where g.slug in ('mlbb','pubg-mobile','free-fire','valorant') and d.key='play_goal'
   and d.value_type='single_select' and d.options='["Santai","Naik Rank","Latihan Tim"]'::jsonb)<>4
 then raise exception 'Canonical role/mode/goal choices mismatch'; end if;
 if (select count(*) from public.game_attribute_definitions d join public.games g on g.id=d.game_id
   where g.slug='free-fire' and d.key in ('rank_br','rank_cs') and d.value_type='slider_tier'
   and d.options='["Bronze","Silver","Gold","Platinum","Diamond","Heroic","Master","Grandmaster"]'::jsonb)<>2
 then raise exception 'FF rank choices mismatch'; end if;
 if not exists(select 1 from public.game_attribute_definitions d join public.games g on g.id=d.game_id
   where g.slug='mlbb' and d.key='position_main' and d.value_type='single_select'
   and d.options='["EXP Lane","Jungle","Mid Lane","Gold Lane","Roam"]'::jsonb)
 or not exists(select 1 from public.game_attribute_definitions d join public.games g on g.id=d.game_id
   where g.slug='free-fire' and d.key='ranked_mode' and d.options='["Battle Royale Ranked","Clash Squad Ranked"]'::jsonb)
 then raise exception 'Canonical choices mismatch'; end if;
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
 if (select public.public_profile_game_attributes((select id from public.game_profiles
   where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'))) <>
   '{"voice_chat":"Aktif - Discord","hero_pool":["Gusion"]}'::jsonb then
   raise exception 'Legacy or untrusted attributes exposed publicly'; end if;
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
-- Canonical roles/ranks and fail-closed mode-specific filters.
update public.game_profiles set attributes=attributes || '{"position_main":"Roam","position_secondary":["Jungle","Mid Lane"],"play_goal":"Naik Rank"}'::jsonb
 where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
update public.game_profiles set attributes=attributes || '{"squad_role_main":"Scout","queue_mode":"Classic Ranked"}'::jsonb
 where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
insert into auth.users(id,raw_user_meta_data) values
 ('cccccccc-cccc-4ccc-8ccc-cccccccccccc','{"adult_declared":true}'),
 ('dddddddd-dddd-4ddd-8ddd-dddddddddddd','{"adult_declared":true}');
insert into public.game_profiles(user_id,game_id,ign,attributes) values
 ('cccccccc-cccc-4ccc-8ccc-cccccccccccc','33333333-3333-4333-8333-333333333333','ff',
 '{"ranked_mode":"Clash Squad Ranked","rank_cs":"Heroic","team_role_main":"Rusher","active_hours":["Malam"],"voice_chat":true}'),
 ('dddddddd-dddd-4ddd-8ddd-dddddddddddd','44444444-4444-4444-8444-444444444444','val',
 '{"rank_current":"Gold 1-3","agent_role_main":"Initiator","game_mode":"Competitive"}');
do $$ declare r record; n int; begin
 select rank,role into r from public.search_game_profiles_by_attributes('mlbb','{"position_main":"Roam","position_secondary":["Jungle"]}');
 if r.rank is distinct from 'Epic' or r.role is distinct from 'Roam' then raise exception 'MLBB canonical role/rank failed: %',r; end if;
 if (select attributes->>'position_main' from public.search_game_profiles_by_attributes_with_public_facts('mlbb','{"position_main":"Roam"}')) is not null
 or (select attributes->'position_secondary' from public.search_game_profiles_by_attributes_with_public_facts('mlbb','{"position_main":"Roam"}')) <>
    '["Jungle","Mid Lane"]'::jsonb then raise exception 'Search public fact projection failed'; end if;
 select rank,role into r from public.public_profile_detail((select id from public.game_profiles
   where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'));
 if r.rank is distinct from 'Epic' or r.role is distinct from 'Roam' then raise exception 'MLBB detail canonical role/rank failed: %',r; end if;
 if (select public.public_profile_game_attributes((select id from public.game_profiles
   where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'))) -> 'position_secondary' <>
   '["Jungle","Mid Lane"]'::jsonb then raise exception 'Public backup position missing'; end if;
 update public.game_profiles set visibility='hidden' where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
 if public.public_profile_game_attributes((select id from public.game_profiles
   where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa')) is not null then
   raise exception 'Hidden profile attributes exposed'; end if;
 update public.game_profiles set visibility='public' where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
 select rank,role into r from public.search_game_profiles_by_attributes('pubg-mobile','{"squad_role_main":"Scout","queue_mode":"Classic Ranked"}');
 if r.role<>'Scout' then raise exception 'PUBG canonical role failed'; end if;
 select rank,role into r from public.search_game_profiles_by_attributes('free-fire','{"ranked_mode":"Clash Squad Ranked","rank_cs":{"min":"Diamond"},"team_role_main":"Rusher"}');
 if r.rank<>'Heroic' or r.role<>'Rusher' then raise exception 'FF canonical role/rank failed: %',r; end if;
 select rank,role into r from public.public_profile_detail((select id from public.game_profiles
   where user_id='cccccccc-cccc-4ccc-8ccc-cccccccccccc'));
 if r.rank<>'Heroic' or r.role<>'Rusher' then raise exception 'FF detail canonical role/rank failed: %',r; end if;
 select count(*) into n from public.search_game_profiles_by_attributes('free-fire','{"rank_br":{"min":"Bronze"}}');
 if n<>0 then raise exception 'FF rank cross-mode leak'; end if;
 select rank,role into r from public.search_game_profiles_by_attributes('valorant','{"game_mode":"Competitive","agent_role_main":"Initiator"}');
 if r.rank<>'Gold 1-3' or r.role<>'Initiator' then raise exception 'Valorant canonical role/rank failed: %',r; end if;
end $$;
do $$ begin
 begin
  update public.game_profiles set attributes=attributes || '{"position_secondary":["Jungle","Mid Lane","Roam"]}'::jsonb
   where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  raise exception 'Three secondary positions accepted';
 exception when check_violation then null; end;
 begin
  update public.game_profiles set attributes=attributes || '{"position_secondary":["Roam"]}'::jsonb
   where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  raise exception 'Primary position accepted as secondary';
 exception when check_violation then null; end;
 begin
  update public.game_profiles set attributes=attributes || '{"position_main":"Tank"}'::jsonb
   where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  raise exception 'Legacy hero role accepted as lane';
 exception when check_violation then null; end;
 update public.game_profiles set attributes=attributes || '{"rank_br":"Diamond"}'::jsonb
  where user_id='cccccccc-cccc-4ccc-8ccc-cccccccccccc';
 if not exists(select 1 from public.game_profiles where user_id='cccccccc-cccc-4ccc-8ccc-cccccccccccc'
   and attributes->>'rank_cs'='Heroic' and attributes->>'rank_br'='Diamond') then
   raise exception 'Independent FF ranks not preserved'; end if;
 update public.game_profiles set attributes=attributes || '{"ranked_mode":"Battle Royale Ranked"}'::jsonb
  where user_id='cccccccc-cccc-4ccc-8ccc-cccccccccccc';
 if (select rank from public.public_profile_detail((select id from public.game_profiles
   where user_id='cccccccc-cccc-4ccc-8ccc-cccccccccccc'))) is distinct from 'Diamond'
 then raise exception 'FF detail preferred BR rank failed'; end if;
 if (select count(*) from public.search_game_profiles_by_attributes('free-fire',
   '{"rank_br":{"min":"Diamond"}}'))<>1
 then raise exception 'FF BR rank search failed'; end if;
 if (select count(*) from public.search_game_profiles_by_attributes('free-fire',
   '{"rank_cs":{"min":"Heroic"}}'))<>0
 then raise exception 'FF CS rank leaked under BR preference'; end if;
 begin
  perform public.search_game_profiles_by_attributes('free-fire','{"ranked_mode":"Clash Squad Ranked","rank_br":{"min":"Bronze"}}');
  raise exception 'Mismatched rank filter accepted';
 exception when invalid_parameter_value then null; end;
 begin
  perform public.search_game_profiles_by_attributes('free-fire',
   '{"rank_br":{"min":"Bronze"},"rank_cs":{"min":"Bronze"}}');
  raise exception 'Two FF rank filters accepted';
 exception when invalid_parameter_value then null; end;
 begin
  perform public.search_game_profiles_by_attributes('mlbb','{"position_secondary":["Jungle","Mid Lane","Roam"]}');
  raise exception 'Three-position search accepted';
 exception when invalid_parameter_value then null; end;
 begin
  perform public.search_game_profiles_by_attributes('free-fire','{"rank_br":{"min":"Grandmaster","max":"Bronze"}}');
  raise exception 'Reversed FF rank accepted';
 exception when invalid_parameter_value then null; end;
end $$;
-- Hero/agent catalog: exact ordered choices, legacy preservation, bounded new writes.
do $$ declare
 heroes jsonb := '["Akai","Alice","Atlas","Barats","Baxia","Belerick","Edith","Franco","Gatotkaca","Grock","Hylos","Johnson","Khufra","Lolita","Minotaur","Tigreal","Uranus","Aldous","Alpha","Alucard","Argus","Arlott","Badang","Balmond","Bane","Chou","Cici","Dyrroth","Freya","Guinevere","Hilda","Jawhead","Julian","Kaja","Kalea","Khaled","Lapu-Lapu","Leomord","Martis","Masha","Minsitthar","Paquito","Phoveus","Ruby","Silvanna","Sora","Sun","Terizla","Thamuz","X.Borg","Yin","Yu Zhong","Zilong","Aamon","Benedetta","Fanny","Gusion","Hanzo","Hayabusa","Helcurt","Hirara","Joy","Karina","Lancelot","Ling","Natalia","Nolan","Saber","Selena","Suyou","Yi Sun-shin","Aurora","Cecilion","Chang''e","Cyclops","Eudora","Faramis","Gord","Harith","Harley","Kadita","Kagura","Lylia","Lunox","Luo Yi","Modess","Nana","Odette","Parsha (Pharsa)","Vale","Valir","Vexana","Xavier","Yve","Zhask","Zhuxin","Zetian","Beatrix","Brody","Bruno","Claude","Clint","Granger","Hanabi","Irithel","Ixia","Karrie","Kimmy","Layla","Lesley","Melissa","Miya","Moskov","Natan","Obsidia","Popol & Kupa","Roger","Wanwan","Angela","Carmilla","Chip","Diggie","Estes","Floryn","Marcel","Mathilda","Rafaela"]'::jsonb;
 agents jsonb := '["Iso","Jett","Neon","Phoenix","Raze","Reyna","Waylay","Yoru","Breach","Fade","Gekko","KAY/O","Skye","Sova","Tejo","Astra","Brimstone","Clove","Harbor","Miks","Omen","Viper","Chamber","Cypher","Deadlock","Killjoy","Sage","Veto","Vyse"]'::jsonb;
 characters jsonb := '["A124","Alok","Andrew \"Fierce\"","Chrono","Clu","Dimitri","Homer","Ignis","Iris","K","Kairos","Kenta","Lila","Orion","Santino","Skyler","Tatsuya","Wukong","Xayne","Ryden","Steffie","Alvaro","Antonio","Ford","Hayato","Jai","Joseph","Jota","J.Biebs","Kla","Luqueta","Maro","Maxim","Miguel","Nairi","Rafael","Shirou","Thiva","Wolfrahh","A-Patroa","Caroline","Dasha","Suzy","Kapella","Kelly","Laura","Luna","Misha","Moco","Nikita","Notora","Olivia","Paloma","Sonia","Sonia Awakened","Shani"]'::jsonb;
 definition public.game_attribute_definitions;
begin
 select ad.* into definition from public.game_attribute_definitions ad join public.games g on g.id=ad.game_id where g.slug='mlbb' and ad.key='hero_pool';
 if definition.options is distinct from heroes or definition.value_type<>'tag_multi' or definition.filter_type<>'tag_select' then raise exception 'MLBB hero options mismatch'; end if;
 select ad.* into definition from public.game_attribute_definitions ad join public.games g on g.id=ad.game_id where g.slug='valorant' and ad.key='main_agent';
 if definition.options is distinct from agents or definition.value_type<>'tag_multi' or definition.filter_type<>'tag_select' then raise exception 'Valorant agent options mismatch'; end if;
 select ad.* into definition from public.game_attribute_definitions ad join public.games g on g.id=ad.game_id where g.slug='free-fire' and ad.key='main_character';
 if definition.options is distinct from characters or definition.value_type<>'tag_multi' or definition.filter_type<>'tag_select' then raise exception 'Free Fire character options mismatch'; end if;
 update public.game_profiles set attributes=attributes || '{"main_character":["Alok","Kelly","Moco"]}'::jsonb
 where user_id='cccccccc-cccc-4ccc-8ccc-cccccccccccc';
 begin
  update public.game_profiles set attributes=attributes || '{"main_character":["Alok","Kelly","Moco","Chrono"]}'::jsonb
  where user_id='cccccccc-cccc-4ccc-8ccc-cccccccccccc';
  raise exception 'Four Free Fire characters accepted';
 exception when check_violation then null; end;
 begin
  update public.game_profiles set attributes=attributes || '{"main_character":["Unknown"]}'::jsonb
  where user_id='cccccccc-cccc-4ccc-8ccc-cccccccccccc';
  raise exception 'Unknown Free Fire character accepted';
 exception when check_violation then null; end;
 update public.game_profiles set attributes=attributes || '{"main_agent":["Jett","KAY/O","Vyse"]}'::jsonb
 where user_id='dddddddd-dddd-4ddd-8ddd-dddddddddddd';
 begin
  update public.game_profiles set attributes=attributes || '{"main_agent":["Jett","Neon","Raze","Yoru"]}'::jsonb
  where user_id='dddddddd-dddd-4ddd-8ddd-dddddddddddd';
  raise exception 'Four agents accepted';
 exception when check_violation then null; end;
 begin
  update public.game_profiles set attributes=attributes || '{"main_agent":["Unknown"]}'::jsonb
  where user_id='dddddddd-dddd-4ddd-8ddd-dddddddddddd';
  raise exception 'Unknown agent accepted';
 exception when check_violation then null; end;
 update public.game_profiles set attributes=attributes || '{"hero_pool":["Akai","Gusion","Zetian"]}'::jsonb
 where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
 begin
  update public.game_profiles set attributes=attributes || '{"hero_pool":["Akai","Gusion","Zetian","Angela"]}'::jsonb
  where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  raise exception 'Four heroes accepted';
 exception when check_violation then null; end;
 begin
  update public.game_profiles set attributes=attributes || '{"hero_pool":["Unknown"]}'::jsonb
  where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  raise exception 'Unknown hero accepted';
 exception when check_violation then null; end;
 -- Test future games: new games with slug mlbb or valorant seed flattened options.
 update public.games set slug='mlbb-old' where id='11111111-1111-4111-8111-111111111111';
 insert into public.games(id,slug,name) values('99999999-9999-4999-8999-999999999991','mlbb','Second MLBB');
 if not exists(select 1 from public.game_attribute_definitions where game_id='99999999-9999-4999-8999-999999999991' and key='hero_pool' and options=heroes)
 then raise exception 'Future MLBB hero seed mismatch'; end if;
 delete from public.game_attribute_definitions where game_id='99999999-9999-4999-8999-999999999991';
 delete from public.games where id='99999999-9999-4999-8999-999999999991';
 update public.games set slug='mlbb' where id='11111111-1111-4111-8111-111111111111';

 update public.games set slug='valorant-old' where id='44444444-4444-4444-8444-444444444444';
 insert into public.games(id,slug,name) values('99999999-9999-4999-8999-999999999992','valorant','Second Valorant');
 if not exists(select 1 from public.game_attribute_definitions where game_id='99999999-9999-4999-8999-999999999992' and key='main_agent' and options=agents)
 then raise exception 'Future Valorant agent seed mismatch'; end if;
 delete from public.game_attribute_definitions where game_id='99999999-9999-4999-8999-999999999992';
 delete from public.games where id='99999999-9999-4999-8999-999999999992';
 update public.games set slug='valorant' where id='44444444-4444-4444-8444-444444444444';
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
