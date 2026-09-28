<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { listFriendRequests, friendRequestPlayers, respondFriend, removeFriend } from '../lib/api'
import type { FriendRequest, FriendRequestPlayer } from '../lib/models'
import { useSessionStore } from '../stores/session'

const session = useSessionStore()
const requests = ref<FriendRequest[]>([]), players = ref<FriendRequestPlayer[]>([])
const loading = ref(true), busy = ref(''), error = ref(''), notice = ref('')
const incoming = computed(() => requests.value.filter(item => item.status === 'pending' && item.recipient_id === session.user?.id))
const sent = computed(() => requests.value.filter(item => item.status === 'pending' && item.requester_id === session.user?.id))
const friends = computed(() => requests.value.filter(item => item.status === 'accepted'))
function other(item: FriendRequest) { return item.requester_id === session.user?.id ? item.recipient_id : item.requester_id }
function player(item: FriendRequest) { return players.value.find(candidate => candidate.user_id === other(item)) }
function friendName(item: FriendRequest) { return player(item)?.display_name || `Pemain ${other(item).slice(0, 8)}` }
function friendInitials(item: FriendRequest) { return friendName(item).trim().slice(0, 2).toUpperCase() }
async function load() {
  loading.value = true; error.value = ''
  try { [requests.value, players.value] = await Promise.all([listFriendRequests(), friendRequestPlayers()]) }
  catch { error.value = 'Daftar teman belum bisa dimuat. Coba lagi.' }
  finally { loading.value = false }
}
async function act(item: FriendRequest, action: 'accept'|'reject'|'remove') {
  if (busy.value) return
  if (action === 'remove' && !window.confirm('Hapus teman? Kontak tidak lagi bisa dilihat oleh kalian berdua.')) return
  busy.value = item.id; error.value = ''; notice.value = ''
  try {
    if (action === 'remove') await removeFriend(other(item))
    else await respondFriend(item.id, action === 'accept')
    await load()
    notice.value = action === 'accept' ? 'Pertemanan diterima. Kontak kini dapat dilihat.' : action === 'reject' ? 'Permintaan ditolak.' : 'Pertemanan dihapus.'
  } catch { error.value = 'Tindakan belum berhasil. Coba lagi.' }
  finally { busy.value = '' }
}
onMounted(load)
</script>
<template>
  <main class="friends page-shell">
    <nav class="breadcrumb"><RouterLink to="/beranda">Beranda</RouterLink><span>/</span><strong>Teman</strong></nav>
    <h1>Teman</h1><p class="muted">Hanya teman yang disetujui dapat melihat nama dalam game, ID game, dan Discord melalui profil game publik.</p>
    <button type="button" class="secondary" :disabled="loading" @click="load">Muat ulang</button>
    <p v-if="loading" role="status">Memuat pertemanan…</p>
    <p v-if="error" role="alert" class="error">{{ error }}</p><p v-if="notice" role="status">{{ notice }}</p>
    <template v-if="!loading">
      <section><h2>Permintaan masuk ({{ incoming.length }})</h2><p v-if="!incoming.length" class="muted">Belum ada permintaan.</p><article v-for="item in incoming" :key="item.id" class="row"><RouterLink v-if="player(item)?.game_profile_id" class="profile-link" :to="`/profil/${player(item)?.game_profile_id}`" :aria-label="`Lihat profil ${player(item)?.display_name}`">{{ player(item)?.display_name }}</RouterLink><span v-else>{{ player(item)?.display_name || `Pemain ${item.requester_id.slice(0, 8)}` }}</span><div><button type="button" :disabled="!!busy" @click="act(item, 'accept')">Terima teman</button><button type="button" class="secondary" :disabled="!!busy" @click="act(item, 'reject')">Tolak</button></div></article></section>
      <section><h2>Menunggu persetujuan ({{ sent.length }})</h2><p v-if="!sent.length" class="muted">Tidak ada permintaan terkirim.</p><article v-for="item in sent" :key="item.id" class="row"><span>Permintaan kepada <RouterLink v-if="player(item)?.game_profile_id" class="profile-link" :to="`/profil/${player(item)?.game_profile_id}`" :aria-label="`Lihat profil ${player(item)?.display_name}`">{{ player(item)?.display_name }}</RouterLink><span v-else>{{ player(item)?.display_name || `pemain ${item.recipient_id.slice(0, 8)}` }}</span> sedang menunggu.</span></article></section>
      <section class="friends-section"><div class="section-header"><div><span class="section-eyebrow">Daftar teman</span><h2>Berteman <span>{{ friends.length }}</span></h2></div><p>Kontak privat hanya tersedia untuk pertemanan aktif.</p></div><div v-if="!friends.length" class="empty-friends"><strong>Belum ada teman</strong><p>Temukan pemain yang cocok untuk mulai mabar bersama.</p><RouterLink class="find-friends" to="/pilih-game">Cari teman mabar</RouterLink></div><div v-else class="friend-list"><article v-for="item in friends" :key="item.id" class="friend-card"><div class="friend-card__identity"><span class="friend-avatar" aria-hidden="true">{{ friendInitials(item) }}</span><div><RouterLink class="profile-link" :to="`/teman/${other(item)}`" :aria-label="`Lihat profil teman ${friendName(item)}`">{{ friendName(item) }}</RouterLink><span class="friend-status"><i></i> Berteman</span><small>Kontak privat tersedia</small></div></div><div class="friend-card__actions"><RouterLink class="view-profile" :to="`/teman/${other(item)}`">Lihat profil</RouterLink><button type="button" class="remove-friend" :disabled="!!busy" @click="act(item, 'remove')">Hapus teman</button></div></article></div></section>
    </template>
  </main>
</template>
<style scoped>
.friends{max-width:980px;padding-bottom:80px;color:#f5f3ee}.friends h1{font-size:2rem}.friends section{margin:28px 0;padding:24px;background:#1e1e29;border:1px solid #393944;border-radius:18px}.friends section h2{font-size:1.15rem;margin:0 0 16px}.row{display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:14px;border-top:1px solid #393944;padding:14px 0}.row div{display:flex;gap:8px}.profile-link{color:#f5f3ee;font-weight:750;text-decoration:none;text-underline-offset:4px}.profile-link:hover,.profile-link:focus-visible{color:#c8ff4d;text-decoration:underline}.friends button{border:1px solid #c8ff4d;border-radius:99px;background:#c8ff4d;color:#14141c;padding:9px 16px;font-weight:700;cursor:pointer}.friends button.secondary{background:transparent;color:#f5f3ee;border-color:#666575}.friends button:disabled{opacity:.5}.muted{color:#b8b6c2}.error{color:#ff9d97}
.friends section.friends-section{padding:0;overflow:hidden}.section-header{display:flex;justify-content:space-between;align-items:end;gap:20px;padding:24px;border-bottom:1px solid #393944}.section-header h2{display:flex;align-items:center;gap:9px;margin:4px 0 0}.section-header h2 span{display:inline-grid;place-items:center;min-width:26px;height:26px;padding:0 8px;border:1px solid #474655;border-radius:8px;color:#b8b6c2;font:700 .75rem 'Inter',sans-serif}.section-header p{max-width:360px;color:#9694a5;font-size:.82rem;line-height:1.5;margin:0;text-align:right}.section-eyebrow{color:#aaa8b8;font-size:.68rem;font-weight:800;letter-spacing:.1em;text-transform:uppercase}.friend-list{display:grid;gap:12px;padding:16px}.friend-card{display:flex;align-items:center;justify-content:space-between;gap:18px;padding:17px 18px;border:1px solid #3d3d4b;border-radius:15px;background:#242430}.friend-card__identity{display:flex;align-items:center;gap:14px;min-width:0}.friend-card__identity>div{display:grid;grid-template-columns:auto auto;align-items:center;gap:5px 10px;min-width:0}.friend-card__identity small{grid-column:1/-1;color:#9694a5;font-size:.78rem}.friend-avatar{width:50px;height:50px;flex:none;display:grid;place-items:center;border:2px solid #8b7cff;border-radius:50%;background:#302b43;color:#f5f3ee;font-weight:800}.friend-status{display:inline-flex;align-items:center;gap:5px;color:#4ade80;font-size:.72rem;font-weight:700}.friend-status i{width:6px;height:6px;border-radius:50%;background:currentColor}.friend-card__actions{display:flex;align-items:center;gap:8px;flex:none}.view-profile,.find-friends{display:inline-flex;align-items:center;justify-content:center;min-height:38px;padding:8px 14px;border-radius:10px;background:#c8ff4d;color:#14141c;font-size:.8rem;font-weight:800}.friends button.remove-friend{min-height:38px;padding:8px 14px;border-radius:10px;border-color:#555463;background:transparent;color:#d1cfda;font-size:.8rem}.empty-friends{padding:28px 24px}.empty-friends strong{font-size:1rem}.empty-friends p{color:#b8b6c2;font-size:.88rem;margin:6px 0 16px}@media(max-width:680px){.section-header,.friend-card{align-items:flex-start;flex-direction:column}.section-header p{text-align:left}.friend-card__actions{width:100%}.view-profile,.friends button.remove-friend{flex:1}.friend-card__identity>div{grid-template-columns:1fr}.friend-status,.friend-card__identity small{grid-column:1}}
</style>
