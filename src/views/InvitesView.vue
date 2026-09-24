<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { useSessionStore } from '../stores/session'
import { configured, demoMode } from '../lib/supabase'
import { listGames, listInvites, respondInvite, cancelInvite, blockUser, reportUser } from '../lib/api'
import type { Game, Invite } from '../lib/models'
const session = useSessionStore(), userId = computed(() => session.user?.id)
const invites = ref<Invite[]>([]), games = ref<Game[]>([]), tab = ref<'incoming'|'sent'>('incoming'), busy = ref(''), loading = ref(false), error = ref(''), notice = ref('')
const visible = computed(() => invites.value.filter(i => tab.value === 'incoming' ? i.recipient_id === userId.value : i.sender_id === userId.value))
function gameName(id: string) { return games.value.find(g => g.id === id)?.name || 'Game' }
function status(i: Invite) { return i.status === 'pending' && new Date(i.expires_at).getTime() < Date.now() ? 'Kedaluwarsa' : ({ pending:'Menunggu', accepted:'Diterima', rejected:'Ditolak', cancelled:'Dibatalkan', expired:'Kedaluwarsa' } as Record<string,string>)[i.status] || i.status }
function date(value: string) { const parsed = new Date(value); return Number.isNaN(parsed.getTime()) ? '' : new Intl.DateTimeFormat('id-ID', { dateStyle:'medium', timeStyle:'short' }).format(parsed) }
async function load() {
  if (!userId.value || (!configured && !demoMode)) return
  loading.value = true; error.value = ''
  try { [invites.value, games.value] = await Promise.all([listInvites(userId.value), listGames()]) }
  catch { error.value = 'Ajakan tidak dapat dimuat. Coba lagi.' }
  finally { loading.value = false }
}
onMounted(load)
async function act(i: Invite, action: 'accepted'|'rejected'|'cancel'|'block'|'report') {
  if (!userId.value || busy.value) return
  const other = i.sender_id === userId.value ? i.recipient_id : i.sender_id
  if (action === 'block' && !window.confirm('Blokir pengguna ini? Kalian tidak dapat saling mengirim ajakan atau pesan.')) return
  let description = ''
  if (action === 'report') {
    const entered = window.prompt('Jelaskan kejadian (minimal 10 karakter):')
    if (entered === null) return
    description = entered.trim()
    if (description.length < 10) { error.value = 'Deskripsi laporan minimal 10 karakter.'; return }
  }
  busy.value = i.id; error.value = ''; notice.value = ''
  try {
    if (action === 'cancel') await cancelInvite(i.id)
    else if (action === 'block') await blockUser(other)
    else if (action === 'report') await reportUser(other, 'harassment', description, i.id)
    else await respondInvite(i.id, action)
    await load()
    notice.value = action === 'report' ? 'Laporan terkirim.' : action === 'block' ? 'Pemain diblokir.' : 'Perubahan tersimpan.'
  } catch { error.value = 'Tindakan gagal. Periksa izin atau status ajakan, lalu coba lagi.' }
  finally { busy.value = '' }
}
</script>
<template>
  <main class="inbox page-shell"><nav class="breadcrumb"><RouterLink to="/">Beranda</RouterLink><span>/</span><strong>Request Mabar</strong></nav><header class="inbox-heading"><h1>Permintaan mabar</h1><p>Pantau ajakan masuk dan terkirim. Chat tersedia setelah ajakan diterima.</p></header>
    <p v-if="!configured && !demoMode" role="alert" class="error">Layanan belum dikonfigurasi.</p><p v-else-if="!userId">Silakan <RouterLink to="/login">masuk</RouterLink> untuk melihat ajakan.</p>
    <template v-else><p v-if="!session.verified" class="warning">Verifikasi email untuk mengirim dan membalas ajakan.</p><div class="tabs" role="group" aria-label="Jenis ajakan"><button type="button" :aria-pressed="tab === 'incoming'" @click="tab = 'incoming'">Diterima Masuk <span>{{ invites.filter(i => i.recipient_id === userId).length }}</span></button><button type="button" :aria-pressed="tab === 'sent'" @click="tab = 'sent'">Terkirim <span>{{ invites.filter(i => i.sender_id === userId).length }}</span></button><button class="refresh" type="button" @click="load" :disabled="loading">Muat ulang</button></div>
      <p v-if="loading" role="status">Memuat ajakan…</p><p v-if="error" role="alert" class="error">{{ error }}</p><p v-if="notice" role="status" class="success">{{ notice }}</p>
      <div v-if="!loading && !visible.length" class="empty"><h2>Belum ada request {{ tab === 'incoming' ? 'masuk' : 'terkirim' }} nih.</h2><p>Yuk mulai cari teman mabar yang cocok!</p><RouterLink class="button" to="/pilih-game">Cari teman mabar</RouterLink></div>
      <div v-if="!loading" class="list"><article v-for="i in visible" :key="i.id" class="card"><div class="invite-info"><div class="invite-avatar" aria-hidden="true">{{ (tab === 'incoming' ? i.sender_id : i.recipient_id).slice(0, 2).toUpperCase() }}</div><div><span class="game-tag">{{ gameName(i.game_id) }}</span><h2>{{ tab === 'incoming' ? 'Ajakan masuk' : 'Ajakan terkirim' }}</h2><p>{{ tab === 'incoming' ? 'Dari' : 'Kepada' }} pemain {{ (tab === 'incoming' ? i.sender_id : i.recipient_id).slice(0, 8) }} | {{ date(i.created_at) }}</p><p v-if="i.message" class="message">“{{ i.message }}”</p><span class="status" :class="`status--${status(i).toLowerCase()}`">{{ status(i) }}</span><p v-if="i.status === 'accepted'" class="private-note">ID game tidak terbuka otomatis. Pemilik dapat membagikannya secara eksplisit lewat chat.</p></div></div><div class="actions"><template v-if="i.status === 'pending' && status(i) !== 'Kedaluwarsa'"><template v-if="tab === 'incoming'"><button type="button" :disabled="!!busy || !session.verified" @click="act(i, 'accepted')">Terima</button><button type="button" class="secondary danger" :disabled="!!busy || !session.verified" @click="act(i, 'rejected')">Tolak</button></template><button v-else type="button" class="secondary" :disabled="!!busy" @click="act(i, 'cancel')">Batalkan</button></template><RouterLink v-if="i.status === 'accepted'" class="button secondary" to="/pesan">Buka chat</RouterLink><button v-if="tab === 'incoming'" type="button" class="secondary" :disabled="!!busy" @click="act(i, 'block')">Blokir</button><button v-if="tab === 'incoming'" type="button" class="secondary" :disabled="!!busy" @click="act(i, 'report')">Laporkan</button></div></article></div>
      <p class="privacy-note">ID game hanya dibagikan setelah pemilik memilih tindakan berbagi di chat. Persetujuan request saja tidak membagikan ID.</p>
    </template>
  </main>
</template>
<style scoped>
.inbox{max-width:1100px;padding-bottom:80px}.inbox-heading h1{font-size:clamp(2rem,4vw,2.75rem);margin-bottom:8px}.inbox-heading p{color:#b8b6c2}.tabs{display:flex;align-items:center;flex-wrap:wrap;gap:10px;margin:28px 0}.inbox button,.inbox .button{border:1px solid transparent;background:#c8ff4d;color:#14141c;border-radius:999px;padding:11px 18px;font-weight:700;display:inline-flex;align-items:center;justify-content:center}.inbox .tabs button{background:transparent;border-color:#666575;color:#f5f3ee}.inbox .tabs button[aria-pressed=true]{background:#c8ff4d;color:#14141c;border-color:#c8ff4d}.inbox .tabs .refresh{margin-left:auto;font-size:.85rem}.tabs span{margin-left:4px;background:#3c3c47;color:#f5f3ee;border-radius:999px;padding:2px 8px}.tabs button[aria-pressed=true] span{background:#14141c;color:#c8ff4d}.list{display:grid;gap:14px}.card{border:1px solid #393944;border-radius:22px;background:#1e1e29;padding:24px;display:flex;align-items:center;justify-content:space-between;gap:18px}.invite-info{display:flex;gap:15px;min-width:0}.invite-info h2{font-size:1.15rem;margin:10px 0 3px}.invite-info p{color:#b8b6c2;font-size:.9rem;margin:0 0 8px;overflow-wrap:anywhere}.invite-avatar{width:54px;height:54px;border-radius:50%;border:3px solid #8b7cff;background:#302b43;display:grid;place-items:center;flex:none;font-weight:800}.game-tag{background:#303823;border-radius:999px;color:#c8ff4d;padding:5px 10px;font-size:.75rem;font-weight:700}.inbox .actions{display:flex;flex-wrap:wrap;gap:8px;justify-content:flex-end}.inbox .secondary{background:transparent;color:#f5f3ee;border-color:#666575}.inbox .danger{color:#ff9d97;border-color:#ff6b5e}.status{display:inline-block;background:#3b3b49;padding:6px 12px;border-radius:999px;font-size:.8rem;font-weight:700}.status--diterima{background:#254030;color:#4ade80}.status--ditolak,.status--dibatalkan{background:#47302d;color:#ff9d97}.status--menunggu{background:#374025;color:#c8ff4d}.empty{text-align:center;padding:48px 20px;border:1px dashed #565665;border-radius:22px;background:#1e1e29}.empty p,.privacy-note{color:#b8b6c2}.privacy-note{margin-top:22px;font-size:.88rem}.private-note{margin-top:12px!important}.error{color:#ff9d97}.success{color:#4ade80}.warning{color:#ffe3a1}:focus-visible{outline:3px solid #8b7cff;outline-offset:2px}@media(max-width:700px){.card{flex-direction:column;align-items:stretch}.inbox .actions{justify-content:flex-start}.inbox .tabs .refresh{margin-left:0}}
</style>
