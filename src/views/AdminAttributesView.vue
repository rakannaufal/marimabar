<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import AdminShell from '../components/AdminShell.vue'
import { useSessionStore } from '../stores/session'
import { requireBackend, supabase } from '../lib/supabase'
import type { Option } from '../lib/models'

type Game = { id: string; name: string; slug: string }
type Definition = {
  game_id: string; key: string; label: string; category: string; value_type: string; filter_type: string
  options: string[] | null; range_min: number | null; range_max: number | null; unit: string | null; sort_order: number; active: boolean
}
const session = useSessionStore()
const games = ref<Game[]>([]), options = ref<Option[]>([]), definitions = ref<Definition[]>([])
const gameId = ref(''), loading = ref(false), busy = ref(false), error = ref(''), notice = ref('')
const kinds = ['rank', 'role', 'mode', 'region', 'server', 'map', 'hero', 'agent', 'perspective', 'team_size'] as const
const kind = ref<(typeof kinds)[number]>('role'), code = ref(''), label = ref(''), rankMode = ref('')
const grouped = computed(() => kinds.map(type => ({ kind: type, options: options.value.filter(o => o.kind === type) })).filter(group => group.options.length))
const modeOptions = computed(() => options.value.filter(o => o.kind === 'mode'))
const editing = ref<string | null>(null)
const form = ref({ key: '', label: '', category: 'kompetensi', value_type: 'single_select', filter_type: 'dropdown', options: '', range_min: '', range_max: '', unit: '', sort_order: '0', active: true })
const typeFilters: Record<string, string[]> = {
  slider_tier: ['range_slider'], multi_select: ['checkbox_group'], tag_multi: ['tag_select'], single_select: ['radio', 'dropdown', 'quick_filter'],
  number: ['range_slider', 'range_min'], decimal: ['range_slider', 'range_min'], boolean: ['toggle'], boolean_with_option: ['toggle_dropdown'],
}
const allowedFilters = computed(() => typeFilters[form.value.value_type] || [])
const hasOptions = computed(() => ['slider_tier', 'multi_select', 'tag_multi', 'single_select', 'boolean_with_option'].includes(form.value.value_type))
function resetForm() {
  editing.value = null
  form.value = { key: '', label: '', category: 'kompetensi', value_type: 'single_select', filter_type: 'dropdown', options: '', range_min: '', range_max: '', unit: '', sort_order: '0', active: true }
}
function edit(definition: Definition) {
  editing.value = definition.key
  form.value = {
    key: definition.key, label: definition.label, category: definition.category, value_type: definition.value_type,
    filter_type: definition.filter_type, options: (definition.options || []).join('\n'), range_min: String(definition.range_min ?? ''),
    range_max: String(definition.range_max ?? ''), unit: definition.unit || '', sort_order: String(definition.sort_order), active: definition.active,
  }
}
async function loadGames() {
  if (!supabase || !session.user || !session.admin) return
  loading.value = true; error.value = ''
  try {
    const { data, error: failure } = await requireBackend().from('games').select('id,name,slug,active').order('name')
    if (failure) throw failure
    games.value = (data || []) as Game[]
    if (!games.value.some(game => game.id === gameId.value)) gameId.value = games.value[0]?.id || ''
    await loadAttributes()
  } catch { error.value = 'Daftar game tidak dapat dimuat.' }
  finally { loading.value = false }
}
async function loadAttributes() {
  options.value = []; definitions.value = []; rankMode.value = ''; resetForm()
  if (!supabase || !session.user || !session.admin || !gameId.value) return
  loading.value = true; error.value = ''
  try {
    const client = requireBackend()
    const [catalog, schema] = await Promise.all([
      client.from('game_catalog_options').select('id,game_id,kind,code,label,sort_order,rank_mode_option_id,active').eq('game_id', gameId.value).order('sort_order'),
      client.from('game_attribute_definitions').select('game_id,key,label,category,value_type,filter_type,options,range_min,range_max,unit,sort_order,active').eq('game_id', gameId.value).order('sort_order'),
    ])
    if (catalog.error || schema.error) throw catalog.error || schema.error
    options.value = (catalog.data || []) as Option[]
    definitions.value = (schema.data || []) as Definition[]
  } catch { error.value = 'Atribut tidak dapat dimuat. Pastikan migrasi atribut sudah dijalankan.' }
  finally { loading.value = false }
}
async function saveDefinition() {
  if (!session.admin || !session.user || !gameId.value || busy.value) return
  error.value = ''; notice.value = ''
  const key = form.value.key.trim(), title = form.value.label.trim()
  const choices = form.value.options.split('\n').map(s => s.trim()).filter(Boolean)
  const minimum = form.value.range_min === '' ? null : Number(form.value.range_min)
  const maximum = form.value.range_max === '' ? null : Number(form.value.range_max)
  const order = Number(form.value.sort_order)
  if (!/^[a-z][a-z0-9_]{1,49}$/.test(key) || title.length < 2 || title.length > 80 || !allowedFilters.value.includes(form.value.filter_type)
    || (hasOptions.value && form.value.value_type !== 'tag_multi' && !choices.length) || choices.length > 200 || new Set(choices).size !== choices.length
    || choices.some(choice => choice.length > 80) || !Number.isInteger(order) || order < 0 || order > 10000
    || (minimum !== null && !Number.isFinite(minimum)) || (maximum !== null && !Number.isFinite(maximum))
    || (minimum !== null && maximum !== null && minimum > maximum)) {
    error.value = 'Periksa kode, jenis, filter, opsi unik, urutan, dan rentang angka.'; return
  }
  busy.value = true
  try {
    const payload = { label: title, category: form.value.category, value_type: form.value.value_type, filter_type: form.value.filter_type,
      options: hasOptions.value ? choices : [], range_min: minimum, range_max: maximum, unit: form.value.unit.trim() || null,
      sort_order: order, active: form.value.active }
    const client = requireBackend()
    const response = editing.value
      ? await client.from('game_attribute_definitions').update(payload).eq('game_id', gameId.value).eq('key', editing.value).select('key').single()
      : await client.from('game_attribute_definitions').insert({ game_id: gameId.value, key, ...payload }).select('key').single()
    if (response.error) throw response.error
    await loadAttributes()
    notice.value = 'Definisi atribut disimpan.'
  } catch { error.value = 'Definisi gagal disimpan. Periksa izin admin dan kecocokan data profil yang sudah ada.' }
  finally { busy.value = false }
}
async function addOption() {
  if (!supabase || !session.user || !session.admin || busy.value) return
  error.value = ''; notice.value = ''
  const normalized = code.value.trim(), title = label.value.trim()
  if (!/^[a-z0-9-]{2,50}$/.test(normalized) || title.length < 2 || title.length > 80) { error.value = 'Kode harus 2–50 karakter kecil, angka atau tanda hubung; label 2–80 karakter.'; return }
  if (kind.value !== 'rank') rankMode.value = ''
  busy.value = true
  try {
    const { error: failure } = await requireBackend().rpc('add_catalog_option', { p_game: gameId.value, p_kind: kind.value, p_code: normalized, p_label: title, p_rank_mode: kind.value === 'rank' && rankMode.value ? rankMode.value : null })
    if (failure) throw failure
    code.value = ''; label.value = ''; rankMode.value = ''
    await loadAttributes(); notice.value = 'Opsi katalog ditambahkan.'
  } catch { error.value = 'Opsi gagal disimpan. Periksa izin dan kode yang unik.' }
  finally { busy.value = false }
}
onMounted(loadGames)
</script>

<template>
  <AdminShell title="Kelola Skema Atribut Game" subtitle="Atur definisi atribut profil, tipe filter, dan pilihan katalog tiap game.">
    <section class="panel intro"><label for="attribute-game">Pilih game yang dikonfigurasi</label><select id="attribute-game" v-model="gameId" :disabled="busy || loading" @change="loadAttributes"><option v-for="game in games" :key="game.id" :value="game.id">{{ game.name }}</option></select><button type="button" class="secondary" :disabled="loading" @click="loadGames">Muat ulang</button></section>
    <p v-if="error" class="error" role="alert">{{ error }}</p><p v-if="notice" class="notice" role="status">{{ notice }}</p><p v-if="loading" role="status">Memuat atribut…</p>
    <section class="panel schema"><h2>Definisi atribut profil</h2><p>Jenis input dan tipe filter menentukan formulir pemain serta filter pencarian. Nilai statistik diisi pemain, belum terverifikasi. Atribut reputasi tanpa sumber tepercaya tidak tersedia.</p>
      <div v-if="!loading && gameId" class="layout"><div><p v-if="!definitions.length">Belum ada definisi atribut.</p><ul><li v-for="item in definitions" :key="item.key"><span><strong>{{ item.label }}</strong><small>{{ item.key }} · {{ item.category }} · {{ item.value_type }} · {{ item.filter_type }}<template v-if="!item.active"> · Nonaktif</template></small><small v-if="item.options?.length">{{ item.options.join(', ') }}</small></span><button type="button" class="secondary" :disabled="busy" @click="edit(item)">Edit</button></li></ul></div>
        <form @submit.prevent="saveDefinition"><h3>{{ editing ? 'Edit definisi' : 'Tambah definisi' }}</h3><label>Kode atribut<input v-model="form.key" required :disabled="Boolean(editing)" maxlength="50" placeholder="contoh: playstyle"></label><label>Label<input v-model="form.label" required minlength="2" maxlength="80"></label><label>Kategori<select v-model="form.category"><option value="kompetensi">Kompetensi</option><option value="gaya_main">Gaya main</option><option value="reputasi">Reputasi</option></select></label><label>Jenis input<select v-model="form.value_type" @change="form.filter_type = allowedFilters[0] || ''"><option v-for="type in Object.keys(typeFilters)" :key="type" :value="type">{{ type }}</option></select></label><label>Tipe filter<select v-model="form.filter_type"><option v-for="type in allowedFilters" :key="type" :value="type">{{ type }}</option></select></label><label v-if="hasOptions">Opsi (satu per baris)<textarea v-model="form.options" rows="5" placeholder="Opsi pertama&#10;Opsi kedua"></textarea></label><div class="pair"><label>Minimum<input v-model="form.range_min" type="number" step="any"></label><label>Maksimum<input v-model="form.range_max" type="number" step="any"></label></div><div class="pair"><label>Satuan<input v-model="form.unit" maxlength="20" placeholder="%"></label><label>Urutan<input v-model="form.sort_order" type="number" min="0" max="10000"></label></div><label class="check"><input v-model="form.active" type="checkbox"> Aktif</label><div class="actions"><button type="submit" :disabled="busy">{{ busy ? 'Menyimpan…' : 'Simpan definisi' }}</button><button v-if="editing" type="button" class="secondary" @click="resetForm">Batal</button></div></form></div>
    </section>
    <section v-if="!loading && gameId" class="panel catalog"><h2>Opsi katalog lama</h2><p>Opsi rank, role, mode, dan wilayah yang sudah digunakan profil lama tetap tersedia. Hapus/edit opsi lama belum didukung.</p><div v-for="group in grouped" :key="group.kind" class="group"><h3>{{ group.kind }} · {{ group.options.length }}</h3><ul><li v-for="option in group.options" :key="option.id"><span><strong>{{ option.label }}</strong><small>{{ option.code }}</small><small v-if="option.rank_mode_option_id">Mode rank: {{ modeOptions.find(o => o.id === option.rank_mode_option_id)?.label || 'Tidak tersedia' }}</small></span></li></ul></div><form class="catalog-form" @submit.prevent="addOption"><h3>Tambah opsi katalog</h3><label>Jenis atribut<select v-model="kind"><option v-for="type in kinds" :key="type" :value="type">{{ type }}</option></select></label><label>Kode unik<input v-model="code" required pattern="[a-z0-9-]{2,50}" maxlength="50"></label><label>Label pemain<input v-model="label" required minlength="2" maxlength="80"></label><label v-if="kind === 'rank'">Mode rank<select v-model="rankMode"><option value="">Tanpa mode</option><option v-for="mode in modeOptions" :key="mode.id" :value="mode.id">{{ mode.label }}</option></select></label><button type="submit" :disabled="busy">Tambah opsi</button></form></section>
  </AdminShell>
</template>
<style scoped>
.panel{background:#1e1e29;border:1px solid #414150;border-radius:18px;padding:24px;margin-bottom:20px}.panel h2{font-size:20px;margin:0 0 10px}.panel p{color:#b9b9c7;font-size:13px}.intro{display:flex;align-items:center;gap:12px;flex-wrap:wrap}.layout{display:grid;grid-template-columns:minmax(0,1fr) minmax(270px,350px);align-items:start;gap:24px}ul{list-style:none;margin:0;padding:0}li{display:flex;justify-content:space-between;align-items:center;gap:14px;padding:14px 0;border-bottom:1px solid #414150;overflow-wrap:anywhere}li span{min-width:0;display:grid;gap:5px}small{font-size:12px;color:#b9b9c7}form,label{display:grid;gap:8px}form{gap:14px}label{font-size:13px;font-weight:650}.pair,.actions{display:flex;gap:10px}.pair>label{min-width:0;flex:1}.check{display:flex;align-items:center}input,select,textarea{background:#2a2a37;color:#f5f3ee;border:1px solid #656575;border-radius:10px;padding:10px 12px;max-width:100%;font:inherit}button{background:#c8ff4d;color:#14141c;border:0;border-radius:12px;padding:10px 16px;font-weight:750;cursor:pointer}.secondary{background:#333341;color:#f5f3ee}button:disabled{opacity:.5;cursor:not-allowed}.error{color:#ffb4ab}.notice{color:#c8ff4d}.group{margin:16px 0;border-top:1px solid #414150}.group h3{text-transform:capitalize}.catalog-form{max-width:400px;margin-top:24px}@media(max-width:900px){.layout{grid-template-columns:1fr}}@media(max-width:540px){.panel{padding:16px}li{align-items:flex-start;flex-direction:column}}
</style>
