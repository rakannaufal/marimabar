// @vitest-environment happy-dom
import { describe, expect, it } from 'vitest'
import { createApp, h, nextTick, ref } from 'vue'
import GameAttributeEditor from './GameAttributeEditor.vue'
import type { AttributeDefinition } from '../lib/models'

describe('character dropdown', () => {
  it('selects multiple heroes up to three, removes one, and filters options', async () => {
    const definitions = [{ game_id: 'id', key: 'hero_pool', label: 'Hero', category: 'kompetensi', active: true, sort_order: 0, value_type: 'tag_multi', filter_type: 'tag_select', options: ['Akai', 'Gusion', 'Layla', 'Angela'], range_min: null, range_max: null, unit: null }] as AttributeDefinition[]
    const values = ref<Record<string, unknown>>({})
    const host = document.createElement('div')
    const app = createApp({ render: () => h(GameAttributeEditor, { slug: 'mlbb', definitions, values: values.value, 'onUpdate:values': (next: Record<string, unknown>) => { values.value = next } }) })
    app.mount(host)
    host.querySelector<HTMLButtonElement>('.character-trigger')!.click()
    await nextTick()
    const checkbox = (name: string) => Array.from(host.querySelectorAll<HTMLLabelElement>('.character-group label')).find(label => label.textContent?.includes(name))!.querySelector('input')!
    for (const name of ['Akai', 'Gusion', 'Layla']) { checkbox(name).dispatchEvent(new Event('change', { bubbles: true })); await nextTick() }
    expect(values.value.hero_pool).toEqual(['Akai', 'Gusion', 'Layla'])
    expect(checkbox('Angela').disabled).toBe(true)
    checkbox('Gusion').dispatchEvent(new Event('change', { bubbles: true })); await nextTick()
    expect(values.value.hero_pool).toEqual(['Akai', 'Layla'])
    const search = host.querySelector<HTMLInputElement>('input[type=search]')!
    search.value = 'ang'; search.dispatchEvent(new Event('input', { bubbles: true })); await nextTick()
    expect(host.querySelector('.character-list')?.textContent).toContain('Angela')
    expect(host.querySelector('.character-list')?.textContent).not.toContain('Akai')
    app.unmount()
  })
})
