import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { visibleProfileFields } from '../lib/gameProfileFields'
import { groupedCharacterOptions } from '../lib/characterGroups'
import type { AttributeDefinition } from '../lib/models'
import { createSSRApp } from 'vue'
import { renderToString } from 'vue/server-renderer'
import GameAttributeEditor from './GameAttributeEditor.vue'

const source = readFileSync(fileURLToPath(new URL('./GameAttributeEditor.vue', import.meta.url)), 'utf8')
describe('shared game attribute editor', () => {
  it('uses the same schema in account and onboarding', () => {
    for (const file of ['../views/AccountView.vue', '../views/OnboardingView.vue']) {
      const view = readFileSync(fileURLToPath(new URL(file, import.meta.url)), 'utf8')
      expect(view).toContain('<GameAttributeEditor')
    }
  })
  it('renders essential and optional fields without showing legacy role', async () => {
    const definitions = ['role', 'position_main', 'rank_current', 'hero_pool'].map((key, sort_order) => ({
      game_id: 'id', key, label: key, category: 'kompetensi', active: true, sort_order,
      value_type: key === 'hero_pool' || key === 'role' ? 'multi_select' : 'single_select',
      options: ['EXP Lane', 'Roam'], filter_type: 'dropdown', range_min: null, range_max: null, unit: null,
    } as AttributeDefinition))
    const html = await renderToString(createSSRApp(GameAttributeEditor, { slug: 'mlbb', definitions, values: {} }))
    expect(html).toContain('Informasi utama')
    expect(html).toContain('Atribut tambahan')
    expect(html).toContain('position_main')
    expect(html).not.toContain('>role<')
  })
  it('omits global communication on onboarding while retaining game-specific hours and rank', async () => {
    const definitions = ['voice_chat', 'active_hours', 'rank_current'].map((key, sort_order) => ({
      game_id: 'id', key, label: key, category: 'gaya_main', active: true, sort_order,
      value_type: key === 'active_hours' ? 'multi_select' : 'single_select',
      options: ['Pagi', 'Malam'], filter_type: 'dropdown', range_min: null, range_max: null, unit: null,
    } as AttributeDefinition))
    const html = await renderToString(createSSRApp(GameAttributeEditor, { slug: 'mlbb', definitions, values: {}, excludeKeys: ['voice_chat'] }))
    expect(html).toContain('active_hours')
    expect(html).toContain('rank_current')
    expect(html).not.toContain('voice_chat')
  })
  it('shows the star input immediately after choosing MLBB Glory or Immortal', async () => {
    const definitions = [
      { game_id: 'id', key: 'rank_current', label: 'Rank Saat Ini', category: 'kompetensi', active: true, sort_order: 0, value_type: 'slider_tier', options: ['Epic', 'Mythic Glory', 'Mythic Immortal'], filter_type: 'range_slider', range_min: null, range_max: null, unit: null },
      { game_id: 'id', key: 'rank_stars', label: 'Jumlah Bintang', category: 'kompetensi', active: true, sort_order: 1, value_type: 'number', options: [], filter_type: 'range_min', range_min: 50, range_max: 1000000, unit: 'bintang' },
    ] as AttributeDefinition[]
    const render = (rank: string) => renderToString(createSSRApp(GameAttributeEditor, { slug: 'mlbb', definitions, values: { rank_current: rank } }))
    expect(await render('Epic')).not.toContain('game-attribute-rank_stars')
    expect(await render('Mythic Glory')).toContain('game-attribute-rank_stars')
    expect(await render('Mythic Glory')).toContain('max="99"')
    expect(await render('Mythic Immortal')).toContain('min="100"')
    expect(await render('Mythic Glory')).not.toContain('Rank Saat Ini')
  })
  it('offers grouped multi-choice dropdowns for MLBB heroes and VALORANT agents', async () => {
    const render = (slug: string, key: string, options: string[], values: string[] = []) => renderToString(createSSRApp(GameAttributeEditor, {
      slug, values: { [key]: values }, definitions: [{ game_id: 'id', key, label: key, category: 'kompetensi', active: true, sort_order: 0, value_type: 'tag_multi', filter_type: 'tag_select', options, range_min: null, range_max: null, unit: null }],
    }))
    const heroes = await render('mlbb', 'hero_pool', ['Akai', 'Gusion', 'Layla'], ['Akai'])
    expect(heroes).toContain('character-trigger')
    expect(heroes).toContain('Akai')
    expect(groupedCharacterOptions('hero_pool', ['Akai', 'Gusion', 'Layla']).map(group => group.label)).toEqual(['Tank', 'Assassin', 'Marksman'])
    expect(heroes).not.toContain('Pisahkan nama dengan koma')
    const agents = await render('valorant', 'main_agent', ['Jett', 'Sova', 'Omen'], ['Jett'])
    expect(agents).toContain('character-trigger')
    expect(groupedCharacterOptions('main_agent', ['Jett', 'Sova', 'Omen']).map(group => group.label)).toEqual(['Duelist', 'Initiator', 'Controller'])
    expect(agents).not.toContain('Pisahkan nama dengan koma')
  })
  it('offers grouped searchable choices for Free Fire characters', async () => {
    const options = ['A124', 'Alok', 'Chrono', 'Alvaro', 'Kelly', 'Moco']
    const groups = groupedCharacterOptions('main_character', options)
    expect(groups.map(group => group.label)).toEqual(['Skill Aktif', 'Skill Pasif · Pria', 'Skill Pasif · Wanita'])
    const html = await renderToString(createSSRApp(GameAttributeEditor, {
      slug: 'free-fire', values: { main_character: ['Alok'] }, definitions: [{ game_id: 'id', key: 'main_character', label: 'Karakter/Skill Andalan', category: 'kompetensi', active: true, sort_order: 0, value_type: 'tag_multi', filter_type: 'tag_select', options, range_min: null, range_max: null, unit: null }],
    }))
    expect(html).toContain('character-trigger')
    expect(html).toContain('Alok')
    expect(html).not.toContain('Pisahkan nama dengan koma')
  })
  it('keeps separate Free Fire mode ranks and prevents repeated secondary positions', () => {
    expect(source).toContain('visibleProfileFields')
    expect(source).toContain('position_secondary')
    const schema = ['ranked_mode', 'rank_br', 'rank_cs'].map(key => ({ key, active: true, value_type: 'slider_tier', options: ['A'], sort_order: 0 } as AttributeDefinition))
    expect(visibleProfileFields('free-fire', schema, { ranked_mode: 'Battle Royale Ranked' }).map(field => field.key)).toEqual(['ranked_mode', 'rank_br'])
    expect(visibleProfileFields('free-fire', schema, { ranked_mode: 'Clash Squad Ranked' }).map(field => field.key)).toEqual(['ranked_mode', 'rank_cs'])
  })
})
