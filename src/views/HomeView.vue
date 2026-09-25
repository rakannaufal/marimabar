<script setup lang="ts">
import { onMounted, onServerPrefetch, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { listGames } from '../lib/api'
import { configured } from '../lib/supabase'
import type { Game } from '../lib/models'

const games = ref<Game[]>([])
const loading = ref(true)
const error = ref('')
const gameDescriptions: Record<string, { genre: string; description: string; icon: string }> = {
  mlbb: { genre: 'RANKED 5V5 MOBA', description: 'Temukan rekan satu tim untuk push rank atau main santai.', icon: '♜' },
  valorant: { genre: 'TACTICAL FPS', description: 'Cari rekan untuk koordinasi dan main bareng.', icon: '⌖' },
  'pubg-mobile': { genre: 'BATTLE ROYALE', description: 'Bentuk squad untuk turun bersama.', icon: '✦' },
  'free-fire': { genre: 'SURVIVAL CLASH', description: 'Cari teman untuk main squad.', icon: '♨' },
}
async function loadGames() {
  if (!configured) { loading.value = false; return }
  loading.value = true
  error.value = ''
  try { games.value = await listGames() }
  catch { error.value = 'Daftar game belum bisa dimuat. Coba lagi, ya.' }
  finally { loading.value = false }
}
onMounted(loadGames)
onServerPrefetch(loadGames)
</script>

<template>
  <main class="site-main landing-page">
    <section class="home-hero page-shell">
      <div class="home-hero__copy">
        <h1>Temukan rekan satu tim, <em>bukan cuma satu server.</em></h1>
        <p>Cari teman mabar sesuai game, rank, role, dan region. Kenalan dulu lewat profil, lalu kirim ajakan kalau sudah cocok.</p>
        <div class="hero-actions"><a class="button button--primary" href="#pilih-game">Mulai Cari Teman Mabar <span aria-hidden="true">↗</span></a><a class="button button--outline" href="#cara-kerja">Lihat Cara Kerja</a></div>
        <div class="hero-benefits"><span>✓ Pilih game favorit</span><span>♧ Filter preferensi</span><span>⚡ Kenalan lewat profil</span></div>
      </div>
      <div class="home-hero__visual" aria-label="Ilustrasi game dan contoh tampilan profil">
        <div class="hero-image"><img src="/design-assets/hero-game.jpg" alt="Ilustrasi suasana game" /></div>
        <div class="hero-preview"><img src="/design-assets/hero-avatar.jpg" alt="Ilustrasi avatar pemain" /><div><strong>Teman mabar berikutnya?</strong><span>Pilih game dan jelajahi profil pemain</span><a href="#pilih-game">Mulai cari teman ↗</a></div></div>
      </div>
    </section>

    <section id="pilih-game" class="page-shell home-section" aria-labelledby="games-title">
      <div class="section-heading"><div><span class="section-kicker">✦ PILIHAN KOMUNITAS</span><h2 id="games-title">Game Populer di Mabar Finder</h2><p>Pilih arena favoritmu dan temukan profil pemain yang bisa kamu ajak mabar.</p></div></div>
      <p v-if="!configured" class="state-card" role="alert">Layanan belum dikonfigurasi.</p>
      <p v-else-if="loading" class="state-card" role="status">Memuat pilihan game…</p>
      <div v-else-if="error" class="state-card" role="alert"><h3>Game belum tampil</h3><p>{{ error }}</p><button class="button button--outline" type="button" @click="loadGames">Coba lagi</button></div>
      <div v-else-if="!games.length" class="state-card"><h3>Belum ada game tersedia</h3><p>Coba kembali nanti untuk melihat pilihan game.</p></div>
      <div v-else class="game-grid">
        <RouterLink v-for="game in games" :key="game.id" class="game-tile" :to="`/cari/${encodeURIComponent(game.slug)}`">
          <span class="game-tile__icon" aria-hidden="true">{{ gameDescriptions[game.slug]?.icon || '✦' }}</span>
          <span class="game-tile__genre">{{ gameDescriptions[game.slug]?.genre || 'GAME KOMUNITAS' }}</span>
          <span class="game-tile__name">{{ game.name }}</span>
          <span class="game-tile__description">{{ gameDescriptions[game.slug]?.description || 'Temukan pemain untuk main bersama.' }}</span>
          <span class="game-tile__foot">Cari teman mabar <span aria-hidden="true">↗</span></span>
        </RouterLink>
      </div>
    </section>

    <section id="cara-kerja" class="page-shell home-section steps" aria-labelledby="steps-title">
      <div class="section-heading section-heading--center"><span class="section-kicker">✦ PROSES ANTI RIBET</span><h2 id="steps-title">Cara Mulai Mabar Asik</h2><p>Tiga langkah untuk kenalan dengan rekan main yang cocok.</p></div>
      <ol class="steps-list"><li><span>01</span><div><h3>Buat Profil Game</h3><p>Isi nama dalam game, rank, role, dan preferensi bermainmu.</p></div><span class="step-label">Profilmu</span></li><li><span>02</span><div><h3>Pilih Game &amp; Pasang Filter</h3><p>Cari berdasarkan rank, role, mode, atau region yang kamu inginkan.</p></div><span class="step-label">Pencarian</span></li><li><span>03</span><div><h3>Kirim Request Mabar</h3><p>Lihat info publik pemain, lalu kirim ajakan setelah masuk akun.</p></div><span class="step-label">Kenalan</span></li></ol>
    </section>
    <section class="page-shell home-bottom"><h2>Siap cari teman mabar?</h2><p>Jelajahi game dan temukan pemain dengan preferensi main yang cocok.</p><a class="button button--primary" href="#pilih-game">Pilih Game <span aria-hidden="true">↗</span></a></section>
  </main>
</template>
