import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app/models/alertas/get_alertas_response_model.dart';
import 'package:salon_app/models/atendimentos/get_atendimentos_response_model.dart';
import 'package:salon_app/models/auth/login_response_model.dart';
import 'package:salon_app/models/estoque/estoque_faltante_model.dart';
import 'package:salon_app/models/estoque/get_estoque_itens_response_model.dart';
import 'package:salon_app/models/estoque/get_movimentacoes_response_model.dart';
import 'package:salon_app/models/gastos/get_gastos_response_model.dart';
import 'package:salon_app/models/kits/get_kits_response_model.dart';
import 'package:salon_app/models/perfil/custo_fixo_model.dart';
import 'package:salon_app/models/perfil/perfil_model.dart';
import 'package:salon_app/models/resumo/get_resumo_mensal_response_model.dart';
import 'package:salon_app/models/servicos/servico_model.dart';
import 'package:salon_app/settings/app_enums.dart';

/// É o teste que paga sozinho o custo de não usar code-gen: cola o JSON do
/// contrato (`.specs/endpoints-backend.md`) e o parse manual fica verificado.
///
/// Cada model é testado duas vezes: com o payload cheio e com o **vazio**, que
/// é onde parse manual costuma quebrar.
void main() {
  group('auth', () {
    test('login lê token, usuário e salão', () {
      final model = LoginResponseModel.fromResponse({
        'total': 1,
        'mensagem': 'ok',
        'result': {
          'token': 'jwt',
          'refresh_token': 'refresh',
          'expira_em': 3600,
          'usuario': {'id': 'u1', 'nome': 'Thamires', 'email': 't@x.com'},
          'salao': {'id': 's1', 'nome': 'Thamires Borges Beauty'},
        },
      });

      expect(model.token, 'jwt');
      expect(model.refreshToken, 'refresh');
      expect(model.usuario.nome, 'Thamires');
      expect(model.salaoNome, 'Thamires Borges Beauty');
    });

    test('login sem o bloco salão não quebra', () {
      final model = LoginResponseModel.fromResponse({
        'total': 1,
        'mensagem': 'ok',
        'result': {
          'token': 'jwt',
          'refresh_token': 'refresh',
          'usuario': <String, dynamic>{},
        },
      });

      expect(model.salaoNome, '');
      expect(model.expiraEm, 0);
    });
  });

  group('atendimentos', () {
    test('converte o agregado, a lista e os totais do servidor', () {
      final model = GetAtendimentosResponseModel.fromResponse({
        'total': 1,
        'mensagem': 'ok',
        'result': {
          'saldo_liquido': 430.0,
          'quantidade': 3,
          'atendimentos': [
            {
              'id': 'a1',
              'cliente_nome': 'Maria',
              'cliente_telefone': '+5511999887766',
              'data': '2026-08-31T10:00:00-03:00',
              'status': 'finalizado',
              'servicos': [
                {
                  'servico_id': 's1',
                  'nome': 'Extensão de cílios',
                  'preco': 180
                },
              ],
              'materiais': [
                {
                  'item_estoque_id': 'e1',
                  'nome': 'Fio mink 0.07',
                  'quantidade': 1,
                  'preco': 35,
                },
              ],
              'total_servicos': 180,
              'total_materiais': 35,
              'saldo': 145,
            },
          ],
        },
      });

      expect(model.saldoLiquido, 430.0);
      expect(model.atendimentos, hasLength(1));
      // int no JSON tem que virar double no model.
      expect(model.atendimentos.first.saldo, 145.0);
      expect(model.atendimentos.first.status, StatusAtendimento.finalizado);
      expect(model.atendimentos.first.servicos.first.preco, 180.0);
    });

    test('lista vazia não quebra', () {
      final model = GetAtendimentosResponseModel.fromResponse({
        'total': 0,
        'mensagem': 'ok',
        'result': {'saldo_liquido': 0, 'quantidade': 0, 'atendimentos': []},
      });

      expect(model.atendimentos, isEmpty);
      expect(model.saldoLiquido, 0.0);
    });

    test('status desconhecido cai em finalizado, não em exceção', () {
      final model = GetAtendimentosResponseModel.fromResponse({
        'total': 1,
        'mensagem': 'ok',
        'result': {
          'atendimentos': [
            {'id': 'a1', 'status': 'status_que_o_backend_inventou'},
          ],
        },
      });

      expect(model.atendimentos.first.status, StatusAtendimento.finalizado);
    });
  });

  group('gastos', () {
    test('converte totais, enums e vencimento', () {
      final model = GetGastosResponseModel.fromResponse({
        'total': 2,
        'mensagem': 'ok',
        'result': {
          'total_pendente': 246.80,
          'total_pago_mes': 210.0,
          'gastos': [
            {
              'id': 'g1',
              'nome': 'Conta de luz',
              'valor': 120.0,
              'prazo_pagamento': '2026-09-03',
              'forma_pagamento': 'pix',
              'categoria': 'fixo',
              'pago': false,
              'vence_em_dias': 1,
              'itens': [],
            },
            {
              'id': 'g2',
              'nome': 'Produtos',
              'valor': 210.0,
              'prazo_pagamento': '2026-08-20',
              'forma_pagamento': 'credito',
              'categoria': 'material',
              'pago': true,
              'pago_em': '2026-08-20',
              'vence_em_dias': -13,
              'itens': [],
            },
          ],
        },
      });

      expect(model.totalPendente, 246.80);
      expect(model.pendentes, hasLength(1));
      expect(model.pagos, hasLength(1));
      expect(model.pendentes.first.formaPagamento, FormaPagamento.pix);
      expect(model.pendentes.first.categoria, CategoriaGasto.fixo);
      expect(model.pendentes.first.isUrgente, isTrue);
      // Vencido só vale para pendente: pago não está vencido.
      expect(model.pagos.first.isVencido, isFalse);
    });
  });

  group('resumo', () {
    test('achata o payload aninhado e os insights', () {
      final model = GetResumoMensalResponseModel.fromResponse({
        'total': 1,
        'mensagem': 'ok',
        'result': {
          'ano': 2026,
          'mes': 8,
          'saldo_final': 1240.0,
          'entrou': 2985.0,
          'saiu': 1745.0,
          'receita': {
            'total_servicos': 2985.0,
            'total_insumos': 397.0,
            'liquido_atendimentos': 2588.0,
            'quantidade_atendimentos': 18,
            'total_kits': 135.0,
            'quantidade_kits_vendidos': 3,
            'custo_kits_vendidos': 51.0,
            'servicos_mais_realizados': [
              {
                'nome': 'Extensão de cílios',
                'quantidade': 2,
                'total_receita': 360.0,
                'lucro': 290.0,
              },
              {
                'nome': 'Limpeza de pele',
                'quantidade': 1,
                'total_receita': 150.0,
                'lucro': 115.0,
              },
            ],
          },
          'gastos': {
            'total_custos_fixos': 1348.0,
            'total_gastos_variaveis': 397.0,
            'total_saiu': 1745.0,
          },
          'insights': {
            'ticket_medio': 165.0,
            'margem_lucro_percentual': 41.5,
            'variacao_percentual_mes_anterior': 18.0,
            'servico_mais_lucrativo': {
              'nome': 'Extensão de cílios',
              'lucro': 290.0
            },
          },
          'alerta_zero_a_zero': false,
          'meta_faturamento_mensal': 9000.0,
          'historico_seis_meses': [
            {'ano': 2026, 'mes': 8, 'receitas': 2985.0, 'despesas': 1745.0},
          ],
        },
      });

      expect(model.saldoFinal, 1240.0);
      expect(model.ticketMedio, 165.0);
      expect(model.servicoMaisLucrativo, 'Extensão de cílios');
      expect(model.servicosMaisRealizados, hasLength(2));
      expect(model.maiorReceitaDoRanking, 290.0);
      expect(model.servicosMaisRealizados.first.lucro, 290.0);
      expect(model.metaFaturamentoMensal, 9000.0);
      expect(model.historicoSeisMeses.single.receitas, 2985.0);
      expect(model.isPositivo, isTrue);
      expect(model.totalKits, 135.0);
      expect(model.quantidadeKitsVendidos, 3);
      expect(model.temVendaDeKit, isTrue);
    });

    test('mês sem venda de kit não mostra a linha de kits', () {
      final model = GetResumoMensalResponseModel.fromResponse({
        'total': 1,
        'mensagem': 'ok',
        'result': {'ano': 2026, 'mes': 9, 'receita': <String, dynamic>{}},
      });

      expect(model.totalKits, 0);
      expect(model.temVendaDeKit, isFalse);
    });

    test('mês sem movimento não divide por zero na barra de proporção', () {
      final model = GetResumoMensalResponseModel.fromResponse({
        'total': 1,
        'mensagem': 'ok',
        'result': {'ano': 2026, 'mes': 8},
      });

      expect(model.entrou, 0.0);
      expect(model.saiu, 0.0);
      expect(model.proporcaoEntrada, 1.0);
      expect(model.maiorReceitaDoRanking, 0.0);
    });
  });

  group('estoque', () {
    test('usa o status que o servidor mandou, não recalcula', () {
      final model = GetEstoqueItensResponseModel.fromResponse({
        'total': 2,
        'mensagem': 'ok',
        'result': {
          'total_alertas': 1,
          'valor_total': 428.50,
          'itens': [
            {
              'id': 'e1',
              'nome': 'Cola adesiva',
              'unidade': 'un',
              'categoria': 'cilios',
              'quantidade_atual': 0,
              'quantidade_minima': 2,
              'custo_medio': 28.0,
              'custo_ultima_compra': 30.0,
              'status': 'critico',
              'deficit': 2,
              'ativo': true,
            },
            {
              'id': 'e2',
              'nome': 'Henna',
              'unidade': 'g',
              'categoria': 'sobrancelha',
              'quantidade_atual': 30,
              'quantidade_minima': 10,
              'custo_medio': 3.0,
              'custo_ultima_compra': 3.0,
              'status': 'ok',
              'deficit': 0,
              'ativo': true,
            },
          ],
        },
      });

      expect(model.emAlerta, hasLength(1));
      expect(model.emOk, hasLength(1));
      expect(model.emAlerta.first.status, StatusEstoque.critico);
      expect(model.emOk.first.unidade, UnidadeEstoque.g);
      expect(model.emAlerta.first.custoMedio, 28.0);
      expect(model.emAlerta.first.custoUltimaCompra, 30.0);
      expect(model.valorTotal, 428.50);
    });

    test('saldo negativo não vira crítico — são estados diferentes', () {
      final model = GetEstoqueItensResponseModel.fromResponse({
        'total': 1,
        'mensagem': 'ok',
        'result': {
          'valor_total': 0.0,
          'itens': [
            {
              'id': 'e3',
              'nome': 'Pinça curva',
              'unidade': 'un',
              'categoria': 'sobrancelha',
              'quantidade_atual': -1,
              'quantidade_minima': 1,
              'custo_medio': 35.0,
              'status': 'negativo',
              'deficit': 2,
              'ativo': true,
            },
          ],
        },
      });

      expect(model.emAlerta.first.status, StatusEstoque.negativo);
    });

    test('faltantes de um erro de estoque insuficiente viram lista', () {
      final faltantes = EstoqueFaltanteModel.listFrom({
        'faltantes': [
          {
            'item_estoque_id': 'e1',
            'nome': 'Cola adesiva para cílios',
            'unidade': 'un',
            'quantidade_solicitada': 2,
            'quantidade_disponivel': 0,
            'deficit': 2,
          },
        ],
      });

      expect(faltantes, hasLength(1));
      expect(faltantes.first.deficit, 2);
      expect(faltantes.first.unidade, UnidadeEstoque.un);
    });

    test('faltantes em formato inesperado devolve lista vazia, não exceção',
        () {
      expect(EstoqueFaltanteModel.listFrom(null), isEmpty);
      expect(EstoqueFaltanteModel.listFrom({'faltantes': 'nada'}), isEmpty);
    });

    test('movimentações trazem o vínculo com o atendimento', () {
      final model = GetMovimentacoesResponseModel.fromResponse({
        'total': 1,
        'mensagem': 'ok',
        'result': {
          'movimentacoes': [
            {
              'id': 'm1',
              'item_id': 'e1',
              'item_nome': 'Cola adesiva',
              'tipo': 'saida',
              'quantidade': 1,
              'motivo': 'Atendimento — Maria',
              'atendimento_id': 'a1',
              'criado_em': '2026-08-31T10:40:00-03:00',
            },
          ],
        },
      });

      expect(model.movimentacoes.first.tipo, TipoMovimentacao.saida);
      expect(model.movimentacoes.first.isEntrada, isFalse);
      expect(model.movimentacoes.first.atendimentoId, 'a1');
    });
  });

  group('kits', () {
    test('monta o resumo textual dos itens', () {
      final model = GetKitsResponseModel.fromResponse({
        'total': 1,
        'mensagem': 'ok',
        'result': {
          'kits': [
            {
              'id': 'k1',
              'nome': 'Kit cuidado pós-cílios',
              'preco_venda': 45.0,
              'custo_total': 21.50,
              'margem': 23.50,
              'quantidade_montada': 3,
              'quantidade_montavel': 7,
              'disponivel': true,
              'itens': [
                {
                  'item_estoque_id': 'e1',
                  'nome': 'Removedor',
                  'quantidade': 1,
                  'unidade': 'un'
                },
                {
                  'item_estoque_id': 'e2',
                  'nome': 'Fita micropore',
                  'quantidade': 2,
                  'unidade': 'cx'
                },
              ],
            },
          ],
        },
      });

      expect(model.kits.first.resumoItens, '1x Removedor, 2x Fita micropore');
      expect(model.kits.first.margem, 23.50);
      expect(model.kits.first.quantidadeMontada, 3);
      expect(model.kits.first.quantidadeMontavel, 7);
      expect(model.kits.first.podeVender, isTrue);
    });

    test('kit sem montagem não pode ser vendido', () {
      final model = GetKitsResponseModel.fromResponse({
        'total': 1,
        'mensagem': 'ok',
        'result': {
          'kits': [
            {
              'id': 'k2',
              'nome': 'Kit sobrancelha',
              'preco_venda': 30.0,
              'quantidade_montada': 0,
              'quantidade_montavel': 4,
              'disponivel': true,
              'itens': <Map<String, dynamic>>[],
            },
          ],
        },
      });

      expect(model.kits.first.podeVender, isFalse);
      expect(model.kits.first.podeMontar, isTrue);
    });
  });

  group('perfil e serviços', () {
    test('perfil lê o bloco salão', () {
      final model = GetPerfilResponseModel.fromResponse({
        'total': 1,
        'mensagem': 'ok',
        'result': {
          'salao': {
            'id': 's1',
            'nome': 'Thamires Borges Beauty',
            'proprietaria': 'Thamires Borges',
            'telefone_whatsapp': '+5511999999999',
          },
        },
      });

      expect(model.perfil.proprietaria, 'Thamires Borges');
      expect(model.perfil.fotoUrl, isNull);
    });

    test('custos fixos trazem o total mensal calculado pelo servidor', () {
      final model = GetCustosFixosResponseModel.fromResponse({
        'total': 3,
        'mensagem': 'ok',
        'result': {
          'total_mensal': 1348.0,
          'custos': [
            {
              'id': 'c1',
              'descricao': 'Aluguel',
              'valor': 1200.0,
              'dia_vencimento': 5,
            },
            {'id': 'c2', 'descricao': 'Internet', 'valor': 99.0},
            {'id': 'c3', 'descricao': 'App de agendamento', 'valor': 49.0},
          ],
        },
      });

      expect(model.totalMensal, 1348.0);
      expect(model.custos, hasLength(3));
      expect(model.custos.first.diaVencimento, 5);
      // Custo cadastrado antes de o campo existir: dia 1, nunca nulo — a tela
      // e o alerta contam com um dia sempre presente.
      expect(model.custos[1].diaVencimento, CustoFixoModel.diaVencimentoPadrao);
      expect(model.custos.first.toBody['dia_vencimento'], 5);
    });

    test('serviço traz os produtos padrão que pré-preenchem a finalização', () {
      final model = GetServicosResponseModel.fromResponse({
        'total': 1,
        'mensagem': 'ok',
        'result': {
          'servicos': [
            {
              'id': 's1',
              'nome': 'Extensão de cílios',
              'preco': 180.0,
              'produtos_padrao': [
                {
                  'item_estoque_id': 'e1',
                  'nome': 'Fio mink 0.07',
                  'quantidade': 1,
                  'unidade': 'un',
                },
              ],
            },
          ],
        },
      });

      expect(model.servicos.first.produtosPadrao, hasLength(1));
      expect(model.servicos.first.produtosPadrao.first.nome, 'Fio mink 0.07');
    });

    test('serviço sem produtos padrão vem com lista vazia, não nulo', () {
      final model = GetServicosResponseModel.fromResponse({
        'total': 1,
        'mensagem': 'ok',
        'result': {
          'servicos': [
            {'id': 's1', 'nome': 'Design', 'preco': 60.0},
          ],
        },
      });

      expect(model.servicos.first.produtosPadrao, isEmpty);
    });
  });

  group('alertas', () {
    test('badge soma crítico e alerta, e não conta info', () {
      final model = GetAlertasResponseModel.fromResponse({
        'total': 4,
        'mensagem': 'ok',
        'result': {
          'total_nao_lidos': 4,
          'resumo': {'critico': 2, 'alerta': 2, 'info': 5},
          'alertas': [
            {
              'id': 'al1',
              'tipo': 'estoque_critico',
              'severidade': 'critico',
              'titulo': 'Cola adesiva acabou',
              'mensagem': 'Você está com 0 un.',
              'referencia_tipo': 'estoque_item',
              'referencia_id': 'e1',
              'criado_em': '2026-09-01T08:00:00-03:00',
            },
          ],
        },
      });

      expect(model.badgeCount, 4);
      expect(model.alertas.first.tipo, TipoAlerta.estoqueCritico);
      expect(model.alertas.first.severidade, SeveridadeAlerta.critico);
      expect(model.alertas.first.isLido, isFalse);
    });

    test('result ausente devolve o model vazio, sem exceção', () {
      final model = GetAlertasResponseModel.fromResponse({
        'total': 0,
        'mensagem': 'ok',
      });

      expect(model.badgeCount, 0);
      expect(model.alertas, isEmpty);
    });
  });
}
