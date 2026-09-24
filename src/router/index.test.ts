import { describe, expect, it, vi } from 'vitest'
vi.mock('vue-router', async (importOriginal) => {
 const original = await importOriginal<typeof import('vue-router')>()
 return {...original, createWebHistory: original.createMemoryHistory}
})
import router from './index'

const implementedRoutes = [
 '/', '/tentang', '/syarat-ketentuan', '/kebijakan-privasi',
 '/login', '/register', '/lupa-password', '/reset-password', '/reset-password/:token',
 '/verifikasi-email', '/verifikasi-email/berhasil', '/onboarding/:step?',
 '/beranda', '/komunitas', '/pilih-game', '/cari/:gameSlug', '/profil/:id',
 '/profil-saya', '/request-mabar', '/pesan', '/admin', '/admin/game',
 '/admin/atribut-game', '/admin/user', '/admin/laporan', '/admin/statistik',
 '/server-bermasalah', '/:pathMatch(.*)*',
]

describe('design route coverage', () => {
 it('has dedicated pages for every original HTML screen family', () => {
   const paths = new Set(router.getRoutes().map(route => route.path))
   expect(implementedRoutes.filter(path => !paths.has(path))).toEqual([])
 })
 it('does not redirect designed pages to unrelated views', () => {
   for(const path of ['/beranda','/pilih-game','/admin/game','/admin/atribut-game','/admin/user','/admin/laporan','/admin/statistik']){
     const route = router.getRoutes().find(route => route.path===path)
     expect(route?.redirect).toBeUndefined()
   }
 })
})
