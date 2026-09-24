import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createSSRApp } from 'vue'
import { renderToString } from 'vue/server-renderer'
import { createPinia, setActivePinia } from 'pinia'
import { createMemoryHistory, createRouter } from 'vue-router'
import type { User } from '@supabase/supabase-js'
import OnboardingView from './OnboardingView.vue'
import VerificationView from './VerificationView.vue'
import ResetPasswordView from './ResetPasswordView.vue'
import AuthView from './AuthView.vue'
import { useSessionStore } from '../stores/session'

const state = vi.hoisted(() => ({ configured: false, profileFails: false }))
vi.mock('../lib/supabase', () => ({ get configured() { return state.configured }, supabase: null }))
vi.mock('../lib/api', () => ({
  ownProfile: vi.fn(async () => { if (state.profileFails) throw new Error('network'); return { display_name: 'Pemain', timezone: 'Asia/Jakarta' } }),
  listGames: vi.fn(async () => []),
  ownGameProfiles: vi.fn(async () => []),
  listOptions: vi.fn(async () => []),
  updateOwnProfile: vi.fn(),
  saveGameProfile: vi.fn(),
}))

async function render(view: object, path: string, user?: { verified: boolean }) {
  const router = createRouter({ history: createMemoryHistory(), routes: [{ path: '/onboarding/:step?', component: view }, { path: '/:pathMatch(.*)*', component: view }] })
  await router.push(path)
  await router.isReady()
  const pinia = createPinia()
  setActivePinia(pinia)
  if (user) {
    const session = useSessionStore(pinia)
    session.user = { id: 'real-user', email: 'user@example.com', email_confirmed_at: user.verified ? '2026-01-01' : undefined } as User
  }
  return renderToString(createSSRApp(view).use(router).use(pinia))
}

beforeEach(() => { state.configured = false; state.profileFails = false })

describe('unconfigured auth', () => {
  it('shows disabled real registration, not personas; adult declaration remains required', async () => {
    const html = await render(AuthView, '/register')
    expect(html).toContain('Layanan akun belum dikonfigurasi')
    expect(html).toContain('type="email"')
    expect(html).toContain('type="password"')
    expect(html).toContain('Saya menyatakan berusia 18 tahun atau lebih.')
    expect(html).not.toContain('Masuk sebagai')
    expect(html).toMatch(/disabled[^>]*>Buat Akun Sekarang/)
  })
  it('shows a disabled Google option without backend on both auth routes', async () => {
    expect(await render(AuthView, '/login')).toMatch(/class="google-button"[^>]*disabled[^>]*>.*Masuk dengan Google/)
    const registration = await render(AuthView, '/register')
    expect(registration).toMatch(/class="google-button"[^>]*disabled[^>]*>.*Daftar dengan Google/)
    expect(registration).toContain('Centang pernyataan usia')
  })
  it('does not offer fake recovery or verification success', async () => {
    expect(await render(ResetPasswordView, '/lupa-password')).toContain('Tidak ada tautan reset yang dapat dikirim')
    expect(await render(ResetPasswordView, '/reset-password')).not.toContain('Simpan Password Baru')
    expect(await render(VerificationView, '/verifikasi-email/berhasil')).toContain('Tidak ada email verifikasi yang dikirim')
  })
  it('blocks onboarding without a backend even with a user', async () => {
    const html = await render(OnboardingView, '/onboarding/3', { verified: true })
    expect(html).toContain('Onboarding belum tersedia')
    expect(html).not.toContain('Selesai, Masuk ke Beranda!')
  })
})

describe('configured onboarding', () => {
  it('uses game definitions and persists selected attributes', async () => {
    const { readFileSync } = await import('node:fs')
    const source = readFileSync(new URL('./OnboardingView.vue', import.meta.url), 'utf8')
    expect(source).toContain('listAttributeDefinitions(gameId)')
    expect(source).toContain('attributes: { ...retained, ...attributeValues.value }')
    expect(source).toContain('definition.value_type')
  })

  beforeEach(() => { state.configured = true })
  it('blocks unverified accounts before profile API work', async () => {
    const html = await render(OnboardingView, '/onboarding/1', { verified: false })
    expect(html).toContain('Verifikasi email dulu')
    expect(html).not.toContain('Nama yang dilihat teman mabar')
  })
  it('shows three separately addressable steps for verified users', async () => {
    const first = await render(OnboardingView, '/onboarding/1', { verified: true })
    expect(first).toContain('Nama yang dilihat teman mabar')
    const second = await render(OnboardingView, '/onboarding/2', { verified: true })
    expect(second).toContain('Pilih game')
    expect(second).toContain('belum terverifikasi')
    const third = await render(OnboardingView, '/onboarding/3', { verified: true })
    expect(third).toContain('Siap mabar sekarang')
    expect(third).not.toContain('type="file"')
  })
  it('does not show editable forms after profile load fails', async () => {
    state.profileFails = true
    const html = await render(OnboardingView, '/onboarding/3', { verified: true })
    expect(html).toContain('Profil atau katalog belum bisa dimuat')
    expect(html).not.toContain('Selesai, Masuk ke Beranda!')
  })
})
