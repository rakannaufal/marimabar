import { describe, expect, it } from 'vitest'
import { ownerGameFacts, publicGameFacts } from './models'
import type { GameProfile, Option, Player } from './models'

const options: Option[] = [
  { id: 'rank', game_id: 'g', kind: 'rank', code: 'epic', label: 'Epic', sort_order: 0 },
  { id: 'role', game_id: 'g', kind: 'role', code: 'mid', label: 'Mid Laner', sort_order: 0 },
  { id: 'region', game_id: 'g', kind: 'region', code: 'sea', label: 'SEA', sort_order: 0 },
]
const owner = (attributes: Record<string, unknown>): GameProfile => ({
  id: 'p', user_id: 'u', game_id: 'g', ign: 'HIDDEN', game_id_private: 'SECRET', region_option_id: 'region',
  primary_rank_option_id: 'rank', primary_rank_mode_option_id: null, primary_role_option_id: 'role',
  visibility: 'public', status: 'active', attributes,
})
const player = (game_name: string, attributes?: Record<string, unknown>): Player => ({
  id: 'p', user_id: 'u', game_id: 'g', game_name, display_name: 'Teman', avatar_url: null,
  ign: 'HIDDEN', rank: 'Epic', role: 'Mid Laner', region: 'SEA', ready: true, updated_at: '', bio: null, attributes,
})

describe('canonical game facts', () => {
  it('uses owner catalog rank and role, canonical MLBB positions, no private attributes', () => {
    expect(ownerGameFacts(owner({ position_main: 'Roam', position_secondary: 'Gold Lane', ign: 'LEAK', game_id_private: 'LEAK' }), 'mlbb', options))
      .toEqual([
        { label: 'Rank', value: 'Epic' }, { label: 'Posisi utama', value: 'Roam' },
        { label: 'Posisi kedua', value: 'Gold Lane' }, { label: 'Server', value: 'SEA' },
      ])
  })
  it('uses canonical attribute rank over stale catalog rank and joins two backup positions', () => {
    expect(ownerGameFacts(owner({ rank_current: 'Mythic', position_main: 'Roam', position_secondary: ['Jungle', 'EXP Lane'] }), 'mlbb', options))
      .toEqual([{ label: 'Rank', value: 'Mythic' }, { label: 'Posisi utama', value: 'Roam' }, { label: 'Posisi kedua', value: 'Jungle, EXP Lane' }, { label: 'Server', value: 'SEA' }])
  })
  it('shows MLBB stars beside the selected rank for the owner without a duplicate rank fact', () => {
    expect(ownerGameFacts(owner({ rank_current: 'Mythic Glory', rank_stars: 75 }), 'mlbb', options))
      .toContainEqual({ label: 'Rank', value: 'Mythic Glory · 75 bintang' })
  })
  it('does not mislabel an old MLBB hero role as a position', () => {
    expect(publicGameFacts({ ...player('Mobile Legends'), role: 'Tank' }))
      .toEqual([{ label: 'Rank', value: 'Epic' }, { label: 'Role', value: 'Tank' }, { label: 'Server', value: 'SEA' }])
  })
  it('shows PUBG queue mode and role without legacy duplicate role', () => {
    expect(ownerGameFacts(owner({ squad_role_main: 'Sniper', queue_mode: 'Squad' }), 'pubg-mobile', options))
      .toEqual([{ label: 'Rank', value: 'Epic' }, { label: 'Peran squad', value: 'Sniper' }, { label: 'Mode', value: 'Squad' }, { label: 'Server', value: 'SEA' }])
  })
  it('shows Free Fire rank for selected ranked mode only and never mixes BR/CS', () => {
    expect(ownerGameFacts(owner({ ranked_mode: 'Clash Squad Ranked', rank_br: 'Diamond', rank_cs: 'Heroic', team_role_main: 'Rusher' }), 'free-fire', options))
      .toEqual([{ label: 'Rank Clash Squad Ranked', value: 'Heroic' }, { label: 'Peran tim', value: 'Rusher' }, { label: 'Mode', value: 'Clash Squad Ranked' }, { label: 'Server', value: 'SEA' }])
  })
  it('does not label a Battle Royale rank as Clash Squad when CS rank is absent', () => {
    expect(ownerGameFacts(owner({ ranked_mode: 'Clash Squad Ranked', rank_br: 'Diamond' }), 'free-fire', options))
      .toEqual([{ label: 'Peran tim', value: 'Mid Laner' }, { label: 'Mode', value: 'Clash Squad Ranked' }, { label: 'Server', value: 'SEA' }])
  })
  it('shows Valorant agent role and mode, not unrelated raw attributes', () => {
    expect(ownerGameFacts(owner({ agent_role_main: 'Controller', game_mode: 'Competitive', token: 'LEAK' }), 'valorant', options))
      .toEqual([{ label: 'Rank', value: 'Epic' }, { label: 'Role agent', value: 'Controller' }, { label: 'Mode', value: 'Competitive' }, { label: 'Server', value: 'SEA' }])
  })
  it('uses public RPC rank/role, never untrusted duplicate rank/role or private fields', () => {
    expect(publicGameFacts(player('Mobile Legends', { position_main: 'Roam', position_secondary: 'Gold Lane', rank: 'FAKE', ign: 'LEAK', game_id_private: 'LEAK' })))
      .toEqual([{ label: 'Rank', value: 'Epic' }, { label: 'Posisi utama', value: 'Mid Laner' }, { label: 'Posisi kedua', value: 'Gold Lane' }, { label: 'Server', value: 'SEA' }])
  })
  it('shows only RPC fields if detail RPC has no public attributes', () => {
    expect(publicGameFacts(player('Valorant'))).toEqual([
      { label: 'Rank', value: 'Epic' }, { label: 'Role agent', value: 'Mid Laner' }, { label: 'Server', value: 'SEA' },
    ])
  })
  it('ignores non-string and unsupported attributes while trusting RPC rank', () => {
    expect(publicGameFacts({ ...player('Free Fire', { ranked_mode: 'Clash Squad', rank_br: 'Diamond', rank_cs: 'Heroic', team_role_main: { secret: true } }), rank: 'Diamond', role: null }))
      .toEqual([{ label: 'Rank', value: 'Diamond' }, { label: 'Mode', value: 'Clash Squad Ranked' }, { label: 'Server', value: 'SEA' }])
  })
})
