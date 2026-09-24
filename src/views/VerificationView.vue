<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { demoMode, supabase } from '../lib/supabase'
import { useSessionStore } from '../stores/session'

const route = useRoute(), session = useSessionStore()
const success = computed(() => route.path.endsWith('/berhasil'))
const email = computed(() => demoMode ? '' : session.user?.email || '')
const busy = ref(false), error = ref(''), notice = ref(''), seconds = ref(0)
let timer: ReturnType<typeof setInterval> | undefined
function cooldown() {
  seconds.value = 60
  if (timer) clearInterval(timer)
  timer = setInterval(() => { seconds.value--; if (seconds.value <= 0 && timer) { clearInterval(timer); timer = undefined } }, 1000)
}
onMounted(() => { if (!success.value && email.value && !session.verified && !demoMode) cooldown() })
onUnmounted(() => { if (timer) clearInterval(timer) })
async function resend() {
  if (!email.value || demoMode || !supabase || seconds.value || busy.value) return
  error.value = ''; notice.value = ''; busy.value = true
  try {
    const { error: failure } = await supabase.auth.resend({ type: 'signup', email: email.value, options: { emailRedirectTo: new URL('/verifikasi-email/berhasil', location.origin).href } })
    if (failure) throw failure
    notice.value = 'Jika alamat ini memenuhi syarat, email verifikasi akan dikirim. Cek kotak masuk dan spam.'
    cooldown()
  } catch { error.value = 'Belum bisa mengirim ulang. Tunggu sebentar lalu coba lagi.' }
  finally { busy.value = false }
}
</script>
<template>
  <main class="verification"><RouterLink class="brand" to="/">Mabar Finder</RouterLink>
    <section class="card" aria-labelledby="verify-title"><div class="symbol" aria-hidden="true">{{ success && (session.verified || demoMode) ? '✓' : '✉' }}</div>
      <template v-if="demoMode"><h1 id="verify-title">Verifikasi tidak diperlukan di demo</h1><p>Mode demo tidak mengirim email atau tautan verifikasi. Pilih persona untuk menjelajah.</p><RouterLink class="primary" to="/login">Pilih persona demo</RouterLink></template>
      <template v-else-if="success && session.verified"><h1 id="verify-title">Yes! Email kamu berhasil diverifikasi</h1><p>Akunmu siap. Lengkapi profil dan game sebelum cari teman mabar.</p><RouterLink class="primary" to="/onboarding/1">Lanjut ke Onboarding</RouterLink></template>
      <template v-else-if="success"><h1 id="verify-title">Tautan belum terverifikasi</h1><p>Tautan mungkin sudah kedaluwarsa atau belum selesai diproses. Masuk kembali untuk mengecek status akun.</p><RouterLink class="primary" to="/login">Kembali ke masuk</RouterLink></template>
      <template v-else-if="session.verified"><h1 id="verify-title">Email kamu sudah terverifikasi</h1><p>Kamu bisa lanjut melengkapi profil.</p><RouterLink class="primary" to="/onboarding/1">Lanjut ke Onboarding</RouterLink></template>
      <template v-else><h1 id="verify-title">Cek email kamu dulu, yuk!</h1><p v-if="email">Tautan verifikasi dikirim ke <strong>{{ email }}</strong>. Klik tautan dari kotak masuk atau spam.</p><p v-else>Setelah mendaftar, periksa kotak masuk atau spam untuk tautan verifikasi. Masuk kembali bila kamu sudah memverifikasi.</p><p v-if="error" class="error" role="alert">{{ error }}</p><p v-if="notice" role="status">{{ notice }}</p><button v-if="email" type="button" class="outline" :disabled="busy || seconds > 0" @click="resend">{{ busy ? 'Mengirim…' : seconds ? `Kirim ulang dalam ${seconds} detik` : 'Kirim Ulang Email' }}</button><RouterLink class="text-link" to="/register">Salah alamat email? Daftar lagi</RouterLink><RouterLink class="text-link" to="/login">Kembali ke halaman masuk</RouterLink></template>
    </section>
  </main>
</template>
<style scoped>
.verification{min-height:100vh;background:#14141c;color:#f5f3ee;display:flex;align-items:center;justify-content:center;padding:5rem 1rem 2rem;position:relative}.brand{position:absolute;top:1.7rem;left:clamp(1rem,5vw,5rem);font:800 1.25rem 'Plus Jakarta Sans',sans-serif;color:#f5f3ee}.card{background:#1e1e29;border:1px solid #4d4b5c;border-radius:24px;box-shadow:0 20px 50px #09091066;width:min(100%,510px);padding:clamp(1.5rem,5vw,3rem);text-align:center}.symbol{width:88px;height:88px;border-radius:27px;background:#303049;color:#c8ff4d;display:grid;place-items:center;font-size:3rem;margin:0 auto 1.8rem}.card h1{font:800 clamp(1.7rem,4vw,2.25rem)/1.2 'Plus Jakarta Sans',sans-serif}.card p{color:#d0ceda;line-height:1.7;overflow-wrap:anywhere}.card strong{color:#f5f3ee}.primary,.outline{display:inline-flex;align-items:center;justify-content:center;min-height:48px;width:100%;border-radius:999px;padding:.8rem 1.2rem;font-weight:800;margin-top:1rem;text-decoration:none}.primary{border:0;background:#c8ff4d;color:#14141c}.outline{border:1px solid #c8ff4d;color:#c8ff4d;background:transparent;cursor:pointer}.outline:disabled{opacity:.6;cursor:not-allowed}.text-link{display:block;color:#c8ff4d;margin:1.1rem auto 0}.error{color:#ffc0ba!important}:focus-visible{outline:3px solid #c8ff4d;outline-offset:3px}
</style>
