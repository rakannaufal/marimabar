// @vitest-environment happy-dom
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createApp, nextTick, reactive } from 'vue'
import { createPinia, getActivePinia, setActivePinia } from 'pinia'
import ChatView from './ChatView.vue'
import { demoLogin, resetDemo } from '../lib/demo'
import { useSessionStore } from '../stores/session'
import * as api from '../lib/api'

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
async function acceptedChat() {
  demoLogin('demo-player')
  await api.respondInvite('invite-seeded', 'accepted')
  const [conversation] = await api.listConversations('demo-player')
  return conversation.id
}

beforeEach(() => { resetDemo(); setActivePinia(createPinia()); route.query = {}; vi.restoreAllMocks() })
describe('chat and safety', () => {
  it('renders a real demo participant name and sends a message after acceptance without exposing private IDs', async () => {
    const id = await acceptedChat()
    const session = useSessionStore(); await session.initialize()
    const view = mount(); await settle()
    expect(view.host.textContent).toContain('Bima (pemain)')
    expect(view.host.textContent).not.toContain('DEMO-PRIVATE')
    expect(view.host.textContent).not.toContain('KONEKSI PEMAIN')
    fill(view.host, '#message', 'Halo, siap mabar?')
    await nextTick()
    view.host.querySelector<HTMLFormElement>('#message-form')!.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await settle()
    expect((await api.listMessages(id)).some(m => m.body === 'Halo, siap mabar?')).toBe(true)
    expect(view.host.textContent).toContain('Halo, siap mabar?')
    view.unmount()
  })

  it('reports the selected message with a message target, not a profile or arbitrary latest message', async () => {
    const id = await acceptedChat()
    demoLogin('demo-rival')
    await api.sendMessage(id, 'Pesan pertama')
    const [first] = await api.listMessages(id)
    await api.sendMessage(id, 'Pesan kedua')
    demoLogin('demo-player')
    const session = useSessionStore(); await session.initialize()
    const spy = vi.spyOn(api, 'reportUser')
    const view = mount(); await settle()
    const reportButton = view.host.querySelector<HTMLButtonElement>(`button[data-message-id="${first.id}"]`)
    expect(reportButton).not.toBeNull()
    reportButton!.click()
    await nextTick()
    fill(view.host, '#report-category', 'spam')
    fill(view.host, '#report-description', 'Pesan ini spam yang mengganggu')
    await nextTick()
    view.host.querySelector<HTMLFormElement>('#report-form')!.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await settle()
    expect(spy).toHaveBeenCalledWith('demo-rival', 'spam', 'Pesan ini spam yang mengganggu', first.id, 'message')
    expect(view.host.textContent).toContain('Laporan terkirim')
    view.unmount()
  })

  it('keeps another player’s game ID hidden until they explicitly share it', async () => {
    const id = await acceptedChat()
    demoLogin('demo-player')
    await api.shareGameId(id, 'profile-0-0')
    demoLogin('demo-rival')
    const session = useSessionStore(); await session.initialize()
    const view = mount(); await settle()
    expect(view.host.textContent).toContain('DEMO-PRIVATE-0-0')
    expect(view.host.textContent).not.toContain('DEMO-PRIVATE-0-1')
    view.unmount()
  })
})
