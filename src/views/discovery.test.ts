import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { createSSRApp } from 'vue'
import { createMemoryHistory, createRouter } from 'vue-router'
import { renderToString } from 'vue/server-renderer'
import PlayerCard from '../components/PlayerCard.vue'

const source = (name: string) => readFileSync(fileURLToPath(new URL(name, import.meta.url)), 'utf8')
const player = { id: 'profile-1', user_id: 'user-2', game_id: 'game-1', game_name: 'Valorant', display_name: 'Bima', avatar_url: null, ign: 'Private IGN', rank: 'Gold', role: 'Duelist', region: 'Asia', ready: true, updated_at: new Date().toISOString(), bio: 'Main bareng.' }

describe('production discovery contracts', () => {
  it('uses catalog options and the server-side search RPC; never invents numeric stats', () => {
    const view = source('SearchView.vue')
    expect(view).toContain('listAttributeDefinitions(game.id)')
    expect(view).toContain('searchProfiles(slug.value, applied.value, nextPage)')
    expect(view).toContain('attributes: { ...draft.value.attributes }')
    expect(view).toContain('filter_type')
    expect(view).not.toMatch(/v-model="draft\.(winRate|mmr|kd|teamSize)"/i)
  })
  it('renders only schema-backed filters and omits untrusted global reputation', () => {
    const view = source('SearchView.vue')
    expect(view).toContain('filter_type')
    expect(view).toContain('mabar_rating')
    expect(view).not.toContain('valorantFull')
  })
  it('opens query-linked report sheet with a reason, details, and keyboard access', () => {
    const view = source('ProfileView.vue')
    expect(view).toContain("route.query.report === '1'")
    expect(view).toContain('role="dialog"')
    expect(view).toContain('type="radio"')
    expect(view).toContain('description.value.trim().length < 10')
    expect(view).toContain('blockUser(player.value.user_id)')
    expect(view).not.toContain('1x24')
  })
  it('never exposes private ID or in-game name in a search card', async () => {
    const app = createSSRApp(PlayerCard, { player: { ...player, game_id_private: 'SECRET' } })
    app.use(createRouter({ history: createMemoryHistory(), routes: [{ path: '/profil/:id', component: PlayerCard }] }))
    const html = await renderToString(app)
    expect(html).not.toContain('SECRET')
    expect(html).not.toContain('Private IGN')
    expect(html).toContain('Duelist')
    expect(html).toContain('/profil/profile-1')
  })
  it('saves account details through production API only', () => {
    const account = source('AccountView.vue')
    for (const label of ['Info Umum', 'Profil Game', 'Pengaturan Akun']) expect(account).toContain(label)
    expect(account).toContain('saveGameProfile(')
    expect(account).toContain('updateOwnProfile(')
    expect(account).not.toContain('demoMode')
  })
  it('separates invites and targets invite reports correctly without exposing private ID', () => {
    const view = source('InvitesView.vue')
    expect(view).toContain("tab.value === 'incoming' ? i.recipient_id === userId.value : i.sender_id === userId.value")
    expect(view).toContain("reportUser(other, category.value, description.value.trim(), reportInvite.value.id, 'invite')")
    expect(view).not.toContain('ID Game / Riot ID Terbuka')
    expect(view).not.toContain('game_id_private')
  })
})
