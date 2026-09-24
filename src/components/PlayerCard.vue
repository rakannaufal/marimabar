<script setup lang="ts">
import { RouterLink } from 'vue-router'
import type { Player } from '../lib/models'
defineProps<{ player: Player }>()
const initials = (name: string) => name.trim().slice(0, 2).toUpperCase() || 'TM'
const stale = (value: string) => { const time = Date.parse(value); return Number.isFinite(time) && Date.now() - time > 30 * 86400000 }
const detailPath = (id: string) => `/profil/${encodeURIComponent(id)}`
</script>
<template>
  <article class="player-card">
    <div class="player-card__identity"><div class="avatar" aria-hidden="true"><img v-if="player.avatar_url" :src="player.avatar_url" alt="" loading="lazy" /><span v-else>{{ initials(player.display_name || '') }}</span></div>
      <div class="player-card__body"><div class="player-card__title"><h3><RouterLink :to="detailPath(player.id)">{{ player.display_name }}</RouterLink></h3><span v-if="player.ready" class="ready-indicator"><span class="status-dot" aria-hidden="true"></span> Siap mabar</span></div><p class="muted">{{ player.game_name }}</p><div class="chip-list"><span v-if="player.rank" class="chip chip--violet">{{ player.rank }}</span><span v-if="player.role" class="chip">{{ player.role }}</span><span v-if="player.region" class="chip">{{ player.region }}</span><span v-if="stale(player.updated_at)" class="chip">Perlu diperbarui</span></div></div>
    </div>
    <RouterLink class="button button--outline player-card__action" :to="detailPath(player.id)">Lihat profil dan ajak mabar</RouterLink>
  </article>
</template>
<style scoped>
.player-card{border-radius:22px;border:1px solid #393944;background:#1e1e29;padding:22px;display:flex;align-items:center;justify-content:space-between;gap:18px}.player-card__identity{display:flex;align-items:center;gap:16px;min-width:0}.player-card__body{min-width:0}.player-card__title{display:flex;align-items:center;flex-wrap:wrap;gap:12px}.player-card__title h3{margin:0}.player-card__body p{margin:4px 0 0}.player-card .avatar{border-radius:50%;border:3px solid #8b7cff;flex:none}.player-card__action{border-radius:999px;white-space:normal}.ready-indicator{display:inline-flex;align-items:center;gap:5px;color:#4ade80;font-size:.8rem}.status-dot{width:7px;height:7px;border-radius:50%;background:#4ade80;box-shadow:none}.chip-list{margin-top:10px}@media(max-width:900px){.player-card{align-items:flex-start;flex-direction:column}.player-card__action{margin-left:0;align-self:flex-start}}@media(max-width:440px){.player-card__identity{align-items:flex-start}.player-card__action{width:100%}}
</style>
