<script setup lang="ts">
import { computed, onMounted, onServerPrefetch, ref, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { useSessionStore } from '../stores/session'
import { configured } from '../lib/supabase'
import { listGames, listAttributeDefinitions, ownGameProfiles, ownProfile, saveGameProfile, updateOwnProfile } from '../lib/api'
import type { AttributeDefinition, Game, GameProfile } from '../lib/models'

const route = useRoute()
const router = useRouter()
const session = useSessionStore()
const step = computed(() => {
  const number = Number(route.params.step || route.query.step || 1)
  return [1, 2, 3].includes(number) ? number : 1
})
const loading = ref(true), loaded = ref(false), busy = ref(false), error = ref(''), notice = ref('')
const nickname = ref(''), bio = ref(''), timezone = ref('Asia/Jakarta')
const games = ref<Game[]>([]), profiles = ref<GameProfile[]>([])
const definitions = ref<AttributeDefinition[]>([]), attributeValues = ref<Record<string, unknown>>({}), attributesLoading = ref(false), attributesLoaded = ref(false)
const supportedDefinitions = computed(() => definitions.value.filter(definition => {
  if (['mabar_rating', 'successful_mabar_count', 'account_verified', 'last_active'].includes(definition.key)) return false
  const choices = Array.isArray(definition.options) && definition.options.length > 0
  return (['single_select', 'multi_select', 'tag_multi', 'slider_tier', 'boolean_with_option'].includes(definition.value_type) && choices)
    || ['boolean', 'number', 'decimal'].includes(definition.value_type)
}))
const selectedGame = ref(''), ign = ref('')
const ready = ref(false), playStyle = ref('casual'), voice = ref('flexible')
const selected = computed(() => games.value.find(game => game.id === selectedGame.value))
const existing = computed(() => profiles.value.find(profile => profile.game_id === selectedGame.value))
const headings = ['Kenalan dulu, yuk!', 'Mau temenan buat main apa?', 'Terakhir nih, atur preferensi kamu']

async function loadProfile() {
  if (!configured || !session.user || !session.verified) { loading.value = false; return }
  try {
    const [profile, catalog, saved] = await Promise.all([ownProfile(session.user.id), listGames(), ownGameProfiles(session.user.id)])
    const data = profile as unknown as { display_name?: string; bio?: string | null; timezone?: string; availability_status?: string; play_style?: string; voice_preference?: string }
    nickname.value = data.display_name === 'Pemain' ? '' : data.display_name || ''
    bio.value = data.bio || ''
    timezone.value = data.timezone || 'Asia/Jakarta'
    ready.value = data.availability_status === 'ready'
    playStyle.value = data.play_style || 'casual'
    voice.value = data.voice_preference || 'flexible'
    games.value = catalog
    profiles.value = saved
    loaded.value = true
  } catch { error.value = 'Profil atau katalog belum bisa dimuat. Coba muat ulang halaman.' }
  finally { loading.value = false }
}
onMounted(loadProfile)
onServerPrefetch(loadProfile)
watch(selectedGame, async gameId => {
  definitions.value = []; attributesLoaded.value = false; attributeValues.value = {}
  ign.value = existing.value?.ign || ''
  if (!gameId) return
  attributesLoading.value = true; error.value = ''
  try {
    const schema = await listAttributeDefinitions(gameId)
    if (selectedGame.value === gameId) {
      definitions.value = schema
      attributeValues.value = Object.fromEntries(Object.entries(existing.value?.attributes || {}).filter(([key]) => schema.some(definition => definition.key === key && definition.active)))
      attributesLoaded.value = true
    }
  } catch { if (selectedGame.value === gameId) error.value = 'Atribut game belum bisa dimuat. Coba pilih game lain lalu kembali.' }
  finally { if (selectedGame.value === gameId) attributesLoading.value = false }
})
function setNumber(key: string, event: Event) {
  const raw = (event.target as HTMLInputElement).value
  if (raw === '') delete attributeValues.value[key]
  else attributeValues.value[key] = Number(raw)
}
function setChoice(key: string, event: Event) {
  const value = (event.target as HTMLSelectElement).value
  if (value) attributeValues.value[key] = value
  else delete attributeValues.value[key]
}
function toggleAttribute(key: string, choice: string) {
  const selected = Array.isArray(attributeValues.value[key]) ? attributeValues.value[key] as string[] : []
  attributeValues.value[key] = selected.includes(choice) ? selected.filter(value => value !== choice) : [...selected, choice]
}
watch(step, () => { error.value = ''; notice.value = '' })
function go(next: number) { void router.push(`/onboarding/${next}`) }
async function saveProfile() {
  if (!configured || !session.user || !session.verified || !loaded.value || busy.value) return
  const name = nickname.value.trim(), about = bio.value.trim(), zone = timezone.value.trim()
  if (name.length < 2 || name.length > 60) { error.value = 'Nickname harus 2–60 karakter.'; return }
  if (about.length > 500) { error.value = 'Bio maksimal 500 karakter.'; return }
  if (!['Asia/Jakarta', 'Asia/Makassar', 'Asia/Jayapura'].includes(zone)) { error.value = 'Pilih zona waktu yang tersedia.'; return }
  error.value = ''; busy.value = true
  try { await updateOwnProfile(session.user.id, { display_name: name, bio: about || null, timezone: zone }); go(2) }
  catch { error.value = 'Profil belum tersimpan. Coba lagi.' }
  finally { busy.value = false }
}
async function saveGame() {
  if (!configured || !session.user || !session.verified || !loaded.value || busy.value) return
  if (!selectedGame.value) { error.value = 'Pilih satu game dulu, atau lewati langkah ini.'; return }
  if (ign.value.trim().length < 2 || ign.value.trim().length > 64) { error.value = 'Nama dalam game harus 2–64 karakter.'; return }
  if (attributesLoading.value || !attributesLoaded.value) { error.value = 'Atribut game belum dimuat. Coba lagi.'; return }
  error.value = ''; busy.value = true
  const retained = Object.fromEntries(Object.entries(existing.value?.attributes || {}).filter(([key]) => !definitions.value.some(definition => definition.key === key)))
  const input = { ign: ign.value.trim(), attributes: { ...retained, ...attributeValues.value } }
  try {
    await saveGameProfile(existing.value ? input : { ...input, user_id: session.user.id, game_id: selectedGame.value }, existing.value?.id)
    profiles.value = await ownGameProfiles(session.user.id)
    go(3)
  } catch { error.value = 'Profil game belum tersimpan. Periksa mode dan rank, lalu coba lagi.' }
  finally { busy.value = false }
}
async function finish() {
  if (!configured || !session.user || !session.verified || !loaded.value || busy.value) return
  error.value = ''; busy.value = true
  try {
    await updateOwnProfile(session.user.id, { availability_status: ready.value ? 'ready' : 'unavailable', play_style: playStyle.value, voice_preference: voice.value })
    await router.push('/beranda')
  } catch { error.value = 'Preferensi belum tersimpan. Coba lagi.' }
  finally { busy.value = false }
}
</script>

<template>
  <main class="onboarding">
    <div class="layout">
      <aside class="aside" aria-label="Panduan onboarding">
        <RouterLink to="/" class="brand">Mabar Finder</RouterLink>
        <h2>Biar squad yang pas lebih gampang ketemu.</h2>
        <p>Profil dan rank diisi sendiri oleh pemain, belum terverifikasi. ID game tidak perlu dibagikan di sini.</p>
        <div class="art" aria-hidden="true"><span>01</span><span>02</span><span>03</span></div>
      </aside>
      <section class="card" aria-labelledby="onboarding-title">
        <p class="step-label">Langkah {{ String(step).padStart(2, '0') }} dari 03</p>
        <ol class="progress" aria-label="Progres onboarding">
          <li v-for="number in 3" :key="number" :class="{ active: step === number, complete: step > number }" :aria-current="step === number ? 'step' : undefined"><span>{{ String(number).padStart(2, '0') }}</span></li>
        </ol>
        <h1 id="onboarding-title">{{ headings[step - 1] }}</h1>
        <p class="muted">{{ step === 1 ? 'Ceritain sedikit tentang dirimu sebelum mulai cari teman main.' : step === 2 ? 'Pilih game pertama. Rank dan role bisa kamu ubah lagi nanti.' : 'Status ini manual, bukan penanda online real-time.' }}</p>
        <p v-if="!configured" class="message" role="alert">Layanan akun belum dikonfigurasi. Onboarding belum tersedia.</p>
        <p v-else-if="!session.user" class="message" role="alert">Masuk dulu untuk menyimpan onboarding. <RouterLink to="/login">Masuk</RouterLink></p>
        <p v-else-if="!session.verified" class="message" role="alert">Verifikasi email dulu sebelum menyimpan profil. <RouterLink to="/verifikasi-email">Cek verifikasi</RouterLink></p>
        <template v-else>
          <p v-if="loading" role="status">Memuat profil…</p>
          <p v-if="error" class="error" role="alert">{{ error }}</p>
          <button v-if="!loading && !loaded" type="button" class="secondary" @click="loadProfile">Coba lagi</button>
          <p v-if="notice" role="status">{{ notice }}</p>
          <form v-if="!loading && loaded && step === 1" @submit.prevent="saveProfile">
            <div class="avatar-placeholder" aria-hidden="true">MF</div>
            <p class="hint">Unggah avatar belum tersedia. Kamu bisa lanjut tanpa foto.</p>
            <label for="onboard-name">Nickname</label><input id="onboard-name" v-model="nickname" autocomplete="nickname" required minlength="2" maxlength="60" placeholder="Nama yang dilihat teman mabar">
            <label for="onboard-zone">Zona waktu</label><select id="onboard-zone" v-model="timezone"><option value="Asia/Jakarta">WIB (Jakarta)</option><option value="Asia/Makassar">WITA (Makassar)</option><option value="Asia/Jayapura">WIT (Jayapura)</option></select>
            <p class="hint">Kota belum tersedia di profil. Zona waktu membantu menentukan jam bermain.</p>
            <label for="onboard-bio">Bio singkat <span class="muted">(opsional)</span></label><textarea id="onboard-bio" v-model="bio" maxlength="500" rows="3" placeholder="Biasanya main santai setelah kerja…"></textarea>
            <button class="primary" :disabled="busy">{{ busy ? 'Menyimpan…' : 'Lanjut' }}</button>
          </form>
          <form v-if="!loading && loaded && step === 2" @submit.prevent="saveGame">
            <fieldset class="game-field"><legend>Pilih game</legend><p v-if="!games.length" class="hint">Belum ada game tersedia. Kamu bisa melewati langkah ini.</p><div v-else class="game-grid"><label v-for="game in games" :key="game.id" class="game-card" :class="{ chosen: selectedGame === game.id }"><input v-model="selectedGame" type="radio" name="game" :value="game.id"><strong>{{ game.name }}</strong><small>{{ profiles.some(profile => profile.game_id === game.id) ? 'Profil tersimpan' : 'Pilih game' }}</small></label></div></fieldset>
            <template v-if="selected"><p class="hint">Data game diisi pengguna, belum terverifikasi. Jangan masukkan ID akun privat ke nama dalam game.</p><label for="onboard-ign">Nama dalam game</label><input id="onboard-ign" v-model="ign" required minlength="2" maxlength="64" autocomplete="off" placeholder="IGN kamu">
              <p v-if="attributesLoading" role="status">Memuat atribut game…</p>
              <div v-for="definition in supportedDefinitions" :key="definition.key" class="attribute-field">
                <label v-if="['single_select', 'slider_tier', 'boolean_with_option'].includes(definition.value_type)" :for="`attribute-${definition.key}`">{{ definition.label }}
                  <select :id="`attribute-${definition.key}`" :value="attributeValues[definition.key] || ''" @change="setChoice(definition.key, $event)">
                    <option value="">Belum dipilih</option><option v-for="choice in (definition.options as string[])" :key="choice" :value="choice">{{ choice }}</option>
                  </select>
                </label>
                <fieldset v-else-if="['multi_select', 'tag_multi'].includes(definition.value_type)" class="attribute-group"><legend>{{ definition.label }}</legend>
                  <label v-for="choice in (definition.options as string[])" :key="choice"><input type="checkbox" :checked="Array.isArray(attributeValues[definition.key]) && (attributeValues[definition.key] as string[]).includes(choice)" @change="toggleAttribute(definition.key, choice)"> {{ choice }}</label>
                </fieldset>
                <label v-else-if="definition.value_type === 'boolean'" class="check-field"><input type="checkbox" :checked="attributeValues[definition.key] === true" @change="attributeValues[definition.key] = ($event.target as HTMLInputElement).checked"> {{ definition.label }}</label>
                <label v-else :for="`attribute-${definition.key}`">{{ definition.label }} {{ definition.unit || '' }}
                  <input :id="`attribute-${definition.key}`" type="number" :step="definition.value_type === 'decimal' ? '0.01' : '1'" :min="definition.range_min ?? undefined" :max="definition.range_max ?? undefined" :value="attributeValues[definition.key] ?? ''" @input="setNumber(definition.key, $event)">
                </label>
              </div>
            </template>
            <div class="actions"><button type="button" class="secondary" @click="go(1)">Kembali</button><button type="button" class="text-button" @click="go(3)">Lewati langkah ini</button><button class="primary" :disabled="busy || !games.length">{{ busy ? 'Menyimpan…' : 'Lanjut' }}</button></div>
          </form>
          <form v-if="!loading && loaded && step === 3" @submit.prevent="finish">
            <label class="toggle"><input v-model="ready" type="checkbox"><span><strong>Siap mabar sekarang</strong><small>Ubah kapan saja. Status ini bukan indikator online.</small></span></label>
            <label for="onboard-style">Gaya bermain</label><select id="onboard-style" v-model="playStyle"><option value="casual">Santai</option><option value="competitive">Kompetitif</option></select>
            <label for="onboard-voice">Komunikasi</label><select id="onboard-voice" v-model="voice"><option value="flexible">Fleksibel</option><option value="voice">Voice chat</option><option value="text">Teks</option></select>
            <fieldset class="slot-field" disabled><legend>Jam aktif bermain</legend><div class="slot-grid"><label v-for="slot in ['Pagi', 'Siang', 'Sore', 'Malam', 'Dini hari']" :key="slot"><input type="checkbox">{{ slot }}</label></div><p class="hint">Pengaturan jadwal belum tersedia di onboarding. Jangan anggap pilihan ini tersimpan.</p></fieldset>
            <div class="actions"><button type="button" class="secondary" @click="go(2)">Kembali</button><button class="primary" :disabled="busy">{{ busy ? 'Menyimpan…' : 'Selesai, Masuk ke Beranda!' }}</button></div>
          </form>
        </template>
      </section>
    </div>
  </main>
</template>

<style scoped>
.onboarding{min-height:100vh;background:#14141c;color:#f5f3ee}.layout{display:grid;grid-template-columns:minmax(280px,40%) minmax(0,1fr);min-height:100vh}.aside{background:#242431 url('/design-assets/hero-game.jpg') center/cover;position:relative;padding:clamp(2rem,5vw,5rem);display:flex;flex-direction:column;align-items:start;justify-content:center;isolation:isolate}.aside:before{content:'';position:absolute;inset:0;background:#14141cba;z-index:-1}.brand{position:absolute;top:2rem;left:clamp(2rem,5vw,5rem);font:800 1.25rem 'Plus Jakarta Sans',sans-serif}.aside h2{font-size:clamp(2rem,3.5vw,3.5rem);line-height:1.17;max-width:480px}.aside p{max-width:440px;color:#dedce6}.art{display:flex;gap:12px;margin-top:2rem}.art span{width:58px;height:58px;border:2px solid #c8ff4d;border-radius:18px;display:grid;place-items:center;font-weight:800;color:#c8ff4d}.card{width:min(620px,calc(100% - 3rem));margin:auto;padding:3rem 0}.step-label{font-weight:700;color:#c8ff4d}.progress{display:flex;gap:8px;padding:0;list-style:none;margin:1.2rem 0 2.4rem}.progress li{height:9px;flex:1;border:1px solid #787683;border-radius:999px;position:relative}.progress li span{position:absolute;left:0;top:15px;color:#bbb9c8;font-size:.75rem}.progress .active{background:#c8ff4d;border-color:#c8ff4d;box-shadow:0 0 16px #c8ff4d55}.progress .complete{background:#4ade80;border-color:#4ade80}.card h1{font:800 clamp(1.9rem,3vw,2.7rem)/1.2 'Plus Jakarta Sans',sans-serif;margin:0 0 .7rem}.muted,.hint{color:#bdbbc9}.hint{font-size:.85rem;line-height:1.5}.card>p.muted{margin-bottom:2rem}.card form{display:grid;gap:.65rem}.card label,.game-field legend,.slot-field legend{font-weight:700}.card input:not([type=radio]):not([type=checkbox]),.card select,.card textarea{width:100%;background:#242431;color:#f5f3ee;border:1px solid #777581;border-radius:14px;padding:.85rem 1rem;min-height:48px}.card textarea{resize:vertical}.card input::placeholder,.card textarea::placeholder{color:#aaa8b4}.avatar-placeholder{width:74px;height:74px;border:2px dashed #8b7cff;border-radius:50%;display:grid;place-items:center;color:#e0dcff;font-weight:800;background:#28273a}.primary,.secondary,.text-button{border-radius:999px;min-height:48px;padding:.75rem 1.4rem;font-weight:800;cursor:pointer}.primary{background:#c8ff4d;color:#14141c;border:0}.secondary{background:transparent;color:#f5f3ee;border:1px solid #777581}.text-button{background:none;border:0;color:#c8ff4d}.card form>.primary{justify-self:end;margin-top:1rem}.actions{display:flex;align-items:center;gap:.6rem;justify-content:flex-end;flex-wrap:wrap;margin-top:1.2rem}.game-field,.slot-field{border:0;padding:0;margin:1.4rem 0 .3rem;min-width:0}.game-field legend,.slot-field legend{margin-bottom:.8rem}.game-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:.8rem}.game-card{display:flex;flex-direction:column;gap:.5rem;background:#23232f;border:1px solid #555463;border-radius:18px;padding:1rem;cursor:pointer}.game-card.chosen{border-color:#c8ff4d;box-shadow:0 0 16px #c8ff4d33}.game-card input{accent-color:#c8ff4d;align-self:flex-start}.game-card small{color:#bdbbc9}.fields{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:1rem}.fields>div{display:grid;gap:.6rem}.toggle{display:flex;align-items:center;gap:1rem;background:#242431;border-radius:16px;padding:1rem;margin:1rem 0}.toggle input{width:22px;height:22px;accent-color:#c8ff4d}.toggle small{display:block;color:#bdbbc9;font-weight:400}.slot-grid{display:flex;flex-wrap:wrap;gap:.5rem}.slot-grid label{border:1px solid #555463;border-radius:999px;padding:.5rem .7rem;font-weight:500}.slot-grid input{margin-right:.4rem}.message,.error{padding:1rem;border-radius:14px;background:#292938;color:#e3e0ee}.error{color:#ffc0ba;border:1px solid #ff6b5e}.card a{color:#c8ff4d}button:disabled{opacity:.55;cursor:not-allowed}:focus-visible{outline:3px solid #c8ff4d;outline-offset:3px}@media(max-width:850px){.layout{grid-template-columns:1fr}.aside{min-height:220px;padding:5rem 1.5rem 1.5rem}.brand{top:1.5rem;left:1.5rem}.aside h2{font-size:1.8rem}.art{display:none}.card{padding:2rem 0 4rem}}@media(max-width:520px){.game-grid,.fields{grid-template-columns:1fr}.actions{justify-content:stretch}.actions button{flex:1}.actions .text-button{flex-basis:100%;order:3}.card{width:calc(100% - 2rem)}}
</style>
