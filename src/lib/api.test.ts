import { describe,it,expect,vi,beforeEach } from 'vitest'
const {rpc,from}=vi.hoisted(()=>({rpc:vi.fn(),from:vi.fn()}))
vi.mock('./supabase',()=>({requireBackend:()=>({rpc,from})}))
import { searchProfiles,listAttributeDefinitions,createInvite,reportUser,profileDetail,addCatalogOption,applyModerationAction } from './api'
describe('kontrak API publik',()=>{
 beforeEach(()=>{rpc.mockReset();from.mockReset()})
 it('mengirim filter dan paginasi ke RPC server, bukan menyaring data pribadi di browser',async()=>{
  rpc.mockResolvedValue({data:[],error:null})
  expect(await searchProfiles('free-fire',{rank:'Heroic',roles:['Rusher','Support'],mode:'Clash Squad',ready:true},2)).toEqual([])
  expect(rpc).toHaveBeenCalledWith('search_game_profiles',{p_game_slug:'free-fire',p_rank:'Heroic',p_roles:['Rusher','Support'],p_mode:'Clash Squad',p_region:null,p_ready:true,p_limit:20,p_offset:40})
 })
 it('memuat definisi aktif terurut untuk satu game',async()=>{
  const rows=[{key:'role',label:'Role'}]
  const order=vi.fn().mockResolvedValue({data:rows,error:null})
  const active=vi.fn().mockReturnValue({order})
  const game=vi.fn().mockReturnValue({eq:active})
  const select=vi.fn().mockReturnValue({eq:game})
  from.mockReturnValue({select})
  expect(await listAttributeDefinitions('game-1')).toEqual(rows)
  expect(from).toHaveBeenCalledWith('game_attribute_definitions')
  expect(select).toHaveBeenCalledWith('game_id,key,label,category,value_type,filter_type,options,range_min,range_max,unit,sort_order,active')
  expect(game).toHaveBeenCalledWith('game_id','game-1')
  expect(active).toHaveBeenCalledWith('active',true)
  expect(order).toHaveBeenCalledWith('sort_order')
 })
 it('mengirim atribut dinamis ke RPC JSONB dengan paginasi',async()=>{
  rpc.mockResolvedValue({data:[],error:null})
  const attributes={role:['Tank'],rank_current:{min:'Epic',max:'Mythic'},voice_chat:false}
  await searchProfiles('mlbb',{attributes},1)
  expect(rpc).toHaveBeenCalledWith('search_game_profiles_by_attributes',{p_game_slug:'mlbb',p_filters:attributes,p_limit:20,p_offset:20})
 })
 it('mengembalikan detail kosong untuk profil yang tidak terlihat',async()=>{
  rpc.mockResolvedValue({data:[],error:null})
  expect(await profileDetail('123')).toBeNull()
 })
 it('ajakan dan laporan menggunakan RPC terproteksi',async()=>{
  rpc.mockResolvedValueOnce({data:{id:'invite-id'},error:null}).mockResolvedValueOnce({data:'report-id',error:null})
  expect(await createInvite('target','game','Hai')).toBe('invite-id')
  expect(rpc).toHaveBeenCalledWith('create_invite',{p_recipient:'target',p_game:'game',p_message:'Hai'})
  await reportUser('target','spam','Pesan mengganggu','profile-id')
  expect(rpc).toHaveBeenCalledWith('create_report',{p_reported:'target',p_category:'spam',p_description:'Pesan mengganggu',p_target_type:'profile',p_target_id:'profile-id'})
  rpc.mockResolvedValue({data:'report-id',error:null})
  await reportUser('target','spam','Pesan mengganggu','invite-id','invite')
  expect(rpc).toHaveBeenCalledWith('create_report',{p_reported:'target',p_category:'spam',p_description:'Pesan mengganggu',p_target_type:'invite',p_target_id:'invite-id'})
  await reportUser('target','spam','Pesan mengganggu','message-id','message')
  expect(rpc).toHaveBeenCalledWith('create_report',{p_reported:'target',p_category:'spam',p_description:'Pesan mengganggu',p_target_type:'message',p_target_id:'message-id'})
 })
 it('routes supported admin mutations to authorized RPCs',async()=>{
  rpc.mockResolvedValueOnce({data:'option-id',error:null}).mockResolvedValueOnce({data:'action-id',error:null})
  expect(await addCatalogOption('game-free-fire','rank','legendary','Legendary','mode-id')).toBe('option-id')
  expect(rpc).toHaveBeenCalledWith('add_catalog_option',{p_game:'game-free-fire',p_kind:'rank',p_code:'legendary',p_label:'Legendary',p_rank_mode:'mode-id'})
  expect(await applyModerationAction('demo-rival','hide_profile','Alasan moderasi','report-id')).toBe('action-id')
  expect(rpc).toHaveBeenCalledWith('apply_moderation_action',{p_subject:'demo-rival',p_action:'hide_profile',p_reason:'Alasan moderasi',p_report:'report-id'})
 })
 it('tidak menyembunyikan kesalahan RPC',async()=>{
  rpc.mockResolvedValue({data:null,error:{message:'Akses ditolak'}})
  await expect(createInvite('target','game')).rejects.toThrow('Akses ditolak')
 })
})
