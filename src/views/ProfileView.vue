<script setup lang="ts">
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { blockUser, createInvite, profileDetail, reportUser } from '../lib/api'
import type { Player } from '../lib/models'
import { useSessionStore } from '../stores/session'
const route = useRoute(), router = useRouter(), session = useSessionStore()
const profileId = computed(() => String(route.params.id || ''))
const player = ref<Player | null>(null), loading = ref(true), error = ref(''), actionError = ref(''), notice = ref(''), busy = ref(false)
const inviteOpen = ref(false), reportOpen = ref(false), reportSent = ref(false), inviteMessage = ref(''), category = ref(''), description = ref('')
const reportDialog = ref<HTMLElement | null>(null)
let previousFocus: HTMLElement | null = null
function closeReport() { reportOpen.value = false }
watch(reportOpen, async open => {
  if (open) { previousFocus = document.activeElement as HTMLElement; await nextTick(); reportDialog.value?.focus() }
  else { previousFocus?.focus(); previousFocus = null }
})
function trapReportFocus(event: KeyboardEvent) {
  if (event.key === 'Escape') { closeReport(); return }
  if (event.key !== 'Tab' || !reportDialog.value) return
  const elements = Array.from(reportDialog.value.querySelectorAll<HTMLElement>('button:not(:disabled), input:not(:disabled), textarea:not(:disabled), a[href]'))
  const first = elements[0], last = elements[elements.length - 1]
  if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last?.focus() }
  else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first?.focus() }
}
onUnmounted(() => { previousFocus?.focus() })
const categories = [
  { code: 'impersonation', label: 'Profil palsu atau rank tidak sesuai' },
  { code: 'harassment', label: 'Perilaku tidak pantas' },
  { code: 'fraud', label: 'Penipuan' },
  { code: 'spam', label: 'Spam' },
  { code: 'inappropriate', label: 'Lainnya' },
]
let requestId = 0
const initials = computed(() => player.value?.display_name?.trim().slice(0, 2).toUpperCase() || 'TM')
const updated = computed(() => { const value = player.value?.updated_at; return value && Number.isFinite(Date.parse(value)) ? new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium' }).format(new Date(value)) : '' })
const stale = computed(() => { const time = Date.parse(player.value?.updated_at || ''); return Number.isFinite(time) && Date.now() - time > 30 * 86400000 })
async function loadProfile() {
  const current = ++requestId
  if (!profileId.value) { error.value = 'Profil tidak ditemukan.'; loading.value = false; return }
  loading.value = true; error.value = ''; player.value = null
  try { const result = await profileDetail(profileId.value); if (current === requestId) player.value = result }
  catch { if (current === requestId) error.value = 'Profil belum bisa dimuat. Coba lagi, ya.' }
  finally { if (current === requestId) loading.value = false }
}
function isAuthError(reason: unknown) {
  if (!reason || typeof reason !== 'object') return false
  const value = reason as { status?: number; code?: string; message?: string }
  return value.status === 401 || value.status === 403 || /^(401|403|PGRST301)$/i.test(value.code || '') || /not authenticated|unauthorized|login required|not logged in|jwt|session missing/i.test(value.message || '')
}
function redirectToLogin() { void router.push({ path: '/login', query: { redirect: route.fullPath } }) }
async function submitInvite() {
  if (!player.value || busy.value) return
  if (!session.user) { redirectToLogin(); return }
  if (!session.verified) { actionError.value = 'Verifikasi emailmu sebelum mengirim ajakan.'; return }
  busy.value = true; actionError.value = ''
  try { await createInvite(player.value.user_id, player.value.game_id, inviteMessage.value.trim()); inviteOpen.value = false; notice.value = 'Ajakan mabar terkirim.' }
  catch (reason) { if (isAuthError(reason)) redirectToLogin(); else actionError.value = 'Ajakan belum bisa dikirim. Periksa akunmu, lalu coba lagi.' }
  finally { busy.value = false }
}
function openReport() { if (reportSent.value) return; reportOpen.value = true; inviteOpen.value = false; actionError.value = ''; notice.value = ''; category.value = ''; description.value = '' }
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
  if (!session.user) { redirectToLogin(); return }
  if (!window.confirm(`Blokir ${player.value.display_name}? Kalian tidak dapat saling menemukan atau mengirim ajakan.`)) return
  busy.value = true; actionError.value = ''
  try { await blockUser(player.value.user_id); notice.value = 'Pemain diblokir.'; void router.push('/') }
  catch (reason) { if (isAuthError(reason)) redirectToLogin(); else actionError.value = 'Pemain belum bisa diblokir. Coba lagi.' }
  finally { busy.value = false }
}
watch(profileId, () => { inviteOpen.value = false; reportOpen.value = false; reportSent.value = false; notice.value = ''; void loadProfile() })
onMounted(() => { void loadProfile(); if (route.query.report === '1') openReport() })
watch(() => route.query.report, value => { if (value === '1' && !reportOpen.value) openReport() })
</script>
<template>
  <main class="page-shell profile-page">
    <nav class="breadcrumb" aria-label="Breadcrumb"><RouterLink to="/">Beranda</RouterLink><span>/</span><span>Profil pemain</span><span v-if="player">/ {{ player.display_name }}</span></nav>
    <p v-if="loading" class="state-card" role="status">Memuat profil pemain…</p>
    <div v-else-if="error" class="state-card" role="alert"><h1>Profil belum tersedia</h1><p>{{ error }}</p><button class="button button--outline" type="button" @click="loadProfile">Coba lagi</button></div>
    <div v-else-if="!player" class="state-card"><h1>Profil tidak ditemukan</h1><p>Profil ini mungkin sudah tidak tersedia.</p><RouterLink class="button button--outline" to="/pilih-game">Pilih game lain</RouterLink></div>
    <template v-else>
      <header class="profile-hero"><div class="profile-hero__identity"><div class="avatar avatar--large" aria-hidden="true"><img v-if="player.avatar_url" :src="player.avatar_url" alt="" /><span v-else>{{ initials }}</span></div><div><h1>{{ player.display_name }}</h1><p class="muted">{{ player.game_name }}<span v-if="player.region"> / {{ player.region }}</span></p><span class="chip" :class="player.ready ? 'chip--ready' : ''">{{ player.ready ? 'Siap mabar' : 'Tidak tersedia' }}</span></div></div><button class="button button--primary" type="button" @click="inviteOpen = !inviteOpen; closeReport(); actionError = ''">Kirim request mabar</button></header>
      <p v-if="notice && !reportSent" class="notice" role="status">{{ notice }}</p>
      <p v-if="actionError && !reportOpen" class="inline-error" role="alert">{{ actionError }}</p>
      <form v-if="inviteOpen" class="action-panel invite-panel" @submit.prevent="submitInvite"><h2>Kirim ajakan mabar</h2><label class="field">Pesan singkat (opsional)<textarea v-model="inviteMessage" maxlength="500" rows="3" placeholder="Sapa pemain ini dulu, yuk."></textarea></label><div class="action-row"><button class="button button--primary" type="submit" :disabled="busy">{{ busy ? 'Mengirim…' : 'Kirim ajakan' }}</button><button class="button button--outline" type="button" @click="inviteOpen = false">Batal</button></div><p class="fine-print">Perlu masuk akun dan verifikasi email untuk mengirim ajakan.</p></form>
      <div class="profile-layout"><div class="profile-main"><section class="content-card"><h2>Tentang pemain</h2><p v-if="player.bio" class="profile-bio">{{ player.bio }}</p><p v-else class="muted">Pemain ini belum menambahkan bio.</p></section><section class="content-card"><h2>Profil game</h2><h3>{{ player.game_name }}</h3><div class="chip-list"><span v-if="player.rank" class="chip chip--violet">{{ player.rank }}</span><span v-if="player.role" class="chip">{{ player.role }}</span><span v-if="player.region" class="chip">{{ player.region }}</span></div><p v-if="updated" class="fine-print">Diperbarui {{ updated }}</p><p v-if="stale" class="fine-print">Profil ini perlu diperbarui.</p><p class="fine-print">Data diisi pengguna, belum terverifikasi. ID game hanya dibagikan oleh pemilik lewat chat setelah ajakan diterima.</p></section></div><aside class="profile-aside"><section class="content-card"><h2>Info singkat</h2><p class="muted">{{ player.ready ? 'Sedang mencari mabar' : 'Belum siap mabar' }}</p><p v-if="player.region">Region pilihan: {{ player.region }}</p><p class="fine-print">Jam aktif dan statistik mabar belum tersedia.</p></section><section class="content-card safety-card"><h2>Jaga ruang mabar</h2><p class="muted">Ada profil yang mengganggu? Laporkan atau blokir pemain ini.</p><div class="safety-actions"><span v-if="reportSent" class="muted">Laporan terkirim</span><button v-else class="text-link text-link--danger" type="button" @click="openReport">Laporkan profil</button><button class="text-link" type="button" :disabled="busy" @click="confirmBlock">Blokir pemain</button></div></section></aside></div>
      <div v-if="reportOpen" class="report-overlay" @click.self="closeReport()"><section ref="reportDialog" class="report-sheet" role="dialog" aria-modal="true" aria-labelledby="report-title" tabindex="-1" @keydown="trapReportFocus"><button type="button" class="report-close" aria-label="Tutup laporan" @click="closeReport()">Tutup</button><template v-if="reportSent"><h2 id="report-title">Laporan diterima</h2><p>{{ notice }}</p><p class="muted">Tim moderasi akan meninjau laporan sesuai antrean. Tidak ada waktu penyelesaian yang dijanjikan.</p><button class="button button--primary" type="button" @click="closeReport()">Selesai</button></template><form v-else @submit.prevent="submitReport"><h2 id="report-title">Kenapa kamu melaporkan profil ini?</h2><p class="muted">Bantu jaga lingkungan mabar tetap nyaman.</p><fieldset class="reason-list"><legend>Alasan laporan</legend><label v-for="option in categories" :key="option.code"><input v-model="category" type="radio" name="category" :value="option.code" required />{{ option.label }}</label></fieldset><label class="field">Detail laporan<textarea v-model="description" minlength="10" maxlength="2000" required rows="4" placeholder="Ceritakan kejadian, minimal 10 karakter."></textarea></label><p v-if="actionError" class="inline-error" role="alert">{{ actionError }}</p><div class="action-row"><button class="button button--outline" type="button" @click="closeReport()">Batal</button><button class="button button--primary" type="submit" :disabled="busy || !category || description.trim().length < 10">{{ busy ? 'Mengirim…' : 'Kirim laporan' }}</button></div></form></section></div>
    </template>
  </main>
</template>
<style scoped>
.profile-page .button{border-radius:999px}.profile-page .profile-hero{background:#242333;border:1px solid #464153;border-radius:24px;box-shadow:none}.profile-page .avatar{border-radius:50%;border-color:#8b7cff}.profile-page .content-card,.profile-page .action-panel{border-radius:22px}.profile-page .chip-list{margin-bottom:16px}.safety-actions{display:flex;flex-wrap:wrap;gap:18px}.report-overlay{position:fixed;inset:0;z-index:50;background:#14141cbb;display:flex;justify-content:center;align-items:flex-end}.report-sheet{background:#1e1e29;border:1px solid #50505f;border-radius:24px 24px 0 0;padding:clamp(20px,4vw,36px);width:min(100%,650px);max-height:90vh;overflow:auto;box-shadow:0 -18px 50px #14141c}.report-close{float:right;background:none;border:0;color:#f5f3ee;font-weight:700}.reason-list{border:0;padding:0;margin:0 0 20px;display:grid;gap:9px}.reason-list legend{font-weight:700;margin-bottom:12px}.reason-list label{border:1px solid #50505f;border-radius:14px;padding:12px;display:flex;gap:10px;cursor:pointer}.reason-list label:has(input:checked){border-color:#8b7cff;background:#302b43}.reason-list input{accent-color:#c8ff4d}.action-row{display:flex;flex-wrap:wrap;gap:10px}.profile-page .profile-bio{white-space:pre-wrap;overflow-wrap:anywhere}@media(max-width:680px){.profile-page .profile-hero{background:#242333}.profile-page .profile-layout{display:block}.profile-page .profile-aside{margin-top:18px}.report-sheet{max-height:94vh}}
</style>
