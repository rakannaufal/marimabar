<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { useSessionStore } from '../stores/session'
import { configured, supabase } from '../lib/supabase'
import { deleteGameProfile, listGames, listAttributeDefinitions, ownGameProfiles, ownProfile, updateOwnProfile, saveGameProfile } from '../lib/api'
import type { AttributeDefinition, Game, GameProfile } from '../lib/models'
import GameAttributeEditor from '../components/GameAttributeEditor.vue'
import { mergeProfileAttributes, validateProfileAttributes, visibleProfileFields } from '../lib/gameProfileFields'
const session = useSessionStore(), route = useRoute(), userId = computed(() => session.user?.id)
const tab = ref<'info'|'games'|'settings'>('info')
const busy = ref(false), verifyBusy = ref(false), verifySeconds = ref(0), loading = ref(true), error = ref(''), notice = ref('')
let verifyTimer: ReturnType<typeof setInterval> | undefined
function startVerifyCooldown() {
  verifySeconds.value = 60
  if (verifyTimer) clearInterval(verifyTimer)
  verifyTimer = setInterval(() => { verifySeconds.value--; if (verifySeconds.value <= 0 && verifyTimer) { clearInterval(verifyTimer); verifyTimer = undefined } }, 1000)
}
async function sendVerification() {
  const email = session.user?.email
  if (!supabase || !email || verifyBusy.value || verifySeconds.value) return
  verifyBusy.value = true; error.value = ''; notice.value = ''
  try {
    const { error: authError } = await supabase.auth.resend({ type: 'signup', email, options: { emailRedirectTo: new URL('/verifikasi-email/berhasil', location.origin).href } })
    if (authError) throw authError
    notice.value = 'Email verifikasi dikirim. Periksa kotak masuk dan spam.'
    startVerifyCooldown()
  } catch { error.value = 'Email verifikasi belum bisa dikirim. Tunggu sebentar lalu coba lagi.' }
  finally { verifyBusy.value = false }
}
const name = ref(''), bio = ref(''), discord = ref(''), timezone = ref('Asia/Jakarta'), language = ref('id'), voice = ref('flexible'), style = ref('casual'), availability = ref('unavailable'), visibility = ref('public')
const timezoneOptions = [
  { value: 'Asia/Jakarta', label: 'WIB — Jakarta (UTC+7)' },
  { value: 'Asia/Makassar', label: 'WITA — Makassar (UTC+8)' },
  { value: 'Asia/Jayapura', label: 'WIT — Jayapura (UTC+9)' },
]
const languageOptions = [
  { value: 'id', label: 'Bahasa Indonesia' },
  { value: 'en', label: 'English' },
]
const games = ref<Game[]>([]), profiles = ref<GameProfile[]>([]), definitions = ref<AttributeDefinition[]>([])
const selectedGame = ref(''), editing = ref(''), deleting = ref<GameProfile|null>(null), ign = ref(''), privateId = ref(''), gameVisibility = ref('public'), attributeValues = ref<Record<string, unknown>>({}), attributesLoading = ref(false), attributesLoaded = ref(false)
const newPassword = ref(''), confirmPassword = ref('')
const game = computed(() => games.value.find(g => g.id === selectedGame.value))
function gameName(id: string) { return games.value.find(g => g.id === id)?.name || 'Game' }
function startGame() { clearGame(); selectedGame.value = games.value[0]?.id || '' }
function friendlyError() { error.value = 'Data belum bisa disimpan. Periksa isian atau coba lagi nanti.' }
async function load() {
  if (!userId.value || !configured) { loading.value = false; return }
  loading.value = true; error.value = ''
  try {
    const [p, g, gp] = await Promise.all([ownProfile(userId.value), listGames(), ownGameProfiles(userId.value)])
    if (!p) throw new Error('Profil belum tersedia')
    const profile = p as unknown as { display_name:string;bio:string|null;timezone:string;languages:string[];voice_preference:string;play_style:string;availability_status:string;visibility:string;discord:string|null }
    name.value = profile.display_name || ''; bio.value = profile.bio || ''; discord.value = profile.discord || ''; timezone.value = timezoneOptions.some(option => option.value === profile.timezone) ? profile.timezone : 'Asia/Jakarta'; language.value = Array.isArray(profile.languages) && languageOptions.some(option => option.value === profile.languages[0]) ? profile.languages[0] : 'id'; voice.value = profile.voice_preference || 'flexible'; style.value = profile.play_style || 'casual'; availability.value = profile.availability_status || 'unavailable'; visibility.value = profile.visibility || 'public'; games.value = g; profiles.value = gp
  } catch { error.value = 'Profil belum bisa dimuat. Coba lagi nanti.' }
  finally { loading.value = false }
}
onMounted(() => { if (route.query.verify === '1') tab.value = 'info'; void load() })
onUnmounted(() => { if (verifyTimer) clearInterval(verifyTimer) })
watch(selectedGame, async id => {
  definitions.value = []; attributeValues.value = {}; attributesLoaded.value = false
  if (!id) return
  attributesLoading.value = true; error.value = ''
  try {
    const loaded = await listAttributeDefinitions(id)
    if (selectedGame.value === id) {
      definitions.value = loaded
      attributeValues.value = editing.value ? { ...profiles.value.find(profile => profile.id === editing.value)?.attributes } : {}
      attributesLoaded.value = true
    }
  } catch { if (selectedGame.value === id) error.value = 'Pilihan game belum bisa dimuat. Coba pilih ulang game.' }
  finally { if (selectedGame.value === id) attributesLoading.value = false }
})
function edit(p: GameProfile) { tab.value = 'games'; editing.value = p.id; selectedGame.value = p.game_id; ign.value = p.ign; privateId.value = p.game_id_private || ''; gameVisibility.value = p.visibility; attributeValues.value = { ...p.attributes } }
function clearGame() { editing.value = ''; selectedGame.value = ''; ign.value = ''; privateId.value = ''; gameVisibility.value = 'public'; attributeValues.value = {}; definitions.value = []; attributesLoaded.value = false }
async function saveProfile() {
  if (!userId.value || busy.value) return
  if (discord.value.trim().length > 100) { error.value = 'Username Discord maksimal 100 karakter.'; return }
  busy.value = true; error.value = ''; notice.value = ''
  try { await updateOwnProfile(userId.value, { display_name:name.value.trim(), bio:bio.value.trim() || null, discord:discord.value.trim() || null, timezone:timezone.value, languages:[language.value], voice_preference:voice.value, play_style:style.value, availability_status:availability.value, visibility:visibility.value }); notice.value = 'Profil disimpan.' }
  catch { friendlyError() } finally { busy.value = false }
}
async function saveGame() {
  if (!userId.value || !selectedGame.value || busy.value) return
  if (ign.value.trim().length < 2 || ign.value.trim().length > 64) { error.value = 'Nama dalam game harus 2–64 karakter.'; return }
  if (privateId.value.trim().length > 100) { error.value = 'ID game maksimal 100 karakter.'; return }
  if (!attributesLoaded.value || attributesLoading.value) { error.value = 'Pilihan game belum dimuat. Coba lagi.'; return }
  const problem = validateProfileAttributes(game.value?.slug || '', attributeValues.value, definitions.value)
  if (problem) { error.value = problem; return }
  busy.value = true; error.value = ''; notice.value = ''
  try {
    const retained = profiles.value.find(profile => profile.id === editing.value)?.attributes || {}
    const shown = visibleProfileFields(game.value?.slug || '', definitions.value, attributeValues.value)
    const input = { ign:ign.value.trim(), game_id_private:privateId.value.trim() || null, visibility:gameVisibility.value, attributes: mergeProfileAttributes(retained, attributeValues.value, shown) }
    await saveGameProfile(editing.value ? input : { ...input, user_id:userId.value, game_id:selectedGame.value }, editing.value || undefined)
    profiles.value = await ownGameProfiles(userId.value); clearGame(); notice.value = 'Profil game disimpan. Nama dalam game dan ID game terlihat oleh teman yang sudah disetujui, jika profil publik.'
  } catch { friendlyError() } finally { busy.value = false }
}
async function removeGame() {
  if (!deleting.value || busy.value) return
  busy.value = true; error.value = ''; notice.value = ''
  const target = deleting.value
  try {
    await deleteGameProfile(target.id)
    profiles.value = await ownGameProfiles(userId.value || '')
    if (editing.value === target.id) clearGame()
    deleting.value = null
    notice.value = `Profil ${gameName(target.game_id)} dihapus.`
  } catch { error.value = 'Profil game belum bisa dihapus. Coba lagi nanti.' }
  finally { busy.value = false }
}
async function savePassword() {
  if (!supabase || busy.value) return
  error.value = ''; notice.value = ''
  if (newPassword.value.length < 8 || newPassword.value !== confirmPassword.value) { error.value = 'Password minimal 8 karakter dan konfirmasi harus sama.'; return }
  busy.value = true
  try { const { error: authError } = await supabase.auth.updateUser({ password:newPassword.value }); if (authError) throw authError; newPassword.value = ''; confirmPassword.value = ''; notice.value = 'Password diperbarui.' }
  catch { error.value = 'Password belum bisa diperbarui. Coba lagi atau gunakan pemulihan akun.' }
  finally { busy.value = false }
}
</script>
<template>
  <main class="account page-shell"><nav class="breadcrumb"><RouterLink to="/">Beranda</RouterLink><span>/</span><strong>Profil Saya</strong></nav><header class="page-heading"><div><div class="heading-title"><h1>Edit profil &amp; akun</h1><span v-if="session.verified" class="verification-badge verification-badge--verified">Email terverifikasi</span><span v-else class="verification-badge">Segera verifikasi email</span></div><p>Atur identitas publik, ketersediaan manual, dan profil game kamu.</p></div></header>
    <p v-if="!configured" role="alert" class="error">Layanan belum dikonfigurasi.</p><p v-else-if="!userId">Masuk untuk mengelola profil. <RouterLink to="/login">Masuk</RouterLink></p>
    <template v-else><nav class="section-tabs" aria-label="Bagian profil"><button type="button" :aria-current="tab === 'info' ? 'page' : undefined" @click="tab = 'info'">Info Umum</button><button type="button" :aria-current="tab === 'games' ? 'page' : undefined" @click="tab = 'games'">Profil Game <span class="count">{{ profiles.length }}</span></button><button type="button" :aria-current="tab === 'settings' ? 'page' : undefined" @click="tab = 'settings'">Pengaturan Akun</button></nav>
      <p v-if="loading" role="status">Memuat profil…</p><p v-if="error" role="alert" class="error">{{ error }}</p><p v-if="notice" role="status" class="success">{{ notice }}</p><section v-if="!session.verified" class="verification-card" role="status"><div><strong>Verifikasi email diperlukan</strong><p>Email <b>{{ session.user?.email }}</b> belum terverifikasi. Profil belum bisa menerima permintaan teman.</p></div><button type="button" :disabled="verifyBusy || verifySeconds > 0" @click="sendVerification">{{ verifyBusy ? 'Mengirim…' : verifySeconds ? `Kirim ulang dalam ${verifySeconds} detik` : 'Kirim email verifikasi' }}</button></section>
      <section v-if="!loading && tab === 'info'" class="panel"><h2>Info umum</h2><form @submit.prevent="saveProfile"><label>Nickname Game / Display Name<input v-model="name" required minlength="2" maxlength="60" /></label><label>Bio singkat<textarea v-model="bio" maxlength="200" rows="3"></textarea></label><label>Username Discord (opsional)<input v-model="discord" maxlength="100" autocomplete="off" placeholder="username Discord" /></label><p class="muted">Discord hanya terlihat setelah permintaan pertemanan diterima.</p><div class="grid"><label>Zona waktu<select v-model="timezone" required><option v-for="option in timezoneOptions" :key="option.value" :value="option.value">{{ option.label }}</option></select></label><label>Bahasa<select v-model="language" required><option v-for="option in languageOptions" :key="option.value" :value="option.value">{{ option.label }}</option></select></label><label>Preferensi voice<select v-model="voice"><option value="flexible">Fleksibel</option><option value="voice">Voice</option><option value="text">Teks</option></select></label><label>Gaya bermain<select v-model="style"><option value="casual">Santai</option><option value="competitive">Kompetitif</option></select></label><label>Status mabar<select v-model="availability"><option value="ready">Siap mabar</option><option value="unavailable">Tidak tersedia</option></select></label><label>Visibilitas<select v-model="visibility"><option value="public">Publik</option><option value="hidden">Tersembunyi</option></select></label></div><p class="muted">Status siap mabar kamu atur sendiri, bukan indikator online real-time. Upload avatar dan kota belum didukung oleh profil saat ini.</p><button type="submit" :disabled="busy">{{ busy ? 'Menyimpan…' : 'Simpan perubahan' }}</button></form></section>
      <section v-if="!loading && tab === 'games'" class="panel"><div class="panel-heading"><div><h2>Game yang kamu mainkan</h2><p class="muted">Satu game dapat memiliki beberapa profil untuk akun utama, smurf, atau server berbeda.</p></div><button v-if="!selectedGame && games.length" class="add-game" type="button" @click="startGame">+ Tambah profil game</button></div><div v-if="profiles.length" class="cards"><article v-for="p in profiles" :key="p.id" class="item"><div><strong>{{ gameName(p.game_id) }}</strong><p>{{ p.ign }} <span class="chip chip--violet">{{ p.visibility === 'public' ? 'Publik' : 'Tersembunyi' }}</span></p></div><div class="item-actions"><button type="button" class="secondary" :aria-expanded="editing === p.id" @click="editing === p.id ? clearGame() : edit(p)">{{ editing === p.id ? 'Tutup' : 'Edit profil' }}</button><button type="button" class="danger-button" @click="deleting = p">Hapus profil</button></div></article></div><p v-else>Belum ada profil game.</p>
        <form v-if="selectedGame" class="game-form" @submit.prevent="saveGame">
          <h3>{{ editing ? `Edit ${game?.name || 'profil game'}` : 'Tambah profil game' }}</h3>
          <label>Game<select v-model="selectedGame" :disabled="!!editing" required><option v-for="g in games" :key="g.id" :value="g.id">{{ g.name }}</option></select></label>
          <label>Nama dalam game<input v-model="ign" required minlength="2" maxlength="64" autocomplete="off" /></label>
          <label>ID game privat (opsional)<input v-model="privateId" maxlength="100" autocomplete="off" /></label>
          <p class="muted">ID game hanya terbuka untuk teman yang kamu setujui saat profil game terlihat publik.</p>
          <p v-if="attributesLoading" role="status">Memuat atribut game…</p>
          <GameAttributeEditor v-if="attributesLoaded && game" :slug="game.slug" :definitions="definitions" v-model:values="attributeValues" />
          <label>Visibilitas<select v-model="gameVisibility"><option value="public">Publik</option><option value="hidden">Tersembunyi</option></select></label>
          <div class="actions"><button type="submit" :disabled="busy || !attributesLoaded">{{ busy ? 'Menyimpan…' : 'Simpan game' }}</button><button type="button" class="secondary" @click="clearGame">Batal</button></div>
        </form>
        <div v-if="deleting" class="confirm-backdrop" role="presentation" @click.self="deleting = null"><section class="confirm-dialog" role="dialog" aria-modal="true" aria-labelledby="delete-game-title"><h3 id="delete-game-title">Hapus profil game?</h3><p>Profil <strong>{{ gameName(deleting.game_id) }}</strong> dengan nama <strong>{{ deleting.ign }}</strong> akan dihapus permanen. Profil game lain tidak terpengaruh.</p><div class="actions"><button type="button" class="danger-button" :disabled="busy" @click="removeGame">{{ busy ? 'Menghapus…' : 'Hapus profil' }}</button><button type="button" class="secondary" :disabled="busy" @click="deleting = null">Batal</button></div></section></div>
      </section>
      <section v-if="!loading && tab === 'settings'" class="panel"><h2>Pengaturan akun</h2><form v-if="configured" @submit.prevent="savePassword"><h3>Ganti password</h3><label>Password baru<input v-model="newPassword" type="password" minlength="8" autocomplete="new-password" required /></label><label>Konfirmasi password baru<input v-model="confirmPassword" type="password" minlength="8" autocomplete="new-password" required /></label><button type="submit" :disabled="busy">Perbarui password</button></form><div class="danger-zone"><h3>Hapus akun</h3><p>Penghapusan akun belum tersedia di aplikasi ini. Jangan anggap data terhapus sebelum permintaan diproses oleh pengelola layanan.</p></div></section>
    </template>
  </main>
</template>
<style scoped>
.account{max-width:1080px;padding-bottom:80px;color:#f5f3ee}.account .page-heading h1{font-size:clamp(2rem,4vw,2.75rem);margin:0}.heading-title{display:flex;align-items:center;gap:14px;flex-wrap:wrap}.verification-badge{display:inline-flex;align-items:center;min-height:30px;padding:5px 11px;border:1px solid #806b3b;border-radius:999px;background:#2b251d;color:#ffe3a1;font-size:.75rem;font-weight:800;letter-spacing:.01em}.verification-badge--verified{border-color:#3f7452;background:#1e3327;color:#9ae6ad}.section-tabs{display:flex;gap:10px;overflow:auto;margin-bottom:24px;padding-bottom:4px}.section-tabs button{white-space:nowrap;background:transparent;color:#f5f3ee;border:1px solid #545461;border-radius:999px;padding:11px 18px;font-weight:700}.section-tabs button[aria-current]{background:#c8ff4d;color:#14141c;border-color:#c8ff4d}.count{padding:2px 7px;border-radius:999px;background:#3a3a4a}.section-tabs button[aria-current] .count{background:#14141c22}.verification-card{display:flex;align-items:center;justify-content:space-between;gap:18px;flex-wrap:wrap;background:#2b251d;border:1px solid #806b3b;border-radius:18px;padding:18px;margin-bottom:22px}.verification-card strong{color:#ffe3a1}.verification-card p{margin:6px 0 0;color:#d8d2c4}.verification-card button{background:#c8ff4d;color:#14141c;border:0;border-radius:999px;padding:11px 18px;font-weight:800}.verification-card button:disabled{opacity:.55}.panel{background:#1e1e29;border:1px solid #393944;border-radius:24px;padding:clamp(20px,4vw,36px)}.panel h2{margin-bottom:24px}.panel h3{font-size:1.1rem}.panel label{display:grid;gap:7px;margin-bottom:18px;font-weight:600}.panel input,.panel textarea,.panel select{width:100%;background:#292934;border:1px solid #666575;border-radius:14px;color:#f5f3ee;padding:12px;font:inherit}.panel textarea{resize:vertical}.panel button:not(.section-tabs button){background:#c8ff4d;color:#14141c;border:1px solid #c8ff4d;border-radius:999px;padding:11px 18px;font-weight:700}.panel button.secondary{background:transparent;color:#f5f3ee;border-color:#666575}.panel button:disabled{opacity:.55}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:0 18px}.panel-heading{display:flex;align-items:flex-start;justify-content:space-between;gap:20px;flex-wrap:wrap}.panel-heading h2{margin-bottom:8px}.panel-heading p{margin:0}.cards{display:grid;gap:12px;margin:24px 0}.item{display:flex;align-items:center;justify-content:space-between;gap:15px;flex-wrap:wrap;background:#292934;border:1px solid #444453;border-radius:18px;padding:16px}.item p{margin:8px 0 0}.item-actions,.actions{display:flex;gap:10px;flex-wrap:wrap}.panel button.danger-button{background:transparent;color:#ff9d97;border-color:#8d4848}.panel button.danger-button:hover{background:#3b2429}.add-game{margin:0}.game-form{border-top:1px solid #444453;margin-top:24px;padding-top:24px}.confirm-backdrop{position:fixed;inset:0;z-index:1000;display:grid;place-items:center;padding:20px;background:#09090dbd}.confirm-dialog{width:min(460px,100%);background:#24242f;border:1px solid #555463;border-radius:20px;padding:24px;box-shadow:0 20px 70px #0009}.confirm-dialog h3{margin:0 0 12px}.confirm-dialog p{color:#d2d0dc;line-height:1.6}.danger-zone{margin-top:48px;border-top:1px solid #ff6b5e;padding-top:22px}.danger-zone h3{color:#ff9d97}.muted{color:#b8b6c2}.error{color:#ff9d97}.success{color:#4ade80}.warning{color:#ffe3a1}:focus-visible{outline:3px solid #8b7cff;outline-offset:2px}@media(max-width:680px){.grid{grid-template-columns:1fr}.panel{padding:20px}.section-tabs{margin-inline:-5px}}
</style>
