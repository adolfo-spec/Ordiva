
create schema if not exists ordiva_test_private;
revoke all on schema ordiva_test_private from public;
grant usage on schema ordiva_test_private to authenticated;
create table public.ordiva_test_spaces(id uuid primary key default gen_random_uuid(),name text not null check(length(name) between 1 and 80),owner_id uuid not null references auth.users(id));
create table public.ordiva_test_members(space_id uuid references public.ordiva_test_spaces on delete cascade,user_id uuid references auth.users on delete cascade,primary key(space_id,user_id));
create index on public.ordiva_test_members(user_id);
create index on public.ordiva_test_spaces(owner_id);
create table public.ordiva_test_invites(id uuid primary key default gen_random_uuid(),space_id uuid not null references public.ordiva_test_spaces on delete cascade,email text not null check(email=lower(trim(email))),expires_at timestamptz not null default now()+interval '7 days');
create index on public.ordiva_test_invites(space_id);
create table public.ordiva_test_entries(id uuid primary key default gen_random_uuid(),space_id uuid references public.ordiva_test_spaces on delete cascade,user_id uuid not null references auth.users on delete cascade,kind text not null check(kind in ('tasks','events','items')),text text not null check(length(text) between 1 and 120),done boolean not null default false,date date,version integer not null default 1,created_at timestamptz not null default now(),check(kind <> 'events' or date is not null));
create index on public.ordiva_test_entries(space_id);
create index on public.ordiva_test_entries(user_id);
create function ordiva_test_private.member(s uuid) returns boolean language sql stable security definer set search_path='' as $$
select (select auth.uid()) is not null and (exists(select 1 from public.ordiva_test_spaces where id=s and owner_id=(select auth.uid())) or exists(select 1 from public.ordiva_test_members where space_id=s and user_id=(select auth.uid())))
$$;
revoke all on function ordiva_test_private.member(uuid) from public;
grant execute on function ordiva_test_private.member(uuid) to authenticated;
alter table public.ordiva_test_spaces enable row level security;
alter table public.ordiva_test_members enable row level security;
alter table public.ordiva_test_invites enable row level security;
alter table public.ordiva_test_entries enable row level security;
create policy read_spaces on public.ordiva_test_spaces for select to authenticated using(ordiva_test_private.member(id));
create policy create_spaces on public.ordiva_test_spaces for insert to authenticated with check(owner_id=(select auth.uid()));
create policy read_members on public.ordiva_test_members for select to authenticated using(ordiva_test_private.member(space_id));
create policy owner_invites on public.ordiva_test_invites for all to authenticated using(exists(select 1 from public.ordiva_test_spaces where id=space_id and owner_id=(select auth.uid()))) with check(exists(select 1 from public.ordiva_test_spaces where id=space_id and owner_id=(select auth.uid())));
create policy read_entries on public.ordiva_test_entries for select to authenticated using((space_id is null and user_id=(select auth.uid())) or ordiva_test_private.member(space_id));
create policy add_entries on public.ordiva_test_entries for insert to authenticated with check(user_id=(select auth.uid()) and (space_id is null or ordiva_test_private.member(space_id)));
create policy update_entries on public.ordiva_test_entries for update to authenticated using((space_id is null and user_id=(select auth.uid())) or ordiva_test_private.member(space_id)) with check((space_id is null and user_id=(select auth.uid())) or ordiva_test_private.member(space_id));
create policy delete_entries on public.ordiva_test_entries for delete to authenticated using((space_id is null and user_id=(select auth.uid())) or ordiva_test_private.member(space_id));
grant select,insert on public.ordiva_test_spaces to authenticated;
grant select on public.ordiva_test_members to authenticated;
grant select,insert,delete on public.ordiva_test_invites to authenticated;
grant select,insert,update,delete on public.ordiva_test_entries to authenticated;
revoke all on public.ordiva_test_spaces,public.ordiva_test_members,public.ordiva_test_invites,public.ordiva_test_entries from anon;
create function ordiva_test_private.accept_invite(code uuid) returns uuid language plpgsql security definer set search_path='' as $$
declare i public.ordiva_test_invites; mail text; uid uuid := auth.uid();
begin
if uid is null then raise exception 'Inicia sesión primero'; end if;
select lower(email) into mail from auth.users where id=uid and email_confirmed_at is not null;
select * into i from public.ordiva_test_invites where id=code and expires_at>now() and email=mail for update;
if not found then raise exception 'Invitación no válida, caducada o para otro correo'; end if;
insert into public.ordiva_test_members(space_id,user_id) values(i.space_id,uid) on conflict do nothing;
delete from public.ordiva_test_invites where id=code;
return i.space_id;
end $$;
revoke all on function ordiva_test_private.accept_invite(uuid) from public;
grant execute on function ordiva_test_private.accept_invite(uuid) to authenticated;
create function public.ordiva_test_accept_invite(code uuid) returns uuid language sql security invoker set search_path='' as $$ select ordiva_test_private.accept_invite(code) $$;
revoke all on function public.ordiva_test_accept_invite(uuid) from public;
grant execute on function public.ordiva_test_accept_invite(uuid) to authenticated;
create function ordiva_test_private.guard_entry() returns trigger language plpgsql set search_path='' as $$
begin
if new.id<>old.id or new.user_id<>old.user_id or new.space_id is distinct from old.space_id or new.kind<>old.kind then raise exception 'No se puede cambiar el propietario o espacio'; end if;
new.version := old.version+1;
return new;
end $$;
revoke all on function ordiva_test_private.guard_entry() from public;
create trigger guard_test_entry before update on public.ordiva_test_entries for each row execute function ordiva_test_private.guard_entry();
