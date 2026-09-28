-- Additive canonical profile taxonomy. Old definitions, catalog options, and profile JSON stay intact.
create function private.seed_canonical_game_attributes_for_existing(p_id uuid,p_slug text) returns void language plpgsql security definer set search_path = '' as $$
begin
 insert into public.game_attribute_definitions
 (game_id,key,label,category,value_type,filter_type,options,sort_order)
 select p_id,v.key,v.label,v.category,v.value_type,v.filter_type,v.options::jsonb,v.sort_order
 from (values
 ('mlbb','position_main','Posisi Utama','kompetensi','single_select','radio','["EXP Lane","Jungle","Mid Lane","Gold Lane","Roam"]',20),
 ('mlbb','position_secondary','Posisi Cadangan','kompetensi','multi_select','checkbox_group','["EXP Lane","Jungle","Mid Lane","Gold Lane","Roam"]',21),
 ('pubg-mobile','squad_role_main','Peran Utama Squad','kompetensi','single_select','radio','["IGL","Entry","Support","Scout","Sniper","Driver"]',20),
 ('pubg-mobile','queue_mode','Mode Antrean','gaya_main','single_select','radio','["Classic Ranked","Classic Unranked"]',21),
 ('free-fire','ranked_mode','Mode Rank','kompetensi','single_select','radio','["Battle Royale Ranked","Clash Squad Ranked"]',20),
 ('free-fire','rank_br','Rank Battle Royale','kompetensi','slider_tier','range_slider','["Bronze","Silver","Gold","Platinum","Diamond","Heroic","Master","Grandmaster"]',21),
 ('free-fire','rank_cs','Rank Clash Squad','kompetensi','slider_tier','range_slider','["Bronze","Silver","Gold","Platinum","Diamond","Heroic","Master","Grandmaster"]',22),
 ('free-fire','team_role_main','Peran Utama Tim','kompetensi','single_select','radio','["IGL","Rusher","Support","Sniper"]',23),
 ('valorant','agent_role_main','Peran Agent Utama','kompetensi','single_select','radio','["Duelist","Initiator","Controller","Sentinel"]',20),
 ('valorant','game_mode','Mode Permainan','gaya_main','single_select','radio','["Competitive","Unrated","Swiftplay"]',21),
 ('mlbb','play_goal','Tujuan Main','gaya_main','single_select','radio','["Santai","Naik Rank","Latihan Tim"]',22),
 ('pubg-mobile','play_goal','Tujuan Main','gaya_main','single_select','radio','["Santai","Naik Rank","Latihan Tim"]',22),
 ('free-fire','play_goal','Tujuan Main','gaya_main','single_select','radio','["Santai","Naik Rank","Latihan Tim"]',24),
 ('valorant','play_goal','Tujuan Main','gaya_main','single_select','radio','["Santai","Naik Rank","Latihan Tim"]',22)
 ) as v(slug,key,label,category,value_type,filter_type,options,sort_order)
 where v.slug=p_slug
 on conflict(game_id,key) do nothing;
end $$;
revoke all on function private.seed_canonical_game_attributes_for_existing(uuid,text) from public,anon,authenticated;
create function private.seed_canonical_game_attributes() returns trigger language plpgsql security definer set search_path = '' as $$
begin
 perform private.seed_canonical_game_attributes_for_existing(new.id,new.slug);
 return new;
end $$;
revoke all on function private.seed_canonical_game_attributes() from public,anon,authenticated;
create trigger seed_canonical_game_attribute_definitions after insert on public.games
 for each row execute function private.seed_canonical_game_attributes();
-- Existing games predate the trigger. Seed through the same path without changing existing records.
do $$ declare g public.games; begin
 for g in select * from public.games where slug in ('mlbb','pubg-mobile','free-fire','valorant') loop
  perform private.seed_canonical_game_attributes_for_existing(g.id,g.slug);
 end loop;
end $$;

-- Add a separate check rather than rewriting the existing ownership/option validator.
create function private.validate_canonical_profile_attributes() returns trigger language plpgsql set search_path = '' as $$
declare a jsonb := new.attributes;
begin
 if a ? 'position_secondary' and jsonb_typeof(a->'position_secondary')='array' then
   if jsonb_array_length(a->'position_secondary')>2 then
     raise exception 'Maksimal dua posisi cadangan' using errcode='23514'; end if;
   if a ? 'position_main' and a->'position_secondary' @> jsonb_build_array(a->'position_main') then
     raise exception 'Posisi utama tidak boleh menjadi posisi cadangan' using errcode='23514'; end if;
 end if;
 -- Both Free Fire ranks can coexist; ranked_mode selects which one is displayed.
 return new;
end $$;
revoke all on function private.validate_canonical_profile_attributes() from public,anon,authenticated;
create trigger game_profile_canonical_attributes before insert or update on public.game_profiles
 for each row execute function private.validate_canonical_profile_attributes();

-- Same RPC signature/columns/grants; existing filter semantics retained.
create or replace function public.search_game_profiles_by_attributes(
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
 if p_game_slug='free-fire' and (
   (p_filters ? 'rank_br' and p_filters ? 'rank_cs')
   or (p_filters ? 'rank_br' and p_filters->>'ranked_mode'='Clash Squad Ranked')
   or (p_filters ? 'rank_cs' and p_filters->>'ranked_mode'='Battle Royale Ranked')
 ) then raise exception 'Rank dan mode filter tidak cocok' using errcode='22023'; end if;
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
   if p_game_slug='mlbb' and f.key='position_secondary' and jsonb_typeof(f.value)='array'
     and jsonb_array_length(f.value)>2 then
     raise exception 'Maksimal dua posisi cadangan' using errcode='22023'; end if;
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
   case when g.slug='mlbb' then coalesce(gp.attributes->>'rank_current',r.label)
     when g.slug='pubg-mobile' then coalesce(gp.attributes->>'rank_tier',r.label)
     when g.slug='free-fire' then case gp.attributes->>'ranked_mode'
       when 'Battle Royale Ranked' then gp.attributes->>'rank_br'
       when 'Clash Squad Ranked' then gp.attributes->>'rank_cs'
       else coalesce(gp.attributes->>'rank',r.label) end
     when g.slug='valorant' then coalesce(gp.attributes->>'rank_current',r.label)
     else r.label end,
   case when g.slug='mlbb' then gp.attributes->>'position_main'
     when g.slug='pubg-mobile' then coalesce(gp.attributes->>'squad_role_main',ro.label)
     when g.slug='free-fire' then coalesce(gp.attributes->>'team_role_main',ro.label)
     when g.slug='valorant' then coalesce(gp.attributes->>'agent_role_main',ro.label)
     else ro.label end,
   reg.label,
   (gp.availability_status='ready' and p.availability_status='ready'),gp.data_updated_at,p.bio
 from public.game_profiles gp join public.games g on g.id=gp.game_id
 join public.profiles p on p.user_id=gp.user_id
 left join public.game_catalog_options r on r.id=gp.primary_rank_option_id
 left join public.game_catalog_options ro on ro.id=gp.primary_role_option_id
 left join public.game_catalog_options reg on reg.id=gp.region_option_id
 where gp.game_id=v_game and gp.status='active' and gp.visibility='public'
   and p.visibility='public' and p.account_status='active' and p.adult_declared_at is not null
   and (auth.uid() is null or not private.blocked(auth.uid(),gp.user_id))
   and (p_game_slug<>'free-fire' or not p_filters ? 'rank_br'
     or gp.attributes->>'ranked_mode'='Battle Royale Ranked')
   and (p_game_slug<>'free-fire' or not p_filters ? 'rank_cs'
     or gp.attributes->>'ranked_mode'='Clash Squad Ranked')
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

-- Detail shares the same canonical presentation, without changing its privacy predicates.
create or replace function public.public_profile_detail(p_id uuid)
returns table(id uuid,user_id uuid,game_id uuid,game_name text,display_name text,avatar_url text,
 ign text,rank text,role text,region text,ready boolean,updated_at timestamptz,bio text)
language sql stable security definer set search_path = '' as $$
 select gp.id,gp.user_id,gp.game_id,g.name,p.display_name,p.avatar_url,gp.ign,
 case when g.slug='mlbb' then coalesce(gp.attributes->>'rank_current',r.label)
   when g.slug='pubg-mobile' then coalesce(gp.attributes->>'rank_tier',r.label)
   when g.slug='free-fire' then case gp.attributes->>'ranked_mode'
     when 'Battle Royale Ranked' then gp.attributes->>'rank_br'
     when 'Clash Squad Ranked' then gp.attributes->>'rank_cs'
     else coalesce(gp.attributes->>'rank',r.label) end
   when g.slug='valorant' then coalesce(gp.attributes->>'rank_current',r.label)
   else r.label end,
 case when g.slug='mlbb' then gp.attributes->>'position_main'
   when g.slug='pubg-mobile' then coalesce(gp.attributes->>'squad_role_main',ro.label)
   when g.slug='free-fire' then coalesce(gp.attributes->>'team_role_main',ro.label)
   when g.slug='valorant' then coalesce(gp.attributes->>'agent_role_main',ro.label)
   else ro.label end,
 reg.label,(gp.availability_status='ready' and p.availability_status='ready'),gp.data_updated_at,p.bio
 from public.game_profiles gp join public.games g on g.id=gp.game_id and g.active
 join public.profiles p on p.user_id=gp.user_id
 left join public.game_catalog_options r on r.id=gp.primary_rank_option_id
 left join public.game_catalog_options ro on ro.id=gp.primary_role_option_id
 left join public.game_catalog_options reg on reg.id=gp.region_option_id
 where gp.id=p_id and gp.status='active' and gp.visibility='public'
 and p.visibility='public' and p.account_status='active' and p.adult_declared_at is not null
 and (auth.uid() is null or not private.blocked(auth.uid(),gp.user_id))
$$;

-- Explicit public projection. Never return the owner JSON wholesale or a private game ID.
create function public.public_profile_game_attributes(p_id uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
 select coalesce((select jsonb_object_agg(a.key,a.value)
   from jsonb_each(gp.attributes) a
   where a.key in ('position_secondary','ranked_mode','queue_mode','game_mode','perspective',
     'mode','match_type','squad_role_main','team_role_main','agent_role_main','play_goal',
     'voice_chat','active_hours','hero_pool','main_character','main_agent','team_role',
     'favorite_map','device','squad_type')), '{}'::jsonb)
 from public.game_profiles gp join public.games g on g.id=gp.game_id and g.active
 join public.profiles p on p.user_id=gp.user_id
 where gp.id=p_id and gp.status='active' and gp.visibility='public'
 and p.visibility='public' and p.account_status='active' and p.adult_declared_at is not null
 and (auth.uid() is null or not private.blocked(auth.uid(),gp.user_id))
$$;
revoke all on function public.public_profile_game_attributes(uuid) from public,anon,authenticated;
grant execute on function public.public_profile_game_attributes(uuid) to anon,authenticated;

-- Search previews use the same limited projection. Avoid a network call for each result card.
create or replace function public.search_game_profiles_by_attributes_with_public_facts(
 p_game_slug text,p_filters jsonb default '{}'::jsonb,p_limit int default 20,p_offset int default 0)
returns table(id uuid,user_id uuid,game_id uuid,game_name text,display_name text,avatar_url text,
 ign text,rank text,role text,region text,ready boolean,updated_at timestamptz,bio text,attributes jsonb)
language sql stable security definer set search_path = '' as $$
 select s.id,s.user_id,s.game_id,s.game_name,s.display_name,s.avatar_url,s.ign,
 s.rank,s.role,s.region,s.ready,s.updated_at,s.bio,public.public_profile_game_attributes(s.id)
 from public.search_game_profiles_by_attributes(p_game_slug,p_filters,p_limit,p_offset) s
$$;
revoke all on function public.search_game_profiles_by_attributes_with_public_facts(text,jsonb,int,int) from public,anon,authenticated;
grant execute on function public.search_game_profiles_by_attributes_with_public_facts(text,jsonb,int,int) to anon,authenticated;
