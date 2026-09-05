-- ================================================================
-- MIGRATION 003 — Agendamento público (lote L8)
-- Salon App · gerado a partir de .specs/endpoints-backend.md §7, §8, §10
-- e .specs/pedidos-backend.md L8
-- ================================================================
--
-- Como executar: Supabase Dashboard > SQL Editor > cole e rode.
-- Idempotente, como a 001: rodar de novo não quebra nem duplica.
--
-- Decisões do dono do projeto (não revisitar sem ele):
--   B1 — link de agendamento fixo por salão, não expira, não é por cliente.
--   B3 — múltiplos serviços por agendamento público; duração bloqueada = soma.
--   B4 — confirmação automática, sem estado "pendente".
--   B6 — expediente por dia da semana, cada um com seu próprio horário,
--        sem exceção por data (feriado/folga pontual) nesta versão.
--
-- Ordem: servicos.duracao_minutos > horario_funcionamento >
-- perfil_salao.slug_agendamento > atendimentos.origem > alertas > RLS > índices.
-- ================================================================

create extension if not exists "uuid-ossp";
create extension if not exists "unaccent";


-- ================================================================
-- 1. SERVICOS.DURACAO_MINUTOS
-- ================================================================
-- Base do cálculo de horário livre (§10): é o que o servidor soma para saber
-- quanto tempo um agendamento bloqueia na agenda. Sem duração não dá pra
-- oferecer horário nenhum no link público.
--
-- Propositalmente SEM default: um número chutado (ex. 60 min pra tudo)
-- ficaria errado silenciosamente — "Extensão de cílios" e "Design de
-- sobrancelha" não duram o mesmo tempo, e um valor errado aqui é o que
-- calcula agenda errada depois. Fica nulável até a usuária preencher cada
-- serviço; a API (§8) já exige o campo em todo POST/PATCH novo.

alter table servicos add column if not exists duracao_minutos integer;

do $mig$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where constraint_name = 'servicos_duracao_minutos_check'
  ) then
    alter table servicos
      add constraint servicos_duracao_minutos_check
      check (duracao_minutos is null or duracao_minutos > 0);
  end if;
end $mig$;

-- Não vira NOT NULL sozinha: só quando não houver mais nenhum serviço sem
-- duração preenchida. Reveja este NOTICE antes de considerar o L8 pronto —
-- enquanto ele aparecer, GET /agendamento-publico/{slug}/horarios-disponiveis
-- não pode contar com duracao_minutos presente em todo serviço.
do $mig$
declare
  pendentes int;
begin
  select count(*) into pendentes from servicos where duracao_minutos is null and ativo;

  if pendentes > 0 then
    raise notice
      '% serviço(s) ativo(s) sem duracao_minutos — preencha antes de ativar o agendamento público (UPDATE servicos SET duracao_minutos = ... WHERE duracao_minutos IS NULL). Constraint NOT NULL não aplicada nesta rodada.',
      pendentes;
  elsif not exists (
    select 1 from information_schema.columns
    where table_name = 'servicos' and column_name = 'duracao_minutos' and is_nullable = 'NO'
  ) then
    alter table servicos alter column duracao_minutos set not null;
  end if;
end $mig$;


-- ================================================================
-- 2. HORARIO_FUNCIONAMENTO
-- ================================================================
-- Expediente por dia da semana (§7) — decisão B6: cada dia tem seu próprio
-- horário, não um expediente único repetido. dia_semana: 0 domingo … 6 sábado.
-- Sem exceção por data nesta versão (feriado/folga pontual fica de fora).

create table if not exists horario_funcionamento (
  id             uuid primary key default uuid_generate_v4(),
  user_id        uuid not null references auth.users(id) on delete cascade,
  dia_semana     smallint not null check (dia_semana between 0 and 6),
  ativo          boolean not null default false,
  hora_inicio    time,
  hora_fim       time,
  atualizado_em  timestamptz not null default now(),
  unique (user_id, dia_semana)
);

do $mig$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where constraint_name = 'horario_funcionamento_intervalo_check'
  ) then
    alter table horario_funcionamento
      add constraint horario_funcionamento_intervalo_check
      check (not ativo or (hora_inicio is not null and hora_fim is not null and hora_inicio < hora_fim));
  end if;
end $mig$;

drop trigger if exists trg_horario_funcionamento_atualizado on horario_funcionamento;
create trigger trg_horario_funcionamento_atualizado
  before update on horario_funcionamento
  for each row execute function set_atualizado_em();


-- ================================================================
-- 3. PERFIL_SALAO.SLUG_AGENDAMENTO
-- ================================================================
-- Link fixo por salão (decisão B1): gerado uma vez a partir do nome do
-- salão, normalizado (sem acento/espaço/maiúscula), com sufixo numérico em
-- caso de colisão. Sem endpoint de regenerar nesta versão.

alter table perfil_salao add column if not exists slug_agendamento text;

-- Gera um slug base a partir de um nome: minúsculo, sem acento, espaços e
-- caracteres não alfanuméricos viram hífen, hífens duplicados/nas pontas
-- são aparados.
create or replace function gerar_slug_base(nome_entrada text)
returns text language sql immutable as $fn$
  select trim(both '-' from
    regexp_replace(
      regexp_replace(lower(unaccent(coalesce(nome_entrada, ''))), '[^a-z0-9]+', '-', 'g'),
      '-{2,}', '-', 'g'
    )
  );
$fn$;

-- Backfill idempotente: só mexe em quem ainda não tem slug. Resolve colisão
-- por sufixo numérico (-2, -3, ...) contra o que já existe na tabela.
do $mig$
declare
  linha record;
  base text;
  candidato text;
  sufixo int;
begin
  for linha in
    select id, nome_salao
    from perfil_salao
    where slug_agendamento is null
    order by criado_em
  loop
    base := gerar_slug_base(linha.nome_salao);
    if base = '' then
      base := 'salao';
    end if;

    candidato := base;
    sufixo := 2;
    while exists (select 1 from perfil_salao where slug_agendamento = candidato) loop
      candidato := base || '-' || sufixo;
      sufixo := sufixo + 1;
    end loop;

    update perfil_salao set slug_agendamento = candidato where id = linha.id;
  end loop;
end $mig$;

alter table perfil_salao alter column slug_agendamento set not null;

do $mig$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'perfil_salao_slug_agendamento_key'
  ) then
    alter table perfil_salao
      add constraint perfil_salao_slug_agendamento_key unique (slug_agendamento);
  end if;
end $mig$;


-- ================================================================
-- 4. ATENDIMENTOS.ORIGEM
-- ================================================================
-- Diferencia na lista/alerta quem veio pelo link público (§10) de quem foi
-- lançado pela profissional (fluxo interno, §2).

alter table atendimentos add column if not exists origem text not null default 'interno';

do $mig$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where constraint_name = 'atendimentos_origem_check'
  ) then
    alter table atendimentos
      add constraint atendimentos_origem_check
      check (origem in ('interno', 'publico'));
  end if;
end $mig$;


-- ================================================================
-- 5. ALERTAS — novo tipo
-- ================================================================
-- "novo agendamento pelo link" (§10): reaproveita o canal in-app que já
-- existe, não depende do n8n.

alter table alertas drop constraint if exists alertas_tipo_check;
alter table alertas
  add constraint alertas_tipo_check
  check (tipo in (
    'estoque_negativo', 'estoque_critico', 'estoque_baixo',
    'gasto_a_vencer', 'gasto_vencido',
    'saldo_negativo', 'zero_a_zero',
    'agendamento_publico_novo'));


-- ================================================================
-- 6. BOOTSTRAP DA USUÁRIA — estende para incluir horário padrão
-- ================================================================
-- Mesma função de 001 §9 (criada on insert em auth.users), agora também
-- semeando um expediente default: seg-sex 09:00–19:00, sáb 09:00–14:00,
-- dom fechado — o mesmo exemplo do mapa de endpoints (§7). A usuária ajusta
-- depois em PUT /perfil/horario-funcionamento.

create or replace function criar_perfil_ao_cadastrar()
returns trigger language plpgsql security definer
set search_path = public
as $fn$
begin
  insert into public.perfil_salao (user_id, email)
  values (new.id, new.email)
  on conflict (user_id) do nothing;

  insert into public.alerta_preferencias (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  insert into public.horario_funcionamento (user_id, dia_semana, ativo, hora_inicio, hora_fim)
  values
    (new.id, 0, false, null,      null),
    (new.id, 1, true,  '09:00',   '19:00'),
    (new.id, 2, true,  '09:00',   '19:00'),
    (new.id, 3, true,  '09:00',   '19:00'),
    (new.id, 4, true,  '09:00',   '19:00'),
    (new.id, 5, true,  '09:00',   '19:00'),
    (new.id, 6, true,  '09:00',   '14:00')
  on conflict (user_id, dia_semana) do nothing;

  return new;
end;
$fn$;

-- Retroativo: quem já existe também ganha o slug (já feito acima) e o
-- expediente default, exatamente como perfil_salao/alerta_preferencias em 001.
insert into horario_funcionamento (user_id, dia_semana, ativo, hora_inicio, hora_fim)
  select id, dia_semana, ativo, hora_inicio, hora_fim
  from auth.users
  cross join (values
    (0, false, null::time, null::time),
    (1, true,  '09:00'::time, '19:00'::time),
    (2, true,  '09:00'::time, '19:00'::time),
    (3, true,  '09:00'::time, '19:00'::time),
    (4, true,  '09:00'::time, '19:00'::time),
    (5, true,  '09:00'::time, '19:00'::time),
    (6, true,  '09:00'::time, '14:00'::time)
  ) as padrao(dia_semana, ativo, hora_inicio, hora_fim)
  on conflict (user_id, dia_semana) do nothing;


-- ================================================================
-- 7. ROW LEVEL SECURITY
-- ================================================================
-- Segunda barreira, igual ao resto do banco (§0 do mapa: quem autoriza de
-- verdade é o FastAPI, com o service role, a partir do JWT validado).
-- GET /agendamento-publico/* não passa por aqui: usa o service role e o
-- FastAPI filtra pelo slug — não há usuária autenticada nesse fluxo.

alter table horario_funcionamento enable row level security;

drop policy if exists "usuario acessa proprio horario_funcionamento" on horario_funcionamento;
create policy "usuario acessa proprio horario_funcionamento"
  on horario_funcionamento for all
  using (auth.uid() = user_id);


-- ================================================================
-- 8. ÍNDICES
-- ================================================================

create index if not exists idx_horario_funcionamento_user
  on horario_funcionamento (user_id);

create index if not exists idx_atendimentos_user_origem
  on atendimentos (user_id, origem);

-- Alimenta o cálculo de horarios-disponiveis: atendimentos do dia que já
-- ocupam a agenda (agendado/finalizado), por usuária.
create index if not exists idx_atendimentos_user_data_status
  on atendimentos (user_id, data, status);
