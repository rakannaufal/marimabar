<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { listGames, listAttributeDefinitions, searchProfiles } from '../lib/api'
import type { AttributeDefinition, Game, Player, SearchFilters } from '../lib/models'
import PlayerCard from '../components/PlayerCard.vue'
import GameLogo from '../components/GameLogo.vue'
import { searchableProfileFields } from '../lib/gameProfileFields'

const route = useRoute()
const slug = computed(() => String(route.params.gameSlug || route.params.slug || ''))
const games = ref<Game[]>([]), definitions = ref<AttributeDefinition[]>([]), players = ref<Player[]>([])
const error = ref(''), catalogError = ref(''), validationError = ref(''), catalogLoading = ref(true), loading = ref(false), loadingMore = ref(false), mobileFiltersOpen = ref(false)
const draft = ref<SearchFilters>({ attributes: {} }), applied = ref<SearchFilters>({ attributes: {} }), page = ref(0), hasMore = ref(false)
const selectedGame = computed(() => games.value.find(game => game.slug === slug.value))
const availableDefinitions = computed(() => searchableProfileFields(slug.value, definitions.value))
const sectionNames: Record<string, string> = { kompetensi: 'Rank & kemampuan', gaya_main: 'Preferensi bermain', reputasi: 'Statistik game' }
const filterSections = computed(() => ['kompetensi', 'gaya_main', 'reputasi'].map(key => ({
  key, title: sectionNames[key], fields: availableDefinitions.value.filter(definition => definition.category === key &&
    (slug.value !== 'free-fire' || definition.key !== 'rank_br' && definition.key !== 'rank_cs' ||
      draft.value.attributes?.ranked_mode === (definition.key === 'rank_br' ? 'Battle Royale Ranked' : 'Clash Squad Ranked'))),
})).filter(section => section.fields.length))
const activeFilters = computed(() => Object.entries(applied.value.attributes || {}).map(([key, value]) => {
  const label = availableDefinitions.value.find(definition => definition.key === key)?.label || (key === 'language' ? 'Bahasa' : key)
  const description = Array.isArray(value) ? value.join(', ') : value && typeof value === 'object' ? Object.entries(value).map(([bound, item]) => `${bound === 'min' ? 'dari' : 'hingga'} ${item}`).join(' · ') : value === true ? 'Ya' : value === false ? 'Tidak' : String(value)
  return { key, label: `${label}: ${description}` }
}))
const gameContext: Record<string, string> = {
  mlbb: 'Cari rekan sesuai posisi EXP, Jungle, Mid, Gold, atau Roam.',
  'pubg-mobile': 'Temukan rekan squad sesuai mode, perspektif, dan peran.',
  'free-fire': 'Cari teman Battle Royale atau Clash Squad dengan rank sesuai mode.',
  valorant: 'Temukan rekan tim sesuai mode, rank, dan kelas agent.',
}
let requestId = 0, catalogRequest = 0
let filterTimer: ReturnType<typeof setTimeout> | undefined
function scheduleFilters(debounced = false) {
  clearTimeout(filterTimer)
  if (debounced) filterTimer = setTimeout(applyFilters, 400)
  else applyFilters()
}
function setFilter(key: string, value: unknown) {
  const attributes = { ...draft.value.attributes }
  if (slug.value === 'free-fire' && key === 'ranked_mode') {
    delete attributes.rank_br
    delete attributes.rank_cs
  }
  if (value === '' || value === undefined || (Array.isArray(value) && !value.length)) delete attributes[key]
  else attributes[key] = value
  draft.value = { attributes }
  validationError.value = ''
  scheduleFilters()
}
function toggleChoice(key: string, choice: string) {
  const values = draft.value.attributes?.[key]
  const selected = Array.isArray(values) ? values as string[] : []
  if (key === 'position_secondary' && !selected.includes(choice) && selected.length >= 2) return
  setFilter(key, selected.includes(choice) ? selected.filter(value => value !== choice) : [...selected, choice])
}
function setRange(key: string, bound: 'min'|'max', raw: string) {
  const existing = draft.value.attributes?.[key]
  const range = existing && typeof existing === 'object' && !Array.isArray(existing) ? { ...existing as Record<string, unknown> } : {}
  if (raw === '') delete range[bound]
  else range[bound] = Number(raw)
  const attributes = { ...draft.value.attributes }
  if (Object.keys(range).length) attributes[key] = range
  else delete attributes[key]
  draft.value = { attributes }
  validationError.value = ''
  scheduleFilters(true)
}
function setTierRange(key: string, bound: 'min'|'max', raw: string) {
  const existing = draft.value.attributes?.[key]
  const range = existing && typeof existing === 'object' && !Array.isArray(existing) ? { ...existing as Record<string, unknown> } : {}
  if (!raw) delete range[bound]
  else range[bound] = raw
  setFilter(key, Object.keys(range).length ? range : undefined)
}
function resetFilters() { clearTimeout(filterTimer); draft.value = { attributes: {} }; applied.value = { attributes: {} }; validationError.value = ''; void loadProfiles(false) }
function removeAppliedFilter(key: string) {
  clearTimeout(filterTimer)
  const attributes = { ...applied.value.attributes }; delete attributes[key]
  if (slug.value === 'free-fire' && key === 'ranked_mode') { delete attributes.rank_br; delete attributes.rank_cs }
  applied.value = { attributes }; draft.value = { attributes: { ...attributes } }
  validationError.value = ''; void loadProfiles(false)
}
function retryCatalog() { void loadCatalog() }
function applyFilters() {
  if (catalogLoading.value || catalogError.value) return
  for (const definition of availableDefinitions.value) {
    const value = draft.value.attributes?.[definition.key]
    if (!value || typeof value !== 'object' || Array.isArray(value)) continue
    const range = value as { min?: number|string; max?: number|string }
    if (definition.value_type !== 'slider_tier') {
      for (const bound of [range.min, range.max]) {
        if (bound === undefined) continue
        if (!Number.isFinite(bound) || definition.range_min !== null && Number(bound) < definition.range_min || definition.range_max !== null && Number(bound) > definition.range_max) {
          validationError.value = `Nilai ${definition.label} di luar batas yang tersedia.`; return
        }
      }
    }
    if (range.min === undefined || range.max === undefined) continue
    const choices = Array.isArray(definition.options) ? definition.options : []
    const reversed = definition.value_type === 'slider_tier'
      ? choices.indexOf(String(range.min)) > choices.indexOf(String(range.max))
      : Number(range.min) > Number(range.max)
    if (reversed) { validationError.value = `Rentang ${definition.label} terbalik. Periksa nilai minimal dan maksimal.`; return }
  }
  validationError.value = ''
  applied.value = { attributes: { ...draft.value.attributes } }; void loadProfiles(false)
}
async function loadCatalog() {
  const current = ++catalogRequest, currentSlug = slug.value
  catalogError.value = ''; catalogLoading.value = true; games.value = []; definitions.value = []
  try {
    const result = await listGames()
    if (current !== catalogRequest) return
    games.value = result
    const game = result.find(item => item.slug === currentSlug)
    if (game) { const available = await listAttributeDefinitions(game.id); if (current === catalogRequest) definitions.value = available }
  } catch { if (current === catalogRequest) catalogError.value = 'Pilihan filter belum bisa dimuat. Coba muat ulang halaman.' }
  finally { if (current === catalogRequest) catalogLoading.value = false }
}
async function loadProfiles(more: boolean) {
  if (!slug.value || (more && (loadingMore.value || !hasMore.value))) return
  const current = ++requestId, nextPage = more ? page.value + 1 : 0
  if (more) loadingMore.value = true
  else { loading.value = true; players.value = []; hasMore.value = false }
  error.value = ''
  try {
    const result = await searchProfiles(slug.value, applied.value, nextPage)
    if (current !== requestId) return
    const existing = new Set(more ? players.value.map(player => player.id) : [])
    players.value = more ? [...players.value, ...result.filter(player => !existing.has(player.id))] : result
    page.value = nextPage; hasMore.value = result.length === 20
  } catch { if (current === requestId) error.value = 'Pencarian belum bisa dimuat. Coba lagi, ya.' }
  finally { if (current === requestId) { loading.value = false; loadingMore.value = false } }
}
watch(slug, () => { clearTimeout(filterTimer); draft.value = { attributes: {} }; applied.value = { attributes: {} }; validationError.value = ''; mobileFiltersOpen.value = false; void loadCatalog(); void loadProfiles(false) })
onMounted(() => { void loadCatalog(); void loadProfiles(false) })
onUnmounted(() => { clearTimeout(filterTimer); requestId++; catalogRequest++ })
</script>

<template>
  <main class="page-shell search-page">
    <nav class="breadcrumb" aria-label="Breadcrumb"><RouterLink to="/">Beranda</RouterLink><span>/</span><RouterLink to="/pilih-game">Pilih Game</RouterLink><span>/</span><strong>{{ selectedGame?.name || slug }}</strong></nav>
    <header class="page-heading"><span v-if="selectedGame" class="search-game-logo"><GameLogo :slug="selectedGame.slug" :name="selectedGame.name" /></span><div><h1>Teman Mabar {{ selectedGame?.name || slug }}</h1><p>{{ gameContext[slug] || 'Temukan teman mabar sesuai pilihanmu.' }}</p></div><RouterLink class="button button--outline" to="/pilih-game">Pilih game lain</RouterLink></header>


    <button class="button button--outline mobile-filter-toggle" type="button" :aria-expanded="mobileFiltersOpen" aria-controls="search-filters" @click="mobileFiltersOpen = !mobileFiltersOpen">{{ mobileFiltersOpen ? 'Tutup filter' : `Filter${activeFilters.length ? ` (${activeFilters.length})` : ''}` }}</button>
    <div class="search-layout">
      <aside id="search-filters" class="filter-panel" :class="{ 'filter-panel--open': mobileFiltersOpen }" aria-label="Filter pemain">
        <div class="filter-panel__header"><div class="filter-title"><svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 7h16M7 12h10m-7 5h4"/><circle cx="8" cy="7" r="2" fill="#1e1e29"/><circle cx="15" cy="12" r="2" fill="#1e1e29"/></svg><h2>Filter</h2><span v-if="activeFilters.length" class="filter-count">{{ activeFilters.length }}</span></div><button v-if="activeFilters.length" type="button" class="filter-clear" @click="resetFilters">Reset semua</button></div>
        <form @submit.prevent="applyFilters">
          <p v-if="validationError" class="filter-error filter-validation" role="alert">{{ validationError }}</p>
          <p v-if="catalogLoading" role="status">Memuat filter game…</p>
          <div v-else-if="catalogError" class="filter-error" role="alert"><p>{{ catalogError }}</p><button type="button" class="text-link" @click="retryCatalog">Coba lagi</button></div><p v-else-if="!availableDefinitions.length" class="fine-print">Belum ada filter atribut tersedia untuk game ini. Kamu masih bisa memilih bahasa.</p>
          <details v-for="section in filterSections" :key="section.key" class="filter-section" :open="section.key === 'kompetensi' || undefined"><summary><span class="section-title">{{ section.title }}</span><span class="section-meta">{{ section.fields.length }} atribut</span><svg aria-hidden="true" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="m5 7.5 5 5 5-5"/></svg></summary><div class="filter-section__body"><div v-for="definition in section.fields" :key="definition.key" class="dynamic-filter">
            <fieldset v-if="['checkbox_group', 'tag_select'].includes(definition.filter_type)" class="filter-group"><legend>{{ definition.label }}</legend><div class="filter-options"><label v-for="choice in (definition.options as string[])" :key="choice" class="filter-option"><input type="checkbox" :checked="Array.isArray(draft.attributes?.[definition.key]) && (draft.attributes?.[definition.key] as string[]).includes(choice)" :disabled="definition.key === 'position_secondary' && Array.isArray(draft.attributes?.position_secondary) && (draft.attributes?.position_secondary as string[]).length >= 2 && !(draft.attributes?.position_secondary as string[]).includes(choice)" @change="toggleChoice(definition.key, choice)"> {{ choice }}</label></div></fieldset>
            <fieldset v-else-if="definition.filter_type === 'radio'" class="filter-group"><legend>{{ definition.label }}</legend><div class="filter-options"><label class="filter-option"><input type="radio" :name="definition.key" :checked="draft.attributes?.[definition.key] === undefined" @change="setFilter(definition.key, undefined)"> Semua</label><label v-for="choice in (definition.options as string[])" :key="choice" class="filter-option"><input type="radio" :name="definition.key" :checked="draft.attributes?.[definition.key] === choice" @change="setFilter(definition.key, choice)"> {{ choice }}</label></div></fieldset>
            <label v-else-if="['dropdown', 'toggle_dropdown'].includes(definition.filter_type)" class="field">{{ definition.label }}<select :value="draft.attributes?.[definition.key] ?? ''" @change="setFilter(definition.key, ($event.target as HTMLSelectElement).value)"><option value="">Semua</option><option v-for="choice in (definition.options as string[])" :key="choice" :value="choice">{{ choice }}</option></select></label>
            <fieldset v-else-if="definition.filter_type === 'toggle'" class="filter-group"><legend>{{ definition.label }}</legend><div class="filter-options"><label v-for="choice in [{ label: 'Semua', value: undefined }, { label: 'Ya', value: true }, { label: 'Tidak', value: false }]" :key="choice.label" class="filter-option"><input type="radio" :name="definition.key" :checked="draft.attributes?.[definition.key] === choice.value" @change="setFilter(definition.key, choice.value)"> {{ choice.label }}</label></div></fieldset>
            <fieldset v-else-if="definition.value_type === 'slider_tier'" class="filter-group"><legend>{{ definition.label }}</legend><div class="range-fields"><label class="field">Minimal<select :value="(draft.attributes?.[definition.key] as Record<string, string> | undefined)?.min || ''" @change="setTierRange(definition.key, 'min', ($event.target as HTMLSelectElement).value)"><option value="">Semua</option><option v-for="choice in (definition.options as string[])" :key="choice">{{ choice }}</option></select></label><label class="field">Maksimal<select :value="(draft.attributes?.[definition.key] as Record<string, string> | undefined)?.max || ''" @change="setTierRange(definition.key, 'max', ($event.target as HTMLSelectElement).value)"><option value="">Semua</option><option v-for="choice in (definition.options as string[])" :key="choice">{{ choice }}</option></select></label></div></fieldset>
            <fieldset v-else class="filter-group"><legend>{{ definition.label }} {{ definition.unit || '' }}</legend><div class="range-fields"><label class="field">Minimal<input type="number" :step="definition.value_type === 'decimal' ? '0.01' : '1'" :min="definition.range_min ?? undefined" :max="definition.range_max ?? undefined" :value="(draft.attributes?.[definition.key] as Record<string, number> | undefined)?.min ?? ''" @input="setRange(definition.key, 'min', ($event.target as HTMLInputElement).value)"></label><label v-if="definition.filter_type === 'range_slider'" class="field">Maksimal<input type="number" :step="definition.value_type === 'decimal' ? '0.01' : '1'" :min="definition.range_min ?? undefined" :max="definition.range_max ?? undefined" :value="(draft.attributes?.[definition.key] as Record<string, number> | undefined)?.max ?? ''" @input="setRange(definition.key, 'max', ($event.target as HTMLInputElement).value)"></label></div></fieldset>
          </div></div></details>
          <fieldset v-if="!catalogError" class="filter-group language-filter"><legend>Bahasa</legend><div class="filter-options"><label v-for="choice in [{ code: 'id', label: 'Indonesia' }, { code: 'en', label: 'English' }]" :key="choice.code" class="filter-option"><input type="checkbox" :checked="Array.isArray(draft.attributes?.language) && (draft.attributes?.language as string[]).includes(choice.code)" @change="toggleChoice('language', choice.code)"> {{ choice.label }}</label></div></fieldset>
          <p class="fine-print">Atribut profil diisi pemain sendiri; statistik belum terverifikasi.</p>
        </form>
      </aside>
      <section class="search-results" aria-labelledby="results-title">
        <div class="results-heading"><h2 id="results-title"><strong>{{ players.length }}</strong> pemain ditampilkan</h2><span class="muted">{{ loading ? 'Memuat…' : hasMore ? 'Masih ada profil lain' : 'Hasil yang tersedia' }}</span></div>
        <div v-if="activeFilters.length" class="active-filters"><button v-for="filter in activeFilters" :key="filter.key" type="button" class="active-filter" :aria-label="`Hapus filter ${filter.label}`" @click="removeAppliedFilter(filter.key)">{{ filter.label }} <span aria-hidden="true">×</span></button><button type="button" class="text-link" @click="resetFilters">Hapus semua</button></div>
        <p v-if="loading" class="state-card" role="status">Mencari teman mabar…</p>
        <div v-else-if="error && !players.length" class="state-card" role="alert"><h3>Pencarian terganggu</h3><p>{{ error }}</p><button class="button button--outline" type="button" @click="loadProfiles(false)">Coba lagi</button></div>
        <div v-else-if="!players.length" class="state-card"><h3>{{ activeFilters.length ? 'Belum ada pemain yang cocok' : 'Belum ada profil untuk game ini' }}</h3><p>{{ activeFilters.length ? 'Coba kurangi pilihan filter untuk melihat lebih banyak profil.' : 'Belum ada pemain yang menampilkan profil publik di game ini. Coba lagi nanti atau pilih game lain.' }}</p><button v-if="activeFilters.length" class="button button--outline" type="button" @click="resetFilters">Reset filter</button><RouterLink v-else class="button button--outline" to="/pilih-game">Pilih game lain</RouterLink></div>
        <template v-else><div class="player-list"><PlayerCard v-for="player in players" :key="player.id" :player="player" /></div><p v-if="error" class="inline-error" role="alert">{{ error }}</p><button v-if="hasMore" class="button button--outline load-more" type="button" :disabled="loadingMore" @click="loadProfiles(true)">{{ loadingMore ? 'Memuat…' : 'Muat lebih banyak' }}</button><p class="fine-print">Rank dan status siap mabar diisi pemain, belum terverifikasi atau real-time.</p></template>
      </section>
    </div>
  </main>
</template>
<style scoped>
.search-page{padding-bottom:100px;max-width:1200px}
.search-page .breadcrumb{flex-wrap:wrap}
.search-page .page-heading{justify-content:flex-start;align-items:center;flex-wrap:wrap;gap:18px;margin-bottom:30px}
.search-page .page-heading>div{min-width:0;flex:1 1 320px}
.search-page .page-heading .button{margin-left:auto;white-space:nowrap}
.search-game-logo{display:grid;place-items:center;width:64px;height:64px;padding:5px;border-radius:16px;background:#272736;flex:none}
.search-page .search-layout{display:grid;grid-template-columns:minmax(0,302px) minmax(0,1fr);gap:28px;align-items:start}
.search-page .search-results{min-width:0}
.search-page .filter-panel{min-width:0;position:sticky;top:16px;max-height:calc(100vh - 32px);overflow-y:auto;overscroll-behavior:contain;padding:0;background:#20202b;border:1px solid #393946;border-radius:18px;scrollbar-color:#565666 transparent}
.search-page .filter-panel__header{display:flex;align-items:center;justify-content:space-between;gap:10px;margin:0;padding:19px 20px 17px;border-bottom:1px solid #393946}
.filter-title{display:flex;align-items:center;gap:10px;min-width:0}
.filter-title svg{width:19px;height:19px;flex:none;color:#c8ff4d}
.search-page .filter-panel__header h2{font:700 18px/1.2 'Plus Jakarta Sans',sans-serif;letter-spacing:-.02em;margin:0}
.filter-count{display:grid;place-items:center;min-width:20px;height:20px;padding:0 5px;border-radius:6px;background:#c8ff4d;color:#14141c;font-size:11px;font-weight:800}
.filter-clear{padding:5px 0;border:0;background:none;color:#c8ff4d;font-size:11px;font-weight:700;white-space:nowrap}
.filter-clear:hover{text-decoration:underline}
.filter-panel form{padding:0}
.filter-panel form>p[role=status],.filter-panel form>.fine-print,.filter-panel form>.filter-error{margin:15px 20px}
.filter-section{border-bottom:1px solid #393946}
.filter-section summary{display:flex;align-items:center;gap:7px;min-height:51px;padding:13px 20px;list-style:none;cursor:pointer}
.filter-section summary::-webkit-details-marker{display:none}
.section-title{flex:1;min-width:0;font:700 13px/1.35 'Plus Jakarta Sans',sans-serif;color:#f5f3ee}
.section-meta{flex:none;font-size:10px;color:#aaaaba;white-space:nowrap}
.filter-section summary svg{width:17px;height:17px;flex:none;color:#a9a8b5;transition:transform .2s ease}
.filter-section[open] summary svg{transform:rotate(180deg)}
.filter-section summary:hover .section-title{color:#c8ff4d}
.filter-section summary:focus-visible{outline:2px solid #c8ff4d;outline-offset:-4px;border-radius:8px}
.filter-section__body{display:grid;gap:19px;padding:3px 20px 20px}
.dynamic-filter{min-width:0}
.search-page .filter-group{padding:0;margin:0;border:0;min-width:0}
.search-page .filter-group legend,.search-page .dynamic-filter>.field{font-size:12px;font-weight:700;color:#e4e1ed}
.search-page .filter-group legend{margin:0 0 10px;padding:0;line-height:1.4}
.search-page .filter-options{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));column-gap:10px;row-gap:2px}
.search-page .filter-option{display:flex;align-items:center;gap:10px;min-height:32px;padding:5px 3px;border:0;border-radius:7px;background:transparent;color:#c4c3ce;font-size:12px;line-height:1.35;overflow-wrap:anywhere;cursor:pointer}
.search-page .filter-option:hover{background:#2b2b38;color:#f5f3ee}
.search-page .filter-option:has(input:checked){color:#f5f3ee;font-weight:600}
.search-page .filter-option:focus-within{outline:2px solid #c8ff4d;outline-offset:1px}
.search-page .filter-option input{width:15px;height:15px;margin:0;flex:none;accent-color:#c8ff4d}
.search-page .field{display:grid;gap:6px;margin:0;color:#b9b8c6;font-size:11px;font-weight:600;min-width:0}
.range-fields{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px}
.search-page .field select,.search-page .field input{width:100%;min-width:0;height:36px;min-height:36px;padding:6px 9px;background:#292935;border:1px solid #555563;border-radius:8px;color:#f5f3ee;font-size:11px;font-weight:500}
.search-page .field select:focus-visible,.search-page .field input:focus-visible{outline:2px solid #c8ff4d;outline-offset:1px;border-color:#c8ff4d}
.search-page .filter-panel .language-filter{padding:17px 20px 18px;border-bottom:1px solid #393946}
.search-page .filter-panel form>.fine-print:last-child{margin:14px 20px 20px;font-size:11px;line-height:1.5}
.filter-error{color:#ffb4ab;font-size:12px;line-height:1.5}
.filter-error p{margin:0 0 8px}
.filter-validation{padding:10px 12px;border-radius:8px;background:#4a2a2d}
.search-page .results-heading h2 strong{font-family:'Plus Jakarta Sans',sans-serif;color:#c8ff4d}
.search-page .active-filters{align-items:center}
.active-filter{display:inline-flex;align-items:center;gap:7px;max-width:100%;padding:7px 10px;border:1px solid #676071;border-radius:8px;background:#342d50;color:#e9e4ff;font-size:12px;text-align:left;overflow-wrap:anywhere}
.active-filter:hover{border-color:#c8ff4d}
.active-filter span{font-size:18px;line-height:1}
.search-page .player-list{display:grid;gap:14px}
.search-page .state-card{max-width:680px}
.search-page .state-card p{max-width:480px}
@media(max-width:760px){
  .search-page .search-layout{display:block}
  .search-page .filter-panel{display:none;margin-bottom:20px}
  .search-page .filter-panel--open{display:block;position:static;max-height:none;overflow:visible}
  .search-page .mobile-filter-toggle{display:inline-flex;margin-bottom:16px}
}
@media(max-width:520px){
  .search-page .page-heading{gap:12px}
  .search-page .page-heading>div{flex-basis:calc(100% - 80px)}
  .search-page .page-heading .button{margin-left:0}
  .search-page .results-heading{align-items:flex-start;flex-direction:column}
}
@media(prefers-reduced-motion:reduce){.filter-section summary svg{transition:none}}
</style>
