import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { User } from '@supabase/supabase-js'
import { supabase } from '../lib/supabase'
import { isAdmin } from '../lib/api'

export const useSessionStore = defineStore('session', () => {
  const user = ref<User | null>(null)
  const loading = ref(true)
  const admin = ref(false)
  const verified = computed(() => Boolean(user.value?.email_confirmed_at))
  let initialized = false
  let revision = 0

  async function refreshUser() {
    const current = ++revision
    if (!supabase) { user.value = null; admin.value = false; return }
    const { data, error } = await supabase.auth.getUser()
    if (error && error.name !== 'AuthSessionMissingError') throw error
    if (current !== revision) return
    user.value = data.user
    admin.value = false
    if (data.user) {
      const value = await isAdmin(data.user.id)
      if (current === revision) admin.value = value
    }
  }

  async function initialize() {
    if (initialized) return
    initialized = true
    try {
      await refreshUser()
      supabase?.auth.onAuthStateChange((_event, session) => {
        const current = ++revision
        user.value = session?.user ?? null
        admin.value = false
        if (session?.user) {
          setTimeout(() => {
            void isAdmin(session.user.id).then(value => {
              if (current === revision) admin.value = value
            }).catch(() => { if (current === revision) admin.value = false })
          }, 0)
        }
      })
    } catch { user.value = null; admin.value = false }
    finally { loading.value = false }
  }

  async function signOut() {
    if (!supabase) throw new Error('Supabase belum dikonfigurasi')
    const { error } = await supabase.auth.signOut()
    if (error) throw error
    ++revision
    user.value = null
    admin.value = false
  }

  return { user, loading, admin, verified, initialize, refreshUser, signOut }
})
