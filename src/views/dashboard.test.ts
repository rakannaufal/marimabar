import { afterEach, beforeEach, describe, expect, it } from 'vitest'
import { createSSRApp } from 'vue'
import { renderToString } from '@vue/server-renderer'
import { createPinia } from 'pinia'
import { createMemoryHistory, createRouter } from 'vue-router'
import { demoBackend, demoLogin, resetDemo } from '../lib/demo'
import { useSessionStore } from '../stores/session'
import GamePickerView from './GamePickerView.vue'
import DashboardView from './DashboardView.vue'
import CommunityView from './CommunityView.vue'

async function html(component: typeof GamePickerView | typeof DashboardView | typeof CommunityView, persona = 'demo-player') {
  demoLogin(persona)
  const router = createRouter({ history: createMemoryHistory(), routes: [
    { path: '/pilih-game', component: { template: '<div />' } },
    { path: '/beranda', component: { template: '<div />' } },
    { path: '/komunitas', component: { template: '<div />' } },
    { path: '/cari/:gameSlug', component: { template: '<div />' } },
    { path: '/profil/:id', component: { template: '<div />' } },
    { path: '/profil-saya', component: { template: '<div />' } },
    { path: '/request-mabar', component: { template: '<div />' } },
  ] })
  const app = createSSRApp(component).use(createPinia()).use(router)
  const session = useSessionStore(app._context.provides.pinia)
  await session.initialize()
  await router.push('/beranda'); await router.isReady()
  return renderToString(app)
}
beforeEach(() => resetDemo())
afterEach(() => resetDemo())

describe('Pilih Game', () => {
  it('lists catalog games and links each to its actual search slug', async () => {
    const view = await html(GamePickerView)
    expect(view).toContain('Mau main apa hari ini?')
    for (const slug of ['mlbb', 'valorant', 'pubg-mobile', 'free-fire']) expect(view).toContain(`/cari/${slug}`)
    expect(view).not.toContain('4.820')
  })
})

describe('Beranda pribadi', () => {
  it('shows own profiles, invite count, real candidate links without revealing private IDs', async () => {
    const view = await html(DashboardView)
    expect(view).toContain('Naya (pemain)')
    expect(view).toMatch(/<strong[^>]*>1<\/strong> Permintaan Masuk/)
    expect(view).toContain('Bima (pemain)')
    expect(view).toContain('/profil/profile-0-1')
    expect(view).not.toContain('DEMO-PRIVATE')
    expect(view).not.toContain('Kompatibel 98%')
  })
  it('updates counts when an invite is accepted, without inventing activity', async () => {
    demoLogin('demo-player')
    await demoBackend.rpc('respond_invite', { p_id: 'invite-seeded', p_accept: true })
    const view = await html(DashboardView)
    expect(view).toMatch(/<strong[^>]*>0<\/strong> Permintaan Masuk/)
    expect(view).toContain('Diterima')
    expect(view).not.toContain('5 menit lalu')
  })
})

describe('Beranda komunitas', () => {
  it('shows catalog-backed game filters, player profiles and personal dashboard CTA without fictitious lobbies', async () => {
    const view = await html(CommunityView)
    expect(view).toContain('Selamat datang kembali, Naya (pemain)!')
    expect(view).toContain('Jelajah Teman Mabar')
    expect(view).toContain('/cari/mlbb')
    expect(view).toContain('/beranda')
    expect(view).not.toContain('3.420 lobi')
    expect(view).not.toContain('Pemain Terhubung')
    expect(view).not.toContain('Weekend Scrim')
    expect(view).not.toContain('Bima Demo')
    expect(view).not.toContain('DEMO-PRIVATE')
  })
})
