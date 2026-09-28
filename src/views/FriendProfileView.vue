<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import GameLogo from '../components/GameLogo.vue'
import { friendProfile } from '../lib/api'
import type { FriendProfileGame } from '../lib/models'

const route = useRoute()
const friendId = computed(() => String(route.params.id || ''))
const rows = ref<FriendProfileGame[]>([])
const loading = ref(true)
const error = ref('')
const person = computed(() => rows.value[0] || null)
const games = computed(() => rows.value.filter(game => game.game_profile_id))
const initials = computed(() => person.value?.display_name.trim().slice(0, 2).toUpperCase() || 'TM')

async function load() {
  if (!friendId.value) {
    error.value = 'Teman tidak ditemukan.'
    loading.value = false
    return
  }

  loading.value = true
  error.value = ''
  try {
    rows.value = await friendProfile(friendId.value)
    if (!rows.value.length) error.value = 'Detail teman tidak tersedia. Pastikan pertemanan masih aktif.'
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'Detail teman belum bisa dimuat. Coba lagi.'
  } finally {
    loading.value = false
  }
}

watch(friendId, load)
onMounted(load)
</script>

<template>
  <main class="friend-profile page-shell">
    <nav class="breadcrumb" aria-label="Breadcrumb">
      <RouterLink to="/beranda">Beranda</RouterLink><span>/</span>
      <RouterLink to="/teman">Teman</RouterLink><span v-if="person">/</span>
      <strong v-if="person">{{ person.display_name }}</strong>
    </nav>

    <p v-if="loading" role="status" class="state">Memuat profil teman…</p>
    <section v-else-if="error" class="state" role="alert">
      <h1>Profil teman tidak tersedia</h1>
      <p>{{ error }}</p>
      <RouterLink class="button secondary" to="/teman">Kembali ke Teman</RouterLink>
    </section>

    <div v-else-if="person" class="profile-stack">
      <header class="profile-summary surface-card">
        <div class="avatar">
          <img v-if="person.avatar_url" :src="person.avatar_url" alt="" />
          <span v-else>{{ initials }}</span>
        </div>
        <div class="profile-summary__copy">
          <span class="eyebrow">Profil teman</span>
          <h1>{{ person.display_name }}</h1>
          <p>{{ person.bio || 'Belum menambahkan bio.' }}</p>
        </div>
      </header>

      <section class="surface-card contact-card">
        <div class="section-heading">
          <div>
            <span class="eyebrow">Kontak privat</span>
            <h2>Kontak teman</h2>
          </div>
        </div>
        <div class="discord-contact">
          <span class="discord-icon" aria-hidden="true">
            <svg viewBox="0 0 24 24" role="img"><path fill="currentColor" d="M19.5 5.34A17.1 17.1 0 0 0 15.44 4l-.5 1.02a15.6 15.6 0 0 0-5.86 0L8.56 4A17.4 17.4 0 0 0 4.5 5.35C1.93 9.15 1.23 12.85 1.58 16.5a16.6 16.6 0 0 0 4.98 2.5l1.2-1.64a10.8 10.8 0 0 1-1.87-.9l.46-.35c3.6 1.66 7.5 1.66 11.06 0l.48.35c-.6.36-1.24.67-1.88.9L17.2 19a16.5 16.5 0 0 0 4.98-2.5c.42-4.23-.72-7.9-2.68-11.16ZM8.82 14.25c-1.08 0-1.97-1-1.97-2.23s.87-2.24 1.97-2.24c1.1 0 1.99 1.01 1.97 2.24 0 1.23-.87 2.23-1.97 2.23Zm6.36 0c-1.08 0-1.97-1-1.97-2.23s.87-2.24 1.97-2.24c1.1 0 1.99 1.01 1.97 2.24 0 1.23-.87 2.23-1.97 2.23Z" /></svg>
          </span>
          <div class="discord-contact__copy">
            <span>Discord</span>
            <strong>{{ person.discord || 'Belum diisi' }}</strong>
          </div>
        </div>
        <p class="privacy-note">Kontak ini hanya terlihat selama kalian masih berteman.</p>
      </section>

      <section class="surface-card game-section">
        <div class="section-heading">
          <div>
            <span class="eyebrow">Profil game</span>
            <h2>Game yang dimainkan</h2>
          </div>
          <span class="game-count">{{ games.length }} game</span>
        </div>

        <div v-if="!games.length" class="empty-games">
          <strong>Belum ada profil game</strong>
          <p>Profil game aktif dan publik akan tampil di sini.</p>
        </div>

        <div v-else class="games">
          <article v-for="game in games" :key="game.game_profile_id!" class="game-card">
            <div class="game-card__heading">
              <span class="game-card__logo" aria-hidden="true">
                <GameLogo :slug="game.game_slug!" :name="game.game_name!" />
              </span>
              <div class="game-card__title">
                <h3>{{ game.game_name }}</h3>
                <span :class="['availability', { 'availability--ready': game.ready }]">
                  {{ game.ready ? 'Siap mabar' : 'Belum siap mabar' }}
                </span>
              </div>
              <RouterLink class="public-link" :to="`/profil/${game.game_profile_id}`">Lihat profil</RouterLink>
            </div>
            <dl class="game-facts">
              <div><dt>Nama dalam game</dt><dd>{{ game.ign || 'Belum diisi' }}</dd></div>
              <div><dt>ID game</dt><dd>{{ game.game_id_private || 'Belum diisi' }}</dd></div>
              <div v-if="game.rank"><dt>Rank</dt><dd>{{ game.rank }}</dd></div>
              <div v-if="game.role"><dt>Role</dt><dd>{{ game.role }}</dd></div>
              <div v-if="game.region"><dt>Region</dt><dd>{{ game.region }}</dd></div>
            </dl>
          </article>
        </div>
      </section>
    </div>
  </main>
</template>

<style scoped>
.friend-profile{width:min(100% - 48px,1080px);max-width:none;padding-bottom:96px;min-width:0}
.profile-stack{display:grid;gap:20px}
.surface-card,.state{background:#1e1e29;border:1px solid #393944;border-radius:18px}
.profile-summary{display:flex;align-items:center;gap:22px;padding:28px 30px}
.avatar{width:80px;height:80px;flex:none;border-radius:50%;border:2px solid #8b7cff;background:#302b43;display:grid;place-items:center;font-size:1.35rem;font-weight:800;overflow:hidden}
.avatar img{width:100%;height:100%;object-fit:cover}
.profile-summary__copy{min-width:0}
.profile-summary h1{font-size:clamp(2rem,4vw,3rem);line-height:1.08;margin:5px 0 8px;overflow-wrap:anywhere}
.profile-summary p{color:#b8b6c2;line-height:1.6;margin:0}
.eyebrow{color:#aaa8b8;font-size:.72rem;font-weight:800;letter-spacing:.1em;text-transform:uppercase}
.contact-card,.game-section{padding:26px 30px}
.section-heading{display:flex;justify-content:space-between;align-items:center;gap:16px;padding-bottom:20px;border-bottom:1px solid #393944}
.section-heading h2{font-size:1.45rem;margin:5px 0 0}
.discord-contact{display:flex;align-items:center;gap:14px;margin-top:20px;padding:16px;border:1px solid #3d3d4b;border-radius:14px;background:#242431}
.discord-icon{width:44px;height:44px;flex:none;display:grid;place-items:center;border-radius:12px;background:#5865f2;color:white}
.discord-icon svg{width:25px;height:25px}
.discord-contact__copy{display:grid;gap:3px;min-width:0}
.discord-contact__copy span{color:#9694a5;font-size:.78rem;font-weight:700}
.discord-contact__copy strong{font-size:1rem;overflow-wrap:anywhere}
.privacy-note{color:#9694a5;font-size:.82rem;line-height:1.5;margin:12px 0 0}
.game-count{color:#b8b6c2;font-size:.8rem;font-weight:700;white-space:nowrap}
.games{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:16px;margin-top:20px}
.game-card{border:1px solid #444352;border-radius:16px;padding:18px;min-width:0;background:#20202b}
.game-card__heading{display:grid;grid-template-columns:52px minmax(0,1fr) auto;align-items:center;gap:13px;padding-bottom:16px;border-bottom:1px solid #393944}
.game-card__logo{width:52px;height:52px;padding:6px;border-radius:13px;border:1px solid #444352;background:#171720}
.game-card__title{min-width:0}
.game-card h3{font-size:1rem;line-height:1.35;margin:0 0 5px;overflow-wrap:anywhere}
.availability{color:#aaa8b8;font-size:.75rem;font-weight:700}
.availability--ready{color:#4ade80}
.game-facts{margin:4px 0 0}
.game-facts div{display:grid;grid-template-columns:minmax(108px,.8fr) minmax(0,1.2fr);gap:14px;padding:11px 0;border-bottom:1px solid #343440}
.game-facts div:last-child{border-bottom:0;padding-bottom:0}
.game-facts dt{color:#9694a5;font-size:.82rem}
.game-facts dd{margin:0;font-size:.86rem;font-weight:700;text-align:right;overflow-wrap:anywhere}
.public-link{color:#c8ff4d;font-size:.78rem;font-weight:700;white-space:nowrap}
.empty-games{padding:28px 0 4px;color:#b8b6c2}
.empty-games strong{color:#f5f3ee}
.empty-games p{font-size:.88rem;margin:6px 0 0}
.state{margin-top:24px;padding:28px}
.secondary{display:inline-flex;margin-top:12px}
@media(max-width:820px){.games{grid-template-columns:1fr}}
@media(max-width:680px){.friend-profile{width:min(100% - 32px,1080px)}.profile-summary{align-items:flex-start;padding:22px}.avatar{width:68px;height:68px}.contact-card,.game-section{padding:22px}.section-heading{align-items:flex-start}.game-card__heading{grid-template-columns:46px minmax(0,1fr)}.game-card__logo{width:46px;height:46px}.public-link{grid-column:2}.game-facts div{grid-template-columns:1fr;gap:4px}.game-facts dd{text-align:left}}
@media(max-width:440px){.profile-summary{display:grid;gap:14px}.section-heading{display:grid}.discord-contact{align-items:flex-start}}
</style>
