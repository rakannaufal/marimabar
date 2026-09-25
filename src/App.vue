<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { configured } from './lib/supabase'
import { useSessionStore } from './stores/session'

const session = useSessionStore()
const router = useRouter()
const route = useRoute()
const mobileOpen = ref(false)
const dashboard = computed(() => route.path === '/beranda' || route.path === '/admin' || route.path.startsWith('/admin/'))
const adminArea = computed(() => route.path === '/admin' || route.path.startsWith('/admin/'))
const displayName = computed(() => String(session.user?.user_metadata?.display_name || session.user?.email?.split('@')[0] || 'Pemain'))
const initials = computed(() => displayName.value.slice(0, 1).toUpperCase())
watch(() => route.fullPath, () => { mobileOpen.value = false })
onMounted(() => { void session.initialize() })

async function logout() {
  try { await session.signOut(); mobileOpen.value = false; await router.push('/') }
  catch (error) { alert(error instanceof Error ? error.message : 'Gagal keluar') }
}
</script>

<template>
  <div class="app-shell" :class="{ 'app-shell--dashboard': dashboard, 'app-shell--admin': adminArea }">
    <div v-if="!configured" role="alert" class="config-banner"><div class="config-banner__inner container">Layanan belum dikonfigurasi. Hubungkan Supabase untuk masuk dan memuat data.</div></div>

    <template v-if="dashboard">
      <div class="dashboard-layout">
        <aside id="dashboard-navigation" class="app-sidebar" :class="{ 'app-sidebar--open': mobileOpen }" aria-label="Navigasi dashboard">
          <div class="app-sidebar__top">
            <RouterLink class="brand" to="/"><span>Marimabar</span></RouterLink>
            <span v-if="adminArea" class="app-sidebar__badge">Admin Panel</span>
            <div class="app-sidebar__identity"><span class="app-avatar" aria-hidden="true">{{ initials }}</span><span class="app-sidebar__person"><strong>{{ displayName }}</strong><small>{{ adminArea ? 'Admin' : 'Siap mabar' }}</small></span></div>
            <nav v-if="adminArea" class="app-sidebar__nav" aria-label="Navigasi admin">
              <RouterLink to="/admin/statistik">Dashboard Overview</RouterLink>
              <RouterLink to="/admin/game">Kelola Game</RouterLink>
              <RouterLink to="/admin/atribut-game">Atribut Game</RouterLink>
              <RouterLink to="/admin/user">Kelola Pengguna</RouterLink>
              <RouterLink to="/admin/laporan">Laporan &amp; Moderasi</RouterLink>
              <RouterLink to="/beranda">Kembali ke Beranda</RouterLink>
            </nav>
            <nav v-else class="app-sidebar__nav" aria-label="Navigasi pemain">
              <RouterLink to="/beranda">Beranda</RouterLink>
              <RouterLink to="/pilih-game">Cari teman mabar</RouterLink>
              <RouterLink to="/request-mabar">Ajakan mabar</RouterLink>
              <RouterLink to="/pesan">Pesan</RouterLink>
              <RouterLink to="/profil-saya">Profil saya</RouterLink>
              <RouterLink v-if="session.admin" to="/admin/statistik">Admin Panel</RouterLink>
            </nav>
          </div>
          <button class="app-sidebar__logout" type="button" @click="logout">Keluar</button>
        </aside>
        <button v-if="mobileOpen" class="sidebar-scrim" type="button" aria-label="Tutup navigasi" @click="mobileOpen = false"></button>
        <div class="dashboard-layout__content">
          <header class="site-header site-header--dashboard">
            <div class="header-inner">
              <button class="menu-toggle" type="button" :aria-expanded="mobileOpen" aria-controls="dashboard-navigation" :aria-label="mobileOpen ? 'Tutup menu' : 'Buka menu'" @click="mobileOpen = !mobileOpen"><span></span><span></span><span></span></button>
              <div class="dashboard-header__title"><span>Marimabar</span><strong>{{ adminArea ? 'Admin Panel' : 'Beranda' }}</strong></div>
              <div class="dashboard-header__actions"><RouterLink to="/pilih-game" class="dashboard-header__search">Cari teman mabar</RouterLink><RouterLink class="app-avatar app-avatar--small" to="/profil-saya" aria-label="Profil saya">{{ initials }}</RouterLink></div>
            </div>
          </header>
          <RouterView />
        </div>
      </div>
    </template>
    <template v-else>
      <header class="site-header site-header--public"><div class="header-inner container">
        <RouterLink class="brand" to="/"><span>Marimabar</span></RouterLink>
        <nav class="nav-links" aria-label="Navigasi utama"><RouterLink to="/">Cari Teman</RouterLink><RouterLink to="/pilih-game">Game</RouterLink><RouterLink to="/tentang">Tentang</RouterLink></nav>
        <div class="header-actions"><template v-if="session.user"><RouterLink class="button button--outline small" to="/beranda">Beranda</RouterLink><button class="button button--primary small" @click="logout">Keluar</button></template><template v-else><RouterLink class="button button--primary small" to="/login">Masuk</RouterLink><RouterLink class="button button--primary small" to="/register">Daftar</RouterLink></template></div>
        <button class="menu-toggle" type="button" :aria-expanded="mobileOpen" aria-controls="public-navigation" :aria-label="mobileOpen ? 'Tutup menu' : 'Buka menu'" @click="mobileOpen = !mobileOpen"><span></span><span></span><span></span></button>
      </div><nav v-if="mobileOpen" id="public-navigation" class="mobile-navigation" aria-label="Navigasi seluler"><RouterLink to="/">Cari Teman</RouterLink><RouterLink to="/pilih-game">Game</RouterLink><RouterLink to="/tentang">Tentang</RouterLink><RouterLink v-if="session.user" to="/beranda">Beranda</RouterLink><template v-else><RouterLink to="/login">Masuk</RouterLink><RouterLink to="/register">Daftar</RouterLink></template></nav></header>
      <RouterView />
      <footer class="site-footer"><div class="container"><div class="footer-grid"><div class="footer-about"><RouterLink class="brand" to="/"><span class="brand-mark" aria-hidden="true">M</span><span>Marimabar</span></RouterLink><p>Temukan teman mabar yang sefrekuensi. Main bareng, tanpa drama solo queue.</p></div><div><h2>Produk</h2><RouterLink to="/beranda">Beranda</RouterLink><RouterLink to="/pilih-game">Pilih game</RouterLink></div><div><h2>Komunitas</h2><RouterLink to="/tentang">Tentang kami</RouterLink><RouterLink to="/request-mabar">Ajakan mabar</RouterLink></div><div><h2>Kebijakan</h2><RouterLink to="/syarat-ketentuan">Syarat &amp; ketentuan</RouterLink><RouterLink to="/kebijakan-privasi">Kebijakan privasi</RouterLink></div></div><div class="footer-bottom"><span>Marimabar</span><span>Data game diisi pengguna, belum terverifikasi.</span></div></div></footer>
    </template>
  </div>
</template>
