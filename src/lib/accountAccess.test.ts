import { describe, expect, it } from 'vitest'
import { accountLanding, safeInternalPath } from './accountAccess'

describe('account landing', () => {
  it('rejects unauthorised OAuth sessions before navigation', () => {
    expect(accountLanding({ registered: false, verified: true, completed: true })).toBe('/register')
  })
  it('routes password accounts to verification and Google accounts to profile verification after onboarding', () => {
    expect(accountLanding({ registered: true, verified: false, completed: false, provider: 'email' })).toBe('/verifikasi-email')
    expect(accountLanding({ registered: true, verified: false, completed: false, provider: 'google' })).toBe('/onboarding/1')
    expect(accountLanding({ registered: true, verified: false, completed: true, provider: 'google' })).toBe('/profil-saya')
    expect(accountLanding({ registered: true, verified: true, completed: false })).toBe('/onboarding/1')
    expect(accountLanding({ registered: true, verified: true, completed: true })).toBe('/beranda')
  })
  it('only accepts same-origin path redirects, never bypasses onboarding', () => {
    expect(safeInternalPath('//evil.example')).toBeNull()
    expect(safeInternalPath('/\\evil.example')).toBeNull()
    expect(safeInternalPath('/beranda')).toBe('/beranda')
    expect(safeInternalPath('/profil-saya')).toBe('/profil-saya')
  })
})