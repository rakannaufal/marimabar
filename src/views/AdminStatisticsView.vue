<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import AdminShell from '../components/AdminShell.vue'
import { useSessionStore } from '../stores/session'
import { requireBackend, supabase } from '../lib/supabase'

type Game = { id:string; name:string; slug:string; active:boolean }
type Report = { id:string; status:string; category:string; created_at:string }
const session=useSessionStore(), games=ref<Game[]>([]),reports=ref<Report[]>([]),loading=ref(false),error=ref('')
const pending=computed(()=>reports.value.filter(r=>r.status==='new'||r.status==='open'||r.status==='reviewing').length)
const reportLimited=computed(()=>reports.value.length===100)
async function load(){if(!supabase||!session.user||!session.admin)return;loading.value=true;error.value='';try{
  const [g,r]=await Promise.all([requireBackend().from('games').select('id,name,slug,active').order('name'),requireBackend().from('reports').select('id,status,category,created_at').order('created_at',{ascending:false}).limit(100)])
  if(g.error)throw g.error;if(r.error)throw r.error
  games.value=(g.data||[]) as Game[];reports.value=(r.data||[]) as Report[]
}catch{error.value='Statistik tidak dapat dimuat. Periksa izin admin dan koneksi.'}finally{loading.value=false}}
onMounted(load)
</script>
<template>
  <AdminShell title="Dashboard Statistik & Analitik" subtitle="Ringkasan katalog dan laporan yang tersedia dari backend. Tidak ada estimasi pertumbuhan atau aktivitas tanpa data terverifikasi.">
    <template #actions><button type="button" class="button" :disabled="loading" @click="load">Muat ulang</button></template>
    <p v-if="error" role="alert" class="error">{{ error }}</p><p v-if="loading" role="status">Memuat statistik…</p>
    <template v-if="!loading&&!error">
      <section class="metrics" aria-label="Ringkasan statistik">
        <article class="metric"><strong>{{ games.length }}</strong><span>Game terdaftar di katalog</span></article>
        <article class="metric"><strong>{{ games.filter(g=>g.active).length }}</strong><span>Game aktif</span></article>
        <article class="metric"><strong>{{ reportLimited?'100+':reports.length }}</strong><span>Laporan terlihat{{ reportLimited?' (minimal)':'' }}</span></article>
        <article class="metric"><strong>{{ pending }}</strong><span>Laporan perlu ditangani{{ reportLimited?' dalam 100 terbaru':'' }}</span></article>
      </section>
      <div class="columns">
        <section class="panel"><h2>Pertumbuhan User</h2><p>Grafik per waktu: <strong>Tidak tersedia</strong>. Backend belum menyediakan riwayat registrasi admin; tidak ada deret waktu sintetis.</p><h2>Request Mabar per Game</h2><p>Grafik permintaan: <strong>Tidak tersedia</strong>. Admin belum memiliki akses agregasi undangan per game.</p></section>
        <section class="panel"><h2>Status laporan{{ reportLimited?' (100 terbaru)':'' }}</h2><div v-if="reports.length" class="bars"><div v-for="status in ['new','open','reviewing','resolved','dismissed']" :key="status" class="bar"><span>{{ status }}</span><strong>{{ reports.filter(r=>r.status===status).length }}</strong></div></div><p v-else>Belum ada laporan yang dapat dilihat.</p></section>
      </div>
      <section class="panel"><h2>Game dalam katalog</h2><div v-if="games.length" class="table-wrap"><table><thead><tr><th>Nama Game</th><th>Slug</th><th>Status</th><th>Jumlah profil</th><th>Request bulan ini</th></tr></thead><tbody><tr v-for="game in games" :key="game.id"><td><strong>{{ game.name }}</strong></td><td>{{ game.slug }}</td><td>{{ game.active?'Aktif':'Nonaktif' }}</td><td>Tidak tersedia</td><td>Tidak tersedia</td></tr></tbody></table></div><p v-else>Belum ada game dalam katalog.</p></section>
    </template>
  </AdminShell>
</template>
<style scoped>
.metrics{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:14px}.metric,.panel{background:#1e1e29;border:1px solid #3e3e4d;border-radius:20px;padding:22px}.metric{display:flex;flex-direction:column;gap:12px}.metric strong{color:#c8ff4d;font:800 34px 'Plus Jakarta Sans',sans-serif}.metric span{color:#c6c5d0;font-size:13px}.columns{display:grid;grid-template-columns:1fr 1fr;gap:16px}.panel{margin-top:18px}.panel h2{font:750 19px 'Plus Jakarta Sans',sans-serif;margin:0 0 18px}.panel h2:not(:first-child){margin-top:26px}.panel p{color:#bdbdc9;line-height:1.6}.bars{display:grid;gap:8px}.bar{display:flex;justify-content:space-between;padding:9px 12px;border-radius:10px;background:#292935;text-transform:capitalize}.bar strong{color:#c8ff4d}.table-wrap{overflow-x:auto}table{width:100%;border-collapse:collapse;text-align:left;min-width:650px}th,td{padding:15px 10px;border-bottom:1px solid #3e3e4d}th{color:#bdbdc9;font-size:12px}td{font-size:14px}.button{background:#c8ff4d;color:#14141c;border:0;border-radius:100px;font-weight:750;padding:11px 19px;cursor:pointer}.button:disabled{opacity:.5}.error{color:#ffb4ab}:focus-visible{outline:3px solid #8b7cff;outline-offset:2px}@media(max-width:900px){.metrics{grid-template-columns:repeat(2,minmax(0,1fr))}.columns{grid-template-columns:1fr}}@media(max-width:540px){.metrics{grid-template-columns:1fr}}
</style>
