-- Forward-only authorization and moderation workflow hardening.
-- Existing user data is preserved; no client may modify moderation audit tables.
-- Privileged operations require the same verified, adult account gate as user mutations.
create or replace function private.is_admin() returns boolean language sql stable security definer set search_path = '' as $$
 select private.verified() and exists(select 1 from public.user_roles r
   join public.profiles p on p.user_id=r.user_id where r.user_id=auth.uid()
   and r.role='admin' and p.account_status='active' and p.adult_declared_at is not null)
$$;
drop policy insert_blocks on public.blocks;
create policy insert_blocks on public.blocks for insert to authenticated
 with check (blocker_id=auth.uid() and private.is_active(auth.uid()) and private.is_active(blocked_id));
drop policy delete_blocks on public.blocks;
create policy delete_blocks on public.blocks for delete to authenticated
 using (blocker_id=auth.uid() and private.is_active(auth.uid()));
drop policy mark_notification on public.notifications;
create policy mark_notification on public.notifications for update to authenticated
 using (user_id=auth.uid() and private.is_active(auth.uid()))
 with check (user_id=auth.uid() and private.is_active(auth.uid()));
-- An expired invite or blocked pair must never reveal the old invite payload.
drop policy own_invites on public.invites;
create policy own_invites on public.invites for select to authenticated
 using (auth.uid() in(sender_id,recipient_id) and private.is_active(auth.uid())
   and not private.blocked(sender_id,recipient_id));
-- Reports are visible to their author as status only through a narrow RPC;
-- underlying descriptions and evidence are for active admins.
drop policy own_reports on public.reports;
create policy own_reports on public.reports for select to authenticated using(private.is_admin());
create function public.my_report_status()
returns table(id uuid,reported_id uuid,category text,target_type text,status text,created_at timestamptz,resolved_at timestamptz)
language sql stable security definer set search_path = '' as $$
 select r.id,r.reported_id,r.category,r.target_type,r.status,r.created_at,r.resolved_at
 from public.reports r where r.reporter_id=auth.uid() and private.is_active(auth.uid())
 order by r.created_at desc limit 100
$$;
-- Case changes are atomic and preserve the reviewer identity.
create function public.review_report(p_id uuid,p_status text) returns void
language plpgsql security definer set search_path = '' as $$
begin
 if not private.is_admin() or p_status is null or p_status not in ('reviewing','resolved','dismissed') then
   raise exception 'Tinjauan tidak diizinkan'; end if;
 update public.reports set status=p_status,reviewed_by=auth.uid(),
   resolved_at=case when p_status in ('resolved','dismissed') then now() else null end
 where id=p_id and (status='new' and p_status='reviewing'
   or status='reviewing' and p_status in ('resolved','dismissed'));
 if not found then raise exception 'Transisi laporan tidak valid'; end if;
end $$;
-- A restricted person must still be able to appeal, without reopening chat or discovery.
create function public.submit_appeal(p_action uuid,p_reason text) returns uuid
language plpgsql security definer set search_path = '' as $$
declare v_id uuid;
begin
 if auth.uid() is null or p_reason is null or char_length(trim(p_reason)) not between 10 and 1000
 or not exists (select 1 from public.moderation_actions a join public.profiles p
   on p.user_id=a.subject_user_id where a.id=p_action and a.subject_user_id=auth.uid()
   and p.account_status<>'deletion_pending') then raise exception 'Banding tidak diizinkan'; end if;
 insert into public.appeals(user_id,moderation_action_id,reason)
 values(auth.uid(),p_action,trim(p_reason)) returning id into v_id;
 return v_id;
end $$;
create function public.review_appeal(p_id uuid,p_status text) returns void
language plpgsql security definer set search_path = '' as $$
begin
 if not private.is_admin() or p_status is null or p_status not in ('reviewing','resolved','rejected') then
   raise exception 'Tinjauan tidak diizinkan'; end if;
 update public.appeals set status=p_status,reviewed_by=auth.uid(),
   resolved_at=case when p_status in ('resolved','rejected') then now() else null end
 where id=p_id and (status='submitted' and p_status='reviewing'
   or status='reviewing' and p_status in ('resolved','rejected'));
 if not found then raise exception 'Transisi banding tidak valid'; end if;
end $$;
-- Admin catalog edits and every moderation state change leave immutable audit records.
create table public.admin_audit (
 id uuid primary key default gen_random_uuid(), actor_id uuid references public.profiles(user_id),
 entity text not null, entity_id uuid not null, action text not null,
 before_data jsonb, after_data jsonb, created_at timestamptz not null default now()
);
alter table public.admin_audit enable row level security;
revoke all on public.admin_audit from public,anon,authenticated;
create function private.audit_admin_changes() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
 insert into public.admin_audit(actor_id,entity,entity_id,action,before_data,after_data)
 values(auth.uid(),tg_table_name,case when tg_op='DELETE' then old.id else new.id end,
 tg_op,case when tg_op='INSERT' then null else to_jsonb(old) end,
 case when tg_op='DELETE' then null else to_jsonb(new) end);
 return case when tg_op='DELETE' then old else new end;
end $$;
create trigger audit_moderation after insert on public.moderation_actions
 for each row execute function private.audit_admin_changes();
create trigger audit_reports after update on public.reports
 for each row when (old.status is distinct from new.status) execute function private.audit_admin_changes();
create trigger audit_appeals after update on public.appeals
 for each row when (old.status is distinct from new.status) execute function private.audit_admin_changes();
create trigger audit_catalog after insert or update or delete on public.game_catalog_options
 for each row execute function private.audit_admin_changes();
-- No one gets PUBLIC execution on newly created SECURITY DEFINER routines.
revoke all on function public.my_report_status(),public.review_report(uuid,text),
 public.submit_appeal(uuid,text),public.review_appeal(uuid,text),private.audit_admin_changes()
 from public,anon,authenticated;
grant execute on function public.my_report_status(),public.review_report(uuid,text),
 public.submit_appeal(uuid,text),public.review_appeal(uuid,text) to authenticated;
