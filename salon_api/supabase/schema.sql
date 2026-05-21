-- ================================================================
-- SCHEMA DO BANCO — Salon App
-- Execute no SQL Editor do Supabase Dashboard
-- ================================================================

-- Habilita a extensão uuid
create extension if not exists "uuid-ossp";

-- ── 1. Serviços (tabela de preços do salão) ───────────────────────
-- Cadastrado na tela de Perfil pelo Flutter.
-- CRUD direto via Supabase REST API — sem passar pelo FastAPI.

create table if not exists servicos (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  nome        text not null,
  preco       numeric(10, 2) not null check (preco >= 0),
  criado_em   timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

-- ── 2. Atendimentos ───────────────────────────────────────────────
-- Cabeçalho do atendimento. Serviços e insumos ficam em tabelas filhas.

create table if not exists atendimentos (
  id                uuid primary key default uuid_generate_v4(),
  user_id           uuid not null references auth.users(id) on delete cascade,
  nome_cliente      text not null,
  telefone_cliente  text not null default '',
  data              timestamptz not null default now(),
  criado_em         timestamptz not null default now()
);

-- ── 3. Serviços de cada atendimento ──────────────────────────────
-- Guarda o snapshot do preço no momento do atendimento.
-- Importante: o preço do serviço pode mudar no perfil, mas o
-- atendimento deve refletir o que foi cobrado na época.

create table if not exists atendimento_servicos (
  id               uuid primary key default uuid_generate_v4(),
  atendimento_id   uuid not null references atendimentos(id) on delete cascade,
  servico_id       uuid references servicos(id) on delete set null,
  nome_servico     text not null,   -- copiado do servico para não perder histórico
  preco_snapshot   numeric(10, 2) not null check (preco_snapshot >= 0)
);

-- ── 4. Insumos descartáveis de cada atendimento ───────────────────
-- Apenas descartáveis entram aqui (cola, fio, protetor, etc.).
-- Ferramentas reutilizáveis não são lançadas por atendimento.

create table if not exists atendimento_insumos (
  id             uuid primary key default uuid_generate_v4(),
  atendimento_id uuid not null references atendimentos(id) on delete cascade,
  nome           text not null,
  preco          numeric(10, 2) not null check (preco >= 0)
);

-- ── 5. Gastos variáveis ───────────────────────────────────────────
-- Compras, reposição de material, despesas avulsas.
-- Cadastrado na tela de Gastos pelo Flutter.

create table if not exists gastos (
  id               uuid primary key default uuid_generate_v4(),
  user_id          uuid not null references auth.users(id) on delete cascade,
  descricao        text not null,
  valor            numeric(10, 2) not null check (valor >= 0),
  prazo            date not null,
  forma_pagamento  text not null check (forma_pagamento in ('à vista', 'cartão')),
  prioridade       text not null check (prioridade in ('alta', 'média', 'baixa')),
  pago             boolean not null default false,
  criado_em        timestamptz not null default now()
);

-- ── 6. Custos fixos mensais ────────────────────────────────────────
-- Aluguel, internet, app de agendamento, etc.
-- Cadastrado na tela de Perfil — entram todo mês no cálculo do resumo.

create table if not exists custos_fixos (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  descricao   text not null,
  valor       numeric(10, 2) not null check (valor >= 0),
  criado_em   timestamptz not null default now()
);

-- ================================================================
-- ROW LEVEL SECURITY (RLS)
-- Garante que cada usuária só acessa seus próprios dados.
-- Essencial porque o Flutter chama o Supabase diretamente com a anon key.
-- ================================================================

alter table servicos        enable row level security;
alter table atendimentos    enable row level security;
alter table atendimento_servicos enable row level security;
alter table atendimento_insumos  enable row level security;
alter table gastos          enable row level security;
alter table custos_fixos    enable row level security;

-- Política padrão: usuário acessa apenas seus próprios registros
create policy "usuario acessa proprios servicos"
  on servicos for all
  using (auth.uid() = user_id);

create policy "usuario acessa proprios atendimentos"
  on atendimentos for all
  using (auth.uid() = user_id);

create policy "usuario acessa servicos dos proprios atendimentos"
  on atendimento_servicos for all
  using (
    atendimento_id in (
      select id from atendimentos where user_id = auth.uid()
    )
  );

create policy "usuario acessa insumos dos proprios atendimentos"
  on atendimento_insumos for all
  using (
    atendimento_id in (
      select id from atendimentos where user_id = auth.uid()
    )
  );

create policy "usuario acessa proprios gastos"
  on gastos for all
  using (auth.uid() = user_id);

create policy "usuario acessa proprios custos fixos"
  on custos_fixos for all
  using (auth.uid() = user_id);

-- ================================================================
-- ÍNDICES
-- Otimizam as queries mais comuns do FastAPI (filtro por mês/semana)
-- ================================================================

create index if not exists idx_atendimentos_user_data
  on atendimentos (user_id, data);

create index if not exists idx_gastos_user_prazo
  on gastos (user_id, prazo);

create index if not exists idx_atend_servicos_atendimento
  on atendimento_servicos (atendimento_id);

create index if not exists idx_atend_insumos_atendimento
  on atendimento_insumos (atendimento_id);

-- ================================================================
-- DADOS DE EXEMPLO (opcional — remova em produção)
-- Substitua 'SEU-USER-ID-AQUI' pelo UUID de um usuário real do Supabase Auth
-- ================================================================

/*
do $$
declare
  uid uuid := 'SEU-USER-ID-AQUI';
  atend1 uuid := uuid_generate_v4();
  atend2 uuid := uuid_generate_v4();
  sv1 uuid := uuid_generate_v4();
  sv2 uuid := uuid_generate_v4();
begin

  -- Serviços do salão
  insert into servicos (id, user_id, nome, preco) values
    (sv1, uid, 'Extensão de cílios', 180.00),
    (sv2, uid, 'Sobrancelha fio a fio', 120.00),
    (uuid_generate_v4(), uid, 'Limpeza de pele', 150.00),
    (uuid_generate_v4(), uid, 'Design de sobrancelha', 60.00),
    (uuid_generate_v4(), uid, 'Manutenção de cílios', 100.00);

  -- Custos fixos mensais
  insert into custos_fixos (user_id, descricao, valor) values
    (uid, 'Aluguel', 1200.00),
    (uid, 'Internet', 99.00),
    (uid, 'App de agendamento', 49.00);

  -- Atendimentos
  insert into atendimentos (id, user_id, nome_cliente, telefone_cliente, data) values
    (atend1, uid, 'Ana Paula', '(11) 99999-0001', '2025-05-12 10:00:00+00'),
    (atend2, uid, 'Carla Mendes', '(11) 98888-0002', '2025-05-10 14:00:00+00');

  -- Serviços dos atendimentos
  insert into atendimento_servicos (atendimento_id, servico_id, nome_servico, preco_snapshot) values
    (atend1, sv1, 'Extensão de cílios', 180.00),
    (atend1, sv2, 'Sobrancelha fio a fio', 120.00),
    (atend2, null, 'Limpeza de pele', 150.00);

  -- Insumos
  insert into atendimento_insumos (atendimento_id, nome, preco) values
    (atend1, 'Fio mink 0.07', 12.00),
    (atend1, 'Cola adesiva', 8.00),
    (atend1, 'Fita micropore', 2.00),
    (atend2, 'Máscara de argila', 9.00),
    (atend2, 'Protetor solar descartável', 4.00);

  -- Gastos variáveis
  insert into gastos (user_id, descricao, valor, prazo, forma_pagamento, prioridade) values
    (uid, 'Aluguel sala', 1200.00, '2025-05-15', 'à vista', 'alta'),
    (uid, 'Fios e colas (extensão)', 340.00, '2025-05-18', 'cartão', 'alta'),
    (uid, 'Produtos limpeza de pele', 210.00, '2025-05-20', 'cartão', 'média'),
    (uid, 'Pinças e acessórios', 85.00, '2025-05-22', 'à vista', 'baixa');

end $$;
*/
