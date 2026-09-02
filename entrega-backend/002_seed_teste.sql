-- ================================================================
-- SEED DE TESTE — dados para validar as telas
-- ================================================================
--
-- NÃO rode em produção.
--
-- Antes de rodar:
--   1. Supabase Dashboard > Authentication > Users > Add user
--      E-mail: teste@salao.app     Senha: Salao@2026
--      Marque "Auto Confirm User" (senão o login recusa por e-mail
--      não confirmado e você perde meia hora achando que é bug).
--   2. Copie o UUID da usuária criada.
--   3. Cole no lugar de COLE-O-UUID-AQUI abaixo.
--   4. Rode 001_v1_completo.sql primeiro, depois este.
--
-- Rodar duas vezes duplica dado. Para recomeçar, use o bloco de
-- limpeza no final do arquivo.
-- ================================================================

do $seed$
declare
  uid uuid := 'COLE-O-UUID-AQUI';

  -- estoque
  i_cola   uuid := uuid_generate_v4();
  i_fio    uuid := uuid_generate_v4();
  i_remov  uuid := uuid_generate_v4();
  i_micro  uuid := uuid_generate_v4();
  i_pinca  uuid := uuid_generate_v4();

  -- serviços
  s_ext    uuid := uuid_generate_v4();
  s_manut  uuid := uuid_generate_v4();
  s_sobr   uuid := uuid_generate_v4();

  -- kits
  k_pos    uuid := uuid_generate_v4();

  -- atendimentos
  a_fin    uuid := uuid_generate_v4();
  a_agend  uuid := uuid_generate_v4();
begin

  -- ── Perfil ──────────────────────────────────────────────────
  update perfil_salao
     set nome_salao        = 'Thamires Borges Beauty',
         nome_proprietaria = 'Thamires Borges',
         telefone          = '5511999990000'
   where user_id = uid;

  -- ── Estoque ─────────────────────────────────────────────────
  -- Um item em cada estado, para as cores da tela aparecerem todas:
  -- ok, alerta, critico e negativo.
  insert into estoque_itens
    (id, user_id, nome, unidade, categoria,
     quantidade_atual, quantidade_minima, custo_medio, custo_ultima_compra)
  values
    (i_fio,   uid, 'Fio mink 0.07',              'cx', 'cilios',       8,  3, 42.00, 45.00),
    (i_remov, uid, 'Removedor de cola',          'ml', 'cilios',     120, 50, 0.35,  0.40),
    (i_micro, uid, 'Fita micropore',             'cx', 'descartavel',  2,  2, 6.50,  6.50),
    (i_cola,  uid, 'Cola adesiva para cílios',   'un', 'cilios',       0,  2, 28.00, 30.00),
    (i_pinca, uid, 'Pinça curva',                'un', 'sobrancelha', -1,  1, 35.00, 35.00);

  insert into estoque_movimentacoes (user_id, item_id, tipo, quantidade, motivo, custo_unitario)
  values
    (uid, i_fio,   'entrada', 10, 'Compra — fornecedor', 45.00),
    (uid, i_remov, 'entrada', 150, 'Compra — fornecedor', 0.40);

  insert into estoque_movimentacoes (user_id, item_id, tipo, quantidade, motivo, forcada)
  values
    (uid, i_pinca, 'saida', 1, 'Atendimento — saldo confirmado pela usuária', true);

  -- ── Serviços ────────────────────────────────────────────────
  insert into servicos (id, user_id, nome, preco) values
    (s_ext,   uid, 'Extensão de cílios',      180.00),
    (s_manut, uid, 'Manutenção de cílios',    100.00),
    (s_sobr,  uid, 'Sobrancelha fio a fio',   120.00);

  insert into servico_produtos_padrao (servico_id, item_estoque_id, quantidade) values
    (s_ext, i_fio,  1),
    (s_ext, i_cola, 1),
    (s_ext, i_micro, 2);

  -- ── Custos fixos ────────────────────────────────────────────
  insert into custos_fixos (user_id, descricao, valor) values
    (uid, 'Aluguel',            1200.00),
    (uid, 'Internet',             99.00),
    (uid, 'App de agendamento',   49.00);

  -- ── Kit ─────────────────────────────────────────────────────
  insert into kits (id, user_id, nome, preco_venda, quantidade_montada) values
    (k_pos, uid, 'Kit cuidado pós-cílios', 45.00, 3);

  insert into kit_itens (kit_id, item_estoque_id, quantidade) values
    (k_pos, i_remov, 30),
    (k_pos, i_micro, 1);

  insert into kit_vendas
    (user_id, kit_id, quantidade, nome_snapshot, preco_unitario, custo_snapshot, forma_pagamento, data)
  values
    (uid, k_pos, 1, 'Kit cuidado pós-cílios', 45.00, 17.00, 'pix', now() - interval '4 days'),
    (uid, k_pos, 2, 'Kit cuidado pós-cílios', 45.00, 17.00, 'a_vista', now() - interval '9 days');

  -- ── Atendimentos ────────────────────────────────────────────
  insert into atendimentos
    (id, user_id, nome_cliente, telefone_cliente, data, status, finalizado_em)
  values
    (a_fin, uid, 'Ana Paula', '(11) 99999-0001', now() - interval '2 days',
     'finalizado', now() - interval '2 days');

  insert into atendimentos (id, user_id, nome_cliente, telefone_cliente, data, status)
  values
    (a_agend, uid, 'Carla Mendes', '(11) 98888-0002', now() + interval '1 day', 'agendado');

  insert into atendimento_servicos (atendimento_id, servico_id, nome_servico, preco_snapshot) values
    (a_fin,   s_ext,   'Extensão de cílios',    180.00),
    (a_fin,   s_sobr,  'Sobrancelha fio a fio', 120.00),
    (a_agend, s_manut, 'Manutenção de cílios',  100.00);

  insert into atendimento_insumos (atendimento_id, item_estoque_id, nome, quantidade, preco) values
    (a_fin, i_fio,   'Fio mink 0.07',   1, 42.00),
    (a_fin, i_micro, 'Fita micropore',  2, 13.00),
    (a_fin, null,    'Máscara de argila', 1, 9.00);

  -- ── Gastos ──────────────────────────────────────────────────
  -- Um vencido, um a vencer e um pago: cobre os três estados da tela.
  insert into gastos (user_id, nome, valor, prazo, forma_pagamento, categoria, pago, pago_em) values
    (uid, 'Fios e colas (extensão)', 340.00, current_date - 3, 'credito', 'material', false, null),
    (uid, 'Aluguel sala',           1200.00, current_date + 2, 'pix',     'fixo',     false, null),
    (uid, 'Pinças e acessórios',      85.00, current_date - 10, 'a_vista', 'material', true, now() - interval '10 days');

  -- ── Alertas ─────────────────────────────────────────────────
  -- Em produção quem gera é o job do backend; aqui é só para a
  -- central de alertas e o badge terem o que mostrar.
  insert into alertas
    (user_id, tipo, severidade, titulo, mensagem, referencia_tipo, referencia_id, chave_dedupe)
  values
    (uid, 'estoque_critico', 'critico',
     'Cola adesiva para cílios acabou',
     'Você está com 0 un. e o mínimo é 2 un.',
     'estoque_item', i_cola, 'estoque_critico:' || i_cola),

    (uid, 'estoque_negativo', 'critico',
     'Pinça curva está com saldo negativo',
     'Saldo -1 un. Reponha para o estoque voltar a bater.',
     'estoque_item', i_pinca, 'estoque_negativo:' || i_pinca),

    (uid, 'estoque_baixo', 'alerta',
     'Fita micropore está no mínimo',
     'Restam 2 cx e o mínimo é 2 cx.',
     'estoque_item', i_micro, 'estoque_baixo:' || i_micro),

    (uid, 'gasto_vencido', 'critico',
     'Fios e colas venceu',
     'R$ 340,00 com prazo em ' || to_char(current_date - 3, 'DD/MM'),
     'gasto', null, 'gasto_vencido:fios-e-colas');

end $seed$;


-- ================================================================
-- LIMPEZA — para recomeçar o seed do zero
-- ================================================================
-- Troque o UUID e descomente. Apaga TUDO da usuária, menos a conta.
--
-- do $limpa$
-- declare uid uuid := 'COLE-O-UUID-AQUI';
-- begin
--   delete from alertas               where user_id = uid;
--   delete from kit_vendas            where user_id = uid;
--   delete from kit_itens             where kit_id in (select id from kits where user_id = uid);
--   delete from kits                  where user_id = uid;
--   delete from estoque_movimentacoes where user_id = uid;
--   delete from servico_produtos_padrao where servico_id in (select id from servicos where user_id = uid);
--   delete from atendimento_insumos   where atendimento_id in (select id from atendimentos where user_id = uid);
--   delete from atendimento_servicos  where atendimento_id in (select id from atendimentos where user_id = uid);
--   delete from atendimentos          where user_id = uid;
--   delete from estoque_itens         where user_id = uid;
--   delete from servicos              where user_id = uid;
--   delete from gastos                where user_id = uid;
--   delete from custos_fixos          where user_id = uid;
-- end $limpa$;
