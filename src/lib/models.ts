export interface Game { id:string; slug:string; name:string }
export interface Player { id:string; user_id:string; game_id:string; game_name:string; game_slug?:string; display_name:string; avatar_url:string|null; ign:string; rank:string|null; role:string|null; region:string|null; ready:boolean; updated_at:string; bio:string|null; attributes?:Record<string,unknown>|null; verified?:boolean }
export interface SearchFilters { attributes?:Record<string,unknown>; rank?:string; roles?:string[]; mode?:string; region?:string; ready?:boolean }
export interface AttributeDefinition { game_id:string; key:string; label:string; category:string; value_type:string; filter_type:string; options:string[]|string|null; range_min:number|null; range_max:number|null; unit:string|null; sort_order:number; active:boolean }
export interface Option { id:string; game_id:string; kind:string; code:string; label:string; sort_order:number; rank_mode_option_id?:string|null }
export interface GameProfile { id:string; user_id:string; game_id:string; ign:string; game_id_private:string|null; region_option_id:string|null; primary_rank_option_id:string|null; primary_rank_mode_option_id:string|null; primary_role_option_id:string|null; visibility:string; status:string; attributes:Record<string,unknown> }
export interface FriendRequest { id:string; requester_id:string; recipient_id:string; status:'pending'|'accepted'|'rejected'; created_at:string; responded_at:string|null }
export interface FriendContact { ign:string|null; game_id_private:string|null; discord:string|null }
export interface FriendRequestPlayer { user_id:string; display_name:string; game_profile_id:string|null }
export interface FriendProfileGame { user_id:string; display_name:string; avatar_url:string|null; bio:string|null; discord:string|null; game_profile_id:string|null; game_id:string|null; game_name:string|null; game_slug:string|null; ign:string|null; game_id_private:string|null; rank:string|null; role:string|null; region:string|null; ready:boolean|null; attributes:Record<string,unknown>|null }
export interface Invite { id:string; sender_id:string; recipient_id:string; game_id:string; message:string|null; status:string; created_at:string; expires_at:string }
export interface Conversation { id:string; invite_id:string; participant_low:string; participant_high:string; status:string }
export interface ChatMessage { id:string; conversation_id:string; sender_id:string; body:string; created_at:string }

export interface GameFact { label:string; value:string }
type GameKind = 'mlbb'|'pubg-mobile'|'free-fire'|'valorant'|null
function gameKind(nameOrSlug:string):GameKind {
  const value = nameOrSlug.toLowerCase().trim()
  if (['mlbb','mobile legends','mobile legends: bang bang'].includes(value)) return 'mlbb'
  if (['pubg-mobile','pubg mobile'].includes(value)) return 'pubg-mobile'
  if (['free-fire','free fire'].includes(value)) return 'free-fire'
  if (value === 'valorant') return 'valorant'
  return null
}
function text(value:unknown):string {
  if (typeof value === 'string') return value.trim()
  if (Array.isArray(value) && value.every(item => typeof item === 'string')) return value.map(item => item.trim()).filter(Boolean).join(', ')
  return ''
}
function add(facts:GameFact[],label:string,value:unknown):void {
  const clean = text(value)
  if (clean) facts.push({label,value:clean})
}
function attribute(attributes:Record<string,unknown>|null|undefined,key:string):string {
  return text(attributes?.[key])
}
function rankedMode(attributes:Record<string,unknown>|null|undefined):'Battle Royale Ranked'|'Clash Squad Ranked'|null {
  const mode = attribute(attributes,'ranked_mode').toLowerCase().replace(/[-_]/g,' ')
  if (['battle royale','battle royale ranked','br'].includes(mode)) return 'Battle Royale Ranked'
  if (['clash squad','clash squad ranked','cs'].includes(mode)) return 'Clash Squad Ranked'
  return null
}
function factLabels(kind:GameKind):{role:string;key:string;mode:string|null} {
  switch (kind) {
    case 'mlbb': return {role:'Posisi utama',key:'position_main',mode:null}
    case 'pubg-mobile': return {role:'Peran squad',key:'squad_role_main',mode:'queue_mode'}
    case 'free-fire': return {role:'Peran tim',key:'team_role_main',mode:'ranked_mode'}
    case 'valorant': return {role:'Role agent',key:'agent_role_main',mode:'game_mode'}
    default: return {role:'Role',key:'',mode:null}
  }
}
function gameFacts(kind:GameKind,rank:unknown,role:unknown,region:unknown,attributes:Record<string,unknown>|null|undefined,owner:boolean):GameFact[] {
  const facts:GameFact[] = []
  const labels = factLabels(kind)
  const ffMode = kind === 'free-fire' ? rankedMode(attributes) : null
  const selectedRank = owner && ffMode ? attribute(attributes,ffMode === 'Clash Squad Ranked' ? 'rank_cs' : 'rank_br') : ''
  const rankKey = kind === 'mlbb' || kind === 'valorant' ? 'rank_current' : kind === 'pubg-mobile' ? 'rank_tier' : ''
  const rankValue = owner && ffMode ? selectedRank : owner && rankKey ? attribute(attributes,rankKey) || text(rank) : text(rank)
  const stars = kind === 'mlbb' && owner && ['Mythic Glory', 'Mythic Immortal'].includes(rankValue) &&
    typeof attributes?.rank_stars === 'number' && Number.isInteger(attributes.rank_stars) ? attributes.rank_stars : null
  add(facts,owner && ffMode ? `Rank ${ffMode}` : 'Rank',stars === null ? rankValue : `${rankValue} · ${stars} bintang`)
  const roleLabel = kind === 'mlbb' && ['Tank','Fighter','Assassin','Mage','Marksman','Support'].includes(text(role)) && !attribute(attributes,'position_main') ? 'Role' : labels.role
  add(facts,roleLabel,owner ? attribute(attributes,labels.key) || role : role || attribute(attributes,labels.key))
  if (kind === 'mlbb') add(facts,'Posisi kedua',attribute(attributes,'position_secondary'))
  if (labels.mode) add(facts,'Mode',kind === 'free-fire' ? ffMode : attribute(attributes,labels.mode))
  if (kind === 'mlbb') { add(facts,'Mode permainan',attribute(attributes,'match_type')); add(facts,'Hero andalan',attribute(attributes,'hero_pool')) }
  if (kind === 'pubg-mobile') { add(facts,'Perspektif',attribute(attributes,'perspective')); add(facts,'Ukuran tim',attribute(attributes,'mode')); add(facts,'Peta pilihan',attribute(attributes,'favorite_map')); add(facts,'Perangkat',attribute(attributes,'device')) }
  if (kind === 'free-fire') add(facts,'Karakter andalan',attribute(attributes,'main_character'))
  if (kind === 'valorant') { add(facts,'Agent andalan',attribute(attributes,'main_agent')); add(facts,'Tugas tim',attribute(attributes,'team_role')) }
  add(facts,'Tujuan main',attribute(attributes,'play_goal'))
  add(facts,'Jam aktif (waktu setempat)',attribute(attributes,'active_hours'))
  if (attributes?.voice_chat === true) add(facts,'Voice chat','Ya')
  else if (attributes?.voice_chat === false) add(facts,'Voice chat','Tidak')
  else add(facts,'Voice chat',attribute(attributes,'voice_chat'))
  add(facts,'Server',region)
  return facts
}
/** Public facts use server-supplied canonical rank/role; never render raw attributes wholesale. */
export function publicGameFacts(player:Player):GameFact[] {
  return gameFacts(gameKind(player.game_slug || player.game_name),player.rank,player.role,player.region,player.attributes,false)
}
/** Owner facts use catalog labels plus the owner's canonical per-game attributes. */
export function ownerGameFacts(profile:GameProfile,gameSlug:string,options:Option[]):GameFact[] {
  const label = (id:string|null) => options.find(option => option.game_id === profile.game_id && option.id === id)?.label || ''
  return gameFacts(gameKind(gameSlug),label(profile.primary_rank_option_id),label(profile.primary_role_option_id),label(profile.region_option_id),profile.attributes,true)
}
