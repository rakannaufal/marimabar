<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import SiteNavbar from './components/SiteNavbar.vue'
import SiteFooter from './components/SiteFooter.vue'
import { configured } from './lib/supabase'
import { useSessionStore } from './stores/session'

const session = useSessionStore()
const router = useRouter()
const route = useRoute()
const mobileOpen = ref(false)

// Dashboard layout: all authenticated workspace routes
const dashboardPaths = ['/beranda', '/profil-saya', '/teman', '/pesan', '/admin']
const dashboard = computed(() => dashboardPaths.some(p => route.path === p || route.path.startsWith(p + '/')))
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
              <RouterLink to="/teman">Teman</RouterLink>
              <RouterLink to="/pesan">Pesan</RouterLink>
              <RouterLink to="/profil-saya">Profil saya</RouterLink>
              <RouterLink v-if="session.admin" to="/admin/statistik">Admin Panel</RouterLink>
            </nav>
          </div>
          <button class="app-sidebar__logout" type="button" @click="logout">Keluar</button>
        </aside>
        <button v-if="mobileOpen" class="sidebar-scrim" type="button" aria-label="Tutup navigasi" @click="mobileOpen = false"></button>
        <div class="dashboard-layout__content">
          <SiteNavbar dashboard :admin-area="adminArea" v-model:mobile-open="mobileOpen" />
          <RouterView />
        </div>
      </div>
    </template>
    <template v-else>
      <SiteNavbar v-model:mobile-open="mobileOpen" />
      <RouterView />
      <SiteFooter />
    </template>
  </div>
</template>
