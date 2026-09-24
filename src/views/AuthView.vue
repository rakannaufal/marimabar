<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { configured, supabase } from '../lib/supabase'
import { useSessionStore } from '../stores/session'

const route = useRoute(), router = useRouter(), session = useSessionStore()
const register = computed(() => route.path === '/register')
const email = ref(''), password = ref(''), nickname = ref(''), city = ref(''), showPassword = ref(false)
const adult = ref(false), consent = ref(false), busy = ref(false), error = ref('')
watch(register, () => { error.value = ''; password.value = ''; showPassword.value = false })
function destination() {
  const redirect = route.query.redirect
  return typeof redirect === 'string' && redirect.startsWith('/') && !redirect.startsWith('//') && !redirect.startsWith('/\\') ? redirect : '/beranda'
}
async function googleSignIn() {
  if (!configured || !supabase || busy.value) return
  error.value = ''
  if (register.value && (!adult.value || !consent.value)) {
    error.value = 'Konfirmasi usia minimal 18 tahun dan persetujuan aturan komunitas sebelum mendaftar dengan Google.'
    return
  }
  busy.value = true
  try {
    const callback = new URL('/auth/callback', location.origin)
    callback.searchParams.set('redirect', destination())
    if (register.value) callback.searchParams.set('register', '1')
    const { error: failure } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: callback.href },
    })
    if (failure) throw failure
  } catch { error.value = 'Gagal terhubung ke Google. Periksa konfigurasi provider dan coba lagi.' }
  finally { busy.value = false }
}
async function submit() {
  if (!configured || !supabase || busy.value) return
  error.value = ''
  if (register.value && (!adult.value || !consent.value)) { error.value = 'Konfirmasi usia minimal 18 tahun dan persetujuan aturan komunitas.'; return }
  if (register.value && (nickname.value.trim().length < 2 || nickname.value.trim().length > 60)) { error.value = 'Nickname harus 2–60 karakter.'; return }
  if (password.value.length < 8) { error.value = 'Kata sandi minimal 8 karakter.'; return }
  busy.value = true
  try {
    if (register.value) {
      const { data, error: failure } = await supabase.auth.signUp({ email: email.value.trim(), password: password.value, options: { emailRedirectTo: new URL('/verifikasi-email/berhasil', location.origin).href, data: { display_name: nickname.value.trim(), adult_declared: true } } })
      // Supabase may return an existing-user obfuscated response; never treat it as proof of registration.
      if (!data.user) throw new Error('Registration did not return an account')
      if (failure) throw failure
      password.value = ''
      await router.push('/verifikasi-email')
    } else {
      const { error: failure } = await supabase.auth.signInWithPassword({ email: email.value.trim(), password: password.value })
      if (failure) throw failure
      password.value = ''
      await session.refreshUser()
      await router.replace(destination())
    }
  } catch { error.value = register.value ? 'Pendaftaran belum berhasil. Periksa data lalu coba lagi.' : 'Gagal masuk. Periksa email dan kata sandi.' }
  finally { busy.value = false }
}
</script>
<template>
  <main class="auth"><aside class="visual"><RouterLink class="brand" to="/">Mabar Finder</RouterLink><div class="visual-copy"><h1>Teman satu frekuensi mulai dari sini.</h1><p>Kenali pemain lewat game, role, dan waktu main. Rank diisi sendiri oleh pengguna, belum terverifikasi.</p><div class="preview"><span class="avatar" aria-hidden="true">MF</span><div><strong>Squad barumu menanti</strong><small>Mulai dengan profilmu sendiri</small></div></div></div></aside>
    <section class="panel" aria-labelledby="auth-title"><nav class="tabs" aria-label="Pilihan akun"><RouterLink to="/login" :aria-current="!register ? 'page' : undefined">Masuk</RouterLink><RouterLink to="/register" :aria-current="register ? 'page' : undefined">Daftar</RouterLink></nav>
      <h2 id="auth-title">{{ register ? 'Buat akun baru, gampang kok' : 'Masuk ke akunmu, yuk!' }}</h2><p>{{ register ? 'Kenalan dulu sebelum masuk ke lobi.' : 'Lanjutkan cari teman mabar yang cocok.' }}</p>
      <p v-if="!configured" role="alert" class="error">Layanan akun belum dikonfigurasi. Pendaftaran dan masuk belum tersedia. Hubungi pengelola situs.</p>
      <p v-if="error" role="alert" class="error">{{ error }}</p>
      <form @submit.prevent="submit"><template v-if="register"><label for="auth-name">Nickname</label><input id="auth-name" v-model="nickname" required minlength="2" maxlength="60" autocomplete="nickname" placeholder="Nama tampilan kamu"><label for="auth-city">Kota <span class="optional">(opsional, belum disimpan)</span></label><input id="auth-city" v-model="city" disabled placeholder="Kota belum tersedia di profil"></template>
        <label for="auth-email">Email</label><input id="auth-email" v-model="email" type="email" autocomplete="email" required placeholder="nama@email.com"><div class="password-label"><label for="auth-password">Kata sandi</label><RouterLink v-if="!register" to="/lupa-password">Lupa kata sandi?</RouterLink></div><div class="password-wrap"><input id="auth-password" v-model="password" :type="showPassword ? 'text' : 'password'" :autocomplete="register ? 'new-password' : 'current-password'" required minlength="8"><button class="show" type="button" :aria-label="showPassword ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi'" :aria-pressed="showPassword" @click="showPassword = !showPassword">{{ showPassword ? 'Sembunyikan' : 'Tampilkan' }}</button></div>
        <template v-if="register"><label class="check"><input v-model="adult" type="checkbox" required> Saya menyatakan berusia 18 tahun atau lebih.</label><label class="check"><input v-model="consent" type="checkbox" required> Saya setuju mengikuti <RouterLink to="/syarat-ketentuan">aturan komunitas</RouterLink> dan <RouterLink to="/kebijakan-privasi">kebijakan privasi</RouterLink>.</label></template>
        <button class="primary" :disabled="busy || !configured">{{ busy ? 'Memproses…' : register ? 'Buat Akun Sekarang' : 'Masuk' }}</button>
      </form><div class="oauth-divider"><span>atau lanjutkan dengan</span></div><button class="google-button" type="button" :disabled="busy || !configured" @click="googleSignIn"><svg viewBox="0 0 48 48" aria-hidden="true"><path fill="#EA4335" d="M24 9.5c3.5 0 6.6 1.2 9 3.5l6.7-6.7C35.6 2.4 30.3 0 24 0 14.6 0 6.5 5.4 2.6 13.2l7.8 6.1C12.3 13.6 17.7 9.5 24 9.5Z"/><path fill="#4285F4" d="M46.1 24.6c0-1.6-.2-3.1-.4-4.6H24v9h12.4c-.5 2.9-2.2 5.3-4.7 7l7.4 5.8c4.4-4.1 7-10.1 7-17.2Z"/><path fill="#FBBC05" d="M10.4 28.7a14.5 14.5 0 0 1 0-9.4l-7.8-6.1a24 24 0 0 0 0 21.6l7.8-6.1Z"/><path fill="#34A853" d="M24 48c6.3 0 11.6-2.1 15.5-5.8L32.1 36c-2.1 1.4-4.8 2.3-8.1 2.3-6.3 0-11.7-4.1-13.6-9.8l-7.8 6.1C6.5 42.6 14.6 48 24 48Z"/></svg>{{ register ? 'Daftar dengan Google' : 'Masuk dengan Google' }}</button><p v-if="register" class="google-note">Centang pernyataan usia dan persetujuan di atas sebelum melanjutkan.</p><p class="swap">{{ register ? 'Sudah punya akun?' : 'Belum punya akun?' }} <RouterLink :to="register ? '/login' : '/register'">{{ register ? 'Masuk di sini' : 'Yuk daftar di sini' }}</RouterLink></p>
      <p class="fine-print">Akun Google memakai layanan Supabase. Jika belum aktif, hubungi pengelola situs.</p>
    </section>
  </main>
</template>
<style scoped>
.auth{min-height:100vh;background:#14141c;color:#f5f3ee;display:grid;grid-template-columns:55% minmax(0,45%)}.visual{min-height:100vh;display:flex;align-items:end;background:#272733 url('/design-assets/hero-game.jpg') center/cover;position:relative;padding:clamp(2rem,5vw,5rem);isolation:isolate}.visual:before{content:'';position:absolute;inset:0;background:#14141caa;z-index:-1}.brand{position:absolute;top:2rem;left:clamp(2rem,5vw,5rem);font:800 1.3rem 'Plus Jakarta Sans',sans-serif;color:#f5f3ee}.visual-copy{max-width:560px}.visual h1{font:800 clamp(2.25rem,4.5vw,4.5rem)/1.13 'Plus Jakarta Sans',sans-serif}.visual p{color:#ebe9ee;line-height:1.65}.preview{display:flex;align-items:center;gap:1rem;background:#252532;border:1px solid #666473;border-radius:19px;padding:1rem;margin-top:1.5rem;width:max-content;max-width:100%}.avatar{width:48px;height:48px;border-radius:50%;border:2px solid #8b7cff;display:grid;place-items:center;font-weight:800}.preview small{display:block;color:#bbb9c8}.panel{width:min(490px,calc(100% - 3rem));margin:auto;padding:2rem 0}.tabs{display:flex;gap:.5rem;margin-bottom:2.4rem}.tabs a{border:1px solid #555463;padding:.7rem 1.5rem;border-radius:999px;text-decoration:none;font-weight:700}.tabs a[aria-current]{background:#c8ff4d;border-color:#c8ff4d;color:#14141c}.panel h2{font:800 clamp(1.75rem,3vw,2.45rem)/1.2 'Plus Jakarta Sans',sans-serif}.panel p{color:#c6c4d0;line-height:1.6}.panel form{display:grid;gap:.65rem;margin-top:1.7rem}.panel label{font-weight:700}.panel input:not([type=checkbox]){width:100%;min-height:48px;background:#242431;color:#f5f3ee;border:1px solid #777581;border-radius:14px;padding:.8rem 1rem}.panel input::placeholder{color:#aaa8b4}.password-wrap{position:relative}.password-wrap input{padding-right:120px!important}.password-label{display:flex;justify-content:space-between;gap:.5rem}.password-label a,.swap a,.check a{color:#c8ff4d}.password-label a{font-size:.85rem}.show{position:absolute;right:.4rem;top:.3rem;min-height:38px;border:0;background:transparent;color:#c8ff4d;padding:.2rem .5rem;font-size:.85rem;font-weight:700}.check{display:flex;align-items:start;gap:.6rem;font-weight:400!important;line-height:1.5;font-size:.87rem}.check input{accent-color:#c8ff4d;margin:.3rem 0 0}.primary,.persona{border:0;border-radius:999px;min-height:48px;padding:.8rem 1.2rem;font-weight:800;cursor:pointer}.primary{background:#c8ff4d;color:#14141c;margin-top:1rem}.personas{display:grid;gap:.75rem}.persona{text-align:left;color:#f5f3ee;background:#292938;border:1px solid #666473}.persona:hover{border-color:#c8ff4d}.swap{margin-top:1.5rem}.fine-print,.optional{font-size:.8rem;color:#aaa8b4!important}.error{color:#ffc0ba!important}button:disabled{opacity:.55;cursor:not-allowed}:focus-visible{outline:3px solid #c8ff4d;outline-offset:3px}@media(max-width:850px){.auth{grid-template-columns:1fr}.visual{min-height:250px;padding:5rem 1.5rem 1.5rem}.brand{top:1.5rem;left:1.5rem}.visual h1{font-size:2rem}.preview{display:none}.panel{padding:2rem 0 4rem}}@media(max-width:480px){.panel{width:calc(100% - 2rem)}.password-label{flex-wrap:wrap}}
.auth{grid-template-columns:minmax(0,1.05fr) minmax(0,.95fr)}.visual,.panel{min-width:0}.panel{max-width:490px}.oauth-divider{display:flex;align-items:center;gap:14px;margin:22px 0 16px;color:#c6c4d0;font-size:.82rem;white-space:nowrap}.oauth-divider:before,.oauth-divider:after{content:'';height:1px;flex:1;background:#555463}.google-button{width:100%;min-height:48px;display:flex;align-items:center;justify-content:center;gap:12px;border:1px solid #777581;border-radius:12px;background:#242431;color:#f5f3ee;font-weight:700}.google-button:hover:not(:disabled){border-color:#c8ff4d;background:#30303b}.google-button svg{width:20px;height:20px;flex:none}.panel .google-note{font-size:.8rem;color:#c6c4d0;margin:10px 0 0}@media(max-width:850px){.auth{grid-template-columns:minmax(0,1fr)}}
</style>
