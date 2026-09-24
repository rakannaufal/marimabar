import { createClient, type SupabaseClient } from '@supabase/supabase-js'
import { demoBackend } from './demo'
const url = import.meta.env.VITE_SUPABASE_URL
const key = import.meta.env.VITE_SUPABASE_ANON_KEY
const realConfigured = Boolean(url && key && !url.includes('YOUR_PROJECT') && !key.includes('YOUR_PUBLISHABLE'))
export const configured = realConfigured
export const demoMode = !realConfigured
export const supabase: SupabaseClient | null = realConfigured ? createClient(url, key, { auth: { autoRefreshToken:true, persistSession:true, detectSessionInUrl:true } }) : null
export function requireBackend(): SupabaseClient {
  return supabase || demoBackend as unknown as SupabaseClient
}
