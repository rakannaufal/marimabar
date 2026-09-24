import { PGlite } from '@electric-sql/pglite'
import { readFileSync, readdirSync } from 'node:fs'
const db = new PGlite()
try {
  await db.exec(`create role anon; create role authenticated; create schema auth;
    create table auth.users(id uuid primary key,instance_id uuid,aud text,role text,email text,
      encrypted_password text,email_confirmed_at timestamptz,raw_user_meta_data jsonb default '{}'::jsonb);
    create function auth.uid() returns uuid language sql stable as $$
      select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
    grant usage on schema auth to authenticated;`)
  for (const file of readdirSync('supabase/migrations').filter(f => f.endsWith('.sql')).sort()) {
    await db.exec(readFileSync(`supabase/migrations/${file}`, 'utf8'))
  }
  await db.exec(readFileSync('supabase/seed.sql', 'utf8'))
  await db.exec(readFileSync('tests/sql/game_attributes.sql', 'utf8'))
  console.log('Game attributes SQL behavior OK')
} catch (error) {
  console.error(error.message, error.detail ?? '', error.where ?? '')
  process.exitCode = 1
} finally { await db.close() }
