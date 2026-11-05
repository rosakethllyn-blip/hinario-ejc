-- Hinário EJC 2026: cria o banco. Rode uma vez no SQL Editor do Supabase.
-- Antes de rodar, troque TROQUE_PELA_SENHA pela senha da equipe (a que quem edita vai digitar).

create table if not exists public.docs (
  col  text not null,
  id   text not null,
  data jsonb not null,
  primary key (col, id)
);

create table if not exists public.config (
  id    int primary key default 1,
  senha text not null
);
insert into public.config (id, senha) values (1, 'TROQUE_PELA_SENHA')
  on conflict (id) do update set senha = excluded.senha;

-- A senha nunca é lida pelo site: só esta função compara a senha enviada pelo celular.
create or replace function public.senha_ok() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(
    (select senha from public.config where id = 1)
      = (current_setting('request.headers', true)::json ->> 'x-senha'),
    false)
$$;
grant execute on function public.senha_ok() to anon, authenticated;

alter table public.docs   enable row level security;
alter table public.config enable row level security;   -- sem regras: ninguém de fora lê a senha
revoke all on public.config from anon, authenticated;

drop policy if exists "todos leem"        on public.docs;
drop policy if exists "equipe cria"       on public.docs;
drop policy if exists "equipe edita"      on public.docs;
drop policy if exists "equipe apaga"      on public.docs;
create policy "todos leem"   on public.docs for select to anon, authenticated using (true);
create policy "equipe cria"  on public.docs for insert to anon, authenticated with check (public.senha_ok());
create policy "equipe edita" on public.docs for update to anon, authenticated using (public.senha_ok()) with check (public.senha_ok());
create policy "equipe apaga" on public.docs for delete to anon, authenticated using (public.senha_ok());
grant select, insert, update, delete on public.docs to anon, authenticated;

-- Atualização ao vivo nos celulares
do $$ begin
  alter publication supabase_realtime add table public.docs;
exception when duplicate_object then null; end $$;
