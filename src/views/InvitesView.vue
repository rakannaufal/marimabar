<script setup lang="ts">
import { RouterLink } from 'vue-router'
</script>

<template>
  <main class="page-shell">
    <nav class="breadcrumb"><RouterLink to="/beranda">Beranda</RouterLink><span>/</span><strong>Teman</strong></nav>
    <section class="state-card" role="status">
      <h1>Halaman dialihkan</h1>
      <p>Fitur ajakan mabar telah disatukan ke dalam pertemanan. Kelola semua koneksi pemain di menu Teman.</p>
      <RouterLink class="button button--primary" to="/teman">Buka Halaman Teman</RouterLink>
    </section>
  </main>
</template>

<style scoped>
.state-card{background:#1e1e29;border:1px solid #393944;border-radius:18px;padding:32px;margin-top:20px}
.state-card h1{font-size:1.6rem;margin-bottom:8px}
.state-card p{color:#b8b6c2;margin-bottom:20px}
</style>
