import type { AttributeDefinition } from './models'

// The database owns values; this list only controls the order and exposure of matching fields.
const fields: Record<string, string[]> = {
  mlbb: ['position_main', 'position_secondary', 'rank_current', 'rank_stars', 'rank_peak', 'hero_pool', 'match_type', 'play_goal', 'squad_type', 'voice_chat', 'active_hours'],
  'pubg-mobile': ['queue_mode', 'perspective', 'mode', 'rank_tier', 'squad_role_main', 'favorite_map', 'play_goal', 'device', 'voice_chat', 'active_hours'],
  'free-fire': ['ranked_mode', 'rank_br', 'rank_cs', 'team_role_main', 'main_character', 'play_goal', 'squad_type', 'device', 'voice_chat', 'active_hours'],
  valorant: ['game_mode', 'rank_current', 'rank_peak', 'agent_role_main', 'main_agent', 'team_role', 'play_goal', 'squad_type', 'voice_chat', 'active_hours'],
}
const searchKeys: Record<string, string[]> = {
  mlbb: ['position_main', 'position_secondary', 'rank_current', 'match_type', 'play_goal', 'squad_type', 'voice_chat', 'active_hours'],
  'pubg-mobile': ['queue_mode', 'perspective', 'mode', 'rank_tier', 'squad_role_main', 'favorite_map', 'play_goal', 'device', 'voice_chat', 'active_hours'],
  'free-fire': ['ranked_mode', 'rank_br', 'rank_cs', 'team_role_main', 'play_goal', 'squad_type', 'device', 'voice_chat', 'active_hours'],
  valorant: ['game_mode', 'rank_current', 'agent_role_main', 'team_role', 'play_goal', 'squad_type', 'voice_chat', 'active_hours'],
}
const isSupported = (definition: AttributeDefinition) => definition.active &&
  (['number', 'decimal', 'boolean', 'tag_multi'].includes(definition.value_type) || Array.isArray(definition.options) && definition.options.length > 0)

export function visibleProfileFields(slug: string, definitions: AttributeDefinition[], values: Record<string, unknown>): AttributeDefinition[] {
  const order = fields[slug] || []
  return definitions.filter(definition => isSupported(definition) && order.includes(definition.key) &&
    (slug !== 'mlbb' || definition.key !== 'rank_stars' || ['Mythic Glory', 'Mythic Immortal'].includes(String(values.rank_current))) &&
    (slug !== 'free-fire' || definition.key !== 'rank_br' && definition.key !== 'rank_cs' ||
      values.ranked_mode === (definition.key === 'rank_br' ? 'Battle Royale Ranked' : 'Clash Squad Ranked')))
    .sort((a, b) => order.indexOf(a.key) - order.indexOf(b.key))
}

// Onboarding collects game-specific details once; voice preference belongs to the general profile in step 3.
export function onboardingGameFields(slug: string, definitions: AttributeDefinition[], values: Record<string, unknown>): AttributeDefinition[] {
  return visibleProfileFields(slug, definitions, values).filter(definition => definition.key !== 'voice_chat')
}

export function searchableProfileFields(slug: string, definitions: AttributeDefinition[]): AttributeDefinition[] {
  const order = searchKeys[slug] || []
  return definitions.filter(definition => isSupported(definition) &&
    (definition.value_type !== 'tag_multi' || Array.isArray(definition.options) && definition.options.length > 0) && order.includes(definition.key))
    .sort((a, b) => order.indexOf(a.key) - order.indexOf(b.key))
}

// Preserve archived fields and the other Free Fire mode rank; remove only fields explicitly cleared.
export function mergeProfileAttributes(previous: Record<string, unknown>, current: Record<string, unknown>, shown: AttributeDefinition[]): Record<string, unknown> {
  const next = { ...previous }
  for (const definition of shown) {
    if (current[definition.key] === undefined) delete next[definition.key]
    else next[definition.key] = current[definition.key]
  }
  if (shown.some(definition => definition.key === 'rank_current') &&
    !['Mythic Glory', 'Mythic Immortal'].includes(String(next.rank_current))) delete next.rank_stars
  return next
}

export function validateProfileAttributes(slug: string, values: Record<string, unknown>, definitions: AttributeDefinition[]): string {
  const schema = new Map(definitions.map(definition => [definition.key, definition]))
  for (const [key, value] of Object.entries(values)) {
    const definition = schema.get(key)
    if (!definition || !definition.active) continue // Historical keys are retained but not rewritten.
    const options = Array.isArray(definition.options) ? definition.options : []
    if (['single_select', 'slider_tier', 'boolean_with_option'].includes(definition.value_type) &&
      (typeof value !== 'string' || !options.includes(value))) return `Periksa pilihan ${definition.label}.`
    if (['multi_select', 'tag_multi'].includes(definition.value_type) &&
      (!Array.isArray(value) || value.length > (['hero_pool', 'main_character', 'main_agent'].includes(key) ? 3 : 20) || new Set(value).size !== value.length ||
        value.some(item => typeof item !== 'string' || !item.length || item.length > 60 || options.length && !options.includes(item)))) return `Periksa pilihan ${definition.label}.`
    if (['number', 'decimal'].includes(definition.value_type) &&
      (typeof value !== 'number' || !Number.isFinite(value) || value < (definition.range_min ?? 0) ||
        value > (definition.range_max ?? 1000000) || definition.value_type === 'number' && !Number.isInteger(value))) return `Periksa nilai ${definition.label}.`
  }
  if (slug === 'mlbb' && values.rank_stars !== undefined) {
    const stars = values.rank_stars
    if (typeof stars !== 'number' || !Number.isInteger(stars) ||
      values.rank_current === 'Mythic Glory' && (stars < 50 || stars > 99) ||
      values.rank_current === 'Mythic Immortal' && stars < 100 ||
      !['Mythic Glory', 'Mythic Immortal'].includes(String(values.rank_current))) return 'Periksa jumlah bintang sesuai rank Mobile Legends.'
  }
  if (slug === 'mlbb' && Array.isArray(values.position_secondary)) {
    if (values.position_secondary.length > 2) return 'Posisi cadangan maksimal dua.'
    if (values.position_secondary.includes(values.position_main)) return 'Posisi cadangan harus berbeda dari posisi utama.'
  }
  return ''
}
