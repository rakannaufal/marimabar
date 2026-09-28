-- Add a curated Free Fire character catalog while preserving unchanged historical free-form values.
create or replace function private.hero_agent_options(p_slug text) returns jsonb language sql immutable set search_path = '' as $$
 select case p_slug
 when 'mlbb' then '["Akai","Alice","Atlas","Barats","Baxia","Belerick","Edith","Franco","Gatotkaca","Grock","Hylos","Johnson","Khufra","Lolita","Minotaur","Tigreal","Uranus","Aldous","Alpha","Alucard","Argus","Arlott","Badang","Balmond","Bane","Chou","Cici","Dyrroth","Freya","Guinevere","Hilda","Jawhead","Julian","Kaja","Kalea","Khaled","Lapu-Lapu","Leomord","Martis","Masha","Minsitthar","Paquito","Phoveus","Ruby","Silvanna","Sora","Sun","Terizla","Thamuz","X.Borg","Yin","Yu Zhong","Zilong","Aamon","Benedetta","Fanny","Gusion","Hanzo","Hayabusa","Helcurt","Hirara","Joy","Karina","Lancelot","Ling","Natalia","Nolan","Saber","Selena","Suyou","Yi Sun-shin","Aurora","Cecilion","Chang''e","Cyclops","Eudora","Faramis","Gord","Harith","Harley","Kadita","Kagura","Lylia","Lunox","Luo Yi","Modess","Nana","Odette","Parsha (Pharsa)","Vale","Valir","Vexana","Xavier","Yve","Zhask","Zhuxin","Zetian","Beatrix","Brody","Bruno","Claude","Clint","Granger","Hanabi","Irithel","Ixia","Karrie","Kimmy","Layla","Lesley","Melissa","Miya","Moskov","Natan","Obsidia","Popol & Kupa","Roger","Wanwan","Angela","Carmilla","Chip","Diggie","Estes","Floryn","Marcel","Mathilda","Rafaela"]'::jsonb
 when 'valorant' then '["Iso","Jett","Neon","Phoenix","Raze","Reyna","Waylay","Yoru","Breach","Fade","Gekko","KAY/O","Skye","Sova","Tejo","Astra","Brimstone","Clove","Harbor","Miks","Omen","Viper","Chamber","Cypher","Deadlock","Killjoy","Sage","Veto","Vyse"]'::jsonb
 when 'free-fire' then '["A124","Alok","Andrew \"Fierce\"","Chrono","Clu","Dimitri","Homer","Ignis","Iris","K","Kairos","Kenta","Lila","Orion","Santino","Skyler","Tatsuya","Wukong","Xayne","Ryden","Steffie","Alvaro","Antonio","Ford","Hayato","Jai","Joseph","Jota","J.Biebs","Kla","Luqueta","Maro","Maxim","Miguel","Nairi","Rafael","Shirou","Thiva","Wolfrahh","A-Patroa","Caroline","Dasha","Suzy","Kapella","Kelly","Laura","Luna","Misha","Moco","Nikita","Notora","Olivia","Paloma","Sonia","Sonia Awakened","Shani"]'::jsonb
 end
$$;

create or replace function private.validate_attribute_definition() returns trigger language plpgsql security definer set search_path = '' as $$
declare item jsonb; seen text[] := array[]::text[];
begin
 if tg_op='UPDATE' and (new.game_id,new.key) is distinct from (old.game_id,old.key) then
   raise exception 'Game/key atribut tidak dapat diganti' using errcode='23514'; end if;
 for item in select value from jsonb_array_elements(new.options) loop
   if jsonb_typeof(item)<>'string' or char_length(item #>> '{}') not between 1 and 80
     or item #>> '{}' = any(seen) then
     raise exception 'Opsi atribut tidak valid' using errcode='23514'; end if;
   seen := array_append(seen,item #>> '{}');
 end loop;
 if tg_op='UPDATE' and (new.value_type,new.options,new.range_min,new.range_max,new.active)
   is distinct from (old.value_type,old.options,old.range_min,old.range_max,old.active)
   and exists (select 1 from public.game_profiles gp where gp.game_id=new.game_id
     and gp.attributes ? new.key and not private.attribute_value_valid(new,gp.attributes->new.key)
     and not (new.key in ('hero_pool','main_agent','main_character') and old.options='[]'::jsonb
       and new.value_type='tag_multi' and new.active and
       new.options=private.hero_agent_options((select g.slug from public.games g where g.id=new.game_id)))) then
   raise exception 'Definisi tidak cocok dengan profil tersimpan' using errcode='23514'; end if;
 return new;
end $$;

create or replace function private.validate_game_profile() returns trigger language plpgsql security definer set search_path = '' as $$
declare v_slug text; v_key text; v_value jsonb; d public.game_attribute_definitions;
begin
 if tg_op='UPDATE' and (new.user_id<>old.user_id or new.game_id<>old.game_id) then raise exception 'Pemilik/game tidak dapat diganti'; end if;
 if tg_op='INSERT' or new.ign is distinct from old.ign or new.primary_rank_option_id is distinct from old.primary_rank_option_id then
   select slug into v_slug from public.games where id=new.game_id and active;
   if v_slug is null then raise exception 'Game tidak aktif'; end if;
 end if;
 perform private.check_option(new.region_option_id,new.game_id,'region');
 perform private.check_option(new.server_option_id,new.game_id,'server');
 perform private.check_option(new.primary_rank_option_id,new.game_id,'rank');
 perform private.check_option(new.primary_rank_mode_option_id,new.game_id,'mode');
 perform private.check_option(new.primary_role_option_id,new.game_id,'role');
 if new.primary_rank_option_id is not null and exists(select 1 from public.game_catalog_options o where o.id=new.primary_rank_option_id and o.rank_mode_option_id is distinct from new.primary_rank_mode_option_id) then raise exception 'Rank dan mode tidak cocok'; end if;
 if jsonb_typeof(new.attributes)<>'object' or octet_length(new.attributes::text)>4096 then raise exception 'Atribut tidak valid' using errcode='23514'; end if;
 for v_key,v_value in select key,value from jsonb_each(new.attributes) loop
   select * into d from public.game_attribute_definitions where game_id=new.game_id and key=v_key for share;
   if found then
     if v_key in ('hero_pool','main_agent','main_character') and tg_op='UPDATE' and old.attributes->v_key is not distinct from v_value then
       null;
     elsif not d.active or not private.attribute_value_valid(d,v_value)
       or (v_key in ('hero_pool','main_agent','main_character') and (jsonb_typeof(v_value)<>'array' or jsonb_array_length(v_value)>3)) then
       raise exception 'Atribut tidak diizinkan: %',v_key using errcode='23514'; end if;
   elsif v_key in ('stars','tier','perspective','team_size','play_goal') then
     if tg_op='UPDATE' and old.attributes->v_key is not distinct from v_value then continue; end if;
     if jsonb_typeof(v_value)<>'string' or char_length(v_value #>> '{}')>120 then raise exception 'Atribut lama tidak valid' using errcode='23514'; end if;
   else raise exception 'Atribut tidak diizinkan: %',v_key using errcode='23514';
   end if;
 end loop;
 new.updated_at=now();
 if tg_op='INSERT' or (new.ign,new.game_id_private,new.region_option_id,new.server_option_id,new.primary_rank_option_id,new.primary_rank_mode_option_id,new.primary_role_option_id,new.play_goal,new.availability_status,new.attributes) is distinct from (old.ign,old.game_id_private,old.region_option_id,old.server_option_id,old.primary_rank_option_id,old.primary_rank_mode_option_id,old.primary_role_option_id,old.play_goal,old.availability_status,old.attributes) then new.data_updated_at=now(); else new.data_updated_at=old.data_updated_at; end if;
 return new;
end $$;

create or replace function private.seed_hero_agent_options() returns trigger language plpgsql security definer set search_path = '' as $$
begin
 if new.slug in ('mlbb','valorant','free-fire') then
   update public.game_attribute_definitions d set options=private.hero_agent_options(new.slug)
   where d.game_id=new.id and d.key=case new.slug when 'mlbb' then 'hero_pool' when 'valorant' then 'main_agent' else 'main_character' end;
 end if;
 return new;
end $$;

update public.game_attribute_definitions d set options=private.hero_agent_options(g.slug)
from public.games g where d.game_id=g.id and g.slug='free-fire' and d.key='main_character';
