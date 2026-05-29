-- ================================================================
-- ADIÇÃO AO SCHEMA — tabela perfil_salao
-- Execute no SQL Editor do Supabase Dashboard
-- ================================================================
-- Esta tabela é necessária para os fluxos do n8n buscarem
-- o telefone/email da proprietária para enviar notificações.
-- ================================================================

create table if not exists perfil_salao (
  id                   uuid primary key default uuid_generate_v4(),
  user_id              uuid not null unique references auth.users(id) on delete cascade,
  nome_salao           text not null default 'Meu Salão',
  nome_proprietaria    text not null default '',
  telefone             text not null default '',  -- formato internacional: 5511999990000
  email                text not null default '',
  notificacoes_ativas  boolean not null default true,
  criado_em            timestamptz not null default now(),
  atualizado_em        timestamptz not null default now()
);

-- RLS: proprietária só acessa o próprio perfil
alter table perfil_salao enable row level security;

create policy "usuario acessa proprio perfil"
  on perfil_salao for all
  using (auth.uid() = user_id);

-- O n8n usa a service key para ler todos os perfis (bypassa RLS)
-- Isso é intencional: o cron precisa iterar todas as proprietárias ativas

-- Trigger para atualizar atualizado_em automaticamente
create or replace function set_atualizado_em()
returns trigger language plpgsql as $$
begin
  new.atualizado_em = now();
  return new;
end;
$$;

create trigger trg_perfil_salao_atualizado
  before update on perfil_salao
  for each row execute function set_atualizado_em();

-- Índice para o n8n filtrar por notificacoes_ativas
create index if not exists idx_perfil_notificacoes
  on perfil_salao (notificacoes_ativas)
  where notificacoes_ativas = true;

-- Criar perfil automaticamente quando usuária se cadastra
-- (evita que a proprietária precise criar manualmente)
create or replace function criar_perfil_ao_cadastrar()
returns trigger language plpgsql security definer as $$
begin
  insert into perfil_salao (user_id, email)
  values (new.id, new.email)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

create trigger trg_criar_perfil_novo_usuario
  after insert on auth.users
  for each row execute function criar_perfil_ao_cadastrar();
