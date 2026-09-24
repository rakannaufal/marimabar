<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { configured, supabase } from '../lib/supabase'
import { useSessionStore } from '../stores/session'

const route = useRoute()
const router = useRouter()
const session = useSessionStore()
const error = ref('')

onMounted(async () => {
  if (!configured || !supabase) { error.value = 'Layanan akun belum dikonfigurasi.'; return }
  try {
    if (route.query.error || route.query.error_description) throw new Error('OAuth cancelled')
    // Supabase completes the OAuth redirect before this callback asks for the verified user.
    await session.refreshUser()
    if (!session.user) throw new Error('No authenticated user')
    if (route.query.register === '1') {
      const { error: failure } = await supabase.rpc('declare_adult_account')
      if (failure) throw failure
    } else {
      const { data: profile, error: failure } = await supabase.from('profiles').select('adult_declared_at').eq('user_id', session.user.id).single()
      if (failure) throw failure
      if (!profile.adult_declared_at) { await router.replace('/register'); return }
    }
    const redirect = route.query.redirect
    const safe = typeof redirect === 'string' && redirect.startsWith('/') && !redirect.startsWith('//') && !redirect.startsWith('/\\')
      ? redirect : '/beranda'
    await router.replace(safe)
  } catch { error.value = 'Masuk dengan Google belum berhasil. Coba lagi atau periksa konfigurasi akun.' }
})
</script>

<template>
  <main class="callback-page" aria-live="polite">
    <h1>{{ error ? 'Tidak dapat masuk' : 'Menghubungkan akun Google…' }}</h1>
    <p v-if="error" role="alert">{{ error }} <RouterLink to="/login">Kembali ke halaman masuk</RouterLink></p>
    <p v-else>Mohon tunggu sebentar.</p>
  </main>
</template>

<style scoped>
.callback-page{width:min(100% - 32px,500px);margin:12vh auto;padding:32px;background:#1e1e29;border:1px solid #393944;border-radius:18px}.callback-page a{color:#c8ff4d;text-decoration:underline}
</style>
