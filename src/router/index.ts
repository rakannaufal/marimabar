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
  { path: '/lupa-password', component: () => import('../views/AuthView.vue') },
  { path: '/reset-password/:token', component: () => import('../views/ResetPasswordView.vue') },
  { path: '/verifikasi-email', component: () => import('../views/VerificationView.vue') },
  { path: '/verifikasi-email/berhasil', component: () => import('../views/VerificationView.vue') },
  { path: '/onboarding/:step?', component: () => import('../views/OnboardingView.vue'), meta: { auth: true } },
  { path: '/beranda', component: () => import('../views/DashboardView.vue'), meta: { auth: true } },
  { path: '/pilih-game', component: () => import('../views/GamePickerView.vue') },
  { path: '/cari/:gameSlug', component: () => import('../views/SearchView.vue') },
  { path: '/profil/:id', component: () => import('../views/ProfileView.vue') },
  { path: '/profil-saya', component: () => import('../views/AccountView.vue'), meta: { auth: true } },
  { path: '/request-mabar', component: () => import('../views/InvitesView.vue'), meta: { auth: true } },
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

router.beforeEach(async to => {
  const session = useSessionStore()
  await session.initialize()
  if (to.meta.auth && !session.user) return { path: '/login', query: { redirect: to.fullPath } }
  if (to.meta.admin && !session.admin) return { path: '/beranda' }
  return true
})

export default router
