import { createRouter, createWebHistory } from 'vue-router'
import { useSessionStore } from '../stores/session'

const router = createRouter({ history: createWebHistory(), routes: [
  { path: '/', component: () => import('../views/HomeView.vue') },
  { path: '/komunitas', component: () => import('../views/CommunityView.vue') },
  { path: '/tentang', component: () => import('../views/AboutView.vue') },
  { path: '/syarat-ketentuan', component: () => import('../views/TermsView.vue') },
  { path: '/kebijakan-privasi', component: () => import('../views/PrivacyView.vue') },
  { path: '/login', component: () => import('../views/AuthView.vue') },
  { path: '/register', component: () => import('../views/AuthView.vue') },
  { path: '/auth/callback', component: () => import('../views/AuthCallbackView.vue') },
  { path: '/lupa-password', component: () => import('../views/ResetPasswordView.vue') },
  { path: '/reset-password', component: () => import('../views/ResetPasswordView.vue') },
  { path: '/reset-password/:token', component: () => import('../views/ResetPasswordView.vue') },
  { path: '/verifikasi-email', component: () => import('../views/VerificationView.vue') },
  { path: '/verifikasi-email/berhasil', component: () => import('../views/VerificationView.vue') },
  { path: '/onboarding/:step?', component: () => import('../views/OnboardingView.vue'), meta: { auth: true } },
  { path: '/beranda', component: () => import('../views/DashboardView.vue'), meta: { auth: true } },
  { path: '/pilih-game', component: () => import('../views/GamePickerView.vue') },
  { path: '/cari/:gameSlug', component: () => import('../views/SearchView.vue') },
  { path: '/profil/:id', component: () => import('../views/ProfileView.vue') },
  { path: '/profil-saya', component: () => import('../views/AccountView.vue'), meta: { auth: true } },
  { path: '/request-mabar', redirect: '/teman', meta: { auth: true } },
  { path: '/teman', component: () => import('../views/FriendsView.vue'), meta: { auth: true } },
  { path: '/teman/:id', component: () => import('../views/FriendProfileView.vue'), meta: { auth: true } },
  { path: '/pesan', component: () => import('../views/ChatView.vue'), meta: { auth: true } },
  { path: '/admin', component: () => import('../views/AdminStatisticsView.vue'), meta: { auth: true, admin: true } },
  { path: '/admin/statistik', component: () => import('../views/AdminStatisticsView.vue'), meta: { auth: true, admin: true } },
  { path: '/admin/game', component: () => import('../views/AdminGamesView.vue'), meta: { auth: true, admin: true } },
  { path: '/admin/atribut-game', component: () => import('../views/AdminAttributesView.vue'), meta: { auth: true, admin: true } },
  { path: '/admin/user', component: () => import('../views/AdminUsersView.vue'), meta: { auth: true, admin: true } },
  { path: '/admin/laporan', component: () => import('../views/AdminReportsView.vue'), meta: { auth: true, admin: true } },
  { path: '/server-bermasalah', component: () => import('../views/ServerErrorView.vue') },
  { path: '/:pathMatch(.*)*', component: () => import('../views/NotFoundView.vue') },
] })

// Auth-only pages that should NOT be accessible when logged in
const guestOnly = new Set(['/login', '/register'])

router.beforeEach(async to => {
  const session = useSessionStore()
  await session.initialize()

  const isAuth = Boolean(session.user)
  const isRegistered = session.registered
  const isGoogle = session.isGoogle

  // Authenticated but not registered (Google auto-created) → force to /register
  if (isAuth && !isRegistered && to.path !== '/register' && to.path !== '/auth/callback') {
    return { path: '/register', query: { pending: '1' } }
  }

  // Already logged in + registered → block /login and /register regardless of onboarding state
  if (isAuth && isRegistered && guestOnly.has(to.path)) {
    return { path: session.landing() }
  }

  // Must login for protected routes
  if (to.meta.auth && !isAuth) {
    return { path: '/login', query: { redirect: to.fullPath } }
  }

  // Registered but onboarding not completed → route to onboarding or email verification
  if (isAuth && isRegistered && !session.onboardingCompleted) {
    if (!isGoogle && !session.verified) {
      if (to.path !== '/verifikasi-email' && to.path !== '/verifikasi-email/berhasil') {
        return { path: '/verifikasi-email' }
      }
      return true
    }
    if (to.meta.auth && !to.path.startsWith('/onboarding')) {
      return { path: '/onboarding/1' }
    }
    return true
  }

  // Already completed onboarding, skip /onboarding
  if (isAuth && session.onboardingCompleted && to.path.startsWith('/onboarding')) {
    return { path: session.landing() }
  }

  // Completed onboarding but email not verified yet (e.g. Google signup needing profile verification)
  if (isAuth && session.onboardingCompleted && !session.verified) {
    if (to.path === '/profil-saya' || to.path === '/verifikasi-email' || to.path === '/verifikasi-email/berhasil') {
      return true
    }
    if (to.meta.auth) {
      return { path: '/profil-saya', query: { verify: '1' } }
    }
  }

  if (to.meta.admin && !session.admin) return { path: '/beranda' }
  return true
})

export default router
