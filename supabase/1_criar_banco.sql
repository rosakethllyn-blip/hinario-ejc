-- Hinário EJC 2026: cria as tabelas do hinário (não mexe em outras tabelas do projeto). Rode uma vez no SQL Editor do Supabase.

create table if not exists public.hinario_docs (
  col  text not null,
  id   text not null,
  data jsonb not null,
  primary key (col, id)
);

create table if not exists public.hinario_config (
  id    int primary key default 1,
  senha text not null
);
-- A senha da equipe é cadastrada à parte, no SQL Editor (veja 3_senha.sql).

-- A senha nunca é lida pelo site: só esta função compara a senha enviada pelo celular.
create or replace function public.hinario_senha_ok() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(
    (select senha from public.hinario_config where id = 1)
      = (current_setting('request.headers', true)::json ->> 'x-senha'),
    false)
$$;
grant execute on function public.hinario_senha_ok() to anon, authenticated;

alter table public.hinario_docs   enable row level security;
alter table public.hinario_config enable row level security;   -- sem regras: ninguém de fora lê a senha
revoke all on public.hinario_config from anon, authenticated;

drop policy if exists "hinario todos leem"   on public.hinario_docs;
drop policy if exists "hinario equipe cria"       on public.hinario_docs;
drop policy if exists "hinario equipe edita"      on public.hinario_docs;
drop policy if exists "hinario equipe apaga"      on public.hinario_docs;
create policy "hinario todos leem"   on public.hinario_docs for select to anon, authenticated using (true);
create policy "hinario equipe cria"  on public.hinario_docs for insert to anon, authenticated with check (public.hinario_senha_ok());
create policy "hinario equipe edita" on public.hinario_docs for update to anon, authenticated using (public.hinario_senha_ok()) with check (public.hinario_senha_ok());
create policy "hinario equipe apaga" on public.hinario_docs for delete to anon, authenticated using (public.hinario_senha_ok());
grant select, insert, update, delete on public.hinario_docs to anon, authenticated;

-- Atualização ao vivo nos celulares
do $$ begin
  alter publication supabase_realtime add table public.hinario_docs;
exception when duplicate_object then null; end $$;
