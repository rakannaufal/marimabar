import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createSSRApp, type Component } from 'vue'
import { renderToString } from '@vue/server-renderer'
import { createPinia } from 'pinia'
import { createMemoryHistory, createRouter } from 'vue-router'
import { useSessionStore } from '../stores/session'
import Statistics from './AdminStatisticsView.vue'
import Games from './AdminGamesView.vue'
import Attributes from './AdminAttributesView.vue'
import Users from './AdminUsersView.vue'
import Reports from './AdminReportsView.vue'

// SSR does not invoke onMounted. These contracts verify the guarded UI; SQL
// authorization is exercised separately by the migration smoke tests.
const backend = vi.hoisted(() => ({ requireBackend: vi.fn(), supabase: {} }))
vi.mock('../lib/supabase', () => backend)

beforeEach(() => backend.requireBackend.mockClear())

async function html(component: Component, admin: boolean) {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/', component: { template: '<div />' } },
      { path: '/profil/:id', component: { template: '<div />' } },
      ...['statistik', 'game', 'atribut-game', 'user', 'laporan'].map(path => ({
        path: `/admin/${path}`, component: { template: '<div />' },
      })),
    ],
  })
  const pinia = createPinia()
  const app = createSSRApp(component).use(pinia).use(router)
  const session = useSessionStore(pinia)
  session.user = { id: admin ? 'admin-id' : 'player-id' } as typeof session.user
  session.admin = admin
  session.loading = false
  await router.push('/')
  await router.isReady()
  return renderToString(app)
}

describe('production admin page contracts', () => {
  it.each([Statistics, Games, Attributes, Users, Reports])('denies admin content to non-admins', async page => {
    const view = await html(page, false)
    expect(view).toContain('Akses ditolak')
    expect(view).not.toContain('Admin Panel')
    expect(backend.requireBackend).not.toHaveBeenCalled()
  })
  it('does not invent growth metrics', async () => {
    const view = await html(Statistics, true)
    expect(view).toContain('Tidak tersedia')
    expect(view).not.toContain('18,4%')
    expect(view).not.toContain('Data sintetis')
  })
  it('disables unsupported game creation and deletion', async () => {
    const view = await html(Games, true)
    expect(view).toMatch(/disabled[^>]*>Tambah Game/)
    expect(view).toContain('belum didukung')
    expect(view).toContain('penghapusan game belum didukung')
  })
  it('only offers supported option creation', async () => {
    const view = await html(Attributes, true)
    expect(view).toContain('Kelola Skema Atribut Game')
    expect(view).not.toContain('Simpan Perubahan Skema')
  })
  it('offers schema metadata management for game attributes', async () => {
    const view = await html(Attributes, true)
    expect(view).toContain('Definisi atribut profil')
    expect(view).toContain('Jenis input')
    expect(view).toContain('tipe filter')
  })
  it('does not claim a full user directory', async () => {
    const view = await html(Users, true)
    expect(view).toContain('akun terlapor')
    expect(view).toMatch(/Tidak tersedia<\/strong>.*Total pengguna terdaftar/)
    expect(view).not.toContain('Tindakan demo')
  })
  it('disables unsupported report status transitions', async () => {
    const view = await html(Reports, true)
    expect(view).toContain('Pusat Laporan')
    expect(view).not.toContain('Terbuka (demo)')
    expect(view).not.toContain('Status laporan berhasil diperbarui')
  })
})
