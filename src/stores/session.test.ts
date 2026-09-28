import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import type { User } from '@supabase/supabase-js'

const state = vi.hoisted(() => ({
  user: null as User | null,
  profile: null as { adult_declared_at: string | null; onboarding_completed_at: string | null; account_status: string } | null,
  error: null as { message: string } | null,
  profileGate: null as Promise<void> | null,
  listeners: [] as Array<(event: string, session: { user: User } | null) => void>,
}))
vi.mock('../lib/supabase', () => ({
  supabase: {
    auth: {
      getUser: async () => ({ data: { user: state.user }, error: null }),
      onAuthStateChange: (listener: (event: string, session: { user: User } | null) => void) => { state.listeners.push(listener) },
    },
    from: () => ({ select: () => ({ eq: () => ({ maybeSingle: async () => { await state.profileGate; return { data: state.profile, error: state.error } } }) }) }),
  },
}))
vi.mock('../lib/api', () => ({ isAdmin: async () => false }))
import { useSessionStore } from './session'

const google = { id: 'google', app_metadata: { provider: 'google' }, user_metadata: { full_name: 'Google Name', display_name: 'Google Name', adult_declared: true }, email_confirmed_at: '2026-01-01' } as unknown as User
const email = { id: 'email', app_metadata: { provider: 'email' }, user_metadata: { display_name: 'Ada' }, email_confirmed_at: '2026-01-01' } as unknown as User

beforeEach(() => {
  setActivePinia(createPinia())
  state.user = null; state.profile = null; state.error = null; state.profileGate = null; state.listeners = []
})

describe('registration state from database', () => {
  it('rejects a Google OAuth-created user despite spoofable display name and metadata', async () => {
    state.user = google
    state.profile = { adult_declared_at: null, onboarding_completed_at: null, account_status: 'active' }
    const session = useSessionStore()
    await session.initialize()
    expect(session.registered).toBe(false)
    expect(session.landing()).toBe('/register')
  })
  it('accepts a registered Google user and sends completed onboarding to dashboard', async () => {
    state.user = google
    state.profile = { adult_declared_at: '2026-01-01', onboarding_completed_at: '2026-01-02', account_status: 'active' }
    const session = useSessionStore()
    await session.initialize()
    expect(session.registered).toBe(true)
    expect(session.landing()).toBe('/beranda')
  })
  it('rejects an email session without an application profile', async () => {
    state.user = email
    const session = useSessionStore()
    await session.initialize()
    expect(session.registered).toBe(false)
    expect(session.landing()).toBe('/register')
  })
  it('rejects an inactive profile despite a completed onboarding timestamp', async () => {
    state.user = google
    state.profile = { adult_declared_at: '2026-01-01', onboarding_completed_at: '2026-01-02', account_status: 'restricted' }
    const session = useSessionStore()
    await session.initialize()
    expect(session.registered).toBe(false)
    expect(session.onboardingCompleted).toBe(false)
  })
  it('does not grant access when profile lookup fails, even for email accounts', async () => {
    state.user = email
    state.error = { message: 'database unavailable' }
    const session = useSessionStore()
    await expect(session.initialize()).rejects.toThrow('database unavailable')
    expect(session.registered).toBe(false)
  })
  it('routes a new registered email user to onboarding', async () => {
    state.user = email
    state.profile = { adult_declared_at: '2026-01-01', onboarding_completed_at: null, account_status: 'active' }
    const session = useSessionStore()
    await session.initialize()
    expect(session.landing()).toBe('/onboarding/1')
  })
  it('waits for the first profile lookup before a second navigation decides registration', async () => {
    state.user = google
    state.profile = { adult_declared_at: '2026-01-01', onboarding_completed_at: '2026-01-02', account_status: 'active' }
    let release!: () => void
    state.profileGate = new Promise<void>(resolve => { release = resolve })
    const session = useSessionStore()
    const first = session.initialize()
    const second = session.initialize()
    expect(session.registered).toBe(false)
    release()
    await Promise.all([first, second])
    expect(session.landing()).toBe('/beranda')
  })
})
