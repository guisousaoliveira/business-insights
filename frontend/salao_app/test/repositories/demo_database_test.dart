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

  group('editar atendimento', () {
    Map<String, dynamic> atendimentoDe(String id) =>
        (db.getAtendimentos(DateTime(2000), DateTime(2100))['result']
                ['atendimentos'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((e) => e['id'] == id);

    Map<String, dynamic> corpo({String nome = 'Cliente Renomeado'}) => {
          'cliente_nome': nome,
          'cliente_telefone': '11988887777',
          'data': DateTime(2026, 9, 20, 15).toIso8601String(),
          'servicos': [
            {'nome': 'Serviço avulso', 'preco': 90.0},
          ],
        };

    test('reescreve cliente, data e serviços do agendado', () {
      final id = idDoAtendimentoAgendado();
      db.editAtendimento(id, corpo());

      final atendimento = atendimentoDe(id);
      expect(atendimento['cliente_nome'], 'Cliente Renomeado');
      expect(atendimento['total_servicos'], 90.0);
      expect(atendimento['status'], 'agendado');
    });

    test('cancelado recusa: registro fora das contas não se reescreve', () {
      final id = idDoAtendimentoAgendado();
      db.cancelarAtendimento(id);

      Object? capturado;
      try {
        db.editAtendimento(id, corpo());
      } catch (e) {
        capturado = e;
      }

      expect(codigoDe(capturado!), AppErrorCodes.appointmentInvalidStatus);
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
  group('vencimentos avisam com uma semana', () {
    test(
        'dia 31 em mês curto cai no último dia, não escorrega para o mês que vem',
        () {
      expect(
        DemoDatabase.diasAteVencer(31, referencia: DateTime(2026, 2, 1)),
        27,
        reason: 'fevereiro de 2026 acaba no dia 28',
      );
      expect(
        DemoDatabase.diasAteVencer(5, referencia: DateTime(2026, 3, 30)),
        -25,
        reason:
            'em aberto, o vencimento que conta é o deste mês — e ele passou',
      );
      expect(
        DemoDatabase.diasAteVencer(
          5,
          referencia: DateTime(2026, 3, 30),
          pagoNoMes: true,
        ),
        6,
        reason: 'pago o mês, o alvo passa a ser o do mês seguinte',
      );
      expect(
          DemoDatabase.diasAteVencer(10, referencia: DateTime(2026, 3, 10)), 0);
    });

    test('custo fixo vira alerta dentro da janela de sete dias, e só nela', () {
      final hoje = DateTime.now();
      final longe = List.generate(31, (index) => index + 1).firstWhere(
        (dia) =>
            DemoDatabase.diasAteVencer(dia) >
            DemoDatabase.diasAntecedenciaVencimento,
      );

      db.createCustoFixo(
        {'descricao': 'Contador', 'valor': 200.0, 'dia_vencimento': hoje.day},
      );
      db.createCustoFixo(
        {
          'descricao': 'Domínio do site',
          'valor': 60.0,
          'dia_vencimento': longe
        },
      );

      final titulos = (db.getAlertas(null)['result']['alertas'] as List)
          .cast<Map<String, dynamic>>()
          .where((e) => e['tipo'] == 'custo_fixo_a_vencer')
          .map((e) => e['titulo'] as String)
          .toList();

      expect(titulos.any((e) => e.contains('Contador')), isTrue);
      expect(titulos.any((e) => e.contains('Domínio do site')), isFalse);
    });
  });

  group('serviços e produtos padrão', () {
    List<Map<String, dynamic>> servicos() =>
        (db.getServicos()['result']['servicos'] as List)
            .cast<Map<String, dynamic>>();

    test('editar resolve nome e unidade do item, não confia no corpo', () {
      final servico = servicos().first;
      final item = itemChamado('Fita micropore');

      db.editServico(servico['id'] as String, {
        'nome': 'Manicure completa',
        'preco': 60.0,
        'produtos_padrao': [
          {'item_estoque_id': item['id'], 'quantidade': 2.0},
        ],
      });

      final depois = servicos().firstWhere((e) => e['id'] == servico['id']);
      expect(depois['nome'], 'Manicure completa');
      expect(depois['preco'], 60.0);

      final produtos =
          (depois['produtos_padrao'] as List).cast<Map<String, dynamic>>();
      expect(produtos, hasLength(1));
      expect(produtos.first['nome'], item['nome']);
      expect(produtos.first['unidade'], item['unidade']);
      expect(produtos.first['quantidade'], 2.0);
    });

    test('vincular item inexistente é 404, não vira baixa fantasma', () {
      final servico = servicos().first;
      final antes = servico['produtos_padrao'];

      expect(
        () => db.editServico(servico['id'] as String, {
          'nome': servico['nome'],
          'preco': servico['preco'],
          'produtos_padrao': [
            {'item_estoque_id': 'item-que-nao-existe', 'quantidade': 1.0},
          ],
        }),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.data['codigo'],
            'codigo',
            AppErrorCodes.notFound,
          ),
        ),
      );
      expect(servicos().first['produtos_padrao'], antes);
    });

    test('material repetido é recusado: baixa dobrada ninguém confere', () {
      final servico = servicos().first;
      final item = itemChamado('Fita micropore');

      expect(
        () => db.editServico(servico['id'] as String, {
          'nome': servico['nome'],
          'preco': servico['preco'],
          'produtos_padrao': [
            {'item_estoque_id': item['id'], 'quantidade': 1.0},
            {'item_estoque_id': item['id'], 'quantidade': 2.0},
          ],
        }),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.data['codigo'],
            'codigo',
            AppErrorCodes.invalidValidation,
          ),
        ),
      );
    });

    test('editar serviço inexistente é 404', () {
      expect(
        () => db.editServico(
          'servico-que-nao-existe',
          {'nome': 'x', 'preco': 1.0, 'produtos_padrao': const []},
        ),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('custos fixos', () {
    List<Map<String, dynamic>> custos() =>
        (db.getCustosFixos()['result']['custos'] as List)
            .cast<Map<String, dynamic>>();

    String competenciaAtual() =>
        db.getCustosFixos()['result']['custos'].first['competencia'] as String;

    List<Map<String, dynamic>> alertasDeCustoFixo() =>
        (db.getAlertas(null)['result']['alertas'] as List)
            .cast<Map<String, dynamic>>()
            .where((e) => (e['tipo'] as String).startsWith('custo_fixo'))
            .toList();

    test('pagar vale só para a competência marcada', () {
      final aluguel = custos().firstWhere((e) => e['descricao'] == 'Aluguel');
      expect(aluguel['pago'], isFalse);

      db.pagarCustoFixo(
        aluguel['id'] as String,
        {'competencia': competenciaAtual(), 'pago': true},
      );

      final depois = custos().firstWhere((e) => e['id'] == aluguel['id']);
      expect(depois['pago'], isTrue);
      expect(depois['pago_em'], isNotNull);
      expect(
        db.getCustosFixos()['result']['total_pago'],
        1200.0,
        reason: 'o servidor soma o pago e o pendente; o app só exibe',
      );

      // O mês que vem nasce em aberto: é o ponto todo de guardar o pagamento
      // por competência em vez de dentro do cadastro.
      db.pagarCustoFixo(
        aluguel['id'] as String,
        {'competencia': '2099-12', 'pago': false},
      );
      expect(
        custos().firstWhere((e) => e['id'] == aluguel['id'])['pago'],
        isTrue,
        reason: 'desmarcar outra competência não mexe na corrente',
      );
    });

    test('desmarcar devolve o custo para pendente', () {
      final id = custos().first['id'] as String;
      final competencia = competenciaAtual();

      db.pagarCustoFixo(id, {'competencia': competencia, 'pago': true});
      db.pagarCustoFixo(id, {'competencia': competencia, 'pago': false});

      final depois = custos().firstWhere((e) => e['id'] == id);
      expect(depois['pago'], isFalse);
      expect(depois['pago_em'], isNull);
      expect(
        db.getCustosFixos()['result']['total_pendente'],
        db.getCustosFixos()['result']['total_mensal'],
      );
    });

    test('competência fora do formato AAAA-MM é 422', () {
      expect(
        () => db.pagarCustoFixo(
          custos().first['id'] as String,
          {'competencia': '2026-13', 'pago': true},
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.data['codigo'],
            'codigo',
            AppErrorCodes.invalidValidation,
          ),
        ),
      );
    });

    test('pagar cala o alerta do mês; vencido só existe em aberto', () {
      final id = custos().first['id'] as String;
      final vencidoOntem = DateTime.now().subtract(const Duration(days: 1));
      db.editCustoFixo(id, {
        'descricao': 'Contabilidade',
        'valor': 300.0,
        'dia_vencimento': vencidoOntem.day,
      });

      final antes =
          alertasDeCustoFixo().where((e) => e['referencia_id'] == id).toList();
      expect(antes, hasLength(1));
      expect(
        antes.first['tipo'],
        vencidoOntem.month == DateTime.now().month
            ? 'custo_fixo_vencido'
            : 'custo_fixo_a_vencer',
        reason: 'passou do dia e ninguém pagou: isso é vencido, não a vencer',
      );

      db.pagarCustoFixo(id, {'competencia': competenciaAtual(), 'pago': true});
      expect(
        alertasDeCustoFixo().where((e) => e['referencia_id'] == id),
        isEmpty,
      );
    });

    test('excluir leva junto o histórico de pagamento', () {
      final id = custos().first['id'] as String;
      db.pagarCustoFixo(id, {'competencia': competenciaAtual(), 'pago': true});
      db.deleteCustoFixo(id);

      expect(
        () => db.pagarCustoFixo(
          id,
          {'competencia': competenciaAtual(), 'pago': true},
        ),
        throwsA(isA<DioException>()),
      );
    });

    test('editar troca os três campos e mantém o total mensal coerente', () {
      final aluguel = custos().firstWhere((e) => e['descricao'] == 'Aluguel');
      expect(aluguel['dia_vencimento'], 5);

      db.editCustoFixo(aluguel['id'] as String, {
        'descricao': 'Aluguel da sala',
        'valor': 1300.0,
        'dia_vencimento': 10,
      });

      final depois = custos().firstWhere((e) => e['id'] == aluguel['id']);
      expect(depois['descricao'], 'Aluguel da sala');
      expect(depois['valor'], 1300.0);
      expect(depois['dia_vencimento'], 10);
      expect(
        db.getCustosFixos()['result']['total_mensal'],
        custos().fold<double>(0, (soma, e) => soma + (e['valor'] as double)),
        reason: 'o total vem do servidor; o app não soma lista',
      );
    });

    test('dia fora de 1..31 é recusado, na criação e na edição', () {
      expect(
        () => db.createCustoFixo(
          {'descricao': 'Luz', 'valor': 180.0, 'dia_vencimento': 40},
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.data['codigo'],
            'codigo',
            AppErrorCodes.invalidValidation,
          ),
        ),
      );

      final id = custos().first['id'] as String;
      expect(
        () => db.editCustoFixo(
          id,
          {'descricao': 'Luz', 'valor': 180.0, 'dia_vencimento': 0},
        ),
        throwsA(isA<DioException>()),
      );
      expect(custos().first['descricao'], isNot('Luz'),
          reason: 'recusa não grava metade');
    });

    test('editar id inexistente é 404', () {
      expect(
        () => db.editCustoFixo(
          'custo-que-nao-existe',
          {'descricao': 'x', 'valor': 1.0, 'dia_vencimento': 1},
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.data['codigo'],
            'codigo',
            AppErrorCodes.notFound,
          ),
        ),
      );
    });
  });
}
