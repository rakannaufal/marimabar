-- Dynamic attributes. Existing catalog options and user profile JSON are never rewritten.
create table public.game_attribute_definitions (
 game_id uuid not null references public.games(id),
 key text not null check (key ~ '^[a-z][a-z0-9_]{1,63}$'
   and key not in ('mabar_rating','successful_mabar_count','account_verified','last_active','language')),
 label text not null check (char_length(trim(label)) between 1 and 100),
 category text not null check (category in ('kompetensi','gaya_main','reputasi')),
 value_type text not null check (value_type in ('slider_tier','multi_select','tag_multi','single_select','boolean_with_option','boolean','number','decimal')),
 filter_type text not null check (filter_type in ('range_slider','range_min','checkbox_group','tag_select','radio','dropdown','toggle_dropdown','toggle')),
 options jsonb not null default '[]'::jsonb,
 range_min numeric, range_max numeric,
 unit text check (unit is null or char_length(unit) between 1 and 20),
 sort_order int not null default 0,
 active bool not null default true,
 primary key (game_id,key),
 check (range_min is null or range_max is null or range_min <= range_max),
 check (range_min is null or range_min >= 0),
 check (range_max is null or range_max between 0 and 1000000),
 check (value_type <> 'number' or
   (range_min is null or range_min=trunc(range_min)) and
   (range_max is null or range_max=trunc(range_max))),
 check (jsonb_typeof(options)='array' and jsonb_array_length(options)<=200),
 check (case
   when value_type in ('slider_tier','multi_select','single_select','boolean_with_option') then jsonb_array_length(options)>0
   when value_type in ('number','decimal','boolean') then options='[]'::jsonb
   else true end),
 check (case
   when value_type in ('number','decimal','slider_tier') then filter_type in ('range_slider','range_min')
   when value_type='multi_select' then filter_type='checkbox_group'
   when value_type='tag_multi' then filter_type='tag_select'
   when value_type='single_select' then filter_type in ('radio','dropdown')
   when value_type='boolean_with_option' then filter_type='toggle_dropdown'
   when value_type='boolean' then filter_type='toggle' else false end),
 check (value_type in ('number','decimal') or (range_min is null and range_max is null and unit is null))
);
create index game_attribute_definitions_order_idx on public.game_attribute_definitions(game_id,active,sort_order);
alter table public.game_attribute_definitions enable row level security;
revoke all on public.game_attribute_definitions from public,anon,authenticated;
grant select on public.game_attribute_definitions to anon,authenticated;
grant insert(game_id,key,label,category,value_type,filter_type,options,range_min,range_max,unit,sort_order,active)
 on public.game_attribute_definitions to authenticated;
grant update(label,category,value_type,filter_type,options,range_min,range_max,unit,sort_order,active)
 on public.game_attribute_definitions to authenticated;
create policy read_game_attributes on public.game_attribute_definitions for select to anon,authenticated
 using (active or private.is_admin());
create policy insert_game_attributes on public.game_attribute_definitions for insert to authenticated
 with check (private.is_admin());
create policy update_game_attributes on public.game_attribute_definitions for update to authenticated
 using (private.is_admin()) with check (private.is_admin());

-- Options are literal display values; tag_multi with [] permits bounded free-form tags until a trusted list exists.
create function private.attribute_value_valid(d public.game_attribute_definitions, v jsonb)
returns boolean language plpgsql immutable set search_path = '' as $$
declare item jsonb; n numeric; seen text[] := array[]::text[];
begin
 if v is null or v='null'::jsonb then return false; end if;
 if d.value_type in ('slider_tier','single_select','boolean_with_option') then
   return jsonb_typeof(v)='string' and d.options @> jsonb_build_array(v);
 elsif d.value_type in ('multi_select','tag_multi') then
   if jsonb_typeof(v)<>'array' or jsonb_array_length(v)>20 then return false; end if;
   for item in select value from jsonb_array_elements(v) loop
     if jsonb_typeof(item)<>'string' or char_length(item #>> '{}') not between 1 and 60
       or item #>> '{}' = any(seen) then return false; end if;
     if d.value_type='multi_select' or jsonb_array_length(d.options)>0 then
       if not d.options @> jsonb_build_array(item) then return false; end if;
     end if;
     seen := array_append(seen,item #>> '{}');
   end loop;
   return true;
 elsif d.value_type='boolean' then return jsonb_typeof(v)='boolean';
 elsif d.value_type in ('number','decimal') then
   if jsonb_typeof(v)<>'number' then return false; end if;
   n := (v #>> '{}')::numeric;
   return n >= coalesce(d.range_min,0) and n <= coalesce(d.range_max,1000000)
     and (d.value_type='decimal' or n=trunc(n));
 end if;
 return false;
exception when numeric_value_out_of_range then return false;
end $$;

-- Keep original ownership/catalog/timestamp behavior; replace only its fixed JSON key allowlist.
create or replace function private.validate_game_profile() returns trigger language plpgsql security definer set search_path = '' as $$
declare v_slug text; v_key text; v_value jsonb; d public.game_attribute_definitions;
begin
 if tg_op='UPDATE' and (new.user_id<>old.user_id or new.game_id<>old.game_id) then
   raise exception 'Pemilik/game tidak dapat diganti'; end if;
 if tg_op='INSERT' or new.ign is distinct from old.ign or new.primary_rank_option_id is distinct from old.primary_rank_option_id then
   select slug into v_slug from public.games where id=new.game_id and active;
   if v_slug is null then raise exception 'Game tidak aktif'; end if;
 end if;
 perform private.check_option(new.region_option_id,new.game_id,'region');
 perform private.check_option(new.server_option_id,new.game_id,'server');
 perform private.check_option(new.primary_rank_option_id,new.game_id,'rank');
 perform private.check_option(new.primary_rank_mode_option_id,new.game_id,'mode');
 perform private.check_option(new.primary_role_option_id,new.game_id,'role');
 if new.primary_rank_option_id is not null and exists(
   select 1 from public.game_catalog_options o where o.id=new.primary_rank_option_id
   and o.rank_mode_option_id is distinct from new.primary_rank_mode_option_id) then
   raise exception 'Rank dan mode tidak cocok'; end if;
 if jsonb_typeof(new.attributes)<>'object' or octet_length(new.attributes::text)>4096 then
   raise exception 'Atribut tidak valid' using errcode='23514'; end if;
 for v_key,v_value in select key,value from jsonb_each(new.attributes) loop
   select * into d from public.game_attribute_definitions
     where game_id=new.game_id and key=v_key for share;
   if found then
     if not d.active or not private.attribute_value_valid(d,v_value) then
       raise exception 'Atribut tidak diizinkan: %',v_key using errcode='23514'; end if;
   elsif v_key in ('stars','tier','perspective','team_size','play_goal') then
     -- Preserve unchanged legacy JSON, including numeric stars, without admitting arbitrary new types.
     if tg_op='UPDATE' and old.attributes->v_key is not distinct from v_value then
       continue;
     end if;
     if jsonb_typeof(v_value)<>'string' or char_length(v_value #>> '{}')>120 then
       raise exception 'Atribut lama tidak valid' using errcode='23514'; end if;
   else
     raise exception 'Atribut tidak diizinkan: %',v_key using errcode='23514';
   end if;
 end loop;
 new.updated_at=now();
 if tg_op='INSERT' or (new.ign,new.game_id_private,new.region_option_id,new.server_option_id,
     new.primary_rank_option_id,new.primary_rank_mode_option_id,new.primary_role_option_id,
     new.play_goal,new.availability_status,new.attributes) is distinct from
    (old.ign,old.game_id_private,old.region_option_id,old.server_option_id,
     old.primary_rank_option_id,old.primary_rank_mode_option_id,old.primary_role_option_id,
     old.play_goal,old.availability_status,old.attributes) then
   new.data_updated_at=now();
 else new.data_updated_at=old.data_updated_at; end if;
 return new;
end $$;

create function private.validate_attribute_definition() returns trigger language plpgsql security definer set search_path = '' as $$
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
     and gp.attributes ? new.key and not private.attribute_value_valid(new,gp.attributes->new.key)) then
   raise exception 'Definisi tidak cocok dengan profil tersimpan' using errcode='23514'; end if;
 return new;
end $$;
create trigger game_attribute_definition_validate before insert or update on public.game_attribute_definitions
 for each row execute function private.validate_attribute_definition();
revoke all on function private.attribute_value_valid(public.game_attribute_definitions,jsonb),
 private.validate_attribute_definition() from public,anon,authenticated;

-- Filters: numeric/tier {"min":...,"max":...} (either bound optional); multi/tag string array (ANY);
-- single/boolean scalar, language array of 'id'/'en' (ANY). Unknown or malformed keys fail closed.
create function public.search_game_profiles_by_attributes(
 p_game_slug text,p_filters jsonb default '{}'::jsonb,p_limit int default 20,p_offset int default 0)
returns table(id uuid,user_id uuid,game_id uuid,game_name text,display_name text,avatar_url text,
 ign text,rank text,role text,region text,ready boolean,updated_at timestamptz,bio text)
language plpgsql stable security definer set search_path = '' as $$
declare v_game uuid; f record; d public.game_attribute_definitions; bound text; n numeric;
begin
 if p_game_slug is null or p_limit is null or p_limit not between 1 and 50
   or p_offset is null or p_offset not between 0 and 5000
   or jsonb_typeof(p_filters)<>'object' or octet_length(p_filters::text)>4096 then
   raise exception 'Filter pencarian tidak valid' using errcode='22023'; end if;
 select g.id into v_game from public.games g where g.slug=p_game_slug and g.active;
 for f in select key,value from jsonb_each(p_filters) loop
   if f.key='language' then
     if jsonb_typeof(f.value)<>'array' or jsonb_array_length(f.value)>20 or
       exists(select 1 from jsonb_array_elements(f.value) x where jsonb_typeof(x.value)<>'string'
         or x.value not in ('"id"'::jsonb,'"en"'::jsonb)) then
       raise exception 'Filter bahasa tidak valid' using errcode='22023'; end if;
     continue;
   end if;
   select ad.* into d from public.game_attribute_definitions ad where ad.game_id=v_game and ad.key=f.key and ad.active;
   if not found then raise exception 'Filter tidak dikenal: %',f.key using errcode='22023'; end if;
   if d.value_type in ('number','decimal','slider_tier') then
     if jsonb_typeof(f.value)<>'object' or f.value='{}'::jsonb
       or exists(select 1 from jsonb_object_keys(f.value) k where k not in ('min','max')) then
       raise exception 'Rentang tidak valid' using errcode='22023'; end if;
     foreach bound in array array['min','max'] loop
       if f.value ? bound then
         if d.value_type='slider_tier' then
           if jsonb_typeof(f.value->bound)<>'string' or not d.options @> jsonb_build_array(f.value->bound) then
             raise exception 'Tier tidak valid' using errcode='22023'; end if;
         else
           if jsonb_typeof(f.value->bound)<>'number' then raise exception 'Angka tidak valid' using errcode='22023'; end if;
           n:=(f.value->>bound)::numeric;
           if n<coalesce(d.range_min,0) or n>coalesce(d.range_max,1000000)
             or (d.value_type='number' and n<>trunc(n)) then
             raise exception 'Angka di luar batas' using errcode='22023'; end if;
         end if;
       end if;
     end loop;
     if f.value ? 'min' and f.value ? 'max' then
       if d.value_type='slider_tier' and
         (select ordinality from jsonb_array_elements(d.options) with ordinality x(value,ordinality) where value=f.value->'min') >
         (select ordinality from jsonb_array_elements(d.options) with ordinality x(value,ordinality) where value=f.value->'max')
       or d.value_type in ('number','decimal') and (f.value->>'min')::numeric>(f.value->>'max')::numeric then
         raise exception 'Rentang terbalik' using errcode='22023'; end if;
     end if;
   elsif not private.attribute_value_valid(d,f.value) then
     raise exception 'Filter nilai tidak valid: %',f.key using errcode='22023'; end if;
 end loop;
 return query
 select gp.id,gp.user_id,gp.game_id,g.name,p.display_name,p.avatar_url,gp.ign,
   r.label,ro.label,reg.label,
   (gp.availability_status='ready' and p.availability_status='ready'),gp.data_updated_at,p.bio
 from public.game_profiles gp join public.games g on g.id=gp.game_id
 join public.profiles p on p.user_id=gp.user_id
 left join public.game_catalog_options r on r.id=gp.primary_rank_option_id
 left join public.game_catalog_options ro on ro.id=gp.primary_role_option_id
 left join public.game_catalog_options reg on reg.id=gp.region_option_id
 where gp.game_id=v_game and gp.status='active' and gp.visibility='public'
   and p.visibility='public' and p.account_status='active' and p.adult_declared_at is not null
   and (auth.uid() is null or not private.blocked(auth.uid(),gp.user_id))
   and not exists (
     select 1 from jsonb_each(p_filters) ff(key,value)
     left join public.game_attribute_definitions def on def.game_id=gp.game_id and def.key=ff.key
     where case
       when ff.key='language' then not (p.languages && array(select jsonb_array_elements_text(ff.value)))
       when def.value_type='slider_tier' then
         not exists (select 1 from jsonb_array_elements(def.options) with ordinality x(value,position)
           where x.value=gp.attributes->ff.key
             and (not ff.value ? 'min' or position >= (select ordinality from jsonb_array_elements(def.options) with ordinality y(value,ordinality) where y.value=ff.value->'min'))
             and (not ff.value ? 'max' or position <= (select ordinality from jsonb_array_elements(def.options) with ordinality y(value,ordinality) where y.value=ff.value->'max')))
       when def.value_type in ('number','decimal') then
         jsonb_typeof(gp.attributes->ff.key) is distinct from 'number'
         or (ff.value ? 'min' and (gp.attributes->>ff.key)::numeric < (ff.value->>'min')::numeric)
         or (ff.value ? 'max' and (gp.attributes->>ff.key)::numeric > (ff.value->>'max')::numeric)
       when def.value_type in ('multi_select','tag_multi') then
         jsonb_typeof(gp.attributes->ff.key) is distinct from 'array'
         or not (gp.attributes->ff.key ?| array(select jsonb_array_elements_text(ff.value)))
       else gp.attributes->ff.key is distinct from ff.value end
   )
 order by (gp.data_updated_at < now()-interval '30 days') asc,gp.data_updated_at desc,gp.id
 limit p_limit offset p_offset;
end $$;
revoke all on function public.search_game_profiles_by_attributes(text,jsonb,int,int) from public,anon,authenticated;
grant execute on function public.search_game_profiles_by_attributes(text,jsonb,int,int) to anon,authenticated;

-- Seed on game creation as well as migration time: migrations precede seed.sql.
-- Only missing definitions inserted; existing admin edits/catalog options remain intact.
create function private.seed_game_attributes() returns trigger language plpgsql security definer set search_path = '' as $$
begin
 insert into public.game_attribute_definitions
 (game_id,key,label,category,value_type,filter_type,options,range_min,range_max,unit,sort_order)
 select new.id,v.key,v.label,v.category,v.value_type,v.filter_type,v.options::jsonb,
   v.range_min::numeric,v.range_max::numeric,v.unit,v.sort_order::int
 from (values
 ('mlbb','rank_current','Rank Saat Ini','kompetensi','slider_tier','range_slider','["Warrior", "Elite", "Master", "Grandmaster", "Epic", "Legend", "Mythic", "Mythic Honor", "Mythic Glory", "Mythic Immortal"]',null,null,null,'0'),
 ('mlbb','rank_peak','Rank Tertinggi (Peak)','kompetensi','slider_tier','range_slider','["Warrior", "Elite", "Master", "Grandmaster", "Epic", "Legend", "Mythic", "Mythic Honor", "Mythic Glory", "Mythic Immortal"]',null,null,null,'1'),
 ('mlbb','role','Role Utama','kompetensi','multi_select','checkbox_group','["Tank", "Fighter", "Assassin", "Mage", "Marksman", "Support"]',null,null,null,'2'),
 ('mlbb','hero_pool','Hero Pool / Signature Hero','kompetensi','tag_multi','tag_select','[]',null,null,null,'3'),
 ('mlbb','win_rate','Win Rate','kompetensi','number','range_slider','[]','0','100','%','4'),
 ('mlbb','match_type','Tipe Match','gaya_main','multi_select','checkbox_group','["Ranked", "Classic", "Brawl", "Draft Pick"]',null,null,null,'5'),
 ('mlbb','squad_type','Tipe Squad','gaya_main','single_select','radio','["Duo", "Trio", "Full Squad (5)"]',null,null,null,'6'),
 ('mlbb','server','Server','kompetensi','single_select','dropdown','["Indonesia", "Malaysia", "Singapura", "SEA/Global"]',null,null,null,'7'),
 ('mlbb','playstyle','Gaya Main','gaya_main','multi_select','checkbox_group','["Agresif/Rotasi Cepat", "Farming/Split Push", "Objective-focused (Turtle/Lord)"]',null,null,null,'8'),
 ('mlbb','voice_chat','Voice Chat','gaya_main','boolean_with_option','toggle_dropdown','["Nonaktif", "Aktif - In-game", "Aktif - Discord"]',null,null,null,'9'),
 ('mlbb','active_hours','Jam Aktif Main','gaya_main','multi_select','checkbox_group','["Pagi", "Siang", "Sore", "Malam", "Dini Hari"]',null,null,null,'10'),
 ('mlbb','account_level','Level Akun','kompetensi','number','range_min','[]',null,null,null,'11'),
 ('mlbb','behavior_score','Credit Score / Behavior Score','reputasi','number','range_slider','[]','0','100',null,'12'),
 ('pubg-mobile','rank_tier','Tier Rank','kompetensi','slider_tier','range_slider','["Bronze", "Silver", "Gold", "Platinum", "Diamond", "Crown", "Ace", "Ace Master", "Ace Dominator", "Conqueror"]',null,null,null,'0'),
 ('pubg-mobile','mode','Mode','kompetensi','single_select','radio','["Solo", "Duo", "Squad"]',null,null,null,'1'),
 ('pubg-mobile','perspective','Perspektif','gaya_main','single_select','radio','["TPP", "FPP"]',null,null,null,'2'),
 ('pubg-mobile','squad_role','Peran dalam Squad','kompetensi','multi_select','checkbox_group','["IGL/Shotcaller", "Entry/Fragger", "Support/Flanker", "Sniper", "Driver"]',null,null,null,'3'),
 ('pubg-mobile','kd_ratio','K/D Ratio','kompetensi','decimal','range_slider','[]',null,null,null,'4'),
 ('pubg-mobile','avg_damage','Rata-rata Damage','kompetensi','number','range_slider','[]',null,null,null,'5'),
 ('pubg-mobile','win_rate','Win Rate / Chicken Dinner','kompetensi','number','range_slider','[]',null,'100','%','6'),
 ('pubg-mobile','favorite_map','Map Favorit','gaya_main','multi_select','checkbox_group','["Erangel", "Miramar", "Sanhok", "Vikendi", "Livik", "Karakin", "Deston"]',null,null,null,'7'),
 ('pubg-mobile','server','Server','kompetensi','single_select','dropdown','["Asia", "SEA", "Global"]',null,null,null,'8'),
 ('pubg-mobile','playstyle','Gaya Main','gaya_main','multi_select','checkbox_group','["Rusher Agresif", "Passive/Camper", "Rotasi Zona Rapi"]',null,null,null,'9'),
 ('pubg-mobile','device','Device','reputasi','single_select','radio','["Mobile (Touchscreen)", "Emulator", "Gamepad/Controller"]',null,null,null,'10'),
 ('pubg-mobile','voice_chat','Voice Chat','gaya_main','boolean','toggle','[]',null,null,null,'11'),
 ('pubg-mobile','behavior_score','Credit Score','reputasi','number','range_min','[]',null,null,null,'12'),
 ('pubg-mobile','active_hours','Jam Aktif Main','gaya_main','multi_select','checkbox_group','["Pagi", "Siang", "Sore", "Malam"]',null,null,null,'13'),
 ('free-fire','rank','Rank','kompetensi','slider_tier','range_slider','["Bronze", "Silver", "Gold", "Platinum", "Diamond", "Heroic", "Master", "Grandmaster"]',null,null,null,'0'),
 ('free-fire','mode','Mode','kompetensi','multi_select','checkbox_group','["Battle Royale - Solo", "Battle Royale - Duo", "Battle Royale - Squad", "Clash Squad", "Lone Wolf"]',null,null,null,'1'),
 ('free-fire','team_role','Peran dalam Tim','kompetensi','multi_select','checkbox_group','["Rusher", "Support/Flanker", "Sniper", "IGL/Shotcaller"]',null,null,null,'2'),
 ('free-fire','kd_ratio','K/D Ratio','kompetensi','decimal','range_slider','[]',null,null,null,'3'),
 ('free-fire','booyah_rate','Booyah Rate (Win Rate)','kompetensi','number','range_slider','[]',null,'100','%','4'),
 ('free-fire','main_character','Karakter/Skill Andalan','kompetensi','tag_multi','tag_select','[]',null,null,null,'5'),
 ('free-fire','server','Server','kompetensi','single_select','dropdown','["Indonesia", "SEA"]',null,null,null,'6'),
 ('free-fire','playstyle','Gaya Main','gaya_main','multi_select','checkbox_group','["Agresif Rush", "Passif/Defensif"]',null,null,null,'7'),
 ('free-fire','device','Device','reputasi','single_select','radio','["Mobile (Touchscreen)", "Emulator"]',null,null,null,'8'),
 ('free-fire','voice_chat','Voice Chat','gaya_main','boolean','toggle','[]',null,null,null,'9'),
 ('free-fire','behavior_score','Credit Score / Riwayat Ban','reputasi','number','range_min','[]',null,null,null,'10'),
 ('free-fire','squad_type','Tipe Squad','gaya_main','single_select','radio','["Tim Tetap", "Random/Cari Tim Baru"]',null,null,null,'11'),
 ('free-fire','active_hours','Jam Aktif Main','gaya_main','multi_select','checkbox_group','["Pagi", "Siang", "Sore", "Malam"]',null,null,null,'12'),
 ('valorant','rank_current','Rank Saat Ini','kompetensi','slider_tier','range_slider','["Iron 1-3", "Bronze 1-3", "Silver 1-3", "Gold 1-3", "Platinum 1-3", "Diamond 1-3", "Ascendant 1-3", "Immortal 1-3", "Radiant"]',null,null,null,'0'),
 ('valorant','rank_peak','Peak Rank','kompetensi','slider_tier','range_slider','["Iron 1-3", "Bronze 1-3", "Silver 1-3", "Gold 1-3", "Platinum 1-3", "Diamond 1-3", "Ascendant 1-3", "Immortal 1-3", "Radiant"]',null,null,null,'1'),
 ('valorant','role_pool','Role/Agent Pool','kompetensi','multi_select','checkbox_group','["Duelist", "Controller", "Initiator", "Sentinel"]',null,null,null,'2'),
 ('valorant','main_agent','Agent Andalan','kompetensi','tag_multi','tag_select','[]',null,null,null,'3'),
 ('valorant','team_role','Peran dalam Tim','kompetensi','multi_select','checkbox_group','["IGL", "Entry Fragger", "Support", "Lurker", "Anchor/Site-holder"]',null,null,null,'4'),
 ('valorant','kd_ratio','K/D Ratio','kompetensi','decimal','range_slider','[]',null,null,null,'5'),
 ('valorant','headshot_percentage','Headshot %','kompetensi','number','range_slider','[]',null,'100','%','6'),
 ('valorant','win_rate','Win Rate','kompetensi','number','range_slider','[]',null,'100','%','7'),
 ('valorant','server','Server','kompetensi','single_select','dropdown','["Asia Pacific", "SEA"]',null,null,null,'8'),
 ('valorant','competitive_experience','Pengalaman Kompetitif','kompetensi','multi_select','checkbox_group','["Ranked Casual", "Scrim Rutin", "Pernah Turnamen"]',null,null,null,'9'),
 ('valorant','playstyle','Gaya Main','gaya_main','multi_select','checkbox_group','["Entry Agresif", "Lurk/Flank", "Support-oriented", "Anchor Site"]',null,null,null,'10'),
 ('valorant','voice_chat','Voice Chat','gaya_main','boolean_with_option','toggle_dropdown','["Nonaktif", "Aktif - In-game", "Aktif - Discord"]',null,null,null,'11'),
 ('valorant','squad_type','Tipe Squad','gaya_main','single_select','radio','["5-stack Tetap", "Duo Queue", "Cari Tim Baru"]',null,null,null,'12'),
 ('valorant','active_hours','Jam Aktif Main','gaya_main','multi_select','checkbox_group','["Pagi", "Siang", "Sore", "Malam"]',null,null,null,'13')
 ) as v(slug,key,label,category,value_type,filter_type,options,range_min,range_max,unit,sort_order)
 where v.slug=new.slug
 on conflict(game_id,key) do nothing;
 return new;
end $$;
revoke all on function private.seed_game_attributes() from public,anon,authenticated;
create trigger seed_game_attribute_definitions after insert on public.games
 for each row execute function private.seed_game_attributes();
insert into public.game_attribute_definitions
 (game_id,key,label,category,value_type,filter_type,options,range_min,range_max,unit,sort_order)
 select g.id,v.key,v.label,v.category,v.value_type,v.filter_type,v.options::jsonb,
   v.range_min::numeric,v.range_max::numeric,v.unit,v.sort_order::int
 from public.games g join (values
 ('mlbb','rank_current','Rank Saat Ini','kompetensi','slider_tier','range_slider','["Warrior", "Elite", "Master", "Grandmaster", "Epic", "Legend", "Mythic", "Mythic Honor", "Mythic Glory", "Mythic Immortal"]',null,null,null,'0'),
 ('mlbb','rank_peak','Rank Tertinggi (Peak)','kompetensi','slider_tier','range_slider','["Warrior", "Elite", "Master", "Grandmaster", "Epic", "Legend", "Mythic", "Mythic Honor", "Mythic Glory", "Mythic Immortal"]',null,null,null,'1'),
 ('mlbb','role','Role Utama','kompetensi','multi_select','checkbox_group','["Tank", "Fighter", "Assassin", "Mage", "Marksman", "Support"]',null,null,null,'2'),
 ('mlbb','hero_pool','Hero Pool / Signature Hero','kompetensi','tag_multi','tag_select','[]',null,null,null,'3'),
 ('mlbb','win_rate','Win Rate','kompetensi','number','range_slider','[]','0','100','%','4'),
 ('mlbb','match_type','Tipe Match','gaya_main','multi_select','checkbox_group','["Ranked", "Classic", "Brawl", "Draft Pick"]',null,null,null,'5'),
 ('mlbb','squad_type','Tipe Squad','gaya_main','single_select','radio','["Duo", "Trio", "Full Squad (5)"]',null,null,null,'6'),
 ('mlbb','server','Server','kompetensi','single_select','dropdown','["Indonesia", "Malaysia", "Singapura", "SEA/Global"]',null,null,null,'7'),
 ('mlbb','playstyle','Gaya Main','gaya_main','multi_select','checkbox_group','["Agresif/Rotasi Cepat", "Farming/Split Push", "Objective-focused (Turtle/Lord)"]',null,null,null,'8'),
 ('mlbb','voice_chat','Voice Chat','gaya_main','boolean_with_option','toggle_dropdown','["Nonaktif", "Aktif - In-game", "Aktif - Discord"]',null,null,null,'9'),
 ('mlbb','active_hours','Jam Aktif Main','gaya_main','multi_select','checkbox_group','["Pagi", "Siang", "Sore", "Malam", "Dini Hari"]',null,null,null,'10'),
 ('mlbb','account_level','Level Akun','kompetensi','number','range_min','[]',null,null,null,'11'),
 ('mlbb','behavior_score','Credit Score / Behavior Score','reputasi','number','range_slider','[]','0','100',null,'12'),
 ('pubg-mobile','rank_tier','Tier Rank','kompetensi','slider_tier','range_slider','["Bronze", "Silver", "Gold", "Platinum", "Diamond", "Crown", "Ace", "Ace Master", "Ace Dominator", "Conqueror"]',null,null,null,'0'),
 ('pubg-mobile','mode','Mode','kompetensi','single_select','radio','["Solo", "Duo", "Squad"]',null,null,null,'1'),
 ('pubg-mobile','perspective','Perspektif','gaya_main','single_select','radio','["TPP", "FPP"]',null,null,null,'2'),
 ('pubg-mobile','squad_role','Peran dalam Squad','kompetensi','multi_select','checkbox_group','["IGL/Shotcaller", "Entry/Fragger", "Support/Flanker", "Sniper", "Driver"]',null,null,null,'3'),
 ('pubg-mobile','kd_ratio','K/D Ratio','kompetensi','decimal','range_slider','[]',null,null,null,'4'),
 ('pubg-mobile','avg_damage','Rata-rata Damage','kompetensi','number','range_slider','[]',null,null,null,'5'),
 ('pubg-mobile','win_rate','Win Rate / Chicken Dinner','kompetensi','number','range_slider','[]',null,'100','%','6'),
 ('pubg-mobile','favorite_map','Map Favorit','gaya_main','multi_select','checkbox_group','["Erangel", "Miramar", "Sanhok", "Vikendi", "Livik", "Karakin", "Deston"]',null,null,null,'7'),
 ('pubg-mobile','server','Server','kompetensi','single_select','dropdown','["Asia", "SEA", "Global"]',null,null,null,'8'),
 ('pubg-mobile','playstyle','Gaya Main','gaya_main','multi_select','checkbox_group','["Rusher Agresif", "Passive/Camper", "Rotasi Zona Rapi"]',null,null,null,'9'),
 ('pubg-mobile','device','Device','reputasi','single_select','radio','["Mobile (Touchscreen)", "Emulator", "Gamepad/Controller"]',null,null,null,'10'),
 ('pubg-mobile','voice_chat','Voice Chat','gaya_main','boolean','toggle','[]',null,null,null,'11'),
 ('pubg-mobile','behavior_score','Credit Score','reputasi','number','range_min','[]',null,null,null,'12'),
 ('pubg-mobile','active_hours','Jam Aktif Main','gaya_main','multi_select','checkbox_group','["Pagi", "Siang", "Sore", "Malam"]',null,null,null,'13'),
 ('free-fire','rank','Rank','kompetensi','slider_tier','range_slider','["Bronze", "Silver", "Gold", "Platinum", "Diamond", "Heroic", "Master", "Grandmaster"]',null,null,null,'0'),
 ('free-fire','mode','Mode','kompetensi','multi_select','checkbox_group','["Battle Royale - Solo", "Battle Royale - Duo", "Battle Royale - Squad", "Clash Squad", "Lone Wolf"]',null,null,null,'1'),
 ('free-fire','team_role','Peran dalam Tim','kompetensi','multi_select','checkbox_group','["Rusher", "Support/Flanker", "Sniper", "IGL/Shotcaller"]',null,null,null,'2'),
 ('free-fire','kd_ratio','K/D Ratio','kompetensi','decimal','range_slider','[]',null,null,null,'3'),
 ('free-fire','booyah_rate','Booyah Rate (Win Rate)','kompetensi','number','range_slider','[]',null,'100','%','4'),
 ('free-fire','main_character','Karakter/Skill Andalan','kompetensi','tag_multi','tag_select','[]',null,null,null,'5'),
 ('free-fire','server','Server','kompetensi','single_select','dropdown','["Indonesia", "SEA"]',null,null,null,'6'),
 ('free-fire','playstyle','Gaya Main','gaya_main','multi_select','checkbox_group','["Agresif Rush", "Passif/Defensif"]',null,null,null,'7'),
 ('free-fire','device','Device','reputasi','single_select','radio','["Mobile (Touchscreen)", "Emulator"]',null,null,null,'8'),
 ('free-fire','voice_chat','Voice Chat','gaya_main','boolean','toggle','[]',null,null,null,'9'),
 ('free-fire','behavior_score','Credit Score / Riwayat Ban','reputasi','number','range_min','[]',null,null,null,'10'),
 ('free-fire','squad_type','Tipe Squad','gaya_main','single_select','radio','["Tim Tetap", "Random/Cari Tim Baru"]',null,null,null,'11'),
 ('free-fire','active_hours','Jam Aktif Main','gaya_main','multi_select','checkbox_group','["Pagi", "Siang", "Sore", "Malam"]',null,null,null,'12'),
 ('valorant','rank_current','Rank Saat Ini','kompetensi','slider_tier','range_slider','["Iron 1-3", "Bronze 1-3", "Silver 1-3", "Gold 1-3", "Platinum 1-3", "Diamond 1-3", "Ascendant 1-3", "Immortal 1-3", "Radiant"]',null,null,null,'0'),
 ('valorant','rank_peak','Peak Rank','kompetensi','slider_tier','range_slider','["Iron 1-3", "Bronze 1-3", "Silver 1-3", "Gold 1-3", "Platinum 1-3", "Diamond 1-3", "Ascendant 1-3", "Immortal 1-3", "Radiant"]',null,null,null,'1'),
 ('valorant','role_pool','Role/Agent Pool','kompetensi','multi_select','checkbox_group','["Duelist", "Controller", "Initiator", "Sentinel"]',null,null,null,'2'),
 ('valorant','main_agent','Agent Andalan','kompetensi','tag_multi','tag_select','[]',null,null,null,'3'),
 ('valorant','team_role','Peran dalam Tim','kompetensi','multi_select','checkbox_group','["IGL", "Entry Fragger", "Support", "Lurker", "Anchor/Site-holder"]',null,null,null,'4'),
 ('valorant','kd_ratio','K/D Ratio','kompetensi','decimal','range_slider','[]',null,null,null,'5'),
 ('valorant','headshot_percentage','Headshot %','kompetensi','number','range_slider','[]',null,'100','%','6'),
 ('valorant','win_rate','Win Rate','kompetensi','number','range_slider','[]',null,'100','%','7'),
 ('valorant','server','Server','kompetensi','single_select','dropdown','["Asia Pacific", "SEA"]',null,null,null,'8'),
 ('valorant','competitive_experience','Pengalaman Kompetitif','kompetensi','multi_select','checkbox_group','["Ranked Casual", "Scrim Rutin", "Pernah Turnamen"]',null,null,null,'9'),
 ('valorant','playstyle','Gaya Main','gaya_main','multi_select','checkbox_group','["Entry Agresif", "Lurk/Flank", "Support-oriented", "Anchor Site"]',null,null,null,'10'),
 ('valorant','voice_chat','Voice Chat','gaya_main','boolean_with_option','toggle_dropdown','["Nonaktif", "Aktif - In-game", "Aktif - Discord"]',null,null,null,'11'),
 ('valorant','squad_type','Tipe Squad','gaya_main','single_select','radio','["5-stack Tetap", "Duo Queue", "Cari Tim Baru"]',null,null,null,'12'),
 ('valorant','active_hours','Jam Aktif Main','gaya_main','multi_select','checkbox_group','["Pagi", "Siang", "Sore", "Malam"]',null,null,null,'13')
 ) as v(slug,key,label,category,value_type,filter_type,options,range_min,range_max,unit,sort_order) on v.slug=g.slug
 on conflict(game_id,key) do nothing;
