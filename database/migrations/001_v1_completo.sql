-- ================================================================
-- MIGRATION 001 — Schema completo da V1
-- Salon App · gerado a partir de .specs/endpoints-backend.md
-- ================================================================
--
-- Como executar: Supabase Dashboard > SQL Editor > cole e rode.
--
-- O script é IDEMPOTENTE: rodar duas vezes não quebra e não duplica
-- dado. Toda alteração destrutiva está protegida por checagem no
-- information_schema.
--
-- Ordem: extensões > helpers > tabelas novas > alterações em tabelas
-- existentes > RLS > índices.
-- ================================================================

create extension if not exists "uuid-ossp";


-- ================================================================
-- 0. HELPERS
-- ================================================================

-- Mantém atualizado_em sem depender de o backend lembrar.
create or replace function set_atualizado_em()
returns trigger language plpgsql as $fn$
begin
  new.atualizado_em = now();
  return new;
end;
$fn$;


-- ================================================================
-- 1. PERFIL DO SALÃO
-- ================================================================
-- Já criada por n8n/supabase_perfil_salao.sql em alguns ambientes.
-- Aqui ela é normalizada e ganha foto_url (§7 do mapa).

create table if not exists perfil_salao (
  id                   uuid primary key default uuid_generate_v4(),
  user_id              uuid not null unique references auth.users(id) on delete cascade,
  nome_salao           text not null default 'Meu Salão',
  nome_proprietaria    text not null default '',
  telefone             text not null default '',   -- E.164 sem '+': 5511999990000
  email                text not null default '',
  foto_url             text,
  meta_faturamento_mensal numeric(12, 2) not null default 9000,
  notificacoes_ativas  boolean not null default true,
  criado_em            timestamptz not null default now(),
  atualizado_em        timestamptz not null default now()
);

alter table perfil_salao add column if not exists foto_url text;
alter table perfil_salao add column if not exists meta_faturamento_mensal numeric(12, 2) not null default 9000;

-- Dia do mês em que o custo fixo vence (§7 do mapa). Sem ele um custo fixo é
-- só uma parcela do total: não dá para avisar que o aluguel vence amanhã nem
-- para ordenar o mês. Guarda o dia literal — 31 continua 31 em fevereiro, e
-- quem agenda o aviso resolve o mês curto. Default 1 para o dado que já existe.
alter table custos_fixos add column if not exists dia_vencimento smallint not null default 1;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'custos_fixos_dia_vencimento_check'
  ) then
    alter table custos_fixos
      add constraint custos_fixos_dia_vencimento_check
      check (dia_vencimento between 1 and 31);
  end if;
end $$;

-- Custo fixo não se paga uma vez: ele volta todo mês. O que se marca como pago
-- é a OCORRÊNCIA do mês, não o cadastro — por isso o pagamento mora numa tabela
-- própria, com a competência na chave. Guardar um `pago` booleano dentro de
-- `custos_fixos` faria o aluguel pago em setembro nascer pago em outubro.
create table if not exists custos_fixos_pagamentos (
  id             uuid primary key default uuid_generate_v4(),
  custo_fixo_id  uuid not null references custos_fixos(id) on delete cascade,
  user_id        uuid not null references auth.users(id) on delete cascade,
  -- Primeiro dia da competência: 2026-09-01 é "setembro de 2026".
  competencia    date not null,
  pago_em        timestamptz not null default now(),
  criado_em      timestamptz not null default now(),
  -- Idempotência: pagar duas vezes o mesmo mês não duplica nada.
  unique (custo_fixo_id, competencia)
);

-- Congela o custo padrão do serviço no atendimento. Sem snapshot, alterar a
-- composição hoje reescreveria o lucro dos meses passados no novo ranking.
alter table atendimento_servicos add column if not exists custo_insumos_snapshot numeric(12, 2) not null default 0;

drop trigger if exists trg_perfil_salao_atualizado on perfil_salao;
create trigger trg_perfil_salao_atualizado
  before update on perfil_salao
  for each row execute function set_atualizado_em();


-- ================================================================
-- 2. ESTOQUE
-- ================================================================
-- A maior lacuna do banco atual: o estoque só existia no mock do app.

create table if not exists estoque_itens (
  id                   uuid primary key default uuid_generate_v4(),
  user_id              uuid not null references auth.users(id) on delete cascade,
  nome                 text not null,
  unidade              text not null default 'un'
                         check (unidade in ('un', 'ml', 'g', 'cx')),
  categoria            text not null default 'outro'
                         check (categoria in ('cilios', 'sobrancelha',
                                              'limpeza_pele', 'descartavel', 'outro')),

  -- SEM check (>= 0): saldo negativo é estado válido e desejado.
  -- Vem de finalizar atendimento com confirmar_estoque_insuficiente
  -- (§2 do mapa) — o consumo aconteceu de verdade, o registro só
  -- estava atrasado. Ver a coluna status logo abaixo.
  quantidade_atual     numeric(12, 3) not null default 0,
  quantidade_minima    numeric(12, 3) not null default 0
                         check (quantidade_minima >= 0),

  -- Média ponderada móvel, recalculada a cada entrada (§5 do mapa).
  custo_medio          numeric(10, 2) not null default 0 check (custo_medio >= 0),
  -- Informativo: quanto ela pagou da última vez.
  custo_ultima_compra  numeric(10, 2) not null default 0,

  ativo                boolean not null default true,
  criado_em            timestamptz not null default now(),
  atualizado_em        timestamptz not null default now(),

  -- A REGRA DO ALERTA MORA AQUI, uma vez só (S7 da adaptação).
  -- Coluna gerada: app, push e n8n leem o mesmo valor e não há como
  -- as três implementações divergirem, porque só existe uma.
  status text generated always as (
    case
      when quantidade_atual < 0                  then 'negativo'
      when quantidade_atual = 0                  then 'critico'
      when quantidade_atual <= quantidade_minima then 'alerta'
      else 'ok'
    end
  ) stored,

  deficit numeric(12, 3) generated always as (
    greatest(quantidade_minima - quantidade_atual, 0)
  ) stored
);

drop trigger if exists trg_estoque_itens_atualizado on estoque_itens;
create trigger trg_estoque_itens_atualizado
  before update on estoque_itens
  for each row execute function set_atualizado_em();


create table if not exists estoque_movimentacoes (
  id              uuid primary key default uuid_generate_v4(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  item_id         uuid not null references estoque_itens(id) on delete cascade,
  tipo            text not null check (tipo in ('entrada', 'saida', 'ajuste')),
  quantidade      numeric(12, 3) not null check (quantidade > 0),
  motivo          text not null default '',

  -- Custo unitário informado na entrada; alimenta a média ponderada.
  custo_unitario  numeric(10, 2),

  -- Rastreabilidade: de onde veio a baixa. Nuláveis e, na prática,
  -- mutuamente exclusivos — saída manual não tem nenhum dos dois.
  atendimento_id  uuid,
  kit_id          uuid,

  -- true quando a movimentação foi gravada com saldo insuficiente
  -- porque a usuária confirmou. Guardar isto permite auditar depois
  -- por que um item ficou negativo.
  forcada         boolean not null default false,

  criado_em       timestamptz not null default now()
);


-- ================================================================
-- 3. KITS
-- ================================================================
-- Montar e vender são dois fatos separados: ela monta cinco numa
-- tarde e vende ao longo das semanas. Por isso o kit tem saldo
-- próprio (quantidade_montada) em vez de baixar insumo na venda.

create table if not exists kits (
  id                  uuid primary key default uuid_generate_v4(),
  user_id             uuid not null references auth.users(id) on delete cascade,
  nome                text not null,
  preco_venda         numeric(10, 2) not null check (preco_venda >= 0),
  quantidade_montada  integer not null default 0 check (quantidade_montada >= 0),
  ativo               boolean not null default true,
  criado_em           timestamptz not null default now(),
  atualizado_em       timestamptz not null default now()
);

drop trigger if exists trg_kits_atualizado on kits;
create trigger trg_kits_atualizado
  before update on kits
  for each row execute function set_atualizado_em();


-- A composição do kit — a "receita".
create table if not exists kit_itens (
  id               uuid primary key default uuid_generate_v4(),
  kit_id           uuid not null references kits(id) on delete cascade,
  item_estoque_id  uuid not null references estoque_itens(id) on delete restrict,
  quantidade       numeric(12, 3) not null check (quantidade > 0),
  unique (kit_id, item_estoque_id)
);


create table if not exists kit_vendas (
  id               uuid primary key default uuid_generate_v4(),
  user_id          uuid not null references auth.users(id) on delete cascade,
  kit_id           uuid not null references kits(id) on delete restrict,
  quantidade       integer not null check (quantidade > 0),

  -- Snapshots: o kit muda de preço e de composição; a venda de ontem
  -- não muda junto. Mesmo motivo do preco_snapshot em atendimento_servicos.
  nome_snapshot    text not null,
  preco_unitario   numeric(10, 2) not null check (preco_unitario >= 0),
  custo_snapshot   numeric(10, 2) not null default 0,

  forma_pagamento  text not null default 'a_vista'
                     check (forma_pagamento in ('a_vista', 'credito', 'debito', 'pix')),
  data             timestamptz not null default now(),
  criado_em        timestamptz not null default now()
);


-- FK que só pode ser criada agora que kits existe.
do $mig$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where constraint_name = 'estoque_movimentacoes_kit_id_fkey'
  ) then
    alter table estoque_movimentacoes
      add constraint estoque_movimentacoes_kit_id_fkey
      foreign key (kit_id) references kits(id) on delete set null;
  end if;
end $mig$;


-- ================================================================
-- 4. SERVIÇOS — produtos padrão e soft delete
-- ================================================================

alter table servicos add column if not exists ativo boolean not null default true;

-- O que a tela de finalizar atendimento pré-preenche.
create table if not exists servico_produtos_padrao (
  id               uuid primary key default uuid_generate_v4(),
  servico_id       uuid not null references servicos(id) on delete cascade,
  item_estoque_id  uuid not null references estoque_itens(id) on delete cascade,
  quantidade       numeric(12, 3) not null default 1 check (quantidade > 0),
  unique (servico_id, item_estoque_id)
);


-- ================================================================
-- 5. ATENDIMENTOS — status e ligação com o estoque
-- ================================================================

alter table atendimentos add column if not exists status text not null default 'agendado';
alter table atendimentos add column if not exists finalizado_em timestamptz;
alter table atendimentos add column if not exists cancelado_em  timestamptz;

do $mig$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where constraint_name = 'atendimentos_status_check'
  ) then
    alter table atendimentos
      add constraint atendimentos_status_check
      check (status in ('agendado', 'finalizado', 'cancelado'));
  end if;
end $mig$;

-- Insumo avulso continua válido: item_estoque_id é nulável de
-- propósito. Nem todo material dela está cadastrado no estoque.
alter table atendimento_insumos
  add column if not exists item_estoque_id uuid references estoque_itens(id) on delete set null;
alter table atendimento_insumos
  add column if not exists quantidade numeric(12, 3) not null default 1;

do $mig$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where constraint_name = 'estoque_movimentacoes_atendimento_id_fkey'
  ) then
    alter table estoque_movimentacoes
      add constraint estoque_movimentacoes_atendimento_id_fkey
      foreign key (atendimento_id) references atendimentos(id) on delete set null;
  end if;
end $mig$;


-- ================================================================
-- 6. GASTOS — alinhar com o contrato do app
-- ================================================================
-- O schema atual aceita 'à vista'/'cartão' (com acento e espaço) e
-- tem 'prioridade' onde o protótipo mostra 'categoria'. Converte sem
-- perder o que já está gravado.

-- 6.1 descricao → nome
do $mig$
begin
  if exists (
    select 1 from information_schema.columns
    where table_name = 'gastos' and column_name = 'descricao'
  ) and not exists (
    select 1 from information_schema.columns
    where table_name = 'gastos' and column_name = 'nome'
  ) then
    alter table gastos rename column descricao to nome;
  end if;
end $mig$;

alter table gastos add column if not exists nome text not null default '';

-- 6.2 forma_pagamento: troca o domínio e converte os valores antigos
alter table gastos drop constraint if exists gastos_forma_pagamento_check;

update gastos set forma_pagamento = 'a_vista' where forma_pagamento in ('à vista', 'a vista');
update gastos set forma_pagamento = 'credito' where forma_pagamento in ('cartão', 'cartao');

do $mig$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where constraint_name = 'gastos_forma_pagamento_check_v2'
  ) then
    alter table gastos
      add constraint gastos_forma_pagamento_check_v2
      check (forma_pagamento in ('a_vista', 'credito', 'debito', 'pix'));
  end if;
end $mig$;

-- 6.3 prioridade → categoria
alter table gastos add column if not exists categoria text not null default 'outros';

do $mig$
begin
  if exists (
    select 1 from information_schema.columns
    where table_name = 'gastos' and column_name = 'prioridade'
  ) then
    update gastos set categoria = case prioridade
      when 'alta'  then 'fixo'
      when 'média' then 'material'
      else 'outros'
    end
    where categoria = 'outros';

    alter table gastos drop constraint if exists gastos_prioridade_check;
    alter table gastos drop column prioridade;
  end if;
end $mig$;

do $mig$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where constraint_name = 'gastos_categoria_check'
  ) then
    alter table gastos
      add constraint gastos_categoria_check
      check (categoria in ('fixo', 'material', 'outros'));
  end if;
end $mig$;

-- 6.4 saber quando pagou, não só que pagou
alter table gastos add column if not exists pago_em timestamptz;


-- ================================================================
-- 7. ALERTAS
-- ================================================================
-- O app não varre lista procurando quantidade <= minima: ele lê
-- alertas prontos. A mesma regra tem que valer para o push e para o
-- n8n, que não passam pelo app (S7).

create table if not exists alertas (
  id               uuid primary key default uuid_generate_v4(),
  user_id          uuid not null references auth.users(id) on delete cascade,
  tipo             text not null check (tipo in (
                     'estoque_negativo', 'estoque_critico', 'estoque_baixo',
                     'gasto_a_vencer', 'gasto_vencido',
                     'saldo_negativo', 'zero_a_zero')),
  severidade       text not null check (severidade in ('critico', 'alerta', 'info')),
  titulo           text not null,
  mensagem         text not null default '',

  -- Permite tocar no alerta e cair na tela certa. O servidor não
  -- conhece rotas de UI — manda tipo + id, o app decide o destino.
  referencia_tipo  text check (referencia_tipo in
                     ('estoque_item', 'gasto', 'atendimento', 'kit', 'resumo')),
  referencia_id    uuid,

  -- Deduplicação: um alerta vivo por (usuária, chave). Sem isto, um
  -- cron de hora em hora gera 24 avisos por dia do mesmo vidro de
  -- cola e a central vira ruído que ela aprende a ignorar.
  chave_dedupe     text not null,

  lido_em          timestamptz,
  resolvido_em     timestamptz,
  criado_em        timestamptz not null default now()
);

-- Renomeia a preferência de antecedência para um banco que já rodou a versão
-- anterior desta migração: a janela deixou de valer só para gasto e passou a
-- valer também para custo fixo, com sete dias em vez de três.
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_name = 'alerta_preferencias'
      and column_name = 'dias_antecedencia_gasto'
  ) then
    alter table alerta_preferencias
      rename column dias_antecedencia_gasto to dias_antecedencia_vencimento;
    alter table alerta_preferencias
      alter column dias_antecedencia_vencimento set default 7;
  end if;
end $$;


create unique index if not exists idx_alertas_dedupe
  on alertas (user_id, chave_dedupe)
  where resolvido_em is null;


create table if not exists alerta_preferencias (
  user_id                  uuid primary key references auth.users(id) on delete cascade,
  limite_saldo_alerta      numeric(10, 2) not null default 0,
  -- Uma semana para tudo que vence: gasto pendente e custo fixo. É o prazo que
  -- dá tempo de fazer alguma coisa; avisar no dia é só informar que já era tarde.
  dias_antecedencia_vencimento integer not null default 7
    check (dias_antecedencia_vencimento >= 0),

  canal_in_app             boolean not null default true,
  canal_push               boolean not null default true,
  -- Mapeados agora, ligados depois (decisão A3 / §10 do mapa).
  canal_whatsapp           boolean not null default false,
  canal_email              boolean not null default false,

  tipos_silenciados        text[] not null default '{}',
  atualizado_em            timestamptz not null default now()
);

drop trigger if exists trg_alerta_pref_atualizado on alerta_preferencias;
create trigger trg_alerta_pref_atualizado
  before update on alerta_preferencias
  for each row execute function set_atualizado_em();


create table if not exists dispositivos (
  id           uuid primary key default uuid_generate_v4(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  token        text not null unique,          -- token FCM
  plataforma   text not null check (plataforma in ('android', 'ios', 'web')),
  modelo       text not null default '',
  ativo        boolean not null default true,
  criado_em    timestamptz not null default now(),
  usado_em     timestamptz not null default now()
);


-- ================================================================
-- 8. REFRESH TOKENS
-- ================================================================
-- POST /auth/logout precisa invalidar o refresh de verdade. Sem esta
-- tabela, "sair" só apaga o token do aparelho e ele continua valendo
-- até expirar sozinho.

create table if not exists refresh_tokens (
  id           uuid primary key default uuid_generate_v4(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  token_hash   text not null unique,          -- guarde o hash, nunca o token
  expira_em    timestamptz not null,
  revogado_em  timestamptz,
  criado_em    timestamptz not null default now()
);


-- ================================================================
-- 9. BOOTSTRAP DA USUÁRIA
-- ================================================================
-- Cria perfil e preferências junto com a conta: ela nunca vê uma
-- tela vazia por falta de uma linha que o sistema podia ter criado.
-- Definida aqui, e não na §1, porque depende de alerta_preferencias.

create or replace function criar_perfil_ao_cadastrar()
returns trigger language plpgsql security definer as $fn$
begin
  insert into perfil_salao (user_id, email)
  values (new.id, new.email)
  on conflict (user_id) do nothing;

  insert into alerta_preferencias (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$fn$;

drop trigger if exists trg_criar_perfil_novo_usuario on auth.users;
create trigger trg_criar_perfil_novo_usuario
  after insert on auth.users
  for each row execute function criar_perfil_ao_cadastrar();

-- Retroativo: quem já existe também ganha as duas linhas.
insert into perfil_salao (user_id, email)
  select id, email from auth.users
  on conflict (user_id) do nothing;

insert into alerta_preferencias (user_id)
  select id from auth.users
  on conflict (user_id) do nothing;


-- ================================================================
-- 10. ROW LEVEL SECURITY
-- ================================================================
-- Segunda barreira. A primeira é o FastAPI derivar o usuário de um
-- JWT VALIDADO — ver a dívida crítica na §0 do mapa de endpoints.

alter table estoque_itens           enable row level security;
alter table estoque_movimentacoes   enable row level security;
alter table kits                    enable row level security;
alter table kit_itens               enable row level security;
alter table kit_vendas              enable row level security;
alter table servico_produtos_padrao enable row level security;
alter table custos_fixos_pagamentos enable row level security;
alter table alertas                 enable row level security;
alter table alerta_preferencias     enable row level security;
alter table dispositivos            enable row level security;
alter table refresh_tokens          enable row level security;
alter table perfil_salao            enable row level security;

do $mig$
declare
  t text;
begin
  -- Tabelas com user_id direto: a política é sempre a mesma.
  foreach t in array array[
    'estoque_itens', 'estoque_movimentacoes', 'kits', 'kit_vendas',
    'alertas', 'dispositivos', 'refresh_tokens', 'perfil_salao',
    'alerta_preferencias', 'custos_fixos_pagamentos'
  ] loop
    execute format('drop policy if exists "usuario acessa proprios %1$s" on %1$I', t);
    execute format(
      'create policy "usuario acessa proprios %1$s" on %1$I for all using (auth.uid() = user_id)',
      t
    );
  end loop;
end $mig$;

-- Tabelas filhas: herdam a política pelo pai.
drop policy if exists "usuario acessa itens dos proprios kits" on kit_itens;
create policy "usuario acessa itens dos proprios kits"
  on kit_itens for all
  using (kit_id in (select id from kits where user_id = auth.uid()));

drop policy if exists "usuario acessa produtos dos proprios servicos" on servico_produtos_padrao;
create policy "usuario acessa produtos dos proprios servicos"
  on servico_produtos_padrao for all
  using (servico_id in (select id from servicos where user_id = auth.uid()));


-- ================================================================
-- 11. ÍNDICES
-- ================================================================

create index if not exists idx_estoque_itens_user
  on estoque_itens (user_id, ativo);

-- Alimenta GET /estoque/itens?status=... e a contagem do badge.
create index if not exists idx_estoque_itens_status
  on estoque_itens (user_id, status)
  where ativo = true;

create index if not exists idx_estoque_mov_item
  on estoque_movimentacoes (item_id, criado_em desc);

create index if not exists idx_estoque_mov_user_data
  on estoque_movimentacoes (user_id, criado_em desc);

create index if not exists idx_estoque_mov_atendimento
  on estoque_movimentacoes (atendimento_id)
  where atendimento_id is not null;

create index if not exists idx_kits_user
  on kits (user_id, ativo);

create index if not exists idx_kit_itens_kit
  on kit_itens (kit_id);

create index if not exists idx_kit_vendas_user_data
  on kit_vendas (user_id, data);

-- Alimenta o GET de custos fixos: um custo, uma competência.
create index if not exists idx_custos_fixos_pagamentos_competencia
  on custos_fixos_pagamentos (user_id, competencia);

create index if not exists idx_alertas_nao_lidos
  on alertas (user_id, criado_em desc)
  where lido_em is null and resolvido_em is null;

create index if not exists idx_dispositivos_user
  on dispositivos (user_id)
  where ativo = true;

create index if not exists idx_refresh_validos
  on refresh_tokens (user_id)
  where revogado_em is null;

create index if not exists idx_atendimentos_user_status_data
  on atendimentos (user_id, status, data);

create index if not exists idx_gastos_user_pago_prazo
  on gastos (user_id, pago, prazo);

create index if not exists idx_servicos_user_ativo
  on servicos (user_id, ativo);
