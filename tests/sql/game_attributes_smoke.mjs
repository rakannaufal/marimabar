import { PGlite } from '@electric-sql/pglite'
import { readFileSync, readdirSync } from 'node:fs'
const db = new PGlite()
try {
  await db.exec(`create role anon; create role authenticated; create schema auth;
    create table auth.users(id uuid primary key,instance_id uuid,aud text,role text,email text,
      encrypted_password text,email_confirmed_at timestamptz,
      raw_user_meta_data jsonb default '{}'::jsonb,
      raw_app_meta_data jsonb default '{}'::jsonb);
    create function auth.uid() returns uuid language sql stable as $$
      select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
    grant usage on schema auth to authenticated;`)
  for (const file of readdirSync('supabase/migrations').filter(f => f.endsWith('.sql')).sort()) {
    if (file === '202609240009_hero_agent_options.sql') {
      // Upgrade path: free-form selections already persisted before the catalog existed.
      await db.exec(`insert into public.games(id,slug,name) values
        ('99999999-9999-4999-8999-999999999991','mlbb','Legacy MLBB'),
        ('99999999-9999-4999-8999-999999999992','valorant','Legacy Valorant');
        insert into auth.users(id,raw_user_meta_data) values
        ('99999999-9999-4999-8999-999999999993','{"adult_declared":true}'),
        ('99999999-9999-4999-8999-999999999994','{"adult_declared":true}');
        insert into public.game_profiles(user_id,game_id,ign,attributes) values
        ('99999999-9999-4999-8999-999999999993','99999999-9999-4999-8999-999999999991','legacy-hero','{"hero_pool":["Legacy hero"]}'),
        ('99999999-9999-4999-8999-999999999994','99999999-9999-4999-8999-999999999992','legacy-agent','{"main_agent":["Legacy agent"]}');`)
    }
    await db.exec(readFileSync(`supabase/migrations/${file}`, 'utf8'))
    if (file === '202609240009_hero_agent_options.sql') {
      await db.exec(`update public.game_profiles set ign='still-editable'
        where user_id in ('99999999-9999-4999-8999-999999999993','99999999-9999-4999-8999-999999999994');
        do $$ begin
          if (select count(*) from public.game_profiles where ign='still-editable'
            and (attributes->'hero_pool'='["Legacy hero"]'::jsonb or attributes->'main_agent'='["Legacy agent"]'::jsonb))<>2
          then raise exception 'Historical choices not preserved'; end if;
        end $$;
        delete from public.game_profiles where user_id in ('99999999-9999-4999-8999-999999999993','99999999-9999-4999-8999-999999999994');
        delete from auth.users where id in ('99999999-9999-4999-8999-999999999993','99999999-9999-4999-8999-999999999994');
        delete from public.game_attribute_definitions where game_id in ('99999999-9999-4999-8999-999999999991','99999999-9999-4999-8999-999999999992');
        delete from public.games where id in ('99999999-9999-4999-8999-999999999991','99999999-9999-4999-8999-999999999992');`)
    }
  }
  await db.exec(readFileSync('supabase/seed.sql', 'utf8'))
  await db.exec(readFileSync('tests/sql/game_attributes.sql', 'utf8'))
  console.log('Game attributes SQL behavior OK')
} catch (error) {
  console.error(error.message, error.detail ?? '', error.where ?? '')
  process.exitCode = 1
} finally { await db.close() }
