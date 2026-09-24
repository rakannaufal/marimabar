import { afterEach, beforeEach, describe, expect, it } from 'vitest'
import { createSSRApp } from 'vue'
import { renderToString } from 'vue/server-renderer'
import { createPinia } from 'pinia'
import { createMemoryHistory, createRouter } from 'vue-router'
import App from './App.vue'
import { resetDemo } from './lib/demo'
import { useSessionStore } from './stores/session'

async function renderShell(path = '/', persona?: string) {
  const router = createRouter({ history: createMemoryHistory(), routes: ['/', '/beranda', '/pilih-game', '/tentang', '/syarat-ketentuan', '/kebijakan-privasi', '/login', '/register', '/request-mabar', '/pesan', '/profil-saya', '/admin', '/admin/statistik', '/admin/game', '/admin/atribut-game', '/admin/user', '/admin/laporan'].map(path => ({ path, component: { template: '<main>Konten</main>' } })) })
  const app = createSSRApp(App)
  const pinia = createPinia()
  app.use(pinia); app.use(router)
  const session = useSessionStore(pinia)
  if (persona) await session.signInDemo(persona)
  await router.push(path); await router.isReady()
  return { html: await renderToString(app), session }
}
beforeEach(() => resetDemo())
afterEach(() => resetDemo())

describe('shared shell', () => {
  it('offers public discovery, about and legal links in a landing header and footer', async () => {
    const { html } = await renderShell()
    expect(html).toContain('class="site-header')
    expect(html).not.toContain('class="app-sidebar')
    for (const path of ['/pilih-game', '/tentang', '/syarat-ketentuan', '/kebijakan-privasi', '/login', '/register']) expect(html).toContain(`href="${path}"`)
    expect(html).toContain('class="site-footer')
  })
  it('renders a player dashboard sidebar with real route destinations', async () => {
    const { html } = await renderShell('/beranda', 'demo-player')
    expect(html).toContain('class="app-sidebar')
    expect(html).toContain('Navigasi pemain')
    for (const path of ['/beranda', '/pilih-game', '/request-mabar', '/pesan', '/profil-saya']) expect(html).toContain(`href="${path}"`)
    expect(html).not.toContain('class="site-footer')
    expect(html).not.toContain('Navigasi admin')
  })
  it('renders one admin sidebar for admin routes, including the overview alias', async () => {
    for (const path of ['/admin', '/admin/statistik', '/admin/game']) {
      const { html } = await renderShell(path, 'demo-admin')
      expect(html).toContain('Navigasi admin')
      expect((html.match(/class="app-sidebar(?:\s|\")/g) || []).length).toBe(1)
      for (const destination of ['/admin/statistik', '/admin/game', '/admin/atribut-game', '/admin/user', '/admin/laporan']) expect(html).toContain(`href="${destination}"`)
      expect(html).not.toContain('class="site-footer')
    }
  })
  it('keeps the demo persona selector visible when signed out and signed in', async () => {
    for (const persona of [undefined, 'demo-admin']) {
      const { html } = await renderShell(persona ? '/admin' : '/', persona)
      expect(html).toContain('id="demo-persona"')
      expect(html).toContain('value="demo-player"')
      expect(html).toContain('value="demo-admin"')
    }
  })
})
