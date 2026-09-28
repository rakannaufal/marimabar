-- MLBB rank stars are a conditional detail of the selected rank, not a second rank.
-- Existing legacy attributes (including stars) are preserved; new writes use rank_stars.
insert into public.game_attribute_definitions
 (game_id,key,label,category,value_type,filter_type,options,range_min,range_max,unit,sort_order)
select id,'rank_stars','Jumlah Bintang','kompetensi','number','range_min','[]'::jsonb,50,1000000,'bintang',1
from public.games where slug='mlbb'
on conflict (game_id,key) do nothing;

create function private.seed_mlbb_rank_stars() returns trigger language plpgsql security definer set search_path = '' as $$
begin
 if new.slug='mlbb' then
  insert into public.game_attribute_definitions
   (game_id,key,label,category,value_type,filter_type,options,range_min,range_max,unit,sort_order)
  values(new.id,'rank_stars','Jumlah Bintang','kompetensi','number','range_min','[]'::jsonb,50,1000000,'bintang',1)
  on conflict (game_id,key) do nothing;
 end if;
 return new;
end $$;
revoke all on function private.seed_mlbb_rank_stars() from public,anon,authenticated;
create trigger seed_mlbb_rank_stars after insert on public.games
 for each row execute function private.seed_mlbb_rank_stars();

create or replace function private.validate_mlbb_rank_stars() returns trigger language plpgsql set search_path = '' as $$
declare v_slug text; v_rank text; v_stars numeric;
begin
 select slug into v_slug from public.games where id=new.game_id;
 if v_slug<>'mlbb' or not (new.attributes ? 'rank_stars') then return new; end if;
 v_rank := new.attributes->>'rank_current';
 if jsonb_typeof(new.attributes->'rank_stars')<>'number' then
   raise exception 'Jumlah bintang tidak valid' using errcode='23514'; end if;
 v_stars := (new.attributes->>'rank_stars')::numeric;
 if v_rank not in ('Mythic Glory','Mythic Immortal') or v_rank is null
   or (v_rank='Mythic Glory' and (v_stars<50 or v_stars>99))
   or (v_rank='Mythic Immortal' and v_stars<100) then
   raise exception 'Jumlah bintang tidak sesuai rank' using errcode='23514'; end if;
 return new;
end $$;
revoke all on function private.validate_mlbb_rank_stars() from public,anon,authenticated;
create trigger game_profile_mlbb_rank_stars before insert or update on public.game_profiles
 for each row execute function private.validate_mlbb_rank_stars();
