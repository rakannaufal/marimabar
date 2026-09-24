<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { listGames, listOptions, searchProfiles } from '../lib/api'
import type { Game, Option, Player, SearchFilters } from '../lib/models'
import PlayerCard from '../components/PlayerCard.vue'

const route = useRoute()
const slug = computed(() => String(route.params.gameSlug || route.params.slug || ''))
const games = ref<Game[]>([]), options = ref<Option[]>([]), players = ref<Player[]>([])
const error = ref(''), catalogError = ref(''), loading = ref(false), loadingMore = ref(false), mobileFiltersOpen = ref(false)
const draft = ref<SearchFilters>({}), applied = ref<SearchFilters>({}), page = ref(0), hasMore = ref(false)
const selectedGame = computed(() => games.value.find(game => game.slug === slug.value))
const optionsOf = (kind: string) => options.value.filter(option => option.kind === kind)
const modeOptions = computed(() => optionsOf('mode'))
const roleOptions = computed(() => optionsOf('role'))
const regionOptions = computed(() => optionsOf('region'))
const modeRanked = computed(() => ['free-fire', 'pubg-mobile'].includes(slug.value))
const valorantFull = computed(() => slug.value === 'valorant' && route.query.variant === 'full')
const valorantCompact = computed(() => slug.value === 'valorant' && !valorantFull.value)
const rankOptions = computed(() => optionsOf('rank').filter(option => !modeRanked.value || (draft.value.mode && option.rank_mode_option_id === modeOptions.value.find(mode => mode.code === draft.value.mode)?.id)))
const activeFilters = computed(() => [
  applied.value.mode && modeOptions.value.find(o => o.code === applied.value.mode)?.label,
  applied.value.rank && optionsOf('rank').find(o => o.code === applied.value.rank)?.label,
  ...(applied.value.roles || []).map(code => roleOptions.value.find(o => o.code === code)?.label),
  applied.value.region && regionOptions.value.find(o => o.code === applied.value.region)?.label,
  applied.value.ready && 'Siap mabar',
].filter(Boolean))
const gameContext: Record<string, string> = {
  mlbb: 'Cari rekan push rank sesuai role dan server pilihanmu.',
  'pubg-mobile': 'Temukan rekan squad sesuai mode dan region pilihanmu.',
  'free-fire': 'Cari teman Battle Royale atau Clash Squad yang sefrekuensi.',
  valorant: 'Temukan rekan tim sesuai rank, role, dan server pilihanmu.',
}
let requestId = 0, catalogRequest = 0
function toggleRole(code: string) {
  const roles = draft.value.roles || []
  draft.value = { ...draft.value, roles: roles.includes(code) ? roles.filter(role => role !== code) : [...roles, code] }
}
function resetFilters() { draft.value = {}; applied.value = {}; mobileFiltersOpen.value = false; void loadProfiles(false) }
function applyFilters() { applied.value = { ...draft.value, roles: [...(draft.value.roles || [])] }; mobileFiltersOpen.value = false; void loadProfiles(false) }
async function loadCatalog() {
  const current = ++catalogRequest, currentSlug = slug.value
  catalogError.value = ''; games.value = []; options.value = []
  try {
    const result = await listGames()
    if (current !== catalogRequest) return
    games.value = result
    const game = result.find(item => item.slug === currentSlug)
    if (game) { const available = await listOptions(game.id); if (current === catalogRequest) options.value = available }
  } catch { if (current === catalogRequest) catalogError.value = 'Pilihan filter belum bisa dimuat. Coba muat ulang halaman.' }
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
watch(slug, () => { draft.value = {}; applied.value = {}; mobileFiltersOpen.value = false; void loadCatalog(); void loadProfiles(false) })
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
          <label v-if="modeRanked && modeOptions.length" class="field">{{ slug === 'pubg-mobile' ? 'Mode rank' : 'Mode permainan' }}<select v-model="draft.mode" @change="draft.rank = ''"><option value="">Semua mode</option><option v-for="mode in modeOptions" :key="mode.id" :value="mode.code">{{ mode.label }}</option></select></label>
          <label v-if="rankOptions.length" class="field">Rank<select v-model="draft.rank"><option value="">Semua rank</option><option v-for="rank in rankOptions" :key="rank.id" :value="rank.code">{{ rank.label }}</option></select></label>
          <p v-else-if="modeRanked && modeOptions.length" class="fine-print">Pilih mode dulu untuk melihat rank yang sesuai.</p>
          <fieldset v-if="roleOptions.length" class="filter-group"><legend>{{ slug === 'pubg-mobile' ? 'Role bermain' : 'Role utama' }}</legend><div class="filter-options"><label v-for="role in roleOptions" :key="role.id" class="filter-option"><input type="checkbox" :checked="(draft.roles || []).includes(role.code)" @change="toggleRole(role.code)" />{{ role.label }}</label></div></fieldset>
          <label v-if="regionOptions.length" class="field">Server / region<select v-model="draft.region"><option value="">Semua region</option><option v-for="region in regionOptions" :key="region.id" :value="region.code">{{ region.label }}</option></select></label>
          <label class="check-field"><input v-model="draft.ready" type="checkbox" /> Hanya yang siap mabar</label>
          <button class="button button--primary filter-submit" type="submit">Terapkan filter</button>
          <button class="filter-reset" type="button" @click="resetFilters">Reset filter</button>
          <p class="fine-print">Filter memakai opsi game yang tersedia. Statistik win rate, K/D, MMR, dan tipe main belum dikumpulkan.</p>
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
.search-page{padding-bottom:80px}.search-page .button{border-radius:999px}.search-page .search-layout{grid-template-columns:280px minmax(0,1fr)}.search-page .filter-panel{border-radius:22px}.search-page .filter-option{border-radius:999px}.search-page .filter-panel__header{margin-bottom:22px}.search-page .filter-submit{border-radius:999px}.search-page .results-heading h2 strong{font-family:'Plus Jakarta Sans',sans-serif;color:#c8ff4d}.search-page .fine-print{margin-top:20px}.search-page .filter-group{border-top:1px solid #393944;padding-top:20px}.search-page .player-list{display:grid;gap:14px}@media(max-width:700px){.search-page .search-layout{display:block}.search-page .filter-panel{display:none}.search-page .filter-panel--open{display:block}}
</style>
