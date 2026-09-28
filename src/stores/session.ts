import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import type { User } from '@supabase/supabase-js'
import { supabase } from '../lib/supabase'
import { isAdmin } from '../lib/api'
import { accountLanding } from '../lib/accountAccess'

export const useSessionStore = defineStore('session', () => {
  const user = ref<User | null>(null)
  const loading = ref(true)
  const admin = ref(false)
  const registered = ref(false)
  const onboardingCompleted = ref(false)
  const verified = computed(() => Boolean(user.value?.email_confirmed_at))
  const provider = computed(() => {
    const raw = user.value?.app_metadata?.provider || (user.value?.app_metadata?.providers as string[] | undefined)?.[0] || user.value?.identities?.[0]?.provider
    return typeof raw === 'string' ? raw.toLowerCase() : null
  })
  const isGoogle = computed(() => provider.value === 'google')
  let revision = 0
  let initialization: Promise<void> | null = null

  function clear() {
    user.value = null
    admin.value = false
    registered.value = false
    onboardingCompleted.value = false
  }

  async function checkProfile() {
    const id = user.value?.id
    const current = revision
    if (!supabase || !id) { registered.value = false; onboardingCompleted.value = false; return }
    const { data, error } = await supabase.from('profiles')
      .select('adult_declared_at,onboarding_completed_at,account_status')
      .eq('user_id', id).maybeSingle()
    if (error) throw new Error(error.message)
    if (current !== revision || user.value?.id !== id) return
    // OAuth metadata is client-editable; only the application profile proves registration.
    registered.value = data?.account_status === 'active' && Boolean(data.adult_declared_at)
    onboardingCompleted.value = registered.value && Boolean(data?.onboarding_completed_at)
  }

  async function refreshUser() {
    const current = ++revision
    if (!supabase) { clear(); return }
    const { data, error } = await supabase.auth.getUser()
    if (error && error.name !== 'AuthSessionMissingError') throw error
    if (current !== revision) return
    user.value = data.user
    admin.value = false
    registered.value = false
    onboardingCompleted.value = false
    if (!data.user) return
    await checkProfile()
    const value = await isAdmin(data.user.id).catch(() => false)
    if (current === revision) admin.value = value
  }

  function initialize(): Promise<void> {
    if (initialization) return initialization
    initialization = (async () => {
      try {
        await refreshUser()
        supabase?.auth.onAuthStateChange((_event, session) => {
          // Supabase warns against awaiting API requests inside this callback.
          if (!session?.user) { ++revision; clear(); return }
          setTimeout(() => { void refreshUser().catch(() => { ++revision; clear() }) }, 0)
        })
      } finally { loading.value = false }
    })().catch(error => { initialization = null; throw error })
    return initialization
  }

  async function signOut() {
    if (!supabase) throw new Error('Supabase belum dikonfigurasi')
    const { error } = await supabase.auth.signOut()
    if (error) throw error
    ++revision
    clear()
  }

  function landing() {
    return accountLanding({
      registered: registered.value,
      verified: verified.value,
      completed: onboardingCompleted.value,
      provider: provider.value,
    })
  }

  return { user, loading, admin, verified, registered, onboardingCompleted, provider, isGoogle, initialize, refreshUser, signOut, checkProfile, landing }
})