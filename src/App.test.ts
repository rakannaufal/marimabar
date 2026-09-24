import { describe, expect, it, vi } from 'vitest'
import { createSSRApp } from 'vue'
import { renderToString } from 'vue/server-renderer'
import { createPinia } from 'pinia'
import { createMemoryHistory, createRouter } from 'vue-router'
import App from './App.vue'

vi.mock('./lib/supabase', () => ({ configured: false, supabase: null, requireBackend: () => { throw new Error('Supabase belum dikonfigurasi') } }))

async function renderShell(path = '/') {
  const paths = ['/', '/beranda', '/pilih-game', '/tentang', '/syarat-ketentuan', '/kebijakan-privasi', '/login', '/register', '/request-mabar', '/pesan', '/profil-saya', '/admin', '/admin/statistik', '/admin/game', '/admin/atribut-game', '/admin/user', '/admin/laporan']
  const router = createRouter({ history: createMemoryHistory(), routes: paths.map(path => ({ path, component: { template: '<main>Konten</main>' } })) })
  const app = createSSRApp(App).use(createPinia()).use(router)
  await router.push(path); await router.isReady()
  return renderToString(app)
}

describe('shared shell without demo personas', () => {
  it('shows an unconfigured state, never synthetic login', async () => {
    const html = await renderShell()
    expect(html).toContain('Layanan belum dikonfigurasi')
    expect(html).not.toContain('demo-persona')
    expect(html).not.toContain('data sintetis')
  })
  it('preserves public discovery, about and legal links', async () => {
    const html = await renderShell()
    for (const path of ['/pilih-game', '/tentang', '/syarat-ketentuan', '/kebijakan-privasi', '/login', '/register']) expect(html).toContain(`href="${path}"`)
    expect(html).toContain('class="site-footer')
  })
  it('renders dashboard and admin navigation without mock identities', async () => {
    expect(await renderShell('/beranda')).toContain('Navigasi pemain')
    expect(await renderShell('/admin/statistik')).toContain('Navigasi admin')
  })
})
