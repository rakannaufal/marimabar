import { describe, expect, it, beforeEach } from 'vitest'
import { createSSRApp } from 'vue'
import { renderToString } from '@vue/server-renderer'
import { createPinia, setActivePinia } from 'pinia'
import { createMemoryHistory, createRouter } from 'vue-router'
import { useSessionStore } from '../stores/session'
import { demoBackend, demoLogin, demoLogout, resetDemo } from '../lib/demo'
import Statistics from './AdminStatisticsView.vue'
import Games from './AdminGamesView.vue'
import Attributes from './AdminAttributesView.vue'
import Users from './AdminUsersView.vue'
import Reports from './AdminReportsView.vue'

beforeEach(() => { resetDemo(); demoLogout(); setActivePinia(createPinia()) })
async function html(component: typeof Statistics, admin: boolean) {
  const router = createRouter({ history: createMemoryHistory(), routes: [{path:'/',component:{template:'<div/>'}}] })
  const app = createSSRApp(component).use(createPinia()).use(router)
  const session = useSessionStore(app._context.provides.pinia)
  session.user = { id: admin ? 'demo-admin' : 'demo-player' } as typeof session.user
  session.admin = admin
  session.loading = false
  await router.push('/'); await router.isReady()
  return renderToString(app)
}
describe('admin page contracts', () => {
  it.each([Statistics, Games, Attributes, Users, Reports])('denies admin content to non-admins', async page => {
    const view = await html(page, false)
    expect(view).toContain('Akses ditolak')
    expect(view).not.toContain('apply_moderation_action')
  })
  it('shows unavailable metrics rather than growth claims', async () => {
    const view = await html(Statistics, true)
    expect(view).toContain('Tidak tersedia')
    expect(view).not.toContain('18,4%')
  })
  it('disables unsupported game creation and deletion', async () => {
    const view = await html(Games, true)
    expect(view).toMatch(/disabled[^>]*>Tambah Game/)
    expect(view).toContain('belum didukung')
  })
  it('disables unsupported attribute editing and deletion', async () => {
    const view = await html(Attributes, true)
    expect(view).toContain('Kelola Skema Atribut Game')
    expect(view).not.toContain('Simpan Perubahan Skema')
  })
  it('does not claim a full user directory', async () => {
    const view = await html(Users, true)
    expect(view).toContain('akun terlapor')
    expect(view).toMatch(/Tidak tersedia<\/strong>.*Total pengguna terdaftar/)
  })
  it('does not offer unsupported report status transitions', async () => {
    const view = await html(Reports, true)
    expect(view).toContain('Pusat Laporan')
    expect(view).not.toContain('Status laporan berhasil diperbarui')
  })
})
describe('demo-backed admin actions', () => {
  it('rejects mutations for regular users; saves admin catalog option', async () => {
    demoLogin('demo-player')
    expect((await demoBackend.rpc('add_catalog_option',{p_game:'game-valorant',p_kind:'role',p_code:'flex-player',p_label:'Flex Player'})).error).toBeTruthy()
    demoLogin('demo-admin')
    expect((await demoBackend.rpc('add_catalog_option',{p_game:'game-valorant',p_kind:'role',p_code:'flex-player',p_label:'Flex Player'})).error).toBeNull()
    const rows = await demoBackend.from('game_catalog_options').select('*').eq('game_id','game-valorant')
    expect(rows.data.some((r:{code:string})=>r.code==='flex-player')).toBe(true)
  })
  it('moderates a reported subject using the supported RPC', async () => {
    demoLogin('demo-player')
    const report = await demoBackend.rpc('create_report',{p_reported:'demo-rival',p_category:'spam',p_description:'Pesan spam berulang kali di ajakan',p_target_type:'profile',p_target_id:'profile-0-1'})
    demoLogin('demo-admin')
    expect((await demoBackend.rpc('apply_moderation_action',{p_subject:'demo-rival',p_report:report.data,p_action:'restrict_account',p_reason:'Pesan spam yang berulang kali'})).error).toBeNull()
    const reports = await demoBackend.from('reports').select('*')
    expect(reports.data.find((r:{id:string})=>r.id===report.data)?.status).toBe('new')
    expect((await demoBackend.rpc('search_game_profiles',{p_game_slug:'free-fire'})).data.some((p:{user_id:string})=>p.user_id==='demo-rival')).toBe(false)
  })
})
