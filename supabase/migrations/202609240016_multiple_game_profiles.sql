-- Allow separate accounts/profiles for the same game and owner-controlled deletion.
alter table public.game_profiles drop constraint if exists game_profiles_user_id_game_id_key;

grant delete on public.game_profiles to authenticated;
create policy delete_game_profile on public.game_profiles for delete to authenticated
 using (user_id=auth.uid() and private.is_active(auth.uid()));
