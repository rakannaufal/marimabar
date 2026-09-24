<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { demoMode, supabase } from '../lib/supabase'

const route = useRoute(), router = useRouter()
const resetting = computed(() => route.path.startsWith('/reset-password'))
const email = ref(''), password = ref(''), confirm = ref('')
const busy = ref(false), checking = ref(true), authorized = ref(false), sent = ref(false), complete = ref(false)
const seconds = ref(0), error = ref('')
const strength = computed(() => password.value.length < 8 ? 'lemah' : password.value.length < 12 || !/[A-Z]/.test(password.value) || !/[0-9]/.test(password.value) ? 'cukup' : 'kuat')
let timer: ReturnType<typeof setInterval> | undefined
let subscription: { unsubscribe: () => void } | undefined
function cooldown() {
  seconds.value = 60
  if (timer) clearInterval(timer)
  timer = setInterval(() => { seconds.value--; if (!seconds.value && timer) { clearInterval(timer); timer = undefined } }, 1000)
}
onMounted(async () => {
  if (demoMode || !supabase) { checking.value = false; return }
  subscription = supabase.auth.onAuthStateChange((event) => { if (event === 'PASSWORD_RECOVERY') authorized.value = true }).data.subscription
  if (resetting.value) {
    // Only PASSWORD_RECOVERY authorizes this form. An ordinary signed-in
    // session or an arbitrary :token path segment must never count as a link.
    await supabase.auth.getSession()
  }
  checking.value = false
})
onUnmounted(() => { subscription?.unsubscribe(); if (timer) clearInterval(timer) })
async function requestLink() {
  if (!supabase || demoMode || busy.value || seconds.value) return
  error.value = ''; busy.value = true
  try {
    const { error: failure } = await supabase.auth.resetPasswordForEmail(email.value.trim(), { redirectTo: new URL('/reset-password', location.origin).href })
    if (failure) throw failure
    sent.value = true
    cooldown()
  } catch { error.value = 'Permintaan belum berhasil. Tunggu sebentar lalu coba lagi.' }
  finally { busy.value = false }
}
async function updatePassword() {
  error.value = ''
  if (!supabase || demoMode || !authorized.value || busy.value) return
  if (password.value.length < 8) { error.value = 'Kata sandi minimal 8 karakter.'; return }
  if (password.value !== confirm.value) { error.value = 'Konfirmasi kata sandi tidak cocok.'; return }
  busy.value = true
  try {
    const { error: failure } = await supabase.auth.updateUser({ password: password.value })
    if (failure) throw failure
    password.value = ''; confirm.value = ''; complete.value = true
    // Recovery sessions should not remain active on a shared device.
    const { error: signOutFailure } = await supabase.auth.signOut()
    if (signOutFailure) error.value = 'Kata sandi tersimpan. Keluar dari sesi ini secara manual jika memakai perangkat bersama.'
  } catch { error.value = 'Tautan mungkin sudah kedaluwarsa. Minta tautan baru dan coba lagi.' }
  finally { busy.value = false }
}
</script>
<template>
  <main class="recovery"><aside class="visual"><RouterLink class="brand" to="/">Mabar Finder</RouterLink><div><h2>Balik ke squad, tanpa ribet.</h2><p>Akunmu tetap milikmu. Gunakan tautan pemulihan yang dikirim oleh Supabase saat layanan aktif.</p></div></aside>
    <section class="panel" aria-labelledby="recovery-title">
      <div v-if="demoMode"><h1 id="recovery-title">Pemulihan tidak tersedia di demo</h1><p>Reset kata sandi dan email tidak tersedia di mode demo. Pilih persona tanpa memasukkan kata sandi.</p><RouterLink class="primary" to="/login">Pilih persona demo</RouterLink></div>
      <div v-else-if="!resetting"><template v-if="sent"><div class="symbol" aria-hidden="true">✉</div><h1 id="recovery-title">Cek email kamu, ya</h1><p>Jika <strong>{{ email }}</strong> terdaftar, tautan reset akan dikirim. Periksa kotak masuk dan spam.</p><button class="outline" type="button" :disabled="busy || seconds > 0" @click="requestLink">{{ busy ? 'Mengirim…' : seconds ? `Kirim ulang dalam ${seconds} detik` : 'Kirim ulang' }}</button></template><template v-else><h1 id="recovery-title">Lupa kata sandi? Santai aja</h1><p>Masukkan email akunmu untuk meminta tautan pemulihan.</p><form @submit.prevent="requestLink"><label for="recovery-email">Email</label><input id="recovery-email" v-model="email" type="email" autocomplete="email" required placeholder="nama@email.com"><button class="primary" :disabled="busy">{{ busy ? 'Mengirim…' : 'Kirim Tautan Reset' }}</button></form></template><p v-if="error" class="error" role="alert">{{ error }}</p><RouterLink class="text-link" to="/login">Kembali ke halaman masuk</RouterLink></div>
      <div v-else-if="checking" role="status">Memeriksa tautan reset…</div>
      <div v-else-if="complete"><h1 id="recovery-title">Kata sandi berhasil diperbarui</h1><p>Silakan masuk dengan kata sandi baru.</p><p v-if="error" class="error" role="alert">{{ error }}</p><RouterLink class="primary" to="/login">Kembali ke masuk</RouterLink></div>
      <div v-else-if="!authorized"><h1 id="recovery-title">Tautan ini sudah tidak berlaku</h1><p>Minta tautan baru, yuk. Jangan gunakan tautan yang sudah kedaluwarsa.</p><RouterLink class="primary" to="/lupa-password">Minta tautan baru</RouterLink></div>
      <div v-else><h1 id="recovery-title">Atur kata sandi baru</h1><p>Gunakan minimal 8 karakter. Jangan bagikan kata sandimu ke siapa pun.</p><p v-if="error" class="error" role="alert">{{ error }}</p><form @submit.prevent="updatePassword"><label for="new-password">Password baru</label><input id="new-password" v-model="password" type="password" autocomplete="new-password" required minlength="8"><div v-if="password" class="strength" :class="strength" role="status">Kekuatan kata sandi: {{ strength }}</div><label for="confirm-password">Konfirmasi password</label><input id="confirm-password" v-model="confirm" type="password" autocomplete="new-password" required minlength="8"><button class="primary" :disabled="busy">{{ busy ? 'Menyimpan…' : 'Simpan Password Baru' }}</button></form></div>
    </section>
  </main>
</template>
<style scoped>
.recovery{min-height:100vh;background:#14141c;color:#f5f3ee;display:grid;grid-template-columns:55% minmax(0,45%)}.visual{min-height:100vh;background:#272733 url('/design-assets/hero-game.jpg') center/cover;position:relative;display:flex;align-items:end;padding:clamp(2rem,5vw,5rem);isolation:isolate}.visual:before{content:'';position:absolute;inset:0;background:#14141caa;z-index:-1}.brand{position:absolute;top:2rem;left:clamp(2rem,5vw,5rem);font:800 1.25rem 'Plus Jakarta Sans',sans-serif}.visual h2{font-size:clamp(2rem,4vw,3.7rem);max-width:540px}.visual p{max-width:490px;color:#e3e1e9}.panel{width:min(490px,calc(100% - 3rem));margin:auto;background:#1e1e29;border:1px solid #424151;border-radius:24px;padding:clamp(1.5rem,4vw,2.7rem)}.panel h1{font:800 clamp(1.7rem,3vw,2.3rem)/1.2 'Plus Jakarta Sans',sans-serif;margin:0 0 1rem}.panel p{color:#d0ced9;line-height:1.65}.panel strong{color:#f5f3ee;overflow-wrap:anywhere}.panel form{display:grid;gap:.7rem;margin:1.5rem 0}.panel label{font-weight:700}.panel input{background:#292935;color:#f5f3ee;border:1px solid #777581;padding:.8rem 1rem;border-radius:14px;min-height:48px;width:100%}.panel input::placeholder{color:#aaa8b4}.primary,.outline{display:inline-flex;justify-content:center;align-items:center;width:100%;min-height:48px;border-radius:999px;padding:.75rem 1rem;font-weight:800;margin-top:1rem;text-decoration:none}.primary{background:#c8ff4d;color:#14141c;border:0}.outline{background:transparent;color:#c8ff4d;border:1px solid #c8ff4d}.text-link{display:block;color:#c8ff4d;margin-top:1.2rem}.symbol{background:#303049;color:#c8ff4d;border-radius:20px;width:70px;height:70px;display:grid;place-items:center;font-size:2.5rem;margin-bottom:1rem}.error{color:#ffc0ba!important}.strength{border-radius:999px;padding:.4rem .8rem;font-size:.83rem;font-weight:700}.strength.lemah{background:#58302f;color:#ffc0ba}.strength.cukup{background:#383845;color:#eeeaf5}.strength.kuat{background:#264833;color:#b9f7cb}button:disabled{opacity:.55;cursor:not-allowed}:focus-visible{outline:3px solid #c8ff4d;outline-offset:3px}@media(max-width:850px){.recovery{grid-template-columns:1fr}.visual{min-height:220px;padding:5rem 1.5rem 1.5rem}.brand{top:1.5rem;left:1.5rem}.visual h2{font-size:1.8rem}.panel{margin:2rem auto 4rem}}@media(max-width:480px){.panel{width:calc(100% - 2rem)}}
</style>
