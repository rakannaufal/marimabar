// @vitest-environment happy-dom
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createApp, nextTick, reactive } from 'vue'
import { createPinia, getActivePinia, setActivePinia } from 'pinia'
import type { User } from '@supabase/supabase-js'
import ChatView from './ChatView.vue'
import { useSessionStore } from '../stores/session'

const mocks = vi.hoisted(() => ({
  configured: false,
  listConversations: vi.fn(), ownGameProfiles: vi.fn(), listInvites: vi.fn(), listGames: vi.fn(),
  searchProfiles: vi.fn(), listMessages: vi.fn(), readSharedGameId: vi.fn(),
  sendMessage: vi.fn(), reportUser: vi.fn(), blockUser: vi.fn(), shareGameId: vi.fn(),
}))
vi.mock('../lib/supabase', () => ({ get configured() { return mocks.configured }, supabase: null }))
vi.mock('../lib/api', () => mocks)
const route = reactive({ query: {} as Record<string, string> })
vi.mock('vue-router', () => ({ useRoute: () => route, RouterLink: { props: ['to'], template: '<a><slot /></a>' } }))
function mount() {
  const host = document.createElement('div')
  document.body.append(host)
  const app = createApp(ChatView)
  app.use(getActivePinia()!)
  app.mount(host)
  return { host, unmount: () => { app.unmount(); host.remove() } }
}
async function settle() { await new Promise(resolve => setTimeout(resolve, 0)); await nextTick() }
function fill(host: HTMLElement, selector: string, value: string) {
  const field = host.querySelector<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>(selector)!
  field.value = value
  field.dispatchEvent(new Event('input', { bubbles: true }))
  field.dispatchEvent(new Event('change', { bubbles: true }))
}
function signIn() {
  useSessionStore().user = { id: 'owner', email_confirmed_at: '2026-01-01' } as User
}
beforeEach(() => {
  setActivePinia(createPinia()); route.query = {}; vi.clearAllMocks(); mocks.configured = false
  mocks.listConversations.mockResolvedValue([{ id: 'conversation-1', invite_id: 'invite-1', participant_low: 'owner', participant_high: 'other', status: 'active' }])
  mocks.ownGameProfiles.mockResolvedValue([])
  mocks.listInvites.mockResolvedValue([{ id: 'invite-1', game_id: 'game-1' }])
  mocks.listGames.mockResolvedValue([{ id: 'game-1', name: 'Valorant', slug: 'valorant' }])
  mocks.searchProfiles.mockResolvedValue([{ user_id: 'other', game_id: 'game-1', display_name: 'Rekan' }])
  mocks.listMessages.mockResolvedValue([{ id: 'message-1', sender_id: 'other', body: 'Halo', created_at: '2026-01-01' }])
  mocks.readSharedGameId.mockResolvedValue(null)
  mocks.sendMessage.mockResolvedValue(undefined)
  mocks.reportUser.mockResolvedValue(undefined)
})
describe('production chat', () => {
  it('shows unconfigured state without querying conversations', async () => {
    signIn()
    const view = mount(); await settle()
    expect(view.host.textContent).toContain('Layanan belum dikonfigurasi.')
    expect(view.host.textContent).not.toContain('Rekan')
    expect(mocks.listConversations).not.toHaveBeenCalled()
    view.unmount()
  })

  it('loads a participant and sends a message through the API', async () => {
    mocks.configured = true; signIn()
    const view = mount(); await settle()
    expect(view.host.textContent).toContain('Rekan')
    expect(mocks.listConversations).toHaveBeenCalledWith('owner')
    fill(view.host, '#message', 'Siap mabar?')
    await nextTick()
    view.host.querySelector<HTMLFormElement>('#message-form')!.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await settle()
    expect(mocks.sendMessage).toHaveBeenCalledWith('conversation-1', 'Siap mabar?')
    view.unmount()
  })

  it('reports the selected message target', async () => {
    mocks.configured = true; signIn()
    const view = mount(); await settle()
    view.host.querySelector<HTMLButtonElement>('button[data-message-id="message-1"]')!.click()
    await nextTick()
    fill(view.host, '#report-category', 'spam')
    fill(view.host, '#report-description', 'Pesan ini spam yang mengganggu')
    await nextTick()
    view.host.querySelector<HTMLFormElement>('#report-form')!.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await settle()
    expect(mocks.reportUser).toHaveBeenCalledWith('other', 'spam', 'Pesan ini spam yang mengganggu', 'message-1', 'message')
    view.unmount()
  })

  it('does not expose private game ID without sharing', async () => {
    mocks.configured = true; signIn()
    const view = mount(); await settle()
    expect(view.host.textContent).toContain('Rekan chat belum membagikan ID game.')
    expect(view.host.textContent).not.toContain('private-game-id')
    view.unmount()
  })
})
