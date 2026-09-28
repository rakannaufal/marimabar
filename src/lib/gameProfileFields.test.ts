import { describe, expect, it } from 'vitest'
import { visibleProfileFields, searchableProfileFields, validateProfileAttributes, mergeProfileAttributes, onboardingGameFields } from './gameProfileFields'
import type { AttributeDefinition } from './models'

const definition = (key: string, type = 'single_select', options = ['A', 'B']): AttributeDefinition => ({ game_id: 'id', key, label: key, category: 'kompetensi', value_type: type, filter_type: type === 'slider_tier' ? 'range_slider' : type === 'multi_select' ? 'checkbox_group' : 'dropdown', options, range_min: null, range_max: null, unit: null, sort_order: 0, active: true })

const mlbb = [definition('role', 'multi_select'), definition('position_main'), definition('position_secondary', 'multi_select'), definition('rank_current', 'slider_tier'), definition('win_rate', 'number', []), definition('play_goal')]

describe('curated profile taxonomy', () => {
  it('uses per-game planned fields on onboarding without repeating the global communication preference', () => {
    for (const slug of ['mlbb', 'pubg-mobile', 'free-fire', 'valorant']) {
      const definitions = [definition('voice_chat'), definition('active_hours', 'multi_select'), definition('play_goal'), definition('rank_current', 'slider_tier')]
      const keys = onboardingGameFields(slug, definitions, {}).map(field => field.key)
      expect(keys).toContain('active_hours')
      if (slug === 'mlbb' || slug === 'valorant') expect(keys).toContain('rank_current')
      expect(keys).not.toContain('voice_chat')
      expect(keys).toContain('play_goal')
    }
  })
  it('does not delete existing game voice settings when onboarding saves other attributes', () => {
    const shown = onboardingGameFields('mlbb', [definition('voice_chat'), definition('rank_current', 'slider_tier')], {})
    expect(mergeProfileAttributes({ voice_chat: 'Aktif - Discord' }, { rank_current: 'A' }, shown)).toEqual({ voice_chat: 'Aktif - Discord', rank_current: 'A' })
  })
  it('reveals MLBB stars only for Glory/Immortal and rejects stale or mismatched values', () => {
    const schema = [definition('rank_current', 'slider_tier', ['Epic', 'Mythic Glory', 'Mythic Immortal']), { ...definition('rank_stars', 'number', []), range_min: 50, range_max: 1000000 }]
    expect(visibleProfileFields('mlbb', schema, { rank_current: 'Epic' }).map(field => field.key)).toEqual(['rank_current'])
    expect(visibleProfileFields('mlbb', schema, { rank_current: 'Mythic Glory' }).map(field => field.key)).toEqual(['rank_current', 'rank_stars'])
    expect(visibleProfileFields('mlbb', schema, { rank_current: 'Mythic Immortal' }).map(field => field.key)).toEqual(['rank_current', 'rank_stars'])
    expect(validateProfileAttributes('mlbb', { rank_current: 'Mythic Glory', rank_stars: 75 }, schema)).toBe('')
    expect(validateProfileAttributes('mlbb', { rank_current: 'Mythic Glory', rank_stars: 100 }, schema)).not.toBe('')
    expect(validateProfileAttributes('mlbb', { rank_current: 'Mythic Immortal', rank_stars: 99 }, schema)).not.toBe('')
    expect(validateProfileAttributes('mlbb', { rank_current: 'Epic', rank_stars: 75 }, schema)).not.toBe('')
    expect(mergeProfileAttributes({ rank_current: 'Mythic Glory', rank_stars: 75 }, { rank_current: 'Epic' }, visibleProfileFields('mlbb', schema, { rank_current: 'Epic' }))).toEqual({ rank_current: 'Epic' })
  })
  it('uses team position, not hero class, for Mobile Legends', () => {
    expect(visibleProfileFields('mlbb', mlbb, {}).map(field => field.key)).toEqual(['position_main', 'position_secondary', 'rank_current', 'play_goal'])
    expect(searchableProfileFields('mlbb', mlbb).map(field => field.key)).toEqual(['position_main', 'position_secondary', 'rank_current', 'play_goal'])
  })
  it('keeps old persisted values out of the editor without deleting them', () => {
    expect(visibleProfileFields('mlbb', mlbb, { role: ['Tank'] }).some(field => field.key === 'role')).toBe(false)
  })
  it('shows rank for the selected Free Fire mode without discarding the other mode', () => {
    const fields = [definition('ranked_mode'), definition('rank_br', 'slider_tier'), definition('rank_cs', 'slider_tier'), definition('rank', 'slider_tier')]
    expect(visibleProfileFields('free-fire', fields, { ranked_mode: 'Battle Royale Ranked' }).map(field => field.key)).toEqual(['ranked_mode', 'rank_br'])
    expect(visibleProfileFields('free-fire', fields, { ranked_mode: 'Clash Squad Ranked' }).map(field => field.key)).toEqual(['ranked_mode', 'rank_cs'])
    expect(visibleProfileFields('free-fire', fields, {}).map(field => field.key)).toEqual(['ranked_mode'])
    expect(searchableProfileFields('free-fire', fields).map(field => field.key)).toEqual(['ranked_mode', 'rank_br', 'rank_cs'])
  })
  it('deletes only fields explicitly cleared while retaining unrelated legacy values', () => {
    expect(mergeProfileAttributes({ role: ['Mage'], position_main: 'Roam', rank_current: 'Epic', rank_cs: 'Gold' }, { position_main: 'Roam', rank_current: 'Mythic' }, [definition('position_main'), definition('rank_current')]))
      .toEqual({ role: ['Mage'], position_main: 'Roam', rank_current: 'Mythic', rank_cs: 'Gold' })
    expect(mergeProfileAttributes({ role: ['Mage'], position_main: 'Roam' }, {}, [definition('position_main')]))
      .toEqual({ role: ['Mage'] })
  })
  it('allows bounded hero and agent selections conforming to catalog options', () => {
    const hero = { ...definition('hero_pool'), value_type: 'tag_multi', options: ['Gusion', 'Balmond', 'Layla', 'Akai'] }
    expect(visibleProfileFields('mlbb', [hero], {})).toHaveLength(1)
    expect(validateProfileAttributes('mlbb', { hero_pool: ['Gusion', 'Balmond'] }, [hero])).toBe('')
    expect(validateProfileAttributes('mlbb', { hero_pool: ['Gusion', 'Gusion'] }, [hero])).toContain('Periksa pilihan')
    expect(validateProfileAttributes('mlbb', { hero_pool: ['UnknownHero'] }, [hero])).toContain('Periksa pilihan')
    expect(validateProfileAttributes('mlbb', { hero_pool: ['Gusion', 'Balmond', 'Layla', 'Akai'] }, [hero])).toContain('Periksa pilihan')
  })
  it('requires at most two distinct secondary positions, different from primary', () => {
    const schema = [definition('position_main', 'single_select', ['EXP Lane', 'Jungle', 'Roam']), definition('position_secondary', 'multi_select', ['EXP Lane', 'Jungle', 'Roam'])]
    expect(validateProfileAttributes('mlbb', { position_main: 'EXP Lane', position_secondary: ['Jungle', 'Roam'] }, schema)).toBe('')
    expect(validateProfileAttributes('mlbb', { position_main: 'EXP Lane', position_secondary: ['EXP Lane'] }, schema)).toMatch(/cadangan/i)
    expect(validateProfileAttributes('mlbb', { position_main: 'EXP Lane', position_secondary: ['Jungle', 'Roam', 'EXP Lane'] }, schema)).toMatch(/maksimal dua/i)
  })
  it('rejects unsupported options and inappropriate mode-specific rank', () => {
    const fields = [definition('ranked_mode', 'single_select', ['Battle Royale Ranked', 'Clash Squad Ranked']), definition('rank_br', 'slider_tier'), definition('rank_cs', 'slider_tier')]
    expect(validateProfileAttributes('free-fire', { ranked_mode: 'Random' }, fields)).toMatch(/pilihan/i)
    expect(validateProfileAttributes('free-fire', { ranked_mode: 'Battle Royale Ranked', rank_cs: 'A' }, fields)).toBe('') // Other mode rank may be retained independently.
  })
})
