<script setup lang="ts">
import { computed, onMounted, onServerPrefetch, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { listGames, listInvites, listOptions, ownGameProfiles, ownProfile, searchProfiles } from '../lib/api'
import type { Game, GameProfile, Invite, Option, Player } from '../lib/models'
import { useSessionStore } from '../stores/session'
import { configured } from '../lib/supabase'

const session = useSessionStore()
const games = ref<Game[]>([]), profiles = ref<GameProfile[]>([]), invites = ref<Invite[]>([])
const recommendations = ref<Player[]>([]), options = ref<Option[]>([])
const name = ref(''), loading = ref(true), error = ref('')
const incoming = computed(() => invites.value.filter(i => i.recipient_id === session.user?.id && i.status === 'pending' && new Date(i.expires_at).getTime() > Date.now()))
const recent = computed(() => invites.value.slice(0, 4))
const gameName = (id: string) => games.value.find(game => game.id === id)?.name || 'Game'
const optionLabel = (id: string | null) => options.value.find(option => option.id === id)?.label || ''
const inviteStatus = (invite: Invite) => invite.status === 'pending' && new Date(invite.expires_at).getTime() <= Date.now() ? 'Kedaluwarsa' : ({ pending: 'Menunggu', accepted: 'Diterima', rejected: 'Ditolak', cancelled: 'Dibatalkan', expired: 'Kedaluwarsa' } as Record<string,string>)[invite.status] || invite.status
const dateLabel = (value: string) => new Date(value).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })
async function load() {
  const id = session.user?.id
  if (!configured || !id) { loading.value = false; return }
  loading.value = true; error.value = ''
  try {
    const [person, catalog, owned, requests] = await Promise.all([ownProfile(id), listGames(), ownGameProfiles(id), listInvites(id)])
    name.value = String((person as unknown as { display_name?: string })?.display_name || session.user?.user_metadata?.display_name || 'Teman')
    games.value = catalog; profiles.value = owned.filter(p => p.status === 'active'); invites.value = requests
    const [optionResults, candidateResults] = await Promise.all([
      Promise.allSettled(profiles.value.map(profile => listOptions(profile.game_id))),
      Promise.allSettled([...new Set(profiles.value.map(p => p.game_id))].map(async gameId => {
        const game = catalog.find(g => g.id === gameId)
        return game ? searchProfiles(game.slug, {}, 0) : []
      })),
    ])
    options.value = optionResults.flatMap(result => result.status === 'fulfilled' ? result.value : [])
    const unique = new Set<string>()
    recommendations.value = candidateResults.flatMap(result => result.status === 'fulfilled' ? result.value : [])
      .filter(player => { if (player.user_id === id || unique.has(player.user_id)) return false; unique.add(player.user_id); return true }).slice(0, 5)
  } catch { error.value = 'Ringkasan belum bisa dimuat. Coba lagi, ya.' }
  finally { loading.value = false }
}
onMounted(load)
onServerPrefetch(load)
</script>

<template>
  <main class="dashboard">
    <div class="dashboard-inner">
      <header class="dashboard-heading"><div><h1>Beranda, {{ name || 'Teman' }}!</h1><p>Profil game dan ajakan mabar kamu ada di sini.</p></div><div class="heading-actions"><RouterLink class="request-pill" to="/request-mabar"><strong>{{ incoming.length }}</strong> Permintaan Masuk</RouterLink><RouterLink class="primary" to="/pilih-game">Cari Teman Mabar</RouterLink></div></header>
      <p v-if="!configured" class="state" role="alert">Layanan belum dikonfigurasi.</p>
      <p v-else-if="!session.user" class="state">Silakan <RouterLink to="/login">masuk</RouterLink> untuk melihat beranda pribadi.</p>
      <p v-else-if="loading" class="state" role="status">Memuat beranda…</p>
      <div v-else-if="error" class="state" role="alert"><p>{{ error }}</p><button type="button" class="secondary" @click="load">Coba lagi</button></div>
      <template v-else>
        <section class="profile-section" aria-labelledby="my-games"><div class="section-heading"><h2 id="my-games">Profil Game Kamu</h2><span>{{ profiles.length }} Game Terhubung</span></div>
          <div class="profile-grid"><article v-for="profile in profiles" :key="profile.id" class="profile-card"><div class="profile-top"><span class="game-icon" aria-hidden="true">{{ gameName(profile.game_id).charAt(0) }}</span><div><h3>{{ gameName(profile.game_id) }}</h3><span class="ign">{{ profile.ign }}</span></div><span v-if="optionLabel(profile.primary_rank_option_id)" class="rank">{{ optionLabel(profile.primary_rank_option_id) }}</span></div><dl><div v-if="optionLabel(profile.primary_role_option_id)"><dt>Role</dt><dd>{{ optionLabel(profile.primary_role_option_id) }}</dd></div><div v-if="optionLabel(profile.region_option_id)"><dt>Server</dt><dd>{{ optionLabel(profile.region_option_id) }}</dd></div></dl><RouterLink class="card-link" to="/profil-saya#profil-game">Edit profil game</RouterLink></article>
            <RouterLink class="add-card" to="/profil-saya#profil-game"><span class="plus" aria-hidden="true">+</span><strong>Tambah Profil Game</strong><span>Lengkapi game lain yang kamu mainkan</span></RouterLink>
          </div>
          <p class="disclaimer">Rank, role, dan server diisi pengguna, belum terverifikasi. ID game tetap privat.</p>
        </section>
        <div class="dashboard-columns"><section aria-labelledby="recommendations"><div class="section-heading"><h2 id="recommendations">Rekomendasi Teman Mabar</h2><span>Berdasarkan game yang sama</span></div>
          <div v-if="recommendations.length" class="candidate-list"><article v-for="player in recommendations" :key="player.id" class="candidate"><div class="avatar" aria-hidden="true">{{ player.display_name.charAt(0) }}</div><div class="candidate-info"><div class="candidate-heading"><h3>{{ player.display_name }}</h3><span v-if="player.rank" class="rank">{{ player.rank }}</span></div><div class="candidate-meta"><span>{{ player.game_name }}</span><span v-if="player.role">{{ player.role }}</span><span v-if="player.region">{{ player.region }}</span><span v-if="player.ready" class="ready">Siap mabar</span></div></div><RouterLink class="primary small" :to="`/profil/${encodeURIComponent(player.id)}`">Lihat Profil</RouterLink></article></div>
          <div v-else class="state"><h3>Belum ada rekomendasi</h3><p>Lengkapi profil game kamu dulu, biar kami bisa menampilkan pemain dengan game yang sama.</p><RouterLink class="primary" to="/profil-saya#profil-game">Lengkapi Profil Game</RouterLink></div>
          <RouterLink class="more-link" to="/pilih-game">Jelajahi semua game</RouterLink>
        </section>
        <aside><div class="section-heading"><h2>Request Mabar Terbaru</h2><RouterLink to="/request-mabar">Lihat semua</RouterLink></div><div class="request-panel"><template v-if="recent.length"><div v-for="invite in recent" :key="invite.id" class="request-row"><div><strong>{{ invite.recipient_id === session.user?.id ? 'Ajakan masuk' : 'Ajakan terkirim' }}</strong><p>{{ gameName(invite.game_id) }}</p><time :datetime="invite.created_at">{{ dateLabel(invite.created_at) }}</time></div><span class="status" :class="`status--${invite.status}`">{{ inviteStatus(invite) }}</span></div></template><p v-else class="empty">Belum ada request mabar. Kenalan dengan pemain baru, yuk.</p><RouterLink v-if="incoming.length" class="secondary full" to="/request-mabar">Tanggapi Ajakan</RouterLink></div>
          <div class="tip-card"><div class="tip-icon" aria-hidden="true"><svg viewBox="0 0 64 64" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round"><path d="M12 36C12 20 21 12 32 12s20 8 20 24M16 43h-3a5 5 0 0 1-5-5v-5a5 5 0 0 1 5-5h3m32 15h3a5 5 0 0 0 5-5v-5a5 5 0 0 0-5-5h-3"/><rect x="18" y="22" width="28" height="27" rx="8"/><path d="M26 34h1m10 0h1m-10 8c2 2 6 2 8 0"/></svg></div><h3>Mau rekomendasi lebih akurat?</h3><p>Lengkapi profil game kamu dulu, biar kami carikan teman mabar yang pas.</p><RouterLink class="secondary full" to="/profil-saya#profil-game">Perbarui Preferensi Game</RouterLink></div>
        </aside></div>
      </template>
    </div>
  </main>
</template>

<style scoped>
.dashboard{background:#14141c;color:#f5f3ee;padding:36px 0 80px}.dashboard-inner{width:min(100% - 48px,1250px);margin:auto}.dashboard-heading,.heading-actions,.section-heading,.profile-top,.candidate,.candidate-heading,.candidate-meta,.request-row{display:flex;align-items:center;gap:14px}.dashboard-heading,.section-heading,.request-row{justify-content:space-between}.dashboard-heading{margin-bottom:36px;align-items:flex-start}.dashboard h1{font:800 clamp(27px,3.5vw,36px)/1.2 'Plus Jakarta Sans',sans-serif;margin:0 0 7px}.dashboard h2{font:700 clamp(18px,2vw,22px) 'Plus Jakarta Sans',sans-serif;margin:0}.dashboard h3{font:700 17px 'Plus Jakarta Sans',sans-serif;margin:0}.dashboard p{color:#a0a0b2;margin:0;line-height:1.5}.heading-actions{flex-wrap:wrap}.primary,.secondary,.request-pill{display:inline-flex;align-items:center;justify-content:center;min-height:44px;padding:10px 18px;border-radius:999px;text-align:center;text-decoration:none;font-weight:700;font-size:13px;border:1px solid transparent}.primary{background:#c8ff4d;color:#14141c}.primary:hover{background:#d9ff80}.secondary{background:#272736;color:#f5f3ee;border-color:#3a3a49}.secondary:hover{border-color:#c8ff4d}.request-pill{background:#1e1e29;color:#f5f3ee;border-color:#2e2e3e;gap:8px}.request-pill strong{display:grid;place-items:center;min-width:26px;height:26px;border-radius:50%;background:#c8ff4d;color:#14141c}.section-heading{margin-bottom:17px;flex-wrap:wrap}.section-heading span,.section-heading a{color:#a0a0b2;font-size:12px}.section-heading a:hover,.more-link:hover{color:#c8ff4d}.profile-section{margin-bottom:35px}.profile-grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:14px}.profile-card,.add-card,.candidate,.request-panel,.tip-card,.state{background:#1e1e29;border:1px solid #2e2e3e;border-radius:20px}.profile-card{min-width:0;padding:19px;display:flex;flex-direction:column;gap:18px}.profile-top{align-items:flex-start;flex-wrap:wrap;gap:10px}.profile-top>div{min-width:0;flex:1}.profile-top h3{overflow-wrap:anywhere}.ign{color:#a0a0b2;font-size:12px}.game-icon{flex:none;display:grid;place-items:center;width:42px;height:42px;border-radius:50%;background:#272736;color:#c8ff4d;font-weight:800}.rank{font-size:11px;white-space:nowrap;padding:5px 9px;background:#332d4c;color:#c7bfff;border-radius:999px;font-weight:700}.profile-card dl{margin:0;display:grid;gap:7px}.profile-card dl div{display:flex;justify-content:space-between;gap:9px;font-size:12px}.profile-card dt{color:#a0a0b2}.profile-card dd{margin:0;text-align:right;overflow-wrap:anywhere}.card-link{border-top:1px solid #2e2e3e;padding-top:12px;color:#c8ff4d;font-size:12px;font-weight:700}.add-card{border:2px dashed #484858;background:#1b1b25;padding:24px;display:flex;flex-direction:column;justify-content:center;align-items:center;gap:10px;text-align:center}.add-card:hover{border-color:#c8ff4d}.add-card span:last-child{color:#a0a0b2;font-size:12px}.plus{display:grid;place-items:center;width:48px;height:48px;border-radius:50%;background:#272736;color:#c8ff4d;font-size:32px}.disclaimer{font-size:12px;margin-top:10px!important}.dashboard-columns{display:grid;grid-template-columns:minmax(0,2fr) minmax(270px,1fr);gap:25px}.candidate-list{display:grid;gap:10px}.candidate{padding:17px;flex-wrap:wrap}.avatar{width:48px;height:48px;border:2px solid #8b7cff;border-radius:50%;display:grid;place-items:center;flex:none;background:#272736;color:#c7bfff;font-weight:800}.candidate-info{flex:1;min-width:160px}.candidate-heading{gap:8px;flex-wrap:wrap;margin-bottom:5px}.candidate-meta{gap:8px;flex-wrap:wrap;color:#a0a0b2;font-size:12px}.candidate-meta span:not(:last-child):after{content:''}.ready{color:#4ade80}.small{min-height:36px;padding:7px 13px}.more-link{display:inline-block;margin-top:17px;font-weight:700;font-size:13px;color:#f5f3ee}.request-panel{padding:20px}.request-row{gap:10px;border-bottom:1px solid #34343d;padding:13px 0;align-items:flex-start}.request-row:first-child{padding-top:0}.request-row:last-of-type{border-bottom:0}.request-row strong{font-size:13px}.request-row p,.request-row time{font-size:12px;color:#a0a0b2}.status{padding:5px 9px;border-radius:999px;background:#34343d;color:#f5f3ee;font-size:11px;font-weight:700}.status--accepted{background:#254332;color:#4ade80}.status--rejected{background:#452d32;color:#ff9b91}.status--pending{background:#343a25;color:#c8ff4d}.full{width:100%;margin-top:13px}.empty{font-size:13px}.tip-card{margin-top:17px;padding:26px;text-align:center}.tip-card p{font-size:13px;margin:9px 0}.tip-icon{width:74px;height:74px;background:#272736;color:#c8ff4d;border-radius:50%;display:grid;place-items:center;margin:0 auto 15px}.tip-icon svg{width:50px}.state{padding:25px}.state h3{margin-bottom:8px}.state .primary{margin-top:14px}@media(max-width:1020px){.profile-grid{grid-template-columns:repeat(2,minmax(0,1fr))}.dashboard-columns{grid-template-columns:1fr}}@media(max-width:600px){.dashboard-inner{width:min(100% - 32px,1250px)}.dashboard-heading{flex-direction:column}.profile-grid{grid-template-columns:1fr}.heading-actions{width:100%}.candidate{align-items:flex-start}.candidate .small{margin-left:62px}.dashboard-columns{gap:36px}}
</style>