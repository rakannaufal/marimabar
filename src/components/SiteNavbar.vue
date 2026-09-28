<script setup lang="ts">
import { computed, nextTick, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useSessionStore } from '../stores/session'

const props = defineProps<{ dashboard?: boolean; adminArea?: boolean; mobileOpen: boolean }>()
const emit = defineEmits<{ 'update:mobileOpen': [value: boolean] }>()
const session = useSessionStore()
const router = useRouter()
const route = useRoute()
const profileDropdownOpen = ref(false)
const dropdownStyle = ref<Record<string, string>>({})
const displayName = computed(() => String(session.user?.user_metadata?.display_name || session.user?.email?.split('@')[0] || 'Pemain'))
const initials = computed(() => displayName.value.slice(0, 1).toUpperCase())

watch(() => route.fullPath, () => { profileDropdownOpen.value = false })
watch(profileDropdownOpen, async (open) => {
  if (!open) return
  await nextTick()
  const trigger = document.querySelector('.profile-dropdown__trigger') as HTMLElement | null
  if (!trigger) return
  const rect = trigger.getBoundingClientRect()
  dropdownStyle.value = {
    position: 'fixed',
    top: `${rect.bottom + 8}px`,
    right: `${window.innerWidth - rect.right}px`,
  }
})

async function logout() {
  try { await session.signOut(); profileDropdownOpen.value = false; emit('update:mobileOpen', false); await router.push('/') }
  catch (error) { alert(error instanceof Error ? error.message : 'Gagal keluar') }
}
</script>

<template>
  <header v-if="dashboard" class="site-header site-header--dashboard">
    <div class="header-inner">
      <button class="menu-toggle" type="button" :aria-expanded="mobileOpen" aria-controls="dashboard-navigation" :aria-label="mobileOpen ? 'Tutup menu' : 'Buka menu'" @click="emit('update:mobileOpen', !mobileOpen)"><span></span><span></span><span></span></button>
      <div class="dashboard-header__title"><span>Marimabar</span><strong>{{ adminArea ? 'Admin Panel' : 'Beranda' }}</strong></div>
      <div class="dashboard-header__actions"><RouterLink to="/pilih-game" class="dashboard-header__search">Cari teman mabar</RouterLink><RouterLink class="app-avatar app-avatar--small" to="/profil-saya" aria-label="Profil saya">{{ initials }}</RouterLink></div>
    </div>
  </header>
  <header v-else class="site-header site-header--public"><div class="header-inner container">
    <RouterLink class="brand" to="/"><span>Marimabar</span></RouterLink>
    <nav class="nav-links" aria-label="Navigasi utama"><RouterLink to="/">Beranda</RouterLink><RouterLink to="/pilih-game">Cari Teman</RouterLink><RouterLink to="/tentang">Tentang</RouterLink></nav>
    <div class="header-actions"><template v-if="session.user"><div class="profile-dropdown" @click.stop><button class="profile-dropdown__trigger" type="button" :aria-expanded="profileDropdownOpen" aria-haspopup="true" @click="profileDropdownOpen = !profileDropdownOpen"><span class="app-avatar app-avatar--small" aria-hidden="true">{{ initials }}</span><span class="profile-dropdown__name">{{ displayName }}</span><svg class="profile-dropdown__chevron" :class="{ 'profile-dropdown__chevron--open': profileDropdownOpen }" width="12" height="12" viewBox="0 0 12 12" aria-hidden="true"><path d="M3 4.5 6 7.5 9 4.5" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg></button><Teleport to="body"><div v-if="profileDropdownOpen" class="profile-dropdown__backdrop" @click="profileDropdownOpen = false"></div><div v-if="profileDropdownOpen" class="profile-dropdown__menu" role="menu" :style="dropdownStyle"><RouterLink to="/profil-saya" role="menuitem" class="profile-dropdown__item" @click="profileDropdownOpen = false">Profil saya</RouterLink><div class="profile-dropdown__divider"></div><button type="button" role="menuitem" class="profile-dropdown__item profile-dropdown__item--danger" @click="logout">Keluar</button></div></Teleport></div></template><template v-else><RouterLink class="button button--outline small" to="/login">Masuk</RouterLink><RouterLink class="button button--primary small" to="/register">Daftar</RouterLink></template></div>
    <button class="menu-toggle" type="button" :aria-expanded="mobileOpen" aria-controls="public-navigation" :aria-label="mobileOpen ? 'Tutup menu' : 'Buka menu'" @click="emit('update:mobileOpen', !mobileOpen)"><span></span><span></span><span></span></button>
  </div><nav v-if="mobileOpen" id="public-navigation" class="mobile-navigation" aria-label="Navigasi seluler"><RouterLink to="/">Beranda</RouterLink><RouterLink to="/pilih-game">Cari Teman</RouterLink><RouterLink to="/tentang">Tentang</RouterLink><template v-if="session.user"><RouterLink to="/beranda">Dashboard</RouterLink><RouterLink to="/profil-saya">Profil saya</RouterLink><button type="button" class="mobile-navigation__logout" @click="logout">Keluar</button></template><template v-else><RouterLink to="/login">Masuk</RouterLink><RouterLink to="/register">Daftar</RouterLink></template></nav></header>
</template>
