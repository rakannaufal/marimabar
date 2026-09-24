<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { listGames, listAttributeDefinitions, searchProfiles } from '../lib/api'
import type { AttributeDefinition, Game, Player, SearchFilters } from '../lib/models'
import PlayerCard from '../components/PlayerCard.vue'

const route = useRoute()
const slug = computed(() => String(route.params.gameSlug || route.params.slug || ''))
const games = ref<Game[]>([]), definitions = ref<AttributeDefinition[]>([]), players = ref<Player[]>([])
const error = ref(''), catalogError = ref(''), catalogLoading = ref(true), loading = ref(false), loadingMore = ref(false), mobileFiltersOpen = ref(false)
const draft = ref<SearchFilters>({ attributes: {} }), applied = ref<SearchFilters>({ attributes: {} }), page = ref(0), hasMore = ref(false)
const selectedGame = computed(() => games.value.find(game => game.slug === slug.value))
const availableDefinitions = computed(() => definitions.value.filter(definition => {
  if (['mabar_rating', 'successful_mabar_count', 'account_verified', 'last_active'].includes(definition.key)) return false
  const choices = Array.isArray(definition.options) && definition.options.length > 0
  return (['dropdown', 'radio', 'checkbox_group', 'tag_select', 'toggle_dropdown'].includes(definition.filter_type) && choices)
    || (['range_slider', 'range_min'].includes(definition.filter_type) && (definition.value_type === 'slider_tier' ? choices : ['number', 'decimal'].includes(definition.value_type)))
    || (definition.filter_type === 'toggle' && definition.value_type === 'boolean')
}))
const activeFilters = computed(() => [...availableDefinitions.value.filter(definition => applied.value.attributes?.[definition.key] !== undefined).map(definition => definition.label), ...(applied.value.attributes?.language ? ['Bahasa'] : [])])
const gameContext: Record<string, string> = {
  mlbb: 'Cari rekan push rank sesuai role dan server pilihanmu.',
  'pubg-mobile': 'Temukan rekan squad sesuai mode dan region pilihanmu.',
  'free-fire': 'Cari teman Battle Royale atau Clash Squad yang sefrekuensi.',
  valorant: 'Temukan rekan tim sesuai rank, role, dan server pilihanmu.',
}
let requestId = 0, catalogRequest = 0
function setFilter(key: string, value: unknown) {
  const attributes = { ...draft.value.attributes }
  if (value === '' || value === undefined || (Array.isArray(value) && !value.length)) delete attributes[key]
  else attributes[key] = value
  draft.value = { attributes }
}
function toggleChoice(key: string, choice: string) {
  const values = draft.value.attributes?.[key]
  const selected = Array.isArray(values) ? values as string[] : []
  setFilter(key, selected.includes(choice) ? selected.filter(value => value !== choice) : [...selected, choice])
}
function setRange(key: string, bound: 'min'|'max', raw: string) {
  const existing = draft.value.attributes?.[key]
  const range = existing && typeof existing === 'object' && !Array.isArray(existing) ? { ...existing as Record<string, unknown> } : {}
  if (raw === '') delete range[bound]
  else range[bound] = Number(raw)
  setFilter(key, Object.keys(range).length ? range : undefined)
}
function setTierRange(key: string, bound: 'min'|'max', raw: string) {
  const existing = draft.value.attributes?.[key]
  const range = existing && typeof existing === 'object' && !Array.isArray(existing) ? { ...existing as Record<string, unknown> } : {}
  if (!raw) delete range[bound]
  else range[bound] = raw
  setFilter(key, Object.keys(range).length ? range : undefined)
}
function resetFilters() { catalogError.value = ''; draft.value = { attributes: {} }; applied.value = { attributes: {} }; mobileFiltersOpen.value = false; void loadProfiles(false) }
function applyFilters() {
  if (catalogLoading.value || catalogError.value && !definitions.value.length) return
  for (const definition of availableDefinitions.value) {
    const value = draft.value.attributes?.[definition.key]
    if (!value || typeof value !== 'object' || Array.isArray(value)) continue
    const range = value as { min?: number|string; max?: number|string }
    if (range.min === undefined || range.max === undefined) continue
    const choices = Array.isArray(definition.options) ? definition.options : []
    const reversed = definition.value_type === 'slider_tier'
      ? choices.indexOf(String(range.min)) > choices.indexOf(String(range.max))
      : Number(range.min) > Number(range.max)
    if (reversed) { catalogError.value = `Rentang ${definition.label} terbalik.`; return }
  }
  catalogError.value = ''
  applied.value = { attributes: { ...draft.value.attributes } }; mobileFiltersOpen.value = false; void loadProfiles(false)
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
watch(slug, () => { draft.value = { attributes: {} }; applied.value = { attributes: {} }; mobileFiltersOpen.value = false; void loadCatalog(); void loadProfiles(false) })
onMounted(() => { void loadCatalog(); void loadProfiles(false) })
</script>

<template>
  <main class="page-shell search-page">
    <nav class="breadcrumb" aria-label="Breadcrumb"><RouterLink to="/">Beranda</RouterLink><span>/</span><RouterLink to="/pilih-game">Pilih Game</RouterLink><span>/</span><strong>{{ selectedGame?.name || slug }}</strong></nav>
    <header class="page-heading"><div><h1>Teman Mabar {{ selectedGame?.name || slug }}</h1><p>{{ gameContext[slug] || 'Temukan teman mabar sesuai pilihanmu.' }}</p></div><RouterLink class="button button--outline" to="/pilih-game">Pilih game lain</RouterLink></header>

    <p v-if="catalogError" role="alert">{{ catalogError }}</p>
    <button class="button button--outline mobile-filter-toggle" type="button" :aria-expanded="mobileFiltersOpen" aria-controls="search-filters" @click="mobileFiltersOpen = !mobileFiltersOpen">{{ mobileFiltersOpen ? 'Tutup filter' : 'Buka filter' }}</button>
    <div class="search-layout">
      <aside id="search-filters" class="filter-panel" :class="{ 'filter-panel--open': mobileFiltersOpen }" aria-label="Filter pemain">
        <div class="filter-panel__header"><h2>Filter</h2><button type="button" class="text-link" @click="resetFilters">Reset</button></div>
        <form @submit.prevent="applyFilters">
          <p v-if="catalogLoading" role="status">Memuat filter game…</p>
          <p v-else-if="!availableDefinitions.length" class="fine-print">Belum ada filter atribut tersedia untuk game ini.</p>
          <div v-for="definition in availableDefinitions" :key="definition.key" class="dynamic-filter">
            <fieldset v-if="['checkbox_group', 'tag_select'].includes(definition.filter_type)" class="filter-group"><legend>{{ definition.label }}</legend><div class="filter-options"><label v-for="choice in (definition.options as string[])" :key="choice" class="filter-option"><input type="checkbox" :checked="Array.isArray(draft.attributes?.[definition.key]) && (draft.attributes?.[definition.key] as string[]).includes(choice)" @change="toggleChoice(definition.key, choice)"> {{ choice }}</label></div></fieldset>
            <fieldset v-else-if="definition.filter_type === 'radio'" class="filter-group"><legend>{{ definition.label }}</legend><div class="filter-options"><label class="filter-option"><input type="radio" :name="definition.key" :checked="draft.attributes?.[definition.key] === undefined" @change="setFilter(definition.key, undefined)"> Semua</label><label v-for="choice in (definition.options as string[])" :key="choice" class="filter-option"><input type="radio" :name="definition.key" :checked="draft.attributes?.[definition.key] === choice" @change="setFilter(definition.key, choice)"> {{ choice }}</label></div></fieldset>
            <label v-else-if="['dropdown', 'toggle_dropdown'].includes(definition.filter_type)" class="field">{{ definition.label }}<select :value="draft.attributes?.[definition.key] ?? ''" @change="setFilter(definition.key, ($event.target as HTMLSelectElement).value)"><option value="">Semua</option><option v-for="choice in (definition.options as string[])" :key="choice" :value="choice">{{ choice }}</option></select></label>
            <fieldset v-else-if="definition.filter_type === 'toggle'" class="filter-group"><legend>{{ definition.label }}</legend><div class="filter-options"><label v-for="choice in [{ label: 'Semua', value: undefined }, { label: 'Ya', value: true }, { label: 'Tidak', value: false }]" :key="choice.label" class="filter-option"><input type="radio" :name="definition.key" :checked="draft.attributes?.[definition.key] === choice.value" @change="setFilter(definition.key, choice.value)"> {{ choice.label }}</label></div></fieldset>
            <fieldset v-else-if="definition.value_type === 'slider_tier'" class="filter-group"><legend>{{ definition.label }}</legend><label class="field">Minimal<select :value="(draft.attributes?.[definition.key] as Record<string, string> | undefined)?.min || ''" @change="setTierRange(definition.key, 'min', ($event.target as HTMLSelectElement).value)"><option value="">Semua</option><option v-for="choice in (definition.options as string[])" :key="choice">{{ choice }}</option></select></label><label class="field">Maksimal<select :value="(draft.attributes?.[definition.key] as Record<string, string> | undefined)?.max || ''" @change="setTierRange(definition.key, 'max', ($event.target as HTMLSelectElement).value)"><option value="">Semua</option><option v-for="choice in (definition.options as string[])" :key="choice">{{ choice }}</option></select></label></fieldset>
            <fieldset v-else class="filter-group"><legend>{{ definition.label }} {{ definition.unit || '' }}</legend><label class="field">Minimal<input type="number" :step="definition.value_type === 'decimal' ? '0.01' : '1'" :min="definition.range_min ?? undefined" :max="definition.range_max ?? undefined" :value="(draft.attributes?.[definition.key] as Record<string, number> | undefined)?.min ?? ''" @input="setRange(definition.key, 'min', ($event.target as HTMLInputElement).value)"></label><label v-if="definition.filter_type === 'range_slider'" class="field">Maksimal<input type="number" :step="definition.value_type === 'decimal' ? '0.01' : '1'" :min="definition.range_min ?? undefined" :max="definition.range_max ?? undefined" :value="(draft.attributes?.[definition.key] as Record<string, number> | undefined)?.max ?? ''" @input="setRange(definition.key, 'max', ($event.target as HTMLInputElement).value)"></label></fieldset>
          </div>
          <fieldset class="filter-group"><legend>Bahasa</legend><div class="filter-options"><label v-for="choice in [{ code: 'id', label: 'Indonesia' }, { code: 'en', label: 'English' }]" :key="choice.code" class="filter-option"><input type="checkbox" :checked="Array.isArray(draft.attributes?.language) && (draft.attributes?.language as string[]).includes(choice.code)" @change="toggleChoice('language', choice.code)"> {{ choice.label }}</label></div></fieldset>
          <button class="button button--primary filter-submit" type="submit" :disabled="catalogLoading || (!!catalogError && !definitions.length)">Terapkan filter</button>
          <button class="filter-reset" type="button" @click="resetFilters">Reset filter</button>
          <p class="fine-print">Atribut profil diisi pemain sendiri; statistik belum terverifikasi.</p>
        </form>
      </aside>
      <section class="search-results" aria-labelledby="results-title">
        <div class="results-heading"><h2 id="results-title"><strong>{{ players.length }}</strong> pemain ditampilkan</h2><span class="muted">{{ loading ? 'Memuat…' : hasMore ? 'Masih ada profil lain' : 'Hasil yang tersedia' }}</span></div>
        <div v-if="activeFilters.length" class="active-filters"><span v-for="(filter, index) in activeFilters" :key="index" class="chip chip--violet">{{ filter }}</span><button type="button" class="text-link" @click="resetFilters">Hapus semua</button></div>
        <p v-if="loading" class="state-card" role="status">Mencari teman mabar…</p>
        <div v-else-if="error && !players.length" class="state-card" role="alert"><h3>Pencarian terganggu</h3><p>{{ error }}</p><button class="button button--outline" type="button" @click="loadProfiles(false)">Coba lagi</button></div>
        <div v-else-if="!players.length" class="state-card"><h3>Belum ada pemain yang cocok</h3><p>Coba longgarkan filter rank atau server, ya.</p><button class="button button--outline" type="button" @click="resetFilters">Reset filter</button></div>
        <template v-else><div class="player-list"><PlayerCard v-for="player in players" :key="player.id" :player="player" /></div><p v-if="error" class="inline-error" role="alert">{{ error }}</p><button v-if="hasMore" class="button button--outline load-more" type="button" :disabled="loadingMore" @click="loadProfiles(true)">{{ loadingMore ? 'Memuat…' : 'Muat lebih banyak' }}</button><p class="fine-print">Rank dan status siap mabar diisi pemain, belum terverifikasi atau real-time.</p></template>
      </section>
    </div>
  </main>
</template>
<style scoped>
.dynamic-filter{margin-bottom:1rem}.dynamic-filter .field{display:block;margin-bottom:.65rem}.search-page{padding-bottom:80px}.search-page .button{border-radius:999px}.search-page .search-layout{grid-template-columns:280px minmax(0,1fr)}.search-page .filter-panel{border-radius:22px}.search-page .filter-option{border-radius:999px}.search-page .filter-panel__header{margin-bottom:22px}.search-page .filter-submit{border-radius:999px}.search-page .results-heading h2 strong{font-family:'Plus Jakarta Sans',sans-serif;color:#c8ff4d}.search-page .fine-print{margin-top:20px}.search-page .filter-group{border-top:1px solid #393944;padding-top:20px}.search-page .player-list{display:grid;gap:14px}@media(max-width:700px){.search-page .search-layout{display:block}.search-page .filter-panel{display:none}.search-page .filter-panel--open{display:block}}
</style>
