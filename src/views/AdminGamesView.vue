<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import AdminShell from '../components/AdminShell.vue'
import { useSessionStore } from '../stores/session'
import { requireBackend, supabase } from '../lib/supabase'

type Game={id:string;slug:string;name:string;active:boolean}
const session=useSessionStore(),games=ref<Game[]>([]),filter=ref('all'),search=ref(''),loading=ref(false),error=ref('')
const visible=computed(()=>games.value.filter(g=>(filter.value==='all'||g.active===(filter.value==='active'))&&`${g.name} ${g.slug}`.toLocaleLowerCase().includes(search.value.toLocaleLowerCase())))
async function load(){if(!supabase||!session.user||!session.admin)return;loading.value=true;error.value='';try{const {data,error:failure}=await requireBackend().from('games').select('id,slug,name,active').order('name');if(failure)throw failure;games.value=(data||[]) as Game[]}catch{error.value='Katalog game tidak dapat dimuat. Periksa izin admin dan koneksi.'}finally{loading.value=false}}
onMounted(load)
</script>
<template>
  <AdminShell title="Kelola Katalog Game" subtitle="Pantau daftar game resmi untuk profil pemain dan pencarian teman mabar.">
    <template #actions><button type="button" disabled title="Backend belum mendukung penambahan game">Tambah Game</button></template>
    <section class="metrics" v-if="!loading&&!error"><div><strong>{{ games.length }}</strong><span>Total game katalog</span></div><div><strong>{{ games.filter(g=>g.active).length }}</strong><span>Game aktif</span></div><div><strong>Tidak tersedia</strong><span>Profil pemain terhubung</span></div><div><strong>Tidak tersedia</strong><span>Request hari ini</span></div></section>
    <section class="panel"><div class="toolbar"><div><h2>Daftar Game Mabar</h2><p>Penambahan, pengubahan dan penghapusan game belum didukung oleh backend. Katalog hanya untuk dilihat.</p></div><button type="button" class="secondary" :disabled="loading" @click="load">Muat ulang</button></div>
      <p v-if="error" role="alert" class="error">{{ error }}</p><p v-if="loading" role="status">Memuat katalog…</p>
      <template v-else-if="!error"><div class="filters"><label>Cari game <input v-model="search" type="search" placeholder="Nama atau slug"></label><label>Status <select v-model="filter"><option value="all">Semua status</option><option value="active">Aktif</option><option value="inactive">Nonaktif</option></select></label></div>
      <div class="table-wrap" v-if="visible.length"><table><thead><tr><th>Ikon</th><th>Nama Game</th><th>Slug</th><th>Jumlah profil aktif</th><th>Status lobi</th><th>Aksi</th></tr></thead><tbody><tr v-for="game in visible" :key="game.id"><td><span class="game-icon" aria-hidden="true">{{ game.name.slice(0,2).toUpperCase() }}</span></td><td><strong>{{ game.name }}</strong></td><td>{{ game.slug }}</td><td>Tidak tersedia</td><td><span class="status">{{ game.active?'Aktif':'Nonaktif' }}</span></td><td><button disabled title="Pengubahan game belum didukung">Edit</button> <button disabled title="Penghapusan game belum didukung">Hapus</button></td></tr></tbody></table></div><p v-else>{{ games.length?'Tidak ada game sesuai pencarian.':'Belum ada game dalam katalog.' }}</p><p class="footnote">{{ visible.length }} game ditampilkan dari {{ games.length }} game terdaftar.</p></template>
    </section>
  </AdminShell>
</template>
<style scoped>
.metrics{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:14px}.metrics>div,.panel{background:#1e1e29;border:1px solid #424250;border-radius:20px;padding:22px}.metrics>div{display:flex;flex-direction:column;gap:9px}.metrics strong{color:#c8ff4d;font:800 clamp(16px,2vw,30px) 'Plus Jakarta Sans',sans-serif}.metrics span{color:#b9b9c7;font-size:13px}.panel{margin-top:20px}.toolbar,.filters{display:flex;align-items:end;justify-content:space-between;gap:16px;flex-wrap:wrap}.toolbar h2{font:750 20px 'Plus Jakarta Sans',sans-serif;margin:0}.toolbar p,.footnote{color:#b9b9c7;font-size:13px;line-height:1.5}.filters{justify-content:flex-start;margin:18px 0}.filters label{display:grid;gap:7px;color:#d9d8e0;font-size:13px}.filters input,.filters select{background:#2b2b38;color:#f5f3ee;border:1px solid #555564;border-radius:12px;padding:10px 12px;min-width:170px;font:inherit}.table-wrap{overflow-x:auto}table{width:100%;min-width:720px;border-collapse:collapse;text-align:left}th,td{padding:15px 10px;border-bottom:1px solid #40404e;font-size:13px}th{color:#aaaaba}td strong{font-size:15px}.game-icon{background:#303e2b;color:#c8ff4d;border-radius:12px;width:42px;height:42px;display:grid;place-items:center;font-weight:800}.status{border:1px solid #6a6a75;border-radius:100px;padding:5px 10px}button{background:#c8ff4d;color:#14141c;border:0;border-radius:100px;padding:10px 16px;font-weight:750;cursor:pointer}button.secondary{background:#333340;color:#f5f3ee}button:disabled{cursor:not-allowed;opacity:.54}.error{color:#ffb4ab}:focus-visible{outline:3px solid #8b7cff;outline-offset:2px}@media(max-width:900px){.metrics{grid-template-columns:repeat(2,1fr)}}@media(max-width:500px){.metrics{grid-template-columns:1fr}}
</style>
