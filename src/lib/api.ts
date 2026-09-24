import { requireBackend } from './supabase'
import type { Game, Player, SearchFilters, Option, GameProfile, Invite, Conversation, ChatMessage } from './models'

function unwrap<T>(result: {data:T|null;error:{message:string}|null}):T {
  if (result.error) throw new Error(result.error.message)
  if (result.data === null) throw new Error('Data tidak tersedia')
  return result.data
}
export async function listGames():Promise<Game[]> { return unwrap(await requireBackend().from('games').select('id,slug,name').eq('active',true).order('name')) as Game[] }
export async function listOptions(gameId:string):Promise<Option[]> { return unwrap(await requireBackend().from('game_catalog_options').select('id,game_id,kind,code,label,sort_order,rank_mode_option_id').eq('game_id',gameId).eq('active',true).order('sort_order')) as Option[] }
export async function searchProfiles(gameSlug:string,filters:SearchFilters={},page=0):Promise<Player[]> {
  return unwrap(await requireBackend().rpc('search_game_profiles',{p_game_slug:gameSlug,p_rank:filters.rank||null,p_roles:filters.roles?.length?filters.roles:null,p_mode:filters.mode||null,p_region:filters.region||null,p_ready:filters.ready??null,p_limit:20,p_offset:page*20})) as Player[]
}
export async function profileDetail(id:string):Promise<Player|null> { const data=unwrap(await requireBackend().rpc('public_profile_detail',{p_id:id})); return Array.isArray(data)?(data[0]||null):data as Player|null }
export async function createInvite(recipientId:string,gameId:string,message=''):Promise<string> { const row=unwrap(await requireBackend().rpc('create_invite',{p_recipient:recipientId,p_game:gameId,p_message:message})) as {id:string};return row.id }
export async function blockUser(id:string):Promise<void> { const client=requireBackend();const {data:{user},error:authError}=await client.auth.getUser();if(authError||!user)throw new Error('Masuk terlebih dahulu');const {error}=await client.from('blocks').insert({blocker_id:user.id,blocked_id:id});if(error)throw error }
export async function reportUser(id:string,category:string,description:string,targetId:string,targetType:'profile'|'invite'|'message'='profile'):Promise<void> { unwrap(await requireBackend().rpc('create_report',{p_reported:id,p_category:category,p_description:description,p_target_type:targetType,p_target_id:targetId})) }
export async function ownProfile(userId:string) { return unwrap(await requireBackend().from('profiles').select('user_id,display_name,bio,timezone,languages,voice_preference,play_style,availability_status,visibility').eq('user_id',userId).single()) }
export async function updateOwnProfile(userId:string,input:Record<string,unknown>) { return unwrap(await requireBackend().from('profiles').update(input).eq('user_id',userId).select('user_id').single()) }
export async function ownGameProfiles(userId:string):Promise<GameProfile[]> { return unwrap(await requireBackend().from('game_profiles').select('id,user_id,game_id,ign,game_id_private,region_option_id,primary_rank_option_id,primary_rank_mode_option_id,primary_role_option_id,visibility,status,attributes').eq('user_id',userId).order('created_at')) as GameProfile[] }
export async function saveGameProfile(input:Record<string,unknown>,id?:string) { return unwrap(id ? await requireBackend().from('game_profiles').update(input).eq('id',id).select('id').single() : await requireBackend().from('game_profiles').insert(input).select('id').single()) }
export async function listInvites(userId:string):Promise<Invite[]> { return unwrap(await requireBackend().from('invites').select('id,sender_id,recipient_id,game_id,message,status,created_at,expires_at').or(`sender_id.eq.${userId},recipient_id.eq.${userId}`).order('created_at',{ascending:false}).limit(100)) as Invite[] }
export async function respondInvite(id:string,decision:'accepted'|'rejected'):Promise<void> { unwrap(await requireBackend().rpc('respond_invite',{p_id:id,p_accept:decision==='accepted'})) }
export async function cancelInvite(id:string):Promise<void> { unwrap(await requireBackend().rpc('cancel_invite',{p_id:id})) }
export async function listConversations(userId:string):Promise<Conversation[]> { return unwrap(await requireBackend().from('conversations').select('id,invite_id,participant_low,participant_high,status').or(`participant_low.eq.${userId},participant_high.eq.${userId}`).order('created_at',{ascending:false})) as Conversation[] }
export async function listMessages(conversationId:string):Promise<ChatMessage[]> { return unwrap(await requireBackend().from('messages').select('id,conversation_id,sender_id,body,created_at').eq('conversation_id',conversationId).order('created_at',{ascending:true}).limit(100)) as ChatMessage[] }
export async function sendMessage(conversationId:string,body:string):Promise<void> { unwrap(await requireBackend().rpc('send_message',{p_conversation:conversationId,p_body:body})) }
export async function shareGameId(conversationId:string,gameProfileId:string):Promise<void> { unwrap(await requireBackend().rpc('share_game_id',{p_conversation:conversationId,p_game_profile:gameProfileId})) }
export async function readSharedGameId(conversationId:string,ownerId:string):Promise<string|null> { const {data,error}=await requireBackend().rpc('read_shared_game_id',{p_conversation:conversationId,p_owner:ownerId});if(error)throw error;return data as string|null }
export async function isAdmin(userId:string):Promise<boolean> { const {data,error}=await requireBackend().from('user_roles').select('role').eq('user_id',userId).maybeSingle(); if(error) throw error; return data?.role==='admin' }
// SQL exposes option creation and moderation RPCs only. Game CRUD and report status edits remain unsupported.
export async function addCatalogOption(gameId:string,kind:string,code:string,label:string,rankModeId:string|null=null):Promise<string> { return unwrap(await requireBackend().rpc('add_catalog_option',{p_game:gameId,p_kind:kind,p_code:code,p_label:label,p_rank_mode:rankModeId})) as string }
export async function applyModerationAction(subjectId:string,action:'hide_profile'|'restrict_account'|'restore_profile'|'restore_account',reason:string,reportId:string|null=null):Promise<string> { return unwrap(await requireBackend().rpc('apply_moderation_action',{p_subject:subjectId,p_action:action,p_reason:reason,p_report:reportId})) as string }
