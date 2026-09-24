import { describe, expect, it } from 'vitest'
import { createSSRApp } from 'vue'
import { renderToString } from 'vue/server-renderer'
import { createMemoryHistory, createRouter } from 'vue-router'
import AboutView from './AboutView.vue'
import TermsView from './TermsView.vue'
import PrivacyView from './PrivacyView.vue'
import ServerErrorView from './ServerErrorView.vue'
import NotFoundView from './NotFoundView.vue'

async function renderPage(view: object, path: string) {
  const router = createRouter({ history: createMemoryHistory(), routes: [
    { path, component: view },
    ...['/', '/tentang', '/register', '/profil-saya', '/cari/:gameSlug', '/syarat-ketentuan', '/kebijakan-privasi'].filter(route => route !== path).map(route => ({ path: route, component: view })),
  ] })
  await router.push(path)
  await router.isReady()
  const app = createSSRApp(view)
  app.use(router)
  return renderToString(app)
}

describe('public content screens', () => {
  it('introduces the service without fictional metrics and links to working routes', async () => {
    const html = await renderPage(AboutView, '/tentang')
    expect(html).toContain('Kenapa Mabar Finder ada')
    expect(html).toContain('Cara kami berpikir')
    expect(html).toContain('Mobile Legends')
    expect(html).toContain('href="/register"')
    expect(html).toContain('href="/"')
    expect(html).not.toMatch(/12\.480|34\.800|gratis selamanya|sistem reputasi|verified|href="#"/i)
  })

  it('makes every terms section reachable without mockup-only guarantees', async () => {
    const html = await renderPage(TermsView, '/syarat-ketentuan')
    for (const id of ['ringkasan', 'ketentuan-akun', 'kode-etik', 'reputasi-matchmaking', 'moderasi-sanksi', 'hak-cipta', 'batasan-tanggung-jawab', 'kontak-bantuan']) {
      expect(html).toContain(`href="#${id}"`)
      expect(html).toContain(`id="${id}"`)
    }
    expect(html).toContain('href="/kebijakan-privasi"')
    expect(html).toContain('18 tahun')
    expect(html).toContain('belum terverifikasi')
    expect(html).not.toMatch(/2FA|WhatsApp|13 tahun|Skor Sportivitas|AI Moderasi|24 jam|PT Mabar Finder|lobi verified|href="#"|efektif 23 September/i)
  })

  it('explains privacy boundaries through linked sections without unbuilt security promises', async () => {
    const html = await renderPage(PrivacyView, '/kebijakan-privasi')
    for (const id of ['ikhtisar', 'data-dikumpulkan', 'tujuan-penggunaan', 'akun-game-tag', 'riwayat-reputasi', 'keamanan-penyimpanan', 'hak-kontrol-user', 'perubahan-kontak']) {
      expect(html).toContain(`href="#${id}"`)
      expect(html).toContain(`id="${id}"`)
    }
    expect(html).toContain('href="/syarat-ketentuan"')
    expect(html).toContain('ID game')
    expect(html).toContain('dibagikan secara eksplisit')
    expect(html).toContain('belum ditetapkan')
    expect(html).not.toMatch(/enkripsi end-to-end|AES-256|TLS 1\.3|zero-log|24 jam|Jakarta, Indonesia|retensi 24|Argon2|Bcrypt|unduh arsip|23 September 2026|href="#"/i)
  })

  it('offers a real reload control and home link for server trouble without invented uptime claims', async () => {
    const html = await renderPage(ServerErrorView, '/server-bermasalah')
    expect(html).toContain('Ada yang nggak beres di server kami')
    expect(html).toContain('Coba Muat Ulang')
    expect(html).toContain('href="/"')
    expect(html).not.toMatch(/Estimasi: Instan|Kru Sedang Menangani|href="#"|1x24 jam/i)
  })

  it('offers both home and discover routes on a missing page without fake telemetry', async () => {
    const html = await renderPage(NotFoundView, '/hilang')
    expect(html).toContain('Waduh, halaman ini nggak ketemu')
    expect(html).toContain('404')
    expect(html).toContain('href="/"')
    expect(html).toContain('href="/cari/mlbb"')
    expect(html).not.toMatch(/Node Jakarta|Room Aktif|Laporan dicatat|href="#"/i)
  })
})
