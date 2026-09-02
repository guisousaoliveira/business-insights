import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app/repositories/demo/demo_database.dart';
import 'package:salon_app/settings/app_error_codes.dart';

/// O modo demo é o único lugar onde as regras de servidor rodam antes do
/// backend existir. Estes testes valem por duas coisas: garantem que a demo não
/// mente, e descrevem em código o comportamento que o FastAPI precisa ter.
void main() {
  late DemoDatabase db;

  setUp(() => db = DemoDatabase.paraTeste());

  Map<String, dynamic> itemChamado(String nome) =>
      (db.getItens()['result']['itens'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((e) => e['nome'] == nome);

  String idDoAtendimentoAgendado() => ((db.getAtendimentos(
        DateTime(2000),
        DateTime(2100),
      )['result']['atendimentos'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((e) => e['status'] == 'agendado'))['id'] as String;

  String? codigoDe(Object erro) =>
      ((erro as DioException).response!.data as Map)['codigo'] as String?;

  Map<String, dynamic> oKit() => (db.getKits()['result']['kits'] as List)
      .cast<Map<String, dynamic>>()
      .first;

  group('estoque', () {
    test('status separa negativo de crítico', () {
      expect(itemChamado('Cola adesiva para cílios')['status'], 'critico');
      expect(itemChamado('Pinça curva')['status'], 'negativo');
      expect(itemChamado('Fita micropore')['status'], 'alerta');
      expect(itemChamado('Fio mink 0.07')['status'], 'ok');
    });

    test('déficit é o quanto falta para o mínimo, nunca negativo', () {
      expect(itemChamado('Fio mink 0.07')['deficit'], 0);
      expect(itemChamado('Cola adesiva para cílios')['deficit'], 2);
      expect(itemChamado('Pinça curva')['deficit'], 2);
    });

    test('entrada recalcula o custo por média ponderada móvel', () {
      final fio = itemChamado('Fio mink 0.07');
      // 8 cx a 42,00 + 2 cx a 60,00 = (336 + 120) / 10
      db.createMovimentacao(fio['id'] as String, {
        'tipo': 'entrada',
        'quantidade': 2.0,
        'motivo': 'Compra',
        'custo_unitario': 60.0,
      });

      final depois = itemChamado('Fio mink 0.07');
      expect(depois['quantidade_atual'], 10);
      expect(depois['custo_medio'], closeTo(45.6, 0.001));
      expect(depois['custo_ultima_compra'], 60.0);
    });

    test('sem saldo para ponderar, o custo novo é o da entrada', () {
      final cola = itemChamado('Cola adesiva para cílios');
      db.createMovimentacao(cola['id'] as String, {
        'tipo': 'entrada',
        'quantidade': 5.0,
        'motivo': 'Compra',
        'custo_unitario': 31.0,
      });

      expect(itemChamado('Cola adesiva para cílios')['custo_medio'], 31.0);
    });

    test('item que compõe kit não pode ser apagado', () {
      final removedor = itemChamado('Removedor de cola');
      expect(
        () => db.deleteItem(removedor['id'] as String),
        throwsA(
            predicate<Object>((e) => codigoDe(e) == AppErrorCodes.itemInUse)),
      );
    });
  });

  group('duas passadas do estoque (A5)', () {
    test('sem saldo, a primeira passada recusa e não grava nada', () {
      final cola = itemChamado('Cola adesiva para cílios');
      final id = idDoAtendimentoAgendado();

      Object? capturado;
      try {
        db.finalizarAtendimento(id, {
          'materiais': [
            {'item_estoque_id': cola['id'], 'quantidade': 2.0},
          ],
          'confirmar_estoque_insuficiente': false,
        });
      } catch (e) {
        capturado = e;
      }

      expect(codigoDe(capturado!), AppErrorCodes.insufficientStock);

      final faltantes = ((capturado as DioException).response!.data
          as Map)['result']['faltantes'] as List;
      expect(faltantes, hasLength(1));
      expect(faltantes.first['nome'], 'Cola adesiva para cílios');
      expect(faltantes.first['quantidade_solicitada'], 2);
      expect(faltantes.first['quantidade_disponivel'], 0);
      expect(faltantes.first['deficit'], 2);

      // Nada gravado: nem o saldo do item, nem o status do atendimento.
      expect(itemChamado('Cola adesiva para cílios')['quantidade_atual'], 0);
      expect(idDoAtendimentoAgendado(), id);
    });

    test('confirmando, grava e deixa o saldo negativo', () {
      final cola = itemChamado('Cola adesiva para cílios');
      final id = idDoAtendimentoAgendado();

      db.finalizarAtendimento(id, {
        'materiais': [
          {'item_estoque_id': cola['id'], 'quantidade': 2.0},
        ],
        'confirmar_estoque_insuficiente': true,
      });

      final depois = itemChamado('Cola adesiva para cílios');
      expect(depois['quantidade_atual'], -2);
      expect(depois['status'], 'negativo');
      expect(
        () => idDoAtendimentoAgendado(),
        throwsA(isA<StateError>()),
        reason: 'o atendimento agendado virou finalizado',
      );
    });

    test('finalizar duas vezes recusa por status, não por estoque', () {
      final id = idDoAtendimentoAgendado();
      db.finalizarAtendimento(
        id,
        {'materiais': const [], 'confirmar_estoque_insuficiente': false},
      );

      expect(
        () => db.finalizarAtendimento(
          id,
          {'materiais': const [], 'confirmar_estoque_insuficiente': true},
        ),
        throwsA(predicate<Object>(
          (e) => codigoDe(e) == AppErrorCodes.appointmentInvalidStatus,
        )),
      );
    });

    test('cancelar atendimento finalizado estorna a baixa', () {
      final fio = itemChamado('Fio mink 0.07');
      final id = idDoAtendimentoAgendado();

      db.finalizarAtendimento(id, {
        'materiais': [
          {'item_estoque_id': fio['id'], 'quantidade': 3.0},
        ],
        'confirmar_estoque_insuficiente': false,
      });
      expect(itemChamado('Fio mink 0.07')['quantidade_atual'], 5);

      db.cancelarAtendimento(id);
      expect(itemChamado('Fio mink 0.07')['quantidade_atual'], 8);
    });
  });

  group('kits (A7)', () {
    test('montado e montável são fatos diferentes', () {
      final kit = oKit();
      // Composição: 30ml de removedor e 1 caixa de micropore.
      // Saldo do seed: 120ml (dá 4) e 2 caixas -> o gargalo é o micropore.
      expect(kit['quantidade_montada'], 3);
      expect(kit['quantidade_montavel'], 2);
      expect(kit['disponivel'], isTrue);
    });

    test('montar consome insumo e soma ao saldo montado', () {
      final antes = itemChamado('Removedor de cola');
      db.montarKit(oKit()['id'] as String, {
        'quantidade': 2.0,
        'confirmar_estoque_insuficiente': false,
      });

      expect(oKit()['quantidade_montada'], 5);
      expect(
        itemChamado('Removedor de cola')['quantidade_atual'],
        (antes['quantidade_atual'] as num) - 60,
      );
      expect(itemChamado('Fita micropore')['quantidade_atual'], 0);
    });

    test('montar acima do saldo pede confirmação antes de gravar', () {
      final id = oKit()['id'] as String;
      final corpo = {
        'quantidade': 4.0,
        'confirmar_estoque_insuficiente': false,
      };

      expect(
        () => db.montarKit(id, corpo),
        throwsA(predicate<Object>(
          (e) => codigoDe(e) == AppErrorCodes.insufficientStock,
        )),
      );
      expect(oKit()['quantidade_montada'], 3, reason: 'nada foi gravado');

      db.montarKit(id, {...corpo, 'confirmar_estoque_insuficiente': true});
      expect(oKit()['quantidade_montada'], 7);
      expect(itemChamado('Fita micropore')['quantidade_atual'], -2);
      expect(itemChamado('Fita micropore')['status'], 'negativo');
    });

    test('vender acima do montado é definitivo, sem segunda passada', () {
      final id = oKit()['id'] as String;

      expect(
        () => db.venderKit(id, {
          'quantidade': 4.0,
          'forma_pagamento': 'pix',
          'confirmar_estoque_insuficiente': true,
        }),
        throwsA(predicate<Object>(
          (e) => codigoDe(e) == AppErrorCodes.kitNotAssembled,
        )),
      );
      expect(oKit()['quantidade_montada'], 3);
    });

    test('vender baixa do montado sem tocar no estoque de insumo', () {
      final removedor = itemChamado('Removedor de cola')['quantidade_atual'];

      db.venderKit(oKit()['id'] as String, {
        'quantidade': 2.0,
        'forma_pagamento': 'pix',
      });

      expect(oKit()['quantidade_montada'], 1);
      expect(itemChamado('Removedor de cola')['quantidade_atual'], removedor);
    });
  });

  group('resumo mensal', () {
    final hoje = DateTime.now();

    Map<String, dynamic> resumo() =>
        db.getResumoMensal(hoje.year, hoje.month)['result']
            as Map<String, dynamic>;

    test('entrou soma serviço e kit; saiu não conta o custo do kit', () {
      final r = resumo();
      final receita = r['receita'] as Map<String, dynamic>;
      final gastos = r['gastos'] as Map<String, dynamic>;

      // 3 kits vendidos no seed, a 45 cada.
      expect(receita['quantidade_kits_vendidos'], 3);
      expect(receita['total_kits'], 135);
      expect(receita['custo_kits_vendidos'], 51);

      expect(r['entrou'], receita['total_servicos'] + receita['total_kits']);
      expect(
        r['saiu'],
        gastos['total_custos_fixos'] + gastos['total_gastos_variaveis'],
      );
      expect(r['saldo_final'], r['entrou'] - r['saiu']);
    });

    test('ticket médio é por atendimento, sem diluir com kit', () {
      final r = resumo();
      final receita = r['receita'] as Map<String, dynamic>;
      final insights = r['insights'] as Map<String, dynamic>;

      expect(
        insights['ticket_medio'],
        (receita['total_servicos'] as double) /
            (receita['quantidade_atendimentos'] as int),
      );
    });

    test('entrega seis meses, lucro por serviço e meta para o novo painel', () {
      final r = resumo();
      final receita = r['receita'] as Map<String, dynamic>;
      final ranking = receita['servicos_mais_realizados'] as List;

      expect(r['historico_seis_meses'], hasLength(6));
      expect(r['meta_faturamento_mensal'], 9000.0);
      expect((ranking.first as Map)['lucro'], isA<double>());
    });

    test('vender kit aumenta o que entrou no mês', () {
      final antes = resumo()['entrou'] as double;

      db.venderKit(oKit()['id'] as String, {
        'quantidade': 1.0,
        'forma_pagamento': 'pix',
      });

      expect(resumo()['entrou'], antes + 45);
    });
  });

  group('alertas', () {
    test('marcar como lido sobrevive à regeração da lista', () {
      final antes = db.getAlertas(null)['result'] as Map<String, dynamic>;
      final naoLidos = antes['total_nao_lidos'] as int;
      expect(naoLidos, greaterThan(0));

      final id = (antes['alertas'] as List).first['id'] as String;
      db.marcarLido(id);

      final depois = db.getAlertas(null)['result'] as Map<String, dynamic>;
      expect(depois['total_nao_lidos'], naoLidos - 1);
      expect(
        (depois['alertas'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((e) => e['id'] == id)['lido_em'],
        isNotNull,
        reason: 'o id do alerta é estável entre leituras',
      );

      db.marcarTodosLidos();
      expect(
        (db.getAlertas(null)['result'] as Map)['total_nao_lidos'],
        0,
      );
    });
  });
}
