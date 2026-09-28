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
    expect(view).toContain('searchableProfileFields')
    expect(view).not.toContain('valorantFull')
  })
  it('opens query-linked report sheet with a reason, details, and keyboard access', () => {
    const view = source('ProfileView.vue')
    expect(view).toContain("route.query.report === '1'")
    expect(view).toContain('role="dialog"')
    expect(view).toContain('type="radio"')
    expect(view).toContain('description.value.trim().length < 10')
    expect(view).toContain('blockUser(player.value.user_id)')
    expect(view).toContain("modalMode === 'block'")
    expect(view).not.toContain('window.confirm')
    expect(view).not.toContain('Tambah teman')
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
  it('keeps Discord in the owned profile and restricts contact display to accepted friends', () => {
    const account = source('AccountView.vue')
    const profile = source('ProfileView.vue')
    const chat = source('ChatView.vue')
    expect(account).toContain('v-model="discord"')
    expect(account).toContain('discord:discord.value.trim() || null')
    expect(account).toContain('v-if="session.verified" class="verification-badge verification-badge--verified"')
    expect(account).toContain('Email terverifikasi')
    expect(account).toContain('v-else class="verification-badge"')
    expect(account).toContain('Segera verifikasi email')
    expect(account).toContain('<select v-model="timezone"')
    expect(account).toContain('<select v-model="language"')
    expect(account).not.toContain('Bahasa (pisahkan koma)')
    expect(profile).toContain("friendship?.status === 'accepted' && contact")
    expect(profile).toContain("requestFriend(player.value.user_id)")
    expect(profile).toContain('Kirim permintaan teman')
    expect(profile).toContain('Permintaan teman terkirim. Pantau statusnya di Teman.')
    expect(profile).not.toContain('createMabarRequest(')
    expect(profile).not.toContain('createInvite(')
    expect(profile).not.toContain('Request mabar terkirim')
    expect(profile).not.toContain('Kirim request mabar')
    expect(chat).not.toContain('readSharedGameId(')
    expect(chat).not.toContain('shareGameId(')
  })
  it('saves account details through production API only', () => {
    const account = source('AccountView.vue')
    for (const label of ['Info Umum', 'Profil Game', 'Pengaturan Akun']) expect(account).toContain(label)
    expect(account).toContain('saveGameProfile(')
    expect(account).toContain('deleteGameProfile(')
    expect(account).toContain('Tambah profil game')
    expect(account).toContain('Hapus profil')
    expect(account).toContain('updateOwnProfile(')
    expect(account).not.toContain('remainingGames')
    expect(account).not.toContain('demoMode')
  })
  it('links accepted friends to their private friend profile and pending requests to public profiles', () => {
    const view = source('FriendsView.vue')
    expect(view).toContain(':to="`/teman/${other(item)}`"')
    expect(view).toContain(':to="`/profil/${player(item)?.game_profile_id}`"')
    expect(view).toContain('class="friend-card"')
    expect(view).toContain('Lihat profil')
    expect(view).toContain('Kontak privat tersedia')
    expect(view).not.toContain('/profil-pemain/')
  })
  it('renders accepted-friend contact details from the protected friend profile RPC', () => {
    const view = source('FriendProfileView.vue')
    expect(view).toContain('friendProfile(friendId.value)')
    for (const label of ['Nama dalam game', 'ID game', 'Discord']) expect(view).toContain(label)
  })
})
