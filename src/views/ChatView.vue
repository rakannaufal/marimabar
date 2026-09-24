<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { useSessionStore } from '../stores/session'
import { configured, demoMode } from '../lib/supabase'
import {
  blockUser, listConversations, listGames, listInvites, listMessages,
  ownGameProfiles, readSharedGameId, reportUser, searchProfiles, sendMessage, shareGameId,
} from '../lib/api'
import type { ChatMessage, Conversation, Game, GameProfile, Invite, Player } from '../lib/models'

const route = useRoute()
const session = useSessionStore()
const userId = computed(() => session.user?.id)
const conversations = ref<Conversation[]>([])
const invites = ref<Invite[]>([])
const games = ref<Game[]>([])
const players = ref<Player[]>([])
const profiles = ref<GameProfile[]>([])
const messages = ref<ChatMessage[]>([])
const selected = ref('')
const draft = ref('')
const profileId = ref('')
const shared = ref<string | null>(null)
const loading = ref(false)
const threadLoading = ref(false)
const busy = ref(false)
const error = ref('')
const threadError = ref('')
const notice = ref('')
const reportMessage = ref<ChatMessage | null>(null)
const category = ref('')
const description = ref('')
let loadVersion = 0
let threadVersion = 0

const categories = [
  { code: 'harassment', label: 'Pelecehan' },
  { code: 'spam', label: 'Spam' },
  { code: 'fraud', label: 'Penipuan' },
  { code: 'impersonation', label: 'Impersonasi' },
  { code: 'inappropriate', label: 'Konten tidak pantas' },
]
const conversation = computed(() => conversations.value.find(c => c.id === selected.value))
const other = computed(() => conversation.value?.participant_low === userId.value
  ? conversation.value?.participant_high : conversation.value?.participant_low)
const invite = computed(() => invites.value.find(i => i.id === conversation.value?.invite_id))
const gameName = computed(() => games.value.find(g => g.id === invite.value?.game_id)?.name || '')
const otherPlayer = computed(() => players.value.find(p => p.user_id === other.value && p.game_id === invite.value?.game_id))
const otherName = computed(() => otherPlayer.value?.display_name?.trim() || 'Pemain')
const eligibleProfiles = computed(() => profiles.value.filter(p => p.status === 'active' && p.game_id === invite.value?.game_id && !!p.game_id_private))
const canChat = computed(() => conversation.value?.status === 'active' && !!session.verified)
function nameFor(c: Conversation) {
  const personId = c.participant_low === userId.value ? c.participant_high : c.participant_low
  const match = invites.value.find(i => i.id === c.invite_id)
  return players.value.find(p => p.user_id === personId && p.game_id === match?.game_id)?.display_name?.trim() || 'Pemain'
}
function gameFor(c: Conversation) {
  const match = invites.value.find(i => i.id === c.invite_id)
  return games.value.find(g => g.id === match?.game_id)?.name || ''
}
function initials(name: string) { return name === 'Pemain' ? 'P' : name.trim().slice(0, 2).toUpperCase() }
function time(value: string) {
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? '' : new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium', timeStyle: 'short' }).format(date)
}

async function load() {
  const version = ++loadVersion
  if ((!configured && !demoMode) || !userId.value) { loading.value = false; return }
  loading.value = true
  error.value = ''
  try {
    const [nextConversations, nextProfiles, nextInvites, nextGames] = await Promise.all([
      listConversations(userId.value), ownGameProfiles(userId.value), listInvites(userId.value), listGames(),
    ])
    if (version !== loadVersion) return
    conversations.value = nextConversations
    profiles.value = nextProfiles
    invites.value = nextInvites
    games.value = nextGames
    const requested = typeof route.query.conversation === 'string' ? route.query.conversation : ''
    selected.value = nextConversations.some(c => c.id === requested) ? requested :
      nextConversations.some(c => c.id === selected.value) ? selected.value : nextConversations[0]?.id || ''
    const relevant = new Set(nextInvites.filter(i => nextConversations.some(c => c.invite_id === i.id)).map(i => i.game_id))
    const results = await Promise.allSettled(nextGames.filter(g => relevant.has(g.id)).map(g => searchProfiles(g.slug)))
    if (version !== loadVersion) return
    players.value = results.flatMap(r => r.status === 'fulfilled' ? r.value : [])
    // A hidden or unavailable public profile must not be replaced by a guessed name.
  } catch {
    if (version === loadVersion) error.value = 'Percakapan belum bisa dimuat. Coba lagi.'
  } finally {
    if (version === loadVersion) loading.value = false
  }
}
async function refresh() {
  const id = selected.value
  const owner = other.value
  const version = ++threadVersion
  if (!id) return
  threadLoading.value = true
  threadError.value = ''
  try {
    const [nextMessages, nextShared] = await Promise.all([
      listMessages(id), owner ? readSharedGameId(id, owner) : Promise.resolve(null),
    ])
    if (version !== threadVersion || selected.value !== id) return
    messages.value = nextMessages
    shared.value = nextShared
  } catch {
    if (version === threadVersion) threadError.value = 'Pesan belum bisa dimuat. Coba lagi.'
  } finally {
    if (version === threadVersion) threadLoading.value = false
  }
}
async function send() {
  const body = draft.value.trim()
  if (!canChat.value || busy.value || !body || body.length > 2000) return
  const id = selected.value
  busy.value = true
  error.value = ''
  try {
    await sendMessage(id, body)
    if (selected.value === id) { draft.value = ''; await refresh() }
  } catch { error.value = 'Pesan belum bisa dikirim. Periksa akun atau status percakapan, lalu coba lagi.' }
  finally { busy.value = false }
}
async function share() {
  if (!canChat.value || busy.value || !eligibleProfiles.value.some(p => p.id === profileId.value)) return
  if (!window.confirm('Bagikan ID game privat ini kepada peserta percakapan? Hanya lakukan jika kamu memang ingin membagikannya.')) return
  busy.value = true
  error.value = ''
  try { await shareGameId(selected.value, profileId.value); notice.value = 'ID game berhasil dibagikan kepada peserta percakapan ini.' }
  catch { error.value = 'ID game belum bisa dibagikan. Periksa profil dan status percakapan.' }
  finally { busy.value = false }
}
function openReport(message: ChatMessage) {
  if (message.sender_id !== other.value) return
  reportMessage.value = message
  category.value = ''
  description.value = ''
  error.value = ''
}
async function submitReport() {
  const target = reportMessage.value
  if (busy.value || !target || target.sender_id !== other.value || !messages.value.some(m => m.id === target.id) || !other.value) return
  if (!category.value || !categories.some(c => c.code === category.value) || description.value.trim().length < 10) {
    error.value = 'Pilih alasan dan isi deskripsi minimal 10 karakter.'
    return
  }
  busy.value = true
  error.value = ''
  try {
    await reportUser(other.value, category.value, description.value.trim(), target.id, 'message')
    reportMessage.value = null
    notice.value = 'Laporan terkirim. Terima kasih sudah menjaga ruang mabar.'
  } catch { error.value = 'Laporan belum bisa dikirim. Coba lagi.' }
  finally { busy.value = false }
}
async function block() {
  if (busy.value || !other.value) return
  if (!window.confirm('Blokir pemain ini? Kalian tidak bisa lagi saling mengirim ajakan atau pesan.')) return
  busy.value = true
  error.value = ''
  try { await blockUser(other.value); reportMessage.value = null; notice.value = 'Pemain diblokir.'; await load() }
  catch { error.value = 'Pemain belum bisa diblokir. Coba lagi.' }
  finally { busy.value = false }
}
watch(userId, () => { selected.value = ''; conversations.value = []; messages.value = []; shared.value = null; reportMessage.value = null; void load() })
watch(() => route.query.conversation, value => {
  if (typeof value === 'string' && conversations.value.some(c => c.id === value)) selected.value = value
})
watch(selected, () => {
  ++threadVersion
  messages.value = []
  shared.value = null
  profileId.value = ''
  draft.value = ''
  reportMessage.value = null
  threadError.value = ''
  notice.value = ''
  void refresh()
})
onMounted(load)
</script>

<template>
  <main class="chat">
    <nav class="breadcrumb" aria-label="Breadcrumb"><RouterLink to="/">Beranda</RouterLink><span>/</span><RouterLink to="/request-mabar">Request mabar</RouterLink><span>/</span><span>Pesan</span></nav>
    <header class="page-head"><h1>Pesan</h1><p>Ajakan sudah diterima? Lanjut ngobrol di sini. ID game tetap privat sampai pemilik membagikannya sendiri.</p></header>
    <p v-if="!configured && !demoMode" role="alert" class="state">Layanan belum dikonfigurasi.</p>
    <p v-else-if="!userId" class="state">Silakan <RouterLink to="/login">masuk</RouterLink> untuk melihat pesan.</p>
    <template v-else>
      <p v-if="!session.verified" class="warning" role="status">Verifikasi email sebelum mengirim pesan atau membagikan ID game.</p>
      <p v-if="error" role="alert" class="error">{{ error }}</p>
      <p v-if="notice" role="status" class="success">{{ notice }}</p>
      <p v-if="loading" role="status" class="state">Memuat percakapan…</p>
      <div v-else class="layout">
        <aside class="conversation-list" aria-label="Daftar percakapan">
          <div class="section-heading"><h2>Percakapan</h2><span class="count">{{ conversations.length }}</span></div>
          <p v-if="!conversations.length" class="empty-list">Belum ada percakapan. Setelah ajakan diterima, chat akan muncul di sini. <RouterLink to="/request-mabar">Lihat ajakan</RouterLink></p>
          <button v-for="c in conversations" :key="c.id" type="button" class="conversation-choice" :aria-pressed="selected === c.id" @click="selected = c.id">
            <span class="avatar" aria-hidden="true">{{ initials(nameFor(c)) }}</span>
            <span class="choice-copy"><strong>{{ nameFor(c) }}</strong><small v-if="gameFor(c)">{{ gameFor(c) }}</small><small>{{ c.status === 'active' ? 'Percakapan aktif' : 'Percakapan tidak aktif' }}</small></span>
          </button>
        </aside>
        <section v-if="conversation" class="thread" aria-label="Isi percakapan">
          <header class="thread-head"><div class="identity"><span class="avatar avatar--large" aria-hidden="true">{{ initials(otherName) }}</span><div><h2>{{ otherName }}</h2><p v-if="gameName">{{ gameName }}</p><p>{{ conversation.status === 'active' ? 'Percakapan aktif' : 'Percakapan tidak aktif' }}</p></div></div><div class="actions"><button type="button" class="secondary" :disabled="threadLoading || busy" @click="refresh">Muat ulang</button><button type="button" class="secondary danger" :disabled="busy" @click="block">Blokir</button></div></header>
          <p class="privacy-note">Hanya peserta percakapan ini yang bisa membaca pesan. Jangan bagikan data pribadi jika belum nyaman.</p>
          <p v-if="threadError" class="error" role="alert">{{ threadError }} <button class="text-action" type="button" @click="refresh">Coba lagi</button></p>
          <div class="messages" aria-live="polite" aria-label="Pesan">
            <p v-if="threadLoading" role="status" class="muted">Memuat pesan…</p>
            <p v-else-if="!threadError && !messages.length" class="message-empty">Belum ada pesan. Sapa rekan mabar kamu dulu, yuk.</p>
            <article v-for="m in messages" :key="m.id" class="message" :class="{ 'message--mine': m.sender_id === userId }">
              <div class="message-meta"><span>{{ m.sender_id === userId ? 'Saya' : otherName }}</span><time :datetime="m.created_at">{{ time(m.created_at) }}</time></div>
              <p>{{ m.body }}</p>
              <button v-if="m.sender_id === other" class="report-link" type="button" aria-label="Laporkan pesan" :data-message-id="m.id" :disabled="busy" @click="openReport(m)">Laporkan pesan</button>
            </article>
          </div>
          <form id="message-form" class="composer" @submit.prevent="send"><label for="message">Pesan baru</label><textarea id="message" v-model="draft" maxlength="2000" rows="3" placeholder="Tulis pesan untuk rekan mabar…" :disabled="!canChat || busy" /><div class="composer-foot"><small>Maksimal 2.000 karakter</small><button type="submit" :disabled="!canChat || busy || !draft.trim()">{{ busy ? 'Mengirim…' : 'Kirim pesan' }}</button></div></form>
          <section class="share"><div><h3>Bagikan ID game</h3><p>ID milikmu tidak akan ditampilkan kepada rekan chat kecuali kamu memilih membagikannya.</p></div><p v-if="shared" class="shared-id">ID game yang dibagikan {{ otherName }}: <strong>{{ shared }}</strong></p><p v-else class="muted">Rekan chat belum membagikan ID game.</p><div v-if="eligibleProfiles.length" class="share-control"><label for="profile-id">Pilih profil game milikmu</label><select id="profile-id" v-model="profileId" :disabled="!canChat || busy"><option value="">Pilih profil</option><option v-for="p in eligibleProfiles" :key="p.id" :value="p.id">{{ p.ign }}</option></select><button type="button" :disabled="!canChat || busy || !profileId" @click="share">Bagikan ID game</button></div><p v-else class="muted">Belum ada profil aktif untuk game ini dengan ID yang bisa dibagikan.</p></section>
          <form v-if="reportMessage" id="report-form" class="report-form" aria-label="Form laporan pesan" @submit.prevent="submitReport"><div class="report-heading"><h3>Laporkan pesan</h3><button class="text-action" type="button" :disabled="busy" @click="reportMessage = null">Batal</button></div><p class="muted">Pesan yang dipilih: “{{ reportMessage.body }}”</p><label for="report-category">Alasan laporan</label><select id="report-category" v-model="category" required><option value="" disabled>Pilih alasan</option><option v-for="option in categories" :key="option.code" :value="option.code">{{ option.label }}</option></select><label for="report-description">Apa yang terjadi?</label><textarea id="report-description" v-model="description" required minlength="10" maxlength="2000" rows="3" placeholder="Ceritakan kejadian secara singkat." /><button type="submit" :disabled="busy || !category || description.trim().length < 10">{{ busy ? 'Mengirim…' : 'Kirim laporan' }}</button></form>
        </section>
        <div v-else class="thread no-selection"><p>Pilih percakapan untuk mulai ngobrol.</p></div>
      </div>
    </template>
  </main>
</template>

<style scoped>
.chat{max-width:1240px;margin:auto;padding:2rem clamp(1rem,3vw,2.5rem) 5rem;color:#f5f3ee;font-family:Inter,"DM Sans",sans-serif}.breadcrumb{display:flex;gap:.7rem;align-items:center;color:#aaaaba;font-size:.85rem;margin:0 0 2rem}.breadcrumb a{color:#aaaaba}.page-head{margin-bottom:2rem}.page-head h1{font:800 clamp(2rem,4vw,3rem)/1.15 "Plus Jakarta Sans",sans-serif;margin:0 0 .65rem}.page-head p{max-width:62ch;line-height:1.6;margin:0;color:#aaaaba}.layout{display:grid;grid-template-columns:minmax(250px,320px) minmax(0,1fr);gap:1rem;align-items:start}.conversation-list,.thread,.state{background:#1e1e29;border:1px solid #2e2e3e;border-radius:22px}.conversation-list{padding:1.25rem;min-height:570px}.section-heading,.thread-head,.identity,.actions,.composer-foot,.report-heading{display:flex;align-items:center;justify-content:space-between;gap:1rem}.section-heading h2,.thread-head h2,.share h3,.report-form h3{font:800 1.2rem "Plus Jakarta Sans",sans-serif;margin:0}.count{border-radius:99px;background:#303043;color:#c8ff4d;padding:.22rem .65rem;font-weight:700}.conversation-choice{display:flex;gap:.85rem;align-items:center;width:100%;padding:1rem;margin:.5rem 0;border:1px solid transparent;background:#282835;color:#f5f3ee;border-radius:16px;text-align:left}.conversation-choice[aria-pressed=true]{border-color:#c8ff4d;background:#303924}.choice-copy{display:grid;min-width:0;gap:.25rem}.choice-copy strong{font:700 1rem "Plus Jakarta Sans",sans-serif;overflow-wrap:anywhere}.choice-copy small{color:#b4b4c2}.avatar{flex:none;border-radius:50%;display:grid;place-items:center;width:48px;height:48px;background:#373344;border:2px solid #8b7cff;color:#f5f3ee;font:800 1rem "Plus Jakarta Sans",sans-serif}.avatar--large{width:54px;height:54px}.thread{padding:clamp(1rem,2.5vw,1.75rem);min-width:0}.thread-head{flex-wrap:wrap;padding-bottom:1.25rem;border-bottom:1px solid #353544}.identity{justify-content:flex-start}.identity p{margin:.22rem 0 0;font-size:.83rem;color:#b4b4c2}.actions{justify-content:flex-start;flex-wrap:wrap;gap:.5rem}.privacy-note{border-radius:14px;padding:.85rem 1rem;background:#29293a;color:#cecdd8;font-size:.85rem;line-height:1.5;margin:1.25rem 0}.messages{background:#191922;border-radius:18px;min-height:250px;max-height:510px;overflow-y:auto;padding:1.1rem;display:flex;flex-direction:column;gap:.9rem}.message{max-width:min(80%,560px);align-self:flex-start;background:#30303f;border-radius:17px 17px 17px 5px;padding:.85rem 1rem;overflow-wrap:anywhere}.message--mine{align-self:flex-end;background:#344127;border-radius:17px 17px 5px 17px}.message-meta{display:flex;flex-wrap:wrap;gap:.45rem 1rem;justify-content:space-between;color:#d1d1dc;font-size:.76rem}.message p{white-space:pre-wrap;margin:.5rem 0 0;line-height:1.5}.message-empty,.empty-list,.muted{color:#b4b4c2;line-height:1.6}.message-empty{text-align:center;margin:auto}.report-link,.text-action{background:none;border:0;padding:.3rem 0;color:#d5cfff;text-decoration:underline;font:600 .82rem Inter,sans-serif;cursor:pointer}.report-link{margin-top:.7rem}.composer,.share,.report-form{display:grid;gap:.75rem;padding-top:1.4rem;margin-top:1.3rem;border-top:1px solid #353544}.composer label,.share label,.report-form label{font-weight:700;font-size:.88rem}.composer-foot small{color:#b4b4c2}.share h3{margin-bottom:.5rem}.share p{margin:.25rem 0;color:#b4b4c2;line-height:1.55}.share-control{display:grid;gap:.7rem;max-width:420px}.shared-id{padding:.85rem 1rem;border-radius:14px;background:#29293a;overflow-wrap:anywhere}.shared-id strong{display:block;color:#f5f3ee;font-size:1.1rem}.report-form{padding:1.3rem;border:1px solid #51434c;border-radius:18px;background:#292632}.report-form .muted{overflow-wrap:anywhere;max-height:5rem;overflow:auto;margin:0}textarea,select{width:100%;box-sizing:border-box;min-width:0;background:#14141c;border:1px solid #555565;border-radius:13px;padding:.8rem 1rem;color:#f5f3ee;font:inherit}textarea{resize:vertical}button:not(.report-link):not(.text-action):not(.conversation-choice){border:1px solid transparent;background:#c8ff4d;color:#14141c;border-radius:999px;padding:.65rem 1.1rem;cursor:pointer;font:700 .86rem Inter,sans-serif}button.secondary{background:#30303f!important;color:#f5f3ee!important;border-color:#505061!important}button.danger{color:#ffaaa2!important}button:disabled{opacity:.5;cursor:not-allowed!important}.state{padding:2rem}.error,.warning,.success{padding:.85rem 1rem;border-radius:13px}.error{color:#ffaaa2;background:#3c292e}.warning{color:#ffe3a1;background:#3e3729}.success{color:#c8ff4d;background:#293624}a{color:#c8ff4d}:focus-visible{outline:3px solid #8b7cff;outline-offset:3px}.no-selection{display:grid;place-items:center;color:#b4b4c2;min-height:300px}@media(max-width:760px){.layout{grid-template-columns:1fr}.conversation-list{min-height:0}.thread-head{align-items:flex-start}.message{max-width:92%}.composer-foot{align-items:flex-start;flex-direction:column}.composer-foot button{align-self:stretch}}
</style>
