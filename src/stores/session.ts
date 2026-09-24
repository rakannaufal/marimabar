import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { User } from '@supabase/supabase-js'
import { demoMode, supabase } from '../lib/supabase'
import { demoLogin, demoLogout, demoUser } from '../lib/demo'
import { isAdmin } from '../lib/api'
export const useSessionStore=defineStore('session',()=>{
  const user=ref<User|null>(null)
  const loading=ref(true)
  const admin=ref(false)
  const verified=computed(()=>Boolean(user.value?.email_confirmed_at))
  let initialized=false
  async function initialize(){
    if(demoMode){user.value=demoUser();admin.value=user.value?.id==='demo-admin';loading.value=false;return}
    if(initialized)return
    initialized=true
    try {
      if(demoMode){ user.value=demoUser();admin.value=user.value?.id==='demo-admin';return }
      if(!supabase)return
      const {data,error}=await supabase.auth.getUser()
      if(error && error.name!=='AuthSessionMissingError') throw error
      user.value=data.user
      if(user.value) admin.value=await isAdmin(user.value.id)
      supabase.auth.onAuthStateChange((_event,session)=>{
        user.value=session?.user??null
        admin.value=false
        if(session?.user) setTimeout(()=>{void isAdmin(session.user.id).then(v=>admin.value=v).catch(()=>admin.value=false)},0)
      })
    } catch { user.value=null;admin.value=false }
    finally {loading.value=false}
  }
  async function signInDemo(id:string){ if(!demoMode)throw new Error('Login demo hanya tersedia tanpa Supabase');user.value=demoLogin(id);admin.value=id==='demo-admin';loading.value=false }
  async function signOut(){ if(demoMode){demoLogout();user.value=null;admin.value=false;return} if(!supabase)return; const {error}=await supabase.auth.signOut();if(error)throw error;user.value=null;admin.value=false }
  return {user,loading,admin,verified,initialize,signInDemo,signOut}
})
