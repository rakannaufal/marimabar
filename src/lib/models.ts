export interface Game { id:string; slug:string; name:string }
export interface Player { id:string; user_id:string; game_id:string; game_name:string; display_name:string; avatar_url:string|null; ign:string; rank:string|null; role:string|null; region:string|null; ready:boolean; updated_at:string; bio:string|null }
export interface SearchFilters { attributes?:Record<string,unknown>; rank?:string; roles?:string[]; mode?:string; region?:string; ready?:boolean }
export interface AttributeDefinition { game_id:string; key:string; label:string; category:string; value_type:string; filter_type:string; options:string[]|string|null; range_min:number|null; range_max:number|null; unit:string|null; sort_order:number; active:boolean }
export interface Option { id:string; game_id:string; kind:string; code:string; label:string; sort_order:number; rank_mode_option_id?:string|null }
export interface GameProfile { id:string; user_id:string; game_id:string; ign:string; game_id_private:string|null; region_option_id:string|null; primary_rank_option_id:string|null; primary_rank_mode_option_id:string|null; primary_role_option_id:string|null; visibility:string; status:string; attributes:Record<string,unknown> }
export interface Invite { id:string; sender_id:string; recipient_id:string; game_id:string; message:string|null; status:string; created_at:string; expires_at:string }
export interface Conversation { id:string; invite_id:string; participant_low:string; participant_high:string; status:string }
export interface ChatMessage { id:string; conversation_id:string; sender_id:string; body:string; created_at:string }
