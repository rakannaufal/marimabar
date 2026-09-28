export interface AccountState { registered: boolean; verified: boolean; completed: boolean; provider?: string | null }

export function accountLanding(state: AccountState): string {
  if (!state.registered) return '/register'
  if (!state.completed) {
    if (state.provider === 'google') return '/onboarding/1'
    if (!state.verified) return '/verifikasi-email'
    return '/onboarding/1'
  }
  if (!state.verified) return '/profil-saya'
  return '/beranda'
}

export function safeInternalPath(value: unknown): string | null {
  return typeof value === 'string' && /^\/(?![\\/])/.test(value) && !/[\r\n\\]/.test(value) ? value : null
}
