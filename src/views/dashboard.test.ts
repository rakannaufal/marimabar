import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createSSRApp } from 'vue'
import { renderToString } from '@vue/server-renderer'
import { createPinia } from 'pinia'
import { createMemoryHistory, createRouter } from 'vue-router'
import type { User } from '@supabase/supabase-js'
import GamePickerView from './GamePickerView.vue'
import DashboardView from './DashboardView.vue'
import CommunityView from './CommunityView.vue'
import HomeView from './HomeView.vue'
import { useSessionStore } from '../stores/session'

const mocks = vi.hoisted(() => ({
  configured: false,
  listGames: vi.fn(), listInvites: vi.fn(), listOptions: vi.fn(),
  ownGameProfiles: vi.fn(), ownProfile: vi.fn(), searchProfiles: vi.fn(),
}))
vi.mock('../lib/supabase', () => ({ get configured() { return mocks.configured }, supabase: null }))
vi.mock('../lib/api', () => mocks)

const games = [{ id: 'game-1', name: 'Valorant', slug: 'valorant' }]
const player = { id: 'public-profile', user_id: 'other', game_id: 'game-1', game_name: 'Valorant', display_name: 'Rekan', updated_at: '2026-01-01', ready: true }
const components = [HomeView, GamePickerView, DashboardView, CommunityView] as const
async function html(component: (typeof components)[number], signedIn = false) {
  const router = createRouter({ history: createMemoryHistory(), routes: [
    { path: '/', component }, { path: '/login', component: { template: '<div />' } },
    { path: '/beranda', component: { template: '<div />' } },
    { path: '/pilih-game', component: { template: '<div />' } },
    { path: '/profil-saya', component: { template: '<div />' } },
    { path: '/request-mabar', component: { template: '<div />' } },
    { path: '/profil/:id', component: { template: '<div />' } },
    { path: '/cari/:gameSlug', component: { template: '<div />' } },
  ] })
  const app = createSSRApp(component).use(createPinia()).use(router)
  if (signedIn) useSessionStore(app._context.provides.pinia).user = { id: 'owner', email_confirmed_at: '2026-01-01' } as User
  await router.push('/'); await router.isReady()
  return renderToString(app)
}
beforeEach(() => {
  vi.clearAllMocks()
  mocks.configured = false
  mocks.listGames.mockResolvedValue(games)
  mocks.searchProfiles.mockResolvedValue([player])
  mocks.ownProfile.mockResolvedValue({ display_name: 'Pemilik' })
  mocks.ownGameProfiles.mockResolvedValue([{ id: 'owned', game_id: 'game-1', status: 'active' }])
  mocks.listInvites.mockResolvedValue([])
  mocks.listOptions.mockResolvedValue([])
})

describe('production-only views', () => {
  it.each(components.map((component, index) => [index, component] as const))('shows unconfigured state without fetching fixture data (%i)', async (_index, component) => {
    const view = await html(component, true)
    expect(view).toContain('Layanan belum dikonfigurasi.')
    expect(view).not.toContain('/cari/valorant')
    expect(mocks.listGames).not.toHaveBeenCalled()
    expect(mocks.searchProfiles).not.toHaveBeenCalled()
  })

  it('renders catalog-backed game links when configured', async () => {
    mocks.configured = true
    expect(await html(GamePickerView)).toContain('/cari/valorant')
    expect(await html(HomeView)).toContain('/cari/valorant')
    expect(mocks.listGames).toHaveBeenCalledTimes(2)
  })

  it('renders own dashboard data without private IDs', async () => {
    mocks.configured = true
    const view = await html(DashboardView, true)
    expect(view).toContain('Pemilik')
    expect(view).toContain('/profil/public-profile')
    expect(view).not.toContain('private-game-id')
    expect(mocks.listInvites).toHaveBeenCalledWith('owner')
  })

  it('renders public community profiles from search', async () => {
    mocks.configured = true
    const view = await html(CommunityView, true)
    expect(view).toContain('Rekan')
    expect(view).toContain('/profil/public-profile')
    expect(mocks.searchProfiles).toHaveBeenCalledWith('valorant')
  })
})
