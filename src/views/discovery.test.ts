import { beforeEach, describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { createSSRApp } from 'vue'
import { createMemoryHistory, createRouter } from 'vue-router'
import { renderToString } from 'vue/server-renderer'
import PlayerCard from '../components/PlayerCard.vue'
import { demoLogin, resetDemo } from '../lib/demo'
import { listGames, listOptions, searchProfiles, profileDetail, ownProfile, updateOwnProfile, ownGameProfiles, saveGameProfile, listInvites, respondInvite, reportUser, blockUser } from '../lib/api'

const source = (name: string) => readFileSync(fileURLToPath(new URL(name, import.meta.url)), 'utf8')
beforeEach(() => resetDemo())
const player = { id: 'profile-0-1', user_id: 'demo-rival', game_id: 'game-valorant', game_name: 'Valorant', display_name: 'Bima', avatar_url: null, ign: 'Bima Demo', rank: 'Gold', role: 'Duelist', region: 'Asia', ready: true, updated_at: new Date().toISOString(), bio: 'Main bareng.' }

describe('discovery, profile, account, and request contracts', () => {
  it('searches per-game catalog rank, role, mode, region without invented numeric filters', async () => {
    const games = await listGames()
    for (const game of games) {
      const options = await listOptions(game.id)
      expect(options.some(o => o.kind === 'rank')).toBe(true)
      expect(options.some(o => o.kind === 'region')).toBe(true)
      expect(options.every(o => o.game_id === game.id)).toBe(true)
      expect((await searchProfiles(game.slug)).every(p => p.game_id === game.id)).toBe(true)
    }
    const view = source('SearchView.vue')
    expect(view).toContain('option.rank_mode_option_id === modeOptions.value.find')
    expect(view).toContain('Pilih mode dulu untuk melihat rank')
    expect(view).not.toMatch(/v-model="draft\.(winRate|mmr|kd|teamSize)"/i)
  })
  it('distinguishes Valorant compact and full query variants using catalog-supported options', () => {
    const view = source('SearchView.vue')
    expect(view).toContain("route.query.variant === 'full'")
    expect(view).toContain('v-if="valorantFull && modeOptions.length"')
    expect(view).toContain('Peran tim belum tersedia sebagai filter')
    expect(view).toContain('Voice chat belum tersedia sebagai filter')
  })
  it('opens report bottom sheet when the profile report query is present', () => {
    const view = source('ProfileView.vue')
    expect(view).toContain("route.query.report === '1'")
    expect(view).toContain('role="dialog"')
  })
  it('never exposes private ID or public in-game name in a search card', async () => {
    const app = createSSRApp(PlayerCard, { player: { ...player, game_id_private: 'SECRET' } })
    app.use(createRouter({ history: createMemoryHistory(), routes: [{ path: '/profil/:id', component: PlayerCard }] }))
    const html = await renderToString(app)
    expect(html).not.toContain('SECRET')
    expect(html).not.toContain('Bima Demo')
    expect(html).toContain('Duelist')
  })
  it('reports through reason selection and offers blocking without a review-time promise', async () => {
    demoLogin('demo-player')
    const detail = await profileDetail('profile-0-1')
    expect(detail?.user_id).toBe('demo-rival')
    const view = source('ProfileView.vue')
    expect(view).toContain('role="dialog"')
    expect(view).toContain('type="radio"')
    expect(view).toContain('description.value.trim().length < 10')
    expect(view).toContain('blockUser(player.value.user_id)')
    expect(view).not.toContain('1x24')
    await reportUser(detail!.user_id, 'harassment', 'Perilaku mengganggu dalam game', detail!.id)
    await blockUser(detail!.user_id)
    expect(await profileDetail(detail!.id)).toBeNull()
  })
  it('updates account profile and game through same demo API used by tabs', async () => {
    demoLogin('demo-player')
    const games = await listGames()
    const account = source('AccountView.vue')
    for (const label of ['Info Umum', 'Profil Game', 'Pengaturan Akun']) expect(account).toContain(label)
    expect(account).toContain('saveGameProfile(')
    await updateOwnProfile('demo-player', { display_name: 'Nama baru' })
    expect((await ownProfile('demo-player') as { display_name: string }).display_name).toBe('Nama baru')
    const profile = (await ownGameProfiles('demo-player'))[0]
    await saveGameProfile({ ign: 'Nama dalam game' }, profile.id)
    expect((await ownGameProfiles('demo-player')).find(p => p.id === profile.id)?.ign).toBe('Nama dalam game')
    expect(games.length).toBeGreaterThan(0)
  })
  it('separates received and sent invites; acceptance does not disclose game ID', async () => {
    demoLogin('demo-player')
    const invites = await listInvites('demo-player')
    const incoming = invites.filter(i => i.recipient_id === 'demo-player')
    const sent = invites.filter(i => i.sender_id === 'demo-player')
    expect(incoming.length).toBeGreaterThan(0)
    expect(sent).toHaveLength(0)
    expect(source('InvitesView.vue')).toContain("tab.value === 'incoming' ? i.recipient_id === userId.value : i.sender_id === userId.value")
    expect(source('InvitesView.vue')).not.toContain('ID Game / Riot ID Terbuka')
    await respondInvite(incoming[0].id, 'accepted')
    expect((await listInvites('demo-player'))[0].status).toBe('accepted')
    expect(JSON.stringify(await listInvites('demo-player'))).not.toContain('DEMO-PRIVATE')
  })
})
