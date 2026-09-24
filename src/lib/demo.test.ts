import { beforeEach, describe, expect, it } from 'vitest'
import { demoBackend, demoLogin, demoLogout, resetDemo } from './demo'

beforeEach(() => { resetDemo(); demoLogout() })
describe('isolated synthetic demo', () => {
 it('offers public games and filterable profiles without private game IDs', async () => {
  const games = await demoBackend.from('games').select('*').eq('active',true).order('name')
  expect(games.data.map((game:{slug:string})=>game.slug).sort()).toEqual(['free-fire','mlbb','pubg-mobile','valorant'])
  const result = await demoBackend.rpc('search_game_profiles',{p_game_slug:'free-fire',p_rank:'heroic',p_roles:null,p_mode:'battle-royale',p_region:null,p_ready:null,p_offset:0,p_limit:20})
  expect(result.data.length).toBeGreaterThan(0)
  expect(JSON.stringify(result.data)).not.toContain('DEMO-PRIVATE')
 })
 it('requires persona for mutations; accepts invitation and restricts private ID to explicit share', async () => {
  const players = (await demoBackend.rpc('search_game_profiles',{p_game_slug:'mlbb'})).data.filter((p:{user_id:string})=>p.user_id==='demo-rival')
  expect((await demoBackend.rpc('create_invite',{p_recipient:players[0].user_id,p_game:players[0].game_id})).error).toBeTruthy()
  demoLogin('demo-player')
  const invite = await demoBackend.rpc('create_invite',{p_recipient:players[0].user_id,p_game:players[0].game_id})
  expect(invite.error).toBeNull()
  demoLogin(players[0].user_id)
  expect((await demoBackend.rpc('respond_invite',{p_id:invite.data.id,p_accept:true})).error).toBeNull()
  const conversations = (await demoBackend.from('conversations').select('*').or(`participant_low.eq.${players[0].user_id},participant_high.eq.${players[0].user_id}`)).data
  expect(conversations.length).toBeGreaterThan(0)
  const id = conversations[0].id
  expect((await demoBackend.rpc('read_shared_game_id',{p_conversation:id,p_owner:'demo-player'})).data).toBeNull()
  demoLogin('demo-player')
  const own = (await demoBackend.from('game_profiles').select('*').eq('user_id','demo-player').eq('game_id',players[0].game_id)).data
  expect((await demoBackend.rpc('share_game_id',{p_conversation:id,p_game_profile:own[0].id})).error).toBeNull()
  demoLogin(players[0].user_id)
  expect((await demoBackend.rpc('read_shared_game_id',{p_conversation:id,p_owner:'demo-player'})).data).toContain('DEMO-PRIVATE')
 })
 it('sends messages only inside accepted conversation', async () => {
  demoLogin('demo-player')
  expect((await demoBackend.rpc('send_message',{p_conversation:'unknown',p_body:'Halo'})).error).toBeTruthy()
  expect((await demoBackend.rpc('respond_invite',{p_id:'invite-seeded',p_accept:true})).error).toBeNull()
  const c=(await demoBackend.from('conversations').select('*').or('participant_low.eq.demo-player,participant_high.eq.demo-player')).data[0]
  expect((await demoBackend.rpc('send_message',{p_conversation:c.id,p_body:'Halo'})).error).toBeNull()
  expect((await demoBackend.from('messages').select('*').eq('conversation_id',c.id)).data[0].body).toBe('Halo')
 })
 it('requires admin persona for moderation and catalog changes', async () => {
  demoLogin('demo-player')
  expect((await demoBackend.rpc('add_catalog_option',{p_game:'game-free-fire',p_kind:'role',p_code:'tank',p_label:'Tank'})).error).toBeTruthy()
  demoLogin('demo-admin')
  expect((await demoBackend.rpc('add_catalog_option',{p_game:'game-free-fire',p_kind:'role',p_code:'tank',p_label:'Tank'})).error).toBeNull()
  expect((await demoBackend.rpc('apply_moderation_action',{p_subject:'demo-rival',p_action:'hide_profile',p_reason:'Contoh moderasi'})).error).toBeNull()
  expect((await demoBackend.rpc('search_game_profiles',{p_game_slug:'free-fire'})).data.some((p:{user_id:string})=>p.user_id==='demo-rival')).toBe(false)
 })
 it('refuses updates to another persona and preserves edits across reads', async () => {
  demoLogin('demo-player')
  expect((await demoBackend.from('profiles').update({display_name:'Baru'}).eq('user_id','demo-player').select('user_id').single()).error).toBeNull()
  expect((await demoBackend.from('profiles').select('*').eq('user_id','demo-player').single()).data.display_name).toBe('Baru')
  expect((await demoBackend.from('profiles').update({display_name:'Bajak'}).eq('user_id','demo-rival').select('user_id').single()).error).toBeTruthy()
 })
 it('mirrors four game catalogs and mode-specific ranks from SQL seed', async () => {
  const expected:Record<string,Record<string,string[]>>={
   mlbb:{rank:['warrior','elite','master','grandmaster','epic','legend','mythic','mythical-glory'],role:['tank','fighter','assassin','mage','marksman','support'],mode:['classic','ranked','brawl']},
   'pubg-mobile':{rank:['bronze','silver','gold','platinum','diamond','crown','ace','conqueror'],role:['igl','rusher','support','sniper'],mode:['classic','arena']},
   'free-fire':{rank:['bronze','silver','gold','platinum','diamond','heroic','grandmaster'],role:['rusher','support','sniper','igl'],mode:['battle-royale','clash-squad']},
   valorant:{rank:['iron','bronze','silver','gold','platinum','diamond','ascendant','immortal','radiant'],role:['duelist','initiator','controller','sentinel'],mode:['competitive','unrated','swiftplay']}
  }
  for(const [slug,kinds] of Object.entries(expected)){
   const options=(await demoBackend.from('game_catalog_options').select('*').eq('game_id',`game-${slug}`)).data
   for(const [kind,codes] of Object.entries(kinds)) expect(options.filter((o:{kind:string;code:string})=>o.kind===kind&&!(slug==='free-fire'&&o.code.endsWith('-cs'))).map((o:{code:string})=>o.code)).toEqual(codes)
  }
  const ff=(await demoBackend.from('game_catalog_options').select('*').eq('game_id','game-free-fire')).data
  const br=ff.find((o:{kind:string;code:string})=>o.kind==='mode'&&o.code==='battle-royale')
  const cs=ff.find((o:{kind:string;code:string})=>o.kind==='mode'&&o.code==='clash-squad')
  expect(ff.find((o:{code:string;rank_mode_option_id:string})=>o.code==='heroic'&&o.rank_mode_option_id===br.id)).toBeTruthy()
  expect(ff.find((o:{code:string;rank_mode_option_id:string})=>o.code==='heroic-cs'&&o.rank_mode_option_id===cs.id)).toBeTruthy()
  expect((await demoBackend.rpc('search_game_profiles',{p_game_slug:'free-fire',p_rank:'heroic',p_mode:'clash-squad'})).data).toEqual([])
  expect((await demoBackend.rpc('search_game_profiles',{p_game_slug:'free-fire',p_rank:'heroic',p_mode:'battle-royale'})).data.length).toBeGreaterThan(0)
  expect((await demoBackend.rpc('search_game_profiles',{p_game_slug:'free-fire',p_rank:'heroic'})).data).toEqual([])
 })
 it('keeps all private tables owner-scoped despite filters and returning clauses', async () => {
  demoLogin('demo-player')
  for(const table of ['profiles','game_profiles','invites','user_roles'] as const){
   const rows=(await demoBackend.from(table).select('*')).data
   expect(rows.every((r:Record<string,string>)=>table==='invites'?['sender_id','recipient_id'].some(k=>r[k]==='demo-player'):r.user_id==='demo-player')).toBe(true)
  }
  expect((await demoBackend.from('game_profiles').select('*').eq('user_id','demo-rival')).data).toEqual([])
  expect((await demoBackend.from('game_profiles').select('game_id_private').eq('user_id','demo-rival').single()).data).toBeNull()
  expect((await demoBackend.from('profiles').update({user_id:'demo-rival'}).eq('user_id','demo-player').select('*').single()).error).toBeTruthy()
  expect((await demoBackend.from('game_profiles').update({user_id:'demo-rival',game_id_private:'STOLEN'}).eq('user_id','demo-player').select('*').single()).error).toBeTruthy()
  expect((await demoBackend.from('game_profiles').insert({user_id:'demo-rival',game_id:'game-free-fire',ign:'Fake'}).select('*').single()).error).toBeTruthy()
  expect((await demoBackend.from('user_roles').update({role:'admin'}).eq('user_id','demo-player').select('*').single()).error).toBeTruthy()
  expect((await demoBackend.from('games').update({active:false}).eq('id','game-free-fire').select('*').single()).error).toBeTruthy()
  expect((await demoBackend.from('game_catalog_options').insert({game_id:'game-free-fire',kind:'role',code:'fake',label:'Fake'})).error).toBeTruthy()
  demoLogout()
  expect((await demoBackend.from('profiles').select('*')).data).toEqual([])
  expect((await demoBackend.from('invites').select('*')).data).toEqual([])
 })
 it('suppresses blocked players from public search and detail',async()=>{
  const rival=(await demoBackend.rpc('search_game_profiles',{p_game_slug:'valorant'})).data.find((p:{user_id:string})=>p.user_id==='demo-rival')
  demoLogin('demo-player')
  expect((await demoBackend.from('blocks').insert({blocker_id:'demo-player',blocked_id:'demo-rival'})).error).toBeNull()
  expect((await demoBackend.rpc('public_profile_detail',{p_id:rival.id})).data).toEqual([])
  expect((await demoBackend.rpc('search_game_profiles',{p_game_slug:'valorant'})).data.some((p:{user_id:string})=>p.user_id==='demo-rival')).toBe(false)
  expect((await demoBackend.rpc('create_invite',{p_recipient:'demo-rival',p_game:rival.game_id})).error).toBeTruthy()
  demoLogin('demo-rival')
  expect((await demoBackend.rpc('public_profile_detail',{p_id:'profile-3-0'})).data).toEqual([])
 })
 it('revokes chat and shared ID reads in both block directions', async () => {
  demoLogin('demo-player')
  expect((await demoBackend.rpc('respond_invite',{p_id:'invite-seeded',p_accept:true})).error).toBeNull()
  const c=(await demoBackend.from('conversations').select('*')).data[0]
  const own=(await demoBackend.from('game_profiles').select('*').eq('game_id','game-free-fire')).data[0]
  expect((await demoBackend.rpc('share_game_id',{p_conversation:c.id,p_game_profile:own.id})).error).toBeNull()
  demoLogin('demo-rival')
  expect((await demoBackend.rpc('read_shared_game_id',{p_conversation:c.id,p_owner:'demo-player'})).data).toContain('DEMO-PRIVATE')
  expect((await demoBackend.from('blocks').insert({blocker_id:'demo-rival',blocked_id:'demo-player'})).error).toBeNull()
  expect((await demoBackend.rpc('read_shared_game_id',{p_conversation:c.id,p_owner:'demo-player'})).data).toBeNull()
  expect((await demoBackend.from('conversations').select('*')).data).toEqual([])
  expect((await demoBackend.from('messages').select('*')).data).toEqual([])
  expect((await demoBackend.rpc('share_game_id',{p_conversation:c.id,p_game_profile:own.id})).error).toBeTruthy()
  demoLogin('demo-player')
  expect((await demoBackend.from('conversations').select('*')).data).toEqual([])
  expect((await demoBackend.rpc('read_shared_game_id',{p_conversation:c.id,p_owner:'demo-rival'})).data).toBeNull()
 })
 it('rejects unsupported game CRUD even for admin and validates catalog rank modes',async()=>{
  demoLogin('demo-admin')
  expect((await demoBackend.from('games').insert({slug:'new-game',name:'New Game'})).error).toBeTruthy()
  expect((await demoBackend.from('games').update({active:false}).eq('id','game-valorant')).error).toBeTruthy()
  expect((await demoBackend.rpc('add_catalog_option',{p_game:'game-free-fire',p_kind:'rank',p_code:'legendary',p_label:'Legendary',p_rank_mode:'option-pubg-mobile-mode-classic'})).error).toBeTruthy()
  expect((await demoBackend.rpc('add_catalog_option',{p_game:'game-free-fire',p_kind:'rank',p_code:'legendary',p_label:'Legendary',p_rank_mode:'option-free-fire-mode-clash-squad'})).error).toBeNull()
 })
 it('enforces game-rank option integrity and prevents returned-row state mutation',async()=>{
  demoLogin('demo-player')
  const own=(await demoBackend.from('game_profiles').select('*').eq('user_id','demo-player').eq('game_id','game-pubg-mobile')).data[0]
  const invalid=await demoBackend.from('game_profiles').update({primary_rank_mode_option_id:'option-pubg-mobile-mode-arena'}).eq('id',own.id).select('*').single()
  expect(invalid.error).toBeTruthy()
  expect((await demoBackend.from('game_profiles').select('*').eq('id',own.id).single()).data.primary_rank_mode_option_id).toBe('option-pubg-mobile-mode-classic')
  const read=(await demoBackend.from('game_profiles').select('*').eq('id',own.id).single()).data
  read.game_id_private='tampered'
  expect((await demoBackend.from('game_profiles').select('*').eq('id',own.id).single()).data.game_id_private).not.toBe('tampered')
  expect((await demoBackend.rpc('search_game_profiles',{p_game_slug:'pubg-mobile',p_rank:'gold',p_mode:'arena'})).data).toEqual([])
  expect((await demoBackend.rpc('search_game_profiles',{p_game_slug:'pubg-mobile',p_rank:'gold',p_mode:'classic'})).data.length).toBeGreaterThan(0)
 })
 it('allows only participants to report invite and message evidence',async()=>{
  demoLogin('demo-player')
  const invite=await demoBackend.rpc('create_report',{p_reported:'demo-rival',p_category:'spam',p_description:'Ajakan spam berulang kali',p_target_type:'invite',p_target_id:'invite-seeded'})
  expect(invite.error).toBeNull()
  expect((await demoBackend.rpc('respond_invite',{p_id:'invite-seeded',p_accept:true})).error).toBeNull()
  const c=(await demoBackend.from('conversations').select('*')).data[0]
  demoLogin('demo-rival')
  const message=await demoBackend.rpc('send_message',{p_conversation:c.id,p_body:'Pesan untuk dilaporkan'})
  expect(message.error).toBeNull()
  demoLogin('demo-player')
  expect((await demoBackend.rpc('create_report',{p_reported:'demo-rival',p_category:'harassment',p_description:'Pesan yang mengganggu',p_target_type:'message',p_target_id:message.data.id})).error).toBeNull()
  expect((await demoBackend.rpc('create_report',{p_reported:'demo-admin',p_category:'spam',p_description:'Salah sasaran invite',p_target_type:'invite',p_target_id:'invite-seeded'})).error).toBeTruthy()
  demoLogin('demo-admin')
  expect((await demoBackend.rpc('create_report',{p_reported:'demo-rival',p_category:'harassment',p_description:'Bukan peserta percakapan',p_target_type:'message',p_target_id:message.data.id})).error).toBeTruthy()
 })
 it('validates report evidence and restricts moderation to admin',async()=>{
  demoLogin('demo-player')
  expect((await demoBackend.rpc('create_report',{p_reported:'demo-rival',p_category:'spam',p_description:'Spam berulang sekali',p_target_type:'profile',p_target_id:'profile-0-1'})).error).toBeNull()
  expect((await demoBackend.rpc('create_report',{p_reported:'demo-rival',p_category:'spam',p_description:'Spam berulang sekali',p_target_type:'profile',p_target_id:'profile-0-1'})).error).toBeTruthy()
  expect((await demoBackend.rpc('create_report',{p_reported:'demo-rival',p_category:'spam',p_description:'Spam berulang sekali',p_target_type:'message',p_target_id:'unknown'})).error).toBeTruthy()
  expect((await demoBackend.rpc('apply_moderation_action',{p_subject:'demo-rival',p_action:'hide_profile',p_reason:'Contoh moderasi'})).error).toBeTruthy()
  demoLogin('demo-admin')
  expect((await demoBackend.rpc('apply_moderation_action',{p_subject:'demo-admin',p_action:'restrict_account',p_reason:'Contoh moderasi'})).error).toBeTruthy()
  expect((await demoBackend.rpc('apply_moderation_action',{p_subject:'demo-rival',p_action:'hide_profile',p_reason:'Contoh moderasi',p_report:'unknown'})).error).toBeTruthy()
 })
})
