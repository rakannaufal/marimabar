import { PGlite } from '@electric-sql/pglite'
import { readFileSync } from 'node:fs'
const db=new PGlite()
const bootstrap=`create role anon;create role authenticated;create schema auth;create table auth.users(id uuid primary key,instance_id uuid,aud text,role text,email text,encrypted_password text,email_confirmed_at timestamptz,raw_user_meta_data jsonb default '{}'::jsonb);create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema auth to authenticated;`
try {
 await db.exec(bootstrap)
 console.log('Bootstrap OK')
 await db.exec(readFileSync(new URL('../../supabase/migrations/202609240001_mvp.sql',import.meta.url),'utf8'))
 console.log('Migration OK in PGlite')
 await db.exec(readFileSync(new URL('../../supabase/seed.sql',import.meta.url),'utf8'))
 console.log('Seed OK in PGlite')
 const {rows}=await db.query('select slug,name from public.games order by slug')
 console.log(rows)
 await db.exec(readFileSync(new URL('./mvp.sql',import.meta.url),'utf8'))
 console.log('SQL behavior/RLS tests OK in PGlite')
} catch(error){ console.error('SQL failure:',error.message, JSON.stringify(error,null,2));process.exitCode=1 }
finally {await db.close()}
