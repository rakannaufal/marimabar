import { describe, expect, it } from 'vitest'
import { createSSRApp } from 'vue'
import { renderToString } from 'vue/server-renderer'
import { createPinia, setActivePinia } from 'pinia'
import { createMemoryHistory, createRouter } from 'vue-router'
import OnboardingView from './OnboardingView.vue'
import VerificationView from './VerificationView.vue'
import ResetPasswordView from './ResetPasswordView.vue'
import AuthView from './AuthView.vue'
import { demoLogin, demoLogout, resetDemo } from '../lib/demo'
import { useSessionStore } from '../stores/session'
import { ownProfile, updateOwnProfile } from '../lib/api'

async function render(view: object, path: string) {
  const router = createRouter({ history: createMemoryHistory(), routes: [{ path: '/onboarding/:step?', component: view }, { path: '/:pathMatch(.*)*', component: view }] })
  await router.push(path)
  await router.isReady()
  const pinia = createPinia()
  setActivePinia(pinia)
  if (view === OnboardingView) {
    demoLogin('demo-player')
    const session = useSessionStore(pinia)
    await session.initialize()
  }
  const html = await renderToString(createSSRApp(view).use(router).use(pinia))
  if (view === OnboardingView) demoLogout()
  return html
}

describe('onboarding screens', () => {
  it('shows three separately addressable progress states with real form fields', async () => {
    const first = await render(OnboardingView, '/onboarding/1')
    expect(first).toContain('Kenalan dulu, yuk!')
    expect(first).toContain('Langkah 01 dari 03')
    const second = await render(OnboardingView, '/onboarding/2')
    expect(second).toContain('Mau temenan buat main apa?')
    expect(second).toContain('Pilih game')
    const third = await render(OnboardingView, '/onboarding/3')
    expect(third).toContain('Terakhir nih, atur preferensi kamu')
    expect(third).toContain('Siap mabar')
  })
  it('does not offer an unpersisted upload or claim verified game data', async () => {
    const html = await render(OnboardingView, '/onboarding/2')
    expect(html).toContain('belum terverifikasi')
    expect(html).not.toContain('type="file"')
  })
})

describe('auth edge screens in demo mode', () => {
  it('offers personas but no fake email or password registration', async () => {
    const html = await render(AuthView, '/register')
    expect(html).toContain('Mode demo')
    expect(html).toContain('Masuk sebagai')
    expect(html).not.toContain('type="password"')
    expect(html).not.toContain('type="email"')
  })
  it('does not promise a demo password reset', async () => {
    const html = await render(ResetPasswordView, '/lupa-password')
    expect(html).toContain('tidak tersedia di mode demo')
    expect(html).not.toContain('Kirim Tautan Reset</button>')
  })
  it('does not claim demo verification email was sent', async () => {
    const html = await render(VerificationView, '/verifikasi-email')
    expect(html).toContain('tidak mengirim email')
    expect(html).not.toContain('Kirim Ulang Email</button>')
  })
  it('persists profile preferences through the existing demo API', async () => {
    resetDemo()
    demoLogin('demo-player')
    await updateOwnProfile('demo-player', { display_name: 'Tester', availability_status: 'ready', play_style: 'competitive' })
    const profile = await ownProfile('demo-player') as unknown as { display_name: string; availability_status: string; play_style: string }
    expect(profile).toMatchObject({ display_name: 'Tester', availability_status: 'ready', play_style: 'competitive' })
    demoLogout()
  })
})
