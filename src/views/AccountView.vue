<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { useSessionStore } from '../stores/session'
import { configured, supabase } from '../lib/supabase'
import { listGames, listOptions, ownGameProfiles, ownProfile, updateOwnProfile, saveGameProfile } from '../lib/api'
import type { Game, GameProfile, Option } from '../lib/models'
const session = useSessionStore(), userId = computed(() => session.user?.id)
const tab = ref<'info'|'games'|'settings'>('info')
const busy = ref(false), loading = ref(true), error = ref(''), notice = ref('')
const name = ref(''), bio = ref(''), timezone = ref('Asia/Jakarta'), languages = ref('id'), voice = ref('flexible'), style = ref('casual'), availability = ref('unavailable'), visibility = ref('public')
const games = ref<Game[]>([]), profiles = ref<GameProfile[]>([]), options = ref<Option[]>([])
const selectedGame = ref(''), editing = ref(''), ign = ref(''), privateId = ref(''), rank = ref(''), rankMode = ref(''), role = ref(''), region = ref(''), gameVisibility = ref('public')
const newPassword = ref(''), confirmPassword = ref('')
const game = computed(() => games.value.find(g => g.id === selectedGame.value))
const remainingGames = computed(() => games.value.filter(g => !profiles.value.some(p => p.game_id === g.id)))
const kinds = (kind: string) => options.value.filter(o => o.kind === kind)
const modeRanked = computed(() => ['free-fire','pubg-mobile'].includes(game.value?.slug || ''))
const rankOptions = computed(() => kinds('rank').filter(o => !modeRanked.value || (rankMode.value && o.rank_mode_option_id === rankMode.value)))
const selectedMode = computed(() => kinds('mode').find(o => o.id === rankMode.value))
function gameName(id: string) { return games.value.find(g => g.id === id)?.name || 'Game' }
function optionLabel(id: string | null) { return options.value.find(o => o.id === id)?.label || '' }
function friendlyError() { error.value = 'Data belum bisa disimpan. Periksa isian atau coba lagi nanti.' }
async function load() {
  if (!userId.value || !configured) { loading.value = false; return }
  loading.value = true; error.value = ''
  try {
    const [p, g, gp] = await Promise.all([ownProfile(userId.value), listGames(), ownGameProfiles(userId.value)])
    if (!p) throw new Error('Profil belum tersedia')
    const profile = p as unknown as { display_name:string;bio:string|null;timezone:string;languages:string[];voice_preference:string;play_style:string;availability_status:string;visibility:string }
    name.value = profile.display_name || ''; bio.value = profile.bio || ''; timezone.value = profile.timezone || 'Asia/Jakarta'; languages.value = Array.isArray(profile.languages) ? profile.languages.join(', ') : 'id'; voice.value = profile.voice_preference || 'flexible'; style.value = profile.play_style || 'casual'; availability.value = profile.availability_status || 'unavailable'; visibility.value = profile.visibility || 'public'; games.value = g; profiles.value = gp
  } catch { error.value = 'Profil belum bisa dimuat. Coba lagi nanti.' }
  finally { loading.value = false }
}
onMounted(load)
watch(selectedGame, async id => {
  options.value = []
  if (!editing.value) { rank.value = ''; role.value = ''; region.value = ''; rankMode.value = '' }
  if (id) try { const loaded = await listOptions(id); if (selectedGame.value === id) options.value = loaded } catch { error.value = 'Pilihan game belum bisa dimuat.' }
})
function edit(p: GameProfile) { tab.value = 'games'; editing.value = p.id; selectedGame.value = p.game_id; ign.value = p.ign; privateId.value = p.game_id_private || ''; gameVisibility.value = p.visibility; rank.value = p.primary_rank_option_id || ''; rankMode.value = p.primary_rank_mode_option_id || ''; role.value = p.primary_role_option_id || ''; region.value = p.region_option_id || '' }
function clearGame() { editing.value = ''; selectedGame.value = ''; ign.value = ''; privateId.value = ''; rank.value = ''; rankMode.value = ''; role.value = ''; region.value = ''; gameVisibility.value = 'public' }
async function saveProfile() {
  if (!userId.value || busy.value) return
  busy.value = true; error.value = ''; notice.value = ''
  try { await updateOwnProfile(userId.value, { display_name:name.value.trim(), bio:bio.value.trim() || null, timezone:timezone.value.trim(), languages:languages.value.split(',').map(x => x.trim()).filter(Boolean), voice_preference:voice.value, play_style:style.value, availability_status:availability.value, visibility:visibility.value }); notice.value = 'Profil disimpan.' }
  catch { friendlyError() } finally { busy.value = false }
}
async function saveGame() {
  if (!userId.value || !selectedGame.value || ign.value.trim().length < 2 || busy.value) return
  if (modeRanked.value && rank.value && !rankMode.value) { error.value = 'Pilih mode rank terlebih dahulu.'; return }
  busy.value = true; error.value = ''; notice.value = ''
  try {
    const input = { ign:ign.value.trim(), game_id_private:privateId.value.trim() || null, primary_rank_option_id:rank.value || null, primary_rank_mode_option_id:rankMode.value || null, primary_role_option_id:role.value || null, region_option_id:region.value || null, visibility:gameVisibility.value, attributes: editing.value ? profiles.value.find(profile => profile.id === editing.value)?.attributes || {} : {} }
    await saveGameProfile(editing.value ? input : { ...input, user_id:userId.value, game_id:selectedGame.value }, editing.value || undefined)
    profiles.value = await ownGameProfiles(userId.value); clearGame(); notice.value = 'Profil game disimpan. ID game tetap privat sampai kamu membagikannya lewat chat.'
  } catch { friendlyError() } finally { busy.value = false }
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
  <main class="account page-shell"><nav class="breadcrumb"><RouterLink to="/">Beranda</RouterLink><span>/</span><strong>Profil Saya</strong></nav><header class="page-heading"><div><h1>Edit profil &amp; akun</h1><p>Atur identitas publik, ketersediaan manual, dan profil game kamu.</p></div></header>
    <p v-if="!configured" role="alert" class="error">Layanan belum dikonfigurasi.</p><p v-else-if="!userId">Masuk untuk mengelola profil. <RouterLink to="/login">Masuk</RouterLink></p>
    <template v-else><nav class="section-tabs" aria-label="Bagian profil"><button type="button" :aria-current="tab === 'info' ? 'page' : undefined" @click="tab = 'info'">Info Umum</button><button type="button" :aria-current="tab === 'games' ? 'page' : undefined" @click="tab = 'games'">Profil Game <span class="count">{{ profiles.length }}</span></button><button type="button" :aria-current="tab === 'settings' ? 'page' : undefined" @click="tab = 'settings'">Pengaturan Akun</button></nav>
      <p v-if="loading" role="status">Memuat profil…</p><p v-if="error" role="alert" class="error">{{ error }}</p><p v-if="notice" role="status" class="success">{{ notice }}</p><p v-if="!session.verified" class="warning">Verifikasi email sebelum mengirim ajakan atau pesan.</p>
      <section v-if="!loading && tab === 'info'" class="panel"><h2>Info umum</h2><form @submit.prevent="saveProfile"><label>Nickname Game / Display Name<input v-model="name" required minlength="2" maxlength="60" /></label><label>Bio singkat<textarea v-model="bio" maxlength="200" rows="3"></textarea></label><div class="grid"><label>Zona waktu IANA<input v-model="timezone" required placeholder="Asia/Jakarta" /></label><label>Bahasa (pisahkan koma)<input v-model="languages" required placeholder="id, en" /></label><label>Preferensi voice<select v-model="voice"><option value="flexible">Fleksibel</option><option value="voice">Voice</option><option value="text">Teks</option></select></label><label>Gaya bermain<select v-model="style"><option value="casual">Santai</option><option value="competitive">Kompetitif</option></select></label><label>Status mabar<select v-model="availability"><option value="ready">Siap mabar</option><option value="unavailable">Tidak tersedia</option></select></label><label>Visibilitas<select v-model="visibility"><option value="public">Publik</option><option value="hidden">Tersembunyi</option></select></label></div><p class="muted">Status siap mabar kamu atur sendiri, bukan indikator online real-time. Upload avatar dan kota belum didukung oleh profil saat ini.</p><button type="submit" :disabled="busy">{{ busy ? 'Menyimpan…' : 'Simpan perubahan' }}</button></form></section>
      <section v-if="!loading && tab === 'games'" class="panel"><h2>Game yang kamu mainkan</h2><p class="muted">Rank dan role diambil dari pilihan game yang tersedia. ID game tidak terlihat di hasil pencarian.</p><div v-if="profiles.length" class="cards"><article v-for="p in profiles" :key="p.id" class="item"><div><strong>{{ gameName(p.game_id) }}</strong><p>{{ p.ign }} <span class="chip chip--violet">{{ p.visibility === 'public' ? 'Publik' : 'Tersembunyi' }}</span></p></div><button type="button" class="secondary" :aria-expanded="editing === p.id" @click="editing === p.id ? clearGame() : edit(p)">{{ editing === p.id ? 'Tutup' : 'Edit game' }}</button></article></div><p v-else>Belum ada profil game.</p>
        <button v-if="!selectedGame && remainingGames.length" class="secondary add-game" type="button" @click="selectedGame = remainingGames[0].id">Tambah game baru</button>
        <form v-if="selectedGame" class="game-form" @submit.prevent="saveGame"><h3>{{ editing ? `Edit ${game?.name || 'profil game'}` : 'Tambah game baru' }}</h3><label>Game<select v-model="selectedGame" :disabled="!!editing" required><option v-for="g in editing ? games.filter(g => g.id === selectedGame) : remainingGames" :key="g.id" :value="g.id">{{ g.name }}</option></select></label><label>Nama dalam game<input v-model="ign" required minlength="2" maxlength="80" /></label><label>ID game privat (opsional)<input v-model="privateId" maxlength="120" autocomplete="off" /></label><p class="muted">Disimpan privat. Kamu yang memutuskan kapan membagikan ID ini di chat setelah ajakan diterima.</p><div class="grid"><label v-if="modeRanked && kinds('mode').length">Mode rank<select v-model="rankMode" @change="rank = ''"><option value="">Pilih mode</option><option v-for="o in kinds('mode')" :key="o.id" :value="o.id">{{ o.label }}</option></select></label><label v-if="rankOptions.length">Rank<select v-model="rank"><option value="">Belum dipilih</option><option v-for="o in rankOptions" :key="o.id" :value="o.id">{{ o.label }}</option></select></label><label v-if="kinds('role').length">Role utama<select v-model="role"><option value="">Belum dipilih</option><option v-for="o in kinds('role')" :key="o.id" :value="o.id">{{ o.label }}</option></select></label><label v-if="kinds('region').length">Region<select v-model="region"><option value="">Belum dipilih</option><option v-for="o in kinds('region')" :key="o.id" :value="o.id">{{ o.label }}</option></select></label><label>Visibilitas<select v-model="gameVisibility"><option value="public">Publik</option><option value="hidden">Tersembunyi</option></select></label></div><p v-if="modeRanked && !rankMode" class="muted">Pilih mode untuk melihat rank yang sesuai.</p><div class="actions"><button type="submit" :disabled="busy">{{ busy ? 'Menyimpan…' : 'Simpan game' }}</button><button type="button" class="secondary" @click="clearGame">Batal</button></div></form><p class="muted">Penghapusan profil game belum didukung. Atur visibilitas ke Tersembunyi bila perlu.</p>
      </section>
      <section v-if="!loading && tab === 'settings'" class="panel"><h2>Pengaturan akun</h2><form v-if="configured" @submit.prevent="savePassword"><h3>Ganti password</h3><label>Password baru<input v-model="newPassword" type="password" minlength="8" autocomplete="new-password" required /></label><label>Konfirmasi password baru<input v-model="confirmPassword" type="password" minlength="8" autocomplete="new-password" required /></label><button type="submit" :disabled="busy">Perbarui password</button></form><div class="danger-zone"><h3>Hapus akun</h3><p>Penghapusan akun belum tersedia di aplikasi ini. Jangan anggap data terhapus sebelum permintaan diproses oleh pengelola layanan.</p></div></section>
    </template>
  </main>
</template>
<style scoped>
.account{max-width:1080px;padding-bottom:80px;color:#f5f3ee}.account .page-heading h1{font-size:clamp(2rem,4vw,2.75rem)}.section-tabs{display:flex;gap:10px;overflow:auto;margin-bottom:24px;padding-bottom:4px}.section-tabs button{white-space:nowrap;background:transparent;color:#f5f3ee;border:1px solid #545461;border-radius:999px;padding:11px 18px;font-weight:700}.section-tabs button[aria-current]{background:#c8ff4d;color:#14141c;border-color:#c8ff4d}.count{padding:2px 7px;border-radius:999px;background:#3a3a4a}.section-tabs button[aria-current] .count{background:#14141c22}.panel{background:#1e1e29;border:1px solid #393944;border-radius:24px;padding:clamp(20px,4vw,36px)}.panel h2{margin-bottom:24px}.panel h3{font-size:1.1rem}.panel label{display:grid;gap:7px;margin-bottom:18px;font-weight:600}.panel input,.panel textarea,.panel select{width:100%;background:#292934;border:1px solid #666575;border-radius:14px;color:#f5f3ee;padding:12px;font:inherit}.panel textarea{resize:vertical}.panel button:not(.section-tabs button){background:#c8ff4d;color:#14141c;border:1px solid #c8ff4d;border-radius:999px;padding:11px 18px;font-weight:700}.panel button.secondary{background:transparent;color:#f5f3ee;border-color:#666575}.panel button:disabled{opacity:.55}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:0 18px}.cards{display:grid;gap:12px;margin:20px 0}.item{display:flex;align-items:center;justify-content:space-between;gap:15px;flex-wrap:wrap;background:#292934;border:1px solid #444453;border-radius:18px;padding:16px}.item p{margin:8px 0 0}.add-game{margin:16px 0}.game-form{border-top:1px solid #444453;margin-top:20px;padding-top:20px}.actions{display:flex;gap:10px;flex-wrap:wrap}.danger-zone{margin-top:48px;border-top:1px solid #ff6b5e;padding-top:22px}.danger-zone h3{color:#ff9d97}.muted{color:#b8b6c2}.error{color:#ff9d97}.success{color:#4ade80}.warning{color:#ffe3a1}:focus-visible{outline:3px solid #8b7cff;outline-offset:2px}@media(max-width:680px){.grid{grid-template-columns:1fr}.panel{padding:20px}.section-tabs{margin-inline:-5px}}
</style>
