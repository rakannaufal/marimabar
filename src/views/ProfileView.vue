<script setup lang="ts">
import { computed, nextTick, onMounted, onServerPrefetch, onUnmounted, ref, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { blockUser, profileDetail, reportUser, listFriendRequests, requestFriend, friendContact } from '../lib/api'
import { publicGameFacts } from '../lib/models'
import type { Player, FriendRequest, FriendContact } from '../lib/models'
import { useSessionStore } from '../stores/session'

const route = useRoute(), router = useRouter(), session = useSessionStore()
const profileId = computed(() => String(route.params.id || ''))
const player = ref<Player | null>(null), loading = ref(true), error = ref(''), actionError = ref(''), notice = ref(''), busy = ref(false)
const friendship = ref<FriendRequest | null>(null), contact = ref<FriendContact | null>(null), friendLoading = ref(false)
const reportSent = ref(false), category = ref(''), description = ref('')
const modalMode = ref<null | 'report' | 'block'>(null)
const modalDialog = ref<HTMLElement | null>(null)
let previousFocus: HTMLElement | null = null
let requestId = 0

const categories = [
  { code: 'impersonation', label: 'Profil palsu atau rank tidak sesuai' },
  { code: 'harassment', label: 'Perilaku tidak pantas' },
  { code: 'fraud', label: 'Penipuan' },
  { code: 'spam', label: 'Spam' },
  { code: 'inappropriate', label: 'Lainnya' },
]
const isOwnProfile = computed(() => Boolean(player.value && session.user?.id === player.value.user_id))
const initials = computed(() => player.value?.display_name?.trim().slice(0, 2).toUpperCase() || 'TM')
const gameFacts = computed(() => player.value ? publicGameFacts(player.value) : [])
const updated = computed(() => { const value = player.value?.updated_at; return value && Number.isFinite(Date.parse(value)) ? new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium' }).format(new Date(value)) : '' })
const stale = computed(() => { const time = Date.parse(player.value?.updated_at || ''); return Number.isFinite(time) && Date.now() - time > 30 * 86400000 })

function closeModal() { modalMode.value = null }
watch(modalMode, async open => {
  if (open) { previousFocus = document.activeElement as HTMLElement; await nextTick(); modalDialog.value?.focus() }
  else { previousFocus?.focus(); previousFocus = null }
})
function trapModalFocus(event: KeyboardEvent) {
  if (event.key === 'Escape') { closeModal(); return }
  if (event.key !== 'Tab' || !modalDialog.value) return
  const elements = Array.from(modalDialog.value.querySelectorAll<HTMLElement>('button:not(:disabled), input:not(:disabled), textarea:not(:disabled), a[href]'))
  const first = elements[0], last = elements[elements.length - 1]
  if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last?.focus() }
  else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first?.focus() }
}
onUnmounted(() => { previousFocus?.focus() })

async function loadFriendship(target: Player, current: number) {
  friendship.value = null; contact.value = null
  if (!session.user || session.user.id === target.user_id) return
  friendLoading.value = true
  try {
    const rows = await listFriendRequests()
    if (current !== requestId) return
    friendship.value = rows.find(row => row.requester_id === target.user_id || row.recipient_id === target.user_id) || null
    if (friendship.value?.status === 'accepted') {
      const result = await friendContact(target.user_id, target.game_id)
      if (current === requestId) contact.value = result
    }
  } catch { /* Request and contact state stay closed when they cannot be verified. */ }
  finally { if (current === requestId) friendLoading.value = false }
}
async function loadProfile() {
  const current = ++requestId
  if (!profileId.value) { error.value = 'Profil tidak ditemukan.'; loading.value = false; return }
  loading.value = true; error.value = ''; player.value = null; friendship.value = null; contact.value = null
  try { const result = await profileDetail(profileId.value); if (current === requestId) { player.value = result; if (result) void loadFriendship(result, current) } }
  catch { if (current === requestId) error.value = 'Profil belum bisa dimuat. Coba lagi, ya.' }
  finally { if (current === requestId) loading.value = false }
}
function isAuthError(reason: unknown) {
  if (!reason || typeof reason !== 'object') return false
  const value = reason as { status?: number; code?: string; message?: string }
  return value.status === 401 || value.status === 403 || /^(401|403|PGRST301)$/i.test(value.code || '') || /not authenticated|unauthorized|login required|not logged in|jwt|session missing/i.test(value.message || '')
}
function redirectToLogin() { void router.push({ path: '/login', query: { redirect: route.fullPath } }) }
async function submitFriendRequest() {
  if (!player.value || busy.value || friendship.value?.status === 'pending') return
  if (!session.user) { redirectToLogin(); return }
  if (!session.verified) { actionError.value = 'Verifikasi emailmu di Profil Saya sebelum mengirim permintaan teman.'; return }
  if (player.value.verified === false) { actionError.value = 'Pemain ini belum memverifikasi email sehingga belum bisa menerima permintaan teman.'; return }
  busy.value = true; actionError.value = ''; notice.value = ''
  try {
    await requestFriend(player.value.user_id)
    friendship.value = { id: 'pending', requester_id: session.user.id, recipient_id: player.value.user_id, status: 'pending', created_at: new Date().toISOString(), responded_at: null }
    notice.value = 'Permintaan teman terkirim. Pantau statusnya di Teman.'
  } catch (reason) {
    if (isAuthError(reason)) redirectToLogin()
    else actionError.value = reason instanceof Error ? reason.message : 'Permintaan teman belum bisa dikirim. Coba lagi.'
  } finally { busy.value = false }
}
function openReport() {
  if (reportSent.value) return
  modalMode.value = 'report'; actionError.value = ''; notice.value = ''; category.value = ''; description.value = ''
}
function openBlock() {
  if (!session.user) { redirectToLogin(); return }
  modalMode.value = 'block'; actionError.value = ''
}
async function submitReport() {
  if (!player.value || !category.value || description.value.trim().length < 10 || busy.value) return
  if (!session.user) { redirectToLogin(); return }
  busy.value = true; actionError.value = ''
  try { await reportUser(player.value.user_id, category.value, description.value.trim(), player.value.id); reportSent.value = true; notice.value = 'Laporan terkirim. Terima kasih sudah membantu menjaga komunitas.' }
  catch (reason) { if (isAuthError(reason)) redirectToLogin(); else actionError.value = 'Laporan belum bisa dikirim. Coba lagi.' }
  finally { busy.value = false }
}
async function confirmBlock() {
  if (!player.value || busy.value) return
  busy.value = true; actionError.value = ''
  try { await blockUser(player.value.user_id); friendship.value = null; contact.value = null; closeModal(); void router.push('/') }
  catch (reason) { if (isAuthError(reason)) redirectToLogin(); else actionError.value = 'Pemain belum bisa diblokir. Coba lagi.' }
  finally { busy.value = false }
}
watch(profileId, () => { closeModal(); reportSent.value = false; notice.value = ''; void loadProfile() })
watch(() => session.user?.id, () => { friendship.value = null; contact.value = null; if (player.value) void loadFriendship(player.value, ++requestId) })
watch(isOwnProfile, own => { if (own && typeof window !== 'undefined') void router.replace('/profil-saya') })
onMounted(() => { if (loading.value) void loadProfile(); if (route.query.report === '1') openReport() })
onServerPrefetch(loadProfile)
watch(() => route.query.report, value => { if (value === '1' && modalMode.value !== 'report') openReport() })
</script>

<template>
  <main class="page-shell profile-page">
    <nav class="breadcrumb" aria-label="Breadcrumb"><RouterLink to="/">Beranda</RouterLink><span>/</span><span>Profil pemain</span><span v-if="player" aria-current="page">/ {{ player.display_name }}</span></nav>
    <p v-if="loading" class="state-card" role="status">Memuat profil pemain…</p>
    <div v-else-if="error" class="state-card" role="alert"><h1>Profil belum tersedia</h1><p>{{ error }}</p><button class="button button--outline" type="button" @click="loadProfile">Coba lagi</button></div>
    <div v-else-if="!player" class="state-card"><h1>Profil tidak ditemukan</h1><p>Profil ini mungkin sudah tidak tersedia.</p><RouterLink class="button button--outline" to="/pilih-game">Pilih game lain</RouterLink></div>
    <div v-else-if="isOwnProfile" class="state-card own-profile-state" role="status"><span class="eyebrow">Profil milikmu</span><h1>Membuka Profil Saya</h1><p>Profil publik milik sendiri tidak ditampilkan agar aksi request, laporan, dan blokir tidak salah digunakan.</p><RouterLink class="button button--primary" to="/profil-saya">Kelola profil</RouterLink></div>
    <template v-else>
      <header class="profile-hero">
        <div class="profile-hero__identity"><div class="avatar avatar--large" aria-hidden="true"><img v-if="player.avatar_url" :src="player.avatar_url" alt="" /><span v-else>{{ initials }}</span></div><div class="identity-copy"><h1>{{ player.display_name }}</h1><p>{{ player.game_name }}<span v-if="player.region"> · {{ player.region }}</span></p><div class="chip-group"><span class="chip" :class="player.ready ? 'chip--ready' : ''">{{ player.ready ? 'Siap mabar' : 'Tidak tersedia' }}</span><span v-if="player.verified === false" class="chip chip--unverified">Email belum terverifikasi</span></div></div></div>
        <div class="profile-hero__actions">
          <button v-if="!friendship || friendship.status === 'rejected'" class="button button--primary" type="button" :disabled="busy || friendLoading || player.verified === false" @click="submitFriendRequest">
            {{ player.verified === false ? 'Belum bisa di-request' : friendLoading ? 'Memeriksa…' : busy ? 'Mengirim…' : 'Kirim permintaan teman' }}
          </button>
          <span v-else-if="friendship.status === 'pending'" class="friend-state">Permintaan teman menunggu persetujuan</span>
          <span v-else-if="friendship.status === 'accepted'" class="friend-state friend-state--accepted">Sudah berteman</span>
        </div>
      </header>
      <p v-if="notice && !reportSent" class="notice" role="status">{{ notice }}</p>
      <p v-if="actionError && !modalMode" class="inline-error" role="alert">{{ actionError }}</p>

      <div class="profile-layout">
        <div class="profile-main">
          <section class="content-card about-card"><h2>Tentang pemain</h2><p v-if="player.bio" class="profile-bio">{{ player.bio }}</p><p v-else class="muted">Pemain ini belum menambahkan bio.</p></section>
          <section class="content-card game-card"><div class="card-heading"><div><span class="eyebrow">Profil game</span><h2>{{ player.game_name }}</h2></div><span v-if="updated" class="updated">Diperbarui {{ updated }}</span></div><dl class="game-facts"><div v-for="fact in gameFacts" :key="fact.label"><dt>{{ fact.label }}</dt><dd>{{ fact.value }}</dd></div></dl><dl v-if="friendship?.status === 'accepted' && contact" class="game-facts contact-facts" aria-label="Kontak teman"><div><dt>Nama dalam game</dt><dd>{{ contact.ign || 'Belum diisi' }}</dd></div><div><dt>ID game</dt><dd>{{ contact.game_id_private || 'Belum diisi' }}</dd></div><div><dt>Discord</dt><dd>{{ contact.discord || 'Belum diisi' }}</dd></div></dl><p v-if="stale" class="fine-print">Profil ini perlu diperbarui.</p><p class="fine-print">Data diisi pengguna, belum terverifikasi.</p></section>
        </div>
        <aside class="profile-aside"><section class="content-card info-card"><h2>Info singkat</h2><dl><div><dt>Status</dt><dd>{{ player.ready ? 'Sedang mencari mabar' : 'Belum siap mabar' }}</dd></div><div v-if="player.region"><dt>Region</dt><dd>{{ player.region }}</dd></div></dl><p class="fine-print">Jam aktif mengikuti waktu setempat pemain.</p></section><section class="content-card safety-card"><h2>Keamanan</h2><p class="muted">Laporkan profil bermasalah atau blokir pemain ini.</p><div class="safety-actions"><span v-if="reportSent" class="muted">Laporan terkirim</span><button v-else class="text-link text-link--danger" type="button" @click="openReport">Laporkan profil</button><button class="text-link" type="button" :disabled="busy" @click="openBlock">Blokir pemain</button></div></section></aside>
      </div>

      <div v-if="modalMode" class="modal-overlay" @click.self="closeModal"><section ref="modalDialog" class="modal-sheet" role="dialog" aria-modal="true" :aria-labelledby="modalMode === 'block' ? 'block-title' : 'report-title'" tabindex="-1" @keydown="trapModalFocus"><button type="button" class="modal-close" aria-label="Tutup" @click="closeModal">Tutup</button>
        <template v-if="modalMode === 'block'"><span class="modal-kicker">Tindakan keamanan</span><h2 id="block-title">Blokir {{ player.display_name }}?</h2><p class="muted">Kalian tidak dapat saling menemukan, mengirim ajakan, atau berkirim pesan. Kontak yang sebelumnya terbuka juga akan ditutup.</p><p v-if="actionError" class="inline-error" role="alert">{{ actionError }}</p><div class="action-row modal-actions"><button class="button button--outline" type="button" @click="closeModal">Batal</button><button class="button button--danger" type="button" :disabled="busy" @click="confirmBlock">{{ busy ? 'Memblokir…' : 'Blokir pemain' }}</button></div></template>
        <template v-else-if="reportSent"><h2 id="report-title">Laporan diterima</h2><p>{{ notice }}</p><p class="muted">Tim moderasi akan meninjau laporan sesuai antrean.</p><button class="button button--primary" type="button" @click="closeModal">Selesai</button></template>
        <form v-else @submit.prevent="submitReport"><span class="modal-kicker">Laporkan profil</span><h2 id="report-title">Kenapa kamu melaporkan profil ini?</h2><p class="muted">Pilih alasan yang paling sesuai, lalu berikan detail singkat.</p><fieldset class="reason-list"><legend>Alasan laporan</legend><label v-for="option in categories" :key="option.code"><input v-model="category" type="radio" name="category" :value="option.code" required />{{ option.label }}</label></fieldset><label class="field">Detail laporan<textarea v-model="description" minlength="10" maxlength="2000" required rows="4" placeholder="Ceritakan kejadian, minimal 10 karakter."></textarea></label><p v-if="actionError" class="inline-error" role="alert">{{ actionError }}</p><div class="action-row modal-actions"><button class="button button--outline" type="button" @click="closeModal">Batal</button><button class="button button--primary" type="submit" :disabled="busy || !category || description.trim().length < 10">{{ busy ? 'Mengirim…' : 'Kirim laporan' }}</button></div></form>
      </section></div>
    </template>
  </main>
</template>

<style scoped>
.profile-page{max-width:1180px;padding-bottom:88px;overflow-x:clip}.profile-page .breadcrumb{flex-wrap:wrap;margin-bottom:22px}.profile-hero{min-height:0!important;display:flex;align-items:center;justify-content:space-between;gap:28px;padding:30px!important;background:#211f2d!important;border:1px solid #3e3b4d!important;border-radius:20px!important;box-shadow:none!important}.profile-hero__identity{display:flex;align-items:center;gap:22px;min-width:0}.profile-hero__actions{display:flex;flex-direction:column;align-items:stretch;gap:10px;min-width:220px}.friend-state{display:block;border:1px solid #666575;border-radius:12px;padding:10px 14px;color:#c9c7d2;font-size:.84rem;font-weight:700;text-align:center}.friend-state--accepted{border-color:#4e734e;color:#9ae6ad}.profile-page .avatar{width:92px;height:92px;flex:none;border:2px solid #8b7cff;border-radius:50%;font-size:1.7rem}.identity-copy{min-width:0}.identity-copy h1{font-size:clamp(1.8rem,4vw,2.75rem);line-height:1.08;margin:0 0 8px;overflow-wrap:anywhere}.identity-copy p{color:#aaa8b8;margin:0}.chip-group{display:flex;gap:8px;flex-wrap:wrap;margin-top:14px}.chip--unverified{background:#3b292d;color:#ffaaa4;border-color:#6d3c40}.notice,.inline-error{margin:16px 0 0}.notice{color:#9ae6ad}.inline-error{color:#ffaaa4}.invite-panel{margin-top:18px;display:grid;grid-template-columns:minmax(180px,.65fr) minmax(280px,1.35fr);gap:24px;align-items:start;border-radius:18px!important}.invite-panel h2{font-size:1.25rem;margin-bottom:6px}.invite-panel .field{margin:0}.invite-panel .action-row{grid-column:2}.profile-layout{display:grid;grid-template-columns:minmax(0,1fr) 310px;gap:20px;align-items:start;margin-top:20px}.profile-main,.profile-aside{display:grid;gap:20px;min-width:0}.content-card{padding:26px!important;border-radius:18px!important;min-width:0}.content-card h2{font-size:1.25rem;margin-bottom:18px}.about-card{min-height:0}.about-card p{margin-bottom:0}.profile-bio{white-space:pre-wrap;overflow-wrap:anywhere}.card-heading{display:flex;align-items:flex-start;justify-content:space-between;gap:18px;padding-bottom:20px;border-bottom:1px solid #353443}.card-heading h2{font-size:1.45rem;margin:5px 0 0}.eyebrow,.modal-kicker{display:block;color:#aaa8b8;font-size:.72rem;font-weight:800;letter-spacing:.1em;text-transform:uppercase}.updated{color:#aaa8b8;font-size:.76rem;white-space:nowrap}.game-facts{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:0 28px;margin:4px 0 20px}.game-facts div{display:grid;grid-template-columns:minmax(110px,.8fr) minmax(0,1.2fr);gap:12px;align-items:start;padding:15px 0;border-bottom:1px solid #33323f}.game-facts dt,.info-card dt{color:#9694a5;font-size:.85rem}.game-facts dd,.info-card dd{margin:0;color:#f2f0f7;font-weight:600;overflow-wrap:anywhere;text-align:left}.contact-facts{padding-top:6px;border-top:1px solid #4a4657}.info-card dl{display:grid;gap:0;margin:0 0 16px}.info-card dl div{display:grid;gap:5px;padding:12px 0;border-bottom:1px solid #33323f}.info-card dd{margin:0}.safety-card p{font-size:.9rem}.safety-actions{display:flex;align-items:center;gap:18px;flex-wrap:wrap}.action-row{display:flex;gap:10px;flex-wrap:wrap}.modal-overlay{position:fixed;inset:0;z-index:50;background:#0c0c12cc;display:grid;place-items:center;padding:20px}.modal-sheet{width:min(100%,620px);max-height:min(88vh,760px);overflow:auto;background:#1e1e29;border:1px solid #50505f;border-radius:20px;padding:30px;box-shadow:0 24px 70px #0009}.modal-close{float:right;background:none;border:0;color:#d3d1dc;padding:4px;font-weight:700}.modal-sheet h2{font-size:1.55rem;margin:8px 40px 10px 0}.reason-list{border:0;padding:0;margin:24px 0 20px;display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:9px}.reason-list legend{font-weight:700;margin-bottom:12px}.reason-list label{border:1px solid #50505f;border-radius:12px;padding:12px;display:flex;gap:10px;cursor:pointer;min-width:0}.reason-list label:has(input:checked){border-color:#8b7cff;background:#302b43}.reason-list input{accent-color:#c8ff4d;flex:none}.modal-actions{justify-content:flex-end}.button--danger{background:#dc574d;color:#fff;border-color:#dc574d}.button--danger:hover{background:#ed665b}.profile-page .button{border-radius:12px}
@media(max-width:850px){.profile-layout{grid-template-columns:1fr}.profile-aside{grid-template-columns:repeat(2,minmax(0,1fr))}.game-facts{grid-template-columns:1fr 1fr}}
@media(max-width:680px){.profile-hero{align-items:stretch;flex-direction:column;padding:22px!important}.profile-hero__identity{align-items:flex-start}.profile-page .avatar{width:72px;height:72px;font-size:1.3rem}.profile-hero>.button{width:100%}.invite-panel{grid-template-columns:1fr}.invite-panel .action-row{grid-column:auto}.profile-aside{grid-template-columns:1fr}.game-facts{grid-template-columns:1fr}.modal-overlay{align-items:end;padding:0}.modal-sheet{width:100%;border-radius:20px 20px 0 0;padding:24px;max-height:92vh}.reason-list{grid-template-columns:1fr}}
@media(max-width:420px){.profile-hero__identity{display:grid;grid-template-columns:auto minmax(0,1fr);gap:14px}.game-facts div{grid-template-columns:1fr;gap:5px}.card-heading{display:block}.updated{display:block;margin-top:10px}.modal-actions .button{width:100%}}
</style>
