import { beforeEach, describe, expect, it, vi } from 'vitest'

const state = vi.hoisted(() => ({
  user: null as { id: string } | null,
  registered: false,
  onboardingCompleted: false,
  admin: false,
  verified: true,
  isGoogle: false,
  initialize: vi.fn(async () => {}),
  landing: () => state.registered ? (state.onboardingCompleted ? (state.verified ? '/beranda' : '/profil-saya') : (!state.verified && !state.isGoogle ? '/verifikasi-email' : '/onboarding/1')) : '/register',
}))
vi.mock('vue-router', async importOriginal => {
  const original = await importOriginal<typeof import('vue-router')>()
  return { ...original, createWebHistory: original.createMemoryHistory }
})
vi.mock('../stores/session', () => ({ useSessionStore: () => state }))
import router from './index'

beforeEach(() => {
  state.user = null
  state.registered = false
  state.onboardingCompleted = false
  state.admin = false
  state.verified = true
  state.isGoogle = false
  state.initialize.mockClear()
})

describe('auth navigation', () => {
  it('lets guests reach login; sends protected routes to login', async () => {
    await router.push('/login')
    expect(router.currentRoute.value.path).toBe('/login')
    await router.push('/beranda')
    expect(router.currentRoute.value.path).toBe('/login')
  })
  it('sends an undeclared Google account to registration', async () => {
    state.user = { id: 'google' }
    await router.push('/beranda')
    expect(router.currentRoute.value.path).toBe('/register')
    expect(router.currentRoute.value.query.pending).toBe('1')
  })
  it('sends a registered unfinished account to onboarding, never login or register', async () => {
    state.user = { id: 'new' }
    state.registered = true
    for (const path of ['/login', '/register', '/beranda', '/profil-saya']) {
      await router.push(path)
      expect(router.currentRoute.value.path).toBe('/onboarding/1')
    }
  })
  it('requires verification before protected pages for an authenticated email account', async () => {
    state.user = { id: 'unverified' }
    state.registered = true
    state.verified = false
    await router.push('/beranda')
    expect(router.currentRoute.value.path).toBe('/verifikasi-email')
    await router.push('/login')
    expect(router.currentRoute.value.path).toBe('/verifikasi-email')
  })
  it('lets Google finish onboarding, then sends unverified accounts to profile verification', async () => {
    state.user = { id: 'google-unverified' }
    state.registered = true
    state.verified = false
    state.isGoogle = true
    await router.push('/onboarding/1')
    expect(router.currentRoute.value.path).toBe('/onboarding/1')
    state.onboardingCompleted = true
    await router.push('/beranda')
    expect(router.currentRoute.value.path).toBe('/profil-saya')
    expect(router.currentRoute.value.query.verify).toBe('1')
  })
  it('sends a completed account to the dashboard, never login or register', async () => {
    state.user = { id: 'returning' }
    state.registered = true
    state.onboardingCompleted = true
    for (const path of ['/login', '/register', '/onboarding/1']) {
      await router.push(path)
      expect(router.currentRoute.value.path).toBe('/beranda')
    }
  })
})
