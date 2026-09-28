import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createSSRApp } from 'vue'
import { renderToString } from '@vue/server-renderer'
import { createPinia } from 'pinia'
import { createMemoryHistory, createRouter } from 'vue-router'
import type { User } from '@supabase/supabase-js'
import DashboardView from './DashboardView.vue'
import ProfileView from './ProfileView.vue'
import PlayerCard from '../components/PlayerCard.vue'
import { useSessionStore } from '../stores/session'

const mocks = vi.hoisted(() => ({
  configured: true,
  listGames: vi.fn(), listFriendRequests: vi.fn(), listOptions: vi.fn(), ownGameProfiles: vi.fn(),
  ownProfile: vi.fn(), searchProfiles: vi.fn(), profileDetail: vi.fn(),
}))
vi.mock('../lib/supabase', () => ({ get configured() { return mocks.configured }, supabase: null }))
vi.mock('../lib/api', () => mocks)
const player = { id: 'public', user_id: 'other', game_id: 'g', game_name: 'Mobile Legends', display_name: 'Rekan',
  avatar_url: null, ign: 'SECRET IGN', rank: 'Epic', role: 'Roam', region: 'SEA', ready: true,
  updated_at: '2026-09-01', bio: null, attributes: { position_secondary: 'Gold Lane', game_id_private: 'SECRET ID' } }
async function render(component: object, path = '/profil/public', props: Record<string, unknown> = {}) {
  const router = createRouter({ history: createMemoryHistory(), routes: [
    { path: '/profil/:id', component: ProfileView }, { path: '/profil-saya', component: DashboardView },
    { path: '/pilih-game', component: DashboardView }, { path: '/request-mabar', component: DashboardView },
    { path: '/', component: DashboardView }, { path: '/login', component: DashboardView },
  ] })
  await router.push(path); await router.isReady()
  const pinia = createPinia()
  const app = createSSRApp(component, props).use(pinia).use(router)
  useSessionStore(pinia).user = { id: 'owner', email_confirmed_at: '2026-01-01' } as User
  return renderToString(app)
}
beforeEach(() => {
  vi.clearAllMocks()
  mocks.listGames.mockResolvedValue([{ id: 'g', slug: 'mlbb', name: 'Mobile Legends' }])
  mocks.listOptions.mockResolvedValue([
    { id: 'rank', game_id: 'g', kind: 'rank', code: 'epic', label: 'Epic' },
    { id: 'role', game_id: 'g', kind: 'role', code: 'tank', label: 'Tank' },
  ])
  mocks.ownGameProfiles.mockResolvedValue([{ id: 'mine', game_id: 'g', status: 'active', ign: 'PRIVATE IGN', game_id_private: 'OWNER SECRET', primary_rank_option_id: 'rank', primary_role_option_id: 'role', attributes: { position_main: 'Roam', position_secondary: 'Gold Lane' } }])
  mocks.ownProfile.mockResolvedValue({ display_name: 'Pemilik' })
  mocks.listFriendRequests.mockResolvedValue([])
  mocks.searchProfiles.mockResolvedValue([player])
  mocks.profileDetail.mockResolvedValue(player)
})
describe('game facts views', () => {
  it('public detail shows canonical facts, never private IGN or ID', async () => {
    const html = await render(ProfileView)
    expect(html).toContain('Posisi utama')
    expect(html).toContain('Gold Lane')
    expect(html).toContain('Epic')
    expect(html).not.toContain('SECRET IGN')
    expect(html).not.toContain('SECRET ID')
  })
  it('redirects an authenticated user away from their own public profile', async () => {
    mocks.profileDetail.mockResolvedValue({ ...player, user_id: 'owner' })
    const html = await render(ProfileView)
    expect(html).toContain('Membuka Profil Saya')
    expect(html).not.toContain('Kirim request mabar')
    expect(html).not.toContain('Laporkan profil')
    expect(html).not.toContain('Blokir pemain')
  })
  it('search card shows canonical rank and role, never IGN or private ID', async () => {
    const html = await render(PlayerCard, '/profil/public', { player })
    expect(html).toContain('Epic')
    expect(html).toContain('Roam')
    expect(html).toContain('Gold Lane')
    expect(html).not.toContain('SECRET IGN')
    expect(html).not.toContain('SECRET ID')
  })
  it('owner dashboard shows canonical positions and catalog rank; recommendations show RPC facts', async () => {
    const html = await render(DashboardView, '/')
    expect(html).toContain('Posisi utama')
    expect(html).toContain('Gold Lane')
    expect(html).toContain('Epic')
    expect(html).not.toContain('OWNER SECRET')
    expect(html).not.toContain('SECRET IGN')
  })
})
