-- Cadastra ou troca a senha da equipe. Rode no SQL Editor do Supabase, trocando SUA_SENHA.
insert into public.hinario_config (id, senha) values (1, 'SUA_SENHA')
  on conflict (id) do update set senha = excluded.senha;
