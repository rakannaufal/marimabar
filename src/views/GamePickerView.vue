<script setup lang="ts">
import { computed, onMounted, onServerPrefetch, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { listGames, searchProfiles } from '../lib/api'
import { configured } from '../lib/supabase'
import type { Game } from '../lib/models'

type Category = 'all' | 'moba' | 'fps' | 'br'
const details: Record<string, { category: Category; label: string; platform: string; description: string; symbol: string }> = {
  mlbb: { category: 'moba', label: 'MOBA 5v5', platform: 'Mobile', description: 'Cari rekan setim untuk push rank atau main santai.', symbol: 'M' },
  valorant: { category: 'fps', label: 'Tactical FPS', platform: 'PC', description: 'Kenalan dengan pemain yang cocok buat koordinasi tim.', symbol: 'V' },
  'pubg-mobile': { category: 'br', label: 'Battle Royale', platform: 'Mobile', description: 'Temukan squad untuk turun bareng di medan tempur.', symbol: 'P' },
  'free-fire': { category: 'br', label: 'Battle Royale', platform: 'Mobile', description: 'Bentuk squad untuk Clash Squad atau Battle Royale.', symbol: 'F' },
}
const categories: { key: Category; name: string }[] = [
  { key: 'all', name: 'Semua Kategori' }, { key: 'moba', name: 'MOBA 5v5' },
  { key: 'fps', name: 'Tactical FPS' }, { key: 'br', name: 'Battle Royale' },
]
const games = ref<Game[]>([])
const counts = ref<Record<string, number>>({})
const category = ref<Category>('all')
const loading = ref(true)
const error = ref('')
const visibleGames = computed(() => games.value.filter(game => category.value === 'all' || details[game.slug]?.category === category.value))
async function load() {
  if (!configured) { loading.value = false; return }
  loading.value = true; error.value = ''
  try {
    games.value = await listGames()
    const results = await Promise.allSettled(games.value.map(game => searchProfiles(game.slug)))
    counts.value = Object.fromEntries(results.flatMap((result, index) => result.status === 'fulfilled' ? [[games.value[index].id, result.value.length]] : []))
  } catch { error.value = 'Daftar game belum bisa dimuat. Coba lagi, ya.' }
  finally { loading.value = false }
}
onMounted(load)
onServerPrefetch(load)
</script>

<template>
  <main class="picker">
    <div class="picker-inner">
      <nav class="crumb" aria-label="Breadcrumb"><RouterLink to="/beranda">Beranda</RouterLink><span>/</span><span aria-current="page">Pilih Game</span></nav>
      <header class="intro">
        <h1>Mau main apa hari ini?</h1>
        <p>Pilih game favoritmu dan temukan rekan mabar sefrekuensi. Kenalan lewat profil sebelum kirim ajakan.</p>
      </header>
      <div class="filters" role="group" aria-label="Kategori game">
        <button v-for="item in categories" :key="item.key" type="button" :aria-pressed="category === item.key" @click="category = item.key">{{ item.name }}</button>
      </div>
      <p v-if="!configured" class="state" role="alert">Layanan belum dikonfigurasi.</p>
      <p v-else-if="loading" class="state" role="status">Memuat pilihan game…</p>
      <div v-else-if="error" class="state" role="alert"><p>{{ error }}</p><button class="secondary" type="button" @click="load">Coba lagi</button></div>
      <p v-else-if="!games.length" class="state">Belum ada game tersedia. Coba lagi nanti, ya.</p>
      <div v-else class="game-grid">
        <article v-for="game in visibleGames" :key="game.id" class="game-card">
          <div class="game-top"><span class="game-icon" :class="`game-icon--${game.slug}`" aria-hidden="true">{{ details[game.slug]?.symbol || game.name.charAt(0) }}</span><div class="badges"><span>{{ details[game.slug]?.label || 'Game komunitas' }}</span><span v-if="details[game.slug]?.platform">{{ details[game.slug]?.platform }}</span></div></div>
          <div class="game-copy"><h2>{{ game.name }}</h2><p>{{ details[game.slug]?.description || 'Temukan pemain untuk main bersama.' }}</p></div>
          <div class="game-foot"><div v-if="counts[game.id] !== undefined" class="count"><strong>{{ counts[game.id] === 20 ? '≥20' : counts[game.id] }}</strong><span>Profil ditampilkan</span></div><p v-else class="count-unavailable">Jumlah profil belum tersedia</p><RouterLink class="primary" :to="`/cari/${encodeURIComponent(game.slug)}`" :aria-label="`Cari teman mabar ${game.name}`">Cari Teman Mabar</RouterLink></div>
        </article>
        <article v-if="category === 'all'" class="game-card upcoming"><span class="game-icon" aria-hidden="true">+</span><div><h2>Game Lainnya Segera Hadir</h2><p>Belum menemukan game favoritmu? Jelajahi pilihan yang tersedia dulu, ya.</p></div><RouterLink class="secondary" to="/beranda">Kembali ke Beranda</RouterLink></article>
        <p v-if="!visibleGames.length" class="state">Belum ada game dalam kategori ini.</p>
      </div>
      <aside class="match-banner"><div class="banner-icon" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M13 2 5 13h6l-1 9 9-12h-6V2Z" /></svg></div><div><h2>Belum punya party tetap?</h2><p>Pilih game, atur filter, lalu lihat profil pemain sebelum mengirim ajakan mabar.</p></div><RouterLink class="primary" to="/cari/valorant" v-if="games.some(game => game.slug === 'valorant')">Coba Cari Teman</RouterLink><RouterLink v-else class="primary" to="/beranda">Kembali ke Beranda</RouterLink></aside>
    </div>
  </main>
</template>

<style scoped>
.picker{background:#14141c;color:#f5f3ee;padding:30px 0 76px}.picker-inner{width:min(100% - 48px,1216px);margin:auto}.crumb{display:flex;gap:9px;align-items:center;color:#a0a0b2;font-size:13px;margin-bottom:34px}.crumb a:hover{color:#c8ff4d}.crumb [aria-current]{color:#f5f3ee}.intro{max-width:760px}.intro h1{font:800 clamp(32px,4vw,48px)/1.14 'Plus Jakarta Sans',sans-serif;margin:0 0 13px}.intro p{color:#a0a0b2;font-size:17px;line-height:1.6;margin:0}.filters{display:flex;gap:9px;overflow-x:auto;margin:32px 0 24px;padding-bottom:6px}.filters button,.primary,.secondary{border-radius:999px;border:1px solid transparent;font-weight:700;text-align:center;text-decoration:none;cursor:pointer}.filters button{padding:11px 19px;white-space:nowrap;background:#272736;color:#f5f3ee}.filters button[aria-pressed=true],.primary{background:#c8ff4d;color:#14141c}.filters button:not([aria-pressed=true]):hover,.secondary:hover{border-color:#c8ff4d}.game-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:24px}.game-card{min-width:0;border:1px solid #2e2e3e;background:#1e1e29;border-radius:24px;padding:28px;display:flex;flex-direction:column;gap:24px}.game-card:hover{border-color:#7c9c3b;box-shadow:0 12px 28px #101015}.game-top{display:flex;justify-content:space-between;align-items:start;gap:12px}.game-icon{flex:none;display:grid;place-items:center;width:64px;height:64px;background:#272736;border-radius:20px;color:#c8ff4d;font:800 28px 'Plus Jakarta Sans',sans-serif}.game-icon--valorant{color:#f5f3ee}.game-icon--pubg-mobile{color:#8b7cff}.badges{display:flex;flex-wrap:wrap;gap:5px;justify-content:flex-end}.badges span{padding:5px 10px;background:#332d4c;color:#c7bfff;border-radius:999px;font-size:11px;font-weight:700}.game-copy{flex:1}.game-card h2{font:700 21px/1.3 'Plus Jakarta Sans',sans-serif;margin:0 0 8px}.game-card p{color:#a0a0b2;font-size:14px;line-height:1.6;margin:0}.game-foot{display:grid;gap:20px}.count{background:#272736;padding:15px 18px;border-radius:16px;display:grid;gap:4px}.count strong{font:800 32px/1.1 'Plus Jakarta Sans',sans-serif;color:#c8ff4d}.count span,.count-unavailable{font-size:12px;color:#a0a0b2}.primary,.secondary{display:inline-flex;justify-content:center;align-items:center;min-height:48px;padding:11px 22px}.primary:hover{background:#d9ff84}.secondary{background:#272736;border-color:#3b3b48;color:#f5f3ee}.upcoming{grid-column:span 2;border-style:dashed;background:#191920}.upcoming .secondary{align-self:flex-start;margin-top:auto}.match-banner{margin-top:34px;background:#1e1e29;border:1px solid #2e2e3e;border-radius:24px;padding:24px;display:flex;align-items:center;gap:18px}.banner-icon{width:50px;height:50px;flex:none;border-radius:50%;background:#332d4c;color:#c7bfff;display:grid;place-items:center}.banner-icon svg{width:25px}.match-banner div:nth-child(2){flex:1}.match-banner h2{font:700 18px 'Plus Jakarta Sans',sans-serif;margin:0 0 5px}.match-banner p{margin:0;color:#a0a0b2;font-size:14px}.state{padding:34px;background:#1e1e29;border-radius:20px;color:#a0a0b2;grid-column:1/-1}@media(max-width:950px){.game-grid{grid-template-columns:repeat(2,minmax(0,1fr))}}@media(max-width:640px){.picker-inner{width:min(100% - 32px,1216px)}.game-grid{grid-template-columns:1fr;gap:14px}.upcoming{grid-column:auto}.game-card{padding:21px}.intro p{font-size:15px}.match-banner{flex-wrap:wrap}.match-banner .primary{width:100%}}@media(prefers-reduced-motion:reduce){.game-card{transition:none}}
</style>