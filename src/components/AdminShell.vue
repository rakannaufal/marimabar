<script setup lang="ts">
import { computed } from 'vue'
import { RouterLink } from 'vue-router'
import { useSessionStore } from '../stores/session'
import { supabase } from '../lib/supabase'

defineProps<{ title: string; subtitle: string }>()
const session = useSessionStore()
const allowed = computed(() => Boolean(supabase && session.user && session.admin))
const sections = [
  { to: '/admin/statistik', text: 'Statistik' },
  { to: '/admin/game', text: 'Kelola Game' },
  { to: '/admin/atribut-game', text: 'Atribut Game' },
  { to: '/admin/user', text: 'Kelola User' },
  { to: '/admin/laporan', text: 'Laporan' },
]
</script>
<template>
  <main class="admin-workspace">
    <p v-if="session.loading" role="status">Memeriksa akses admin…</p>
    <p v-else-if="!allowed" role="alert" class="guard">Akses ditolak. Masuk sebagai admin pada backend produksi untuk membuka halaman ini.</p>
    <template v-else>
      <div class="crumb"><RouterLink to="/">Mabar Finder</RouterLink><span>/</span> Admin Panel</div>
      <nav class="section-nav" aria-label="Bagian admin"><RouterLink v-for="section in sections" :key="section.to" :to="section.to">{{ section.text }}</RouterLink></nav>
      <header class="page-head"><div><h1>{{ title }}</h1><p>{{ subtitle }}</p></div><slot name="actions" /></header>
      <slot />
    </template>
  </main>
</template>
<style scoped>
.admin-workspace{width:100%;min-width:0;max-width:1400px;margin:0 auto;padding:28px 32px 104px;color:#f5f3ee;box-sizing:border-box}
.crumb{display:flex;gap:10px;color:#a9a9b8;font-size:13px;margin-bottom:20px}.crumb a{color:#c8ff4d;text-decoration:none}
.section-nav{display:flex;flex-wrap:wrap;gap:8px;margin-bottom:22px}.section-nav a{padding:10px 16px;border:1px solid #444451;border-radius:100px;color:#dbdae1;text-decoration:none;font-weight:650;font-size:13px}.section-nav a.router-link-exact-active{color:#14141c;background:#c8ff4d;border-color:#c8ff4d}
.page-head{background:#1e1e29;border:1px solid #3a3a47;border-radius:22px;padding:28px 30px;display:flex;align-items:center;gap:18px;margin-bottom:24px;flex-wrap:wrap}.page-head>div:first-child{flex:1;min-width:200px}.page-head h1{font:800 clamp(24px,3vw,34px) 'Plus Jakarta Sans',sans-serif;margin:0 0 8px}.page-head p{color:#b9b9c7;font-size:14px;margin:0;line-height:1.6}.demo-tag{border:1px solid #555560;border-radius:100px;padding:7px 12px;color:#d9d6e0;font-size:12px}.guard{padding:24px;background:#1e1e29;border-radius:18px;color:#ffb4ab}:focus-visible{outline:3px solid #8b7cff;outline-offset:2px}
@media(max-width:640px){.admin-workspace{padding:22px 16px 96px}.page-head{padding:22px}.section-nav{flex-wrap:nowrap;overflow-x:auto;padding-bottom:6px}.section-nav a{white-space:nowrap}}
</style>
