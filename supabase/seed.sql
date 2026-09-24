-- Stable seed IDs; safe to rerun. Taxonomy labels are starter values, not official live ranks.
insert into public.games(id,slug,name) values
 ('11111111-1111-4111-8111-111111111111','mlbb','Mobile Legends: Bang Bang'),
 ('22222222-2222-4222-8222-222222222222','pubg-mobile','PUBG Mobile'),
 ('33333333-3333-4333-8333-333333333333','free-fire','Free Fire'),
 ('44444444-4444-4444-8444-444444444444','valorant','Valorant')
on conflict(id) do nothing;
insert into public.game_seasons(id,game_id,code,label) values
 ('11111111-1111-4111-8111-111111111112','11111111-1111-4111-8111-111111111111','mvp','MVP'),
 ('22222222-2222-4222-8222-222222222223','22222222-2222-4222-8222-222222222222','mvp','MVP'),
 ('33333333-3333-4333-8333-333333333334','33333333-3333-4333-8333-333333333333','mvp','MVP'),
 ('44444444-4444-4444-8444-444444444445','44444444-4444-4444-8444-444444444444','mvp','MVP')
on conflict(id) do nothing;
with source(game_id,kind,codes) as (values
 ('11111111-1111-4111-8111-111111111111'::uuid,'rank',array['warrior','elite','master','grandmaster','epic','legend','mythic','mythical-glory']),
 ('11111111-1111-4111-8111-111111111111'::uuid,'role',array['tank','fighter','assassin','mage','marksman','support']),
 ('11111111-1111-4111-8111-111111111111'::uuid,'mode',array['classic','ranked','brawl']),
 ('11111111-1111-4111-8111-111111111111'::uuid,'hero',array['other']),
 ('22222222-2222-4222-8222-222222222222'::uuid,'rank',array['bronze','silver','gold','platinum','diamond','crown','ace','conqueror']),
 ('22222222-2222-4222-8222-222222222222'::uuid,'role',array['igl','rusher','support','sniper']),
 ('22222222-2222-4222-8222-222222222222'::uuid,'mode',array['classic','arena']),
 ('22222222-2222-4222-8222-222222222222'::uuid,'perspective',array['tpp','fpp']),
 ('22222222-2222-4222-8222-222222222222'::uuid,'team_size',array['solo','duo','squad']),
 ('22222222-2222-4222-8222-222222222222'::uuid,'map',array['erangel','miramar','sanhok','vikendi']),
 ('33333333-3333-4333-8333-333333333333'::uuid,'rank',array['bronze','silver','gold','platinum','diamond','heroic','grandmaster']),
 ('33333333-3333-4333-8333-333333333333'::uuid,'role',array['rusher','support','sniper','igl']),
 ('33333333-3333-4333-8333-333333333333'::uuid,'mode',array['battle-royale','clash-squad']),
 ('44444444-4444-4444-8444-444444444444'::uuid,'rank',array['iron','bronze','silver','gold','platinum','diamond','ascendant','immortal','radiant']),
 ('44444444-4444-4444-8444-444444444444'::uuid,'role',array['duelist','initiator','controller','sentinel']),
 ('44444444-4444-4444-8444-444444444444'::uuid,'mode',array['competitive','unrated','swiftplay']),
 ('44444444-4444-4444-8444-444444444444'::uuid,'agent',array['other'])
), expanded as (
 select game_id,kind,code,ordinality::integer as position from source cross join lateral unnest(codes) with ordinality as u(code,ordinality)
), regions as (
 select id as game_id,'region'::text as kind,code,position from public.games
 cross join (values('asia',1),('sea',2),('indonesia',3)) as r(code,position)
 where slug in('mlbb','pubg-mobile','free-fire','valorant')
), rows as (select * from expanded union all select * from regions)
insert into public.game_catalog_options(game_id,season_id,kind,code,label,sort_order)
select rows.game_id,s.id,rows.kind,rows.code,initcap(replace(rows.code,'-',' ')),rows.position
from rows join public.game_seasons s on s.game_id=rows.game_id and s.code='mvp'
on conflict(game_id,kind,season_id,code) do nothing;
-- Rank options for mode-specific games must always carry their mode.
update public.game_catalog_options r set rank_mode_option_id=m.id
from public.game_catalog_options m where r.game_id=m.game_id and r.season_id=m.season_id and r.kind='rank' and m.kind='mode'
 and m.code=case when r.game_id='33333333-3333-4333-8333-333333333333' then 'battle-royale'
                 when r.game_id='22222222-2222-4222-8222-222222222222' then 'classic' end
 and r.rank_mode_option_id is null;
-- Distinct BR/CS Free Fire ranks (same display label, stable distinct IDs).
insert into public.game_catalog_options(game_id,season_id,kind,code,label,sort_order,rank_mode_option_id)
select r.game_id,r.season_id,'rank',r.code || '-cs',r.label,r.sort_order,m.id
from public.game_catalog_options r join public.game_catalog_options m on m.game_id=r.game_id and m.season_id=r.season_id and m.kind='mode' and m.code='clash-squad'
where r.game_id='33333333-3333-4333-8333-333333333333' and r.kind='rank' and r.code not like '%-cs'
on conflict(game_id,kind,season_id,code) do nothing;
