import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../settings/app_error_codes.dart';

/// Servidor falso do modo demo — o backend inteiro, em memória.
///
/// Existe por um motivo só: deixar o app navegável enquanto o FastAPI não
/// responde às 52 operações de `.specs/endpoints-backend.md`. **Não é cache e
/// não é offline-first** (decisão A4): o estado vive no processo e some quando o
/// app fecha.
///
/// Três regras que ele segue de propósito, porque são as que o app assume:
///
/// 1. **Devolve envelope, não modelo.** Todo retorno passa pelo mesmo
///    `{ total, mensagem, codigo, result }` e é lido pelos mesmos
///    `fromResponse` de produção. O que está aqui é, literalmente, um exemplo
///    executável do payload que o backend precisa produzir.
/// 2. **Erro de negócio é `DioException` com `codigo`.** É assim que o
///    `ErrorModel.fromDioException` monta o erro que a tela mostra — inclusive
///    o `result.faltantes` das duas passadas de estoque (regra A5).
/// 3. **O servidor entrega número pronto** (S7): status, déficit, margem,
///    totais e alertas são calculados aqui, nunca na tela.
class DemoDatabase {
  DemoDatabase._() {
    _semear();
  }

  static final DemoDatabase instance = DemoDatabase._();

  /// Instância isolada com o seed intacto. Sem isto, um teste herdaria o que o
  /// anterior escreveu no singleton.
  @visibleForTesting
  factory DemoDatabase.paraTeste() => DemoDatabase._();

  /// Latência artificial. Sem ela os `loading` piscam e ninguém vê o estado de
  /// carregamento que o app tem em cada operação.
  static const latencia = Duration(milliseconds: 320);

  int _seq = 0;
  String _novoId(String prefixo) => '$prefixo-${++_seq}';

  // ── Tabelas ────────────────────────────────────────────────────────────────

  final List<Map<String, dynamic>> _itens = [];
  final List<Map<String, dynamic>> _movimentacoes = [];
  final List<Map<String, dynamic>> _servicos = [];
  final List<Map<String, dynamic>> _kits = [];
  final List<Map<String, dynamic>> _kitVendas = [];
  final List<Map<String, dynamic>> _atendimentos = [];
  final List<Map<String, dynamic>> _gastos = [];
  final List<Map<String, dynamic>> _custosFixos = [];
  final Set<String> _alertasLidos = {};

  Map<String, dynamic> _perfil = {};

  // ── Envelope e erro ────────────────────────────────────────────────────────

  /// O envelope de §3 de `endpoints-backend.md`, igual para sucesso e falha.
  Map<String, dynamic> envelope(
    Map<String, dynamic> result, {
    int total = 0,
    String mensagem = 'ok',
  }) =>
      {'total': total, 'mensagem': mensagem, 'codigo': null, 'result': result};

  /// Erro de negócio no formato que o `ErrorModel` sabe ler.
  ///
  /// Nasce como `DioException` de propósito: em produção quem lança é o Dio, e
  /// o repository não trata exceção — quem trata é o cubit. O modo demo entra
  /// exatamente no mesmo caminho.
  Never _erro(
    String codigo, {
    required int status,
    required String mensagem,
    Map<String, dynamic> result = const {},
  }) {
    final options = RequestOptions(path: 'demo');
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: options,
        statusCode: status,
        data: {
          'total': 0,
          'mensagem': mensagem,
          'codigo': codigo,
          'result': result,
        },
      ),
    );
  }

  Never _naoEncontrado(String oQue) => _erro(
        AppErrorCodes.notFound,
        status: 404,
        mensagem: '$oQue não encontrado.',
      );

  // ── Datas ──────────────────────────────────────────────────────────────────

  static DateTime _hoje() {
    final agora = DateTime.now();
    return DateTime(agora.year, agora.month, agora.day);
  }

  static DateTime _dias(int quantidade) =>
      _hoje().add(Duration(days: quantidade));

  static bool _noMes(DateTime data, int ano, int mes) =>
      data.year == ano && data.month == mes;

  // ── Estoque: cálculo ───────────────────────────────────────────────────────

  Map<String, dynamic> _itemPorId(String id) => _itens.firstWhere(
        (e) => e['id'] == id,
        orElse: () => _naoEncontrado('Item'),
      );

  /// `negativo` é status próprio (regra 4 da entrega): "devo mais do que tenho"
  /// não é a mesma coisa que "acabou".
  static String _statusDoItem(double atual, double minima) {
    if (atual < 0) return 'negativo';
    if (atual == 0) return 'critico';
    if (atual <= minima) return 'alerta';
    return 'ok';
  }

  Map<String, dynamic> _itemToApi(Map<String, dynamic> row) {
    final atual = row['quantidade_atual'] as double;
    final minima = row['quantidade_minima'] as double;
    return {
      'id': row['id'],
      'nome': row['nome'],
      'unidade': row['unidade'],
      'categoria': row['categoria'],
      'quantidade_atual': atual,
      'quantidade_minima': minima,
      'custo_medio': row['custo_medio'],
      'custo_ultima_compra': row['custo_ultima_compra'],
      'status': _statusDoItem(atual, minima),
      'deficit': math.max(0, minima - atual),
      'ativo': row['ativo'],
    };
  }

  void _movimentar(
    Map<String, dynamic> item,
    String tipo,
    double quantidade,
    String motivo, {
    String? atendimentoId,
  }) {
    _movimentacoes.insert(0, {
      'id': _novoId('mov'),
      'item_id': item['id'],
      'item_nome': item['nome'],
      'tipo': tipo,
      'quantidade': quantidade,
      'motivo': motivo,
      'atendimento_id': atendimentoId,
      'criado_em': DateTime.now().toIso8601String(),
    });
  }

  /// A primeira passada de A5: devolve o que falta **sem gravar nada**.
  ///
  /// `pedidos` é `{ item_estoque_id: quantidade }`. Lista vazia = tem saldo
  /// para tudo.
  List<Map<String, dynamic>> _faltantes(Map<String, double> pedidos) {
    final faltando = <Map<String, dynamic>>[];
    for (final pedido in pedidos.entries) {
      final item = _itemPorId(pedido.key);
      final disponivel = item['quantidade_atual'] as double;
      if (disponivel >= pedido.value) continue;
      faltando.add({
        'item_estoque_id': item['id'],
        'nome': item['nome'],
        'unidade': item['unidade'],
        'quantidade_solicitada': pedido.value,
        'quantidade_disponivel': disponivel,
        'deficit': pedido.value - disponivel,
      });
    }
    return faltando;
  }

  Never _estoqueInsuficiente(List<Map<String, dynamic>> faltantes) => _erro(
        AppErrorCodes.insufficientStock,
        status: 409,
        mensagem: 'Estoque insuficiente para concluir.',
        result: {'faltantes': faltantes},
      );

  // ── Kits: cálculo ──────────────────────────────────────────────────────────

  Map<String, dynamic> _kitPorId(String id) => _kits.firstWhere(
        (e) => e['id'] == id,
        orElse: () => _naoEncontrado('Kit'),
      );

  double _custoDoKit(Map<String, dynamic> kit) {
    var custo = 0.0;
    for (final composicao in kit['itens'] as List) {
      final linha = composicao as Map<String, dynamic>;
      final item = _itemPorId(linha['item_estoque_id'] as String);
      custo +=
          (linha['quantidade'] as double) * (item['custo_medio'] as double);
    }
    return custo;
  }

  /// Quantos kits o estoque de hoje ainda cobre — `min(saldo ÷ composição)`.
  /// Separado de `quantidade_montada`, que é o que já está pronto na prateleira
  /// (decisão A7).
  double _montavel(Map<String, dynamic> kit) {
    final itens = kit['itens'] as List;
    if (itens.isEmpty) return 0;
    var minimo = double.infinity;
    for (final composicao in itens) {
      final linha = composicao as Map<String, dynamic>;
      final item = _itemPorId(linha['item_estoque_id'] as String);
      final porKit = linha['quantidade'] as double;
      if (porKit <= 0) continue;
      final cabe = (item['quantidade_atual'] as double) / porKit;
      minimo = math.min(minimo, cabe);
    }
    if (minimo == double.infinity) return 0;
    return math.max(0, minimo.floorToDouble());
  }

  Map<String, dynamic> _kitToApi(Map<String, dynamic> kit) {
    final custo = _custoDoKit(kit);
    final montada = kit['quantidade_montada'] as double;
    final montavel = _montavel(kit);
    return {
      'id': kit['id'],
      'nome': kit['nome'],
      'preco_venda': kit['preco_venda'],
      'custo_total': custo,
      'margem': (kit['preco_venda'] as double) - custo,
      'quantidade_montada': montada,
      'quantidade_montavel': montavel,
      'disponivel': montada > 0 || montavel > 0,
      'itens': (kit['itens'] as List).map((e) {
        final linha = e as Map<String, dynamic>;
        final item = _itemPorId(linha['item_estoque_id'] as String);
        return {
          'item_estoque_id': item['id'],
          'nome': item['nome'],
          'quantidade': linha['quantidade'],
          'unidade': item['unidade'],
        };
      }).toList(),
    };
  }

  // ── Atendimentos e gastos: cálculo ─────────────────────────────────────────

  Map<String, dynamic> _atendimentoToApi(Map<String, dynamic> row) {
    final servicos = (row['servicos'] as List).cast<Map<String, dynamic>>();
    final materiais = (row['materiais'] as List).cast<Map<String, dynamic>>();
    final totalServicos = servicos.fold<double>(
      0,
      (soma, e) => soma + (e['preco'] as double),
    );
    final totalMateriais = materiais.fold<double>(
      0,
      (soma, e) => soma + (e['preco'] as double),
    );
    return {
      'id': row['id'],
      'cliente_nome': row['cliente_nome'],
      'cliente_telefone': row['cliente_telefone'],
      'data': row['data'],
      'status': row['status'],
      'servicos': servicos,
      'materiais': materiais,
      'total_servicos': totalServicos,
      'total_materiais': totalMateriais,
      'saldo': totalServicos - totalMateriais,
    };
  }

  Map<String, dynamic> _gastoToApi(Map<String, dynamic> row) {
    final prazo = DateTime.parse(row['prazo_pagamento'] as String);
    return {
      'id': row['id'],
      'nome': row['nome'],
      'valor': row['valor'],
      'prazo_pagamento': row['prazo_pagamento'],
      'forma_pagamento': row['forma_pagamento'],
      'categoria': row['categoria'],
      'pago': row['pago'],
      'pago_em': row['pago_em'],
      // Negativo = vencido. Quem calcula prazo é o servidor: é a mesma regra
      // que gera o alerta de gasto a vencer.
      'vence_em_dias': prazo.difference(_hoje()).inDays,
      'itens': row['itens'],
    };
  }

  // ── auth ───────────────────────────────────────────────────────────────────

  /// Aceita qualquer e-mail e qualquer senha — **menos a senha `errada`**, que
  /// devolve `AUTH_CREDENCIAIS_INVALIDAS`. É a única forma de ver o caminho de
  /// erro do login sem backend; convenção do modo demo, não contrato de API.
  Map<String, dynamic> login(String email, String senha) {
    if (senha == 'errada') {
      _erro(
        AppErrorCodes.invalidCredentials,
        status: 401,
        mensagem: 'E-mail ou senha incorretos.',
      );
    }
    return envelope({
      'token': 'demo-token',
      'refresh_token': 'demo-refresh-token',
      'expira_em': 3600,
      'usuario': {
        'id': 'demo-usuario',
        'nome': _perfil['proprietaria'],
        'email': email,
      },
      'salao': {'id': _perfil['id'], 'nome': _perfil['nome']},
    });
  }

  // ── atendimentos ───────────────────────────────────────────────────────────

  Map<String, dynamic> getAtendimentos(DateTime inicio, DateTime fim) {
    final limite = DateTime(fim.year, fim.month, fim.day, 23, 59, 59);
    final lista = _atendimentos
        .where((e) {
          final data = DateTime.parse(e['data'] as String);
          return !data.isBefore(inicio) && !data.isAfter(limite);
        })
        .map(_atendimentoToApi)
        .toList()
      ..sort((a, b) => (b['data'] as String).compareTo(a['data'] as String));

    final saldo = lista
        .where((e) => e['status'] == 'finalizado')
        .fold<double>(0, (soma, e) => soma + (e['saldo'] as double));

    return envelope(
      {
        'saldo_liquido': saldo,
        'quantidade': lista.length,
        'atendimentos': lista,
      },
      total: lista.length,
    );
  }

  Map<String, dynamic> createAtendimento(Map<String, dynamic> body) {
    // Preço do catálogo é congelado aqui, no servidor: mudar a tabela de preços
    // depois não pode reescrever o histórico financeiro.
    final servicos = (body['servicos'] as List).map((e) {
      final linha = e as Map<String, dynamic>;
      final id = linha['servico_id'] as String?;
      if (id == null) {
        return {
          'servico_id': null,
          'nome': linha['nome'],
          'preco': (linha['preco'] as num).toDouble(),
        };
      }
      final servico = _servicos.firstWhere(
        (s) => s['id'] == id,
        orElse: () => _naoEncontrado('Serviço'),
      );
      return {
        'servico_id': servico['id'],
        'nome': servico['nome'],
        'preco': servico['preco'],
      };
    }).toList();

    _atendimentos.add({
      'id': _novoId('atendimento'),
      'cliente_nome': body['cliente_nome'],
      'cliente_telefone': body['cliente_telefone'],
      'data': body['data'],
      'status': 'agendado',
      'servicos': servicos,
      'materiais': <Map<String, dynamic>>[],
    });
    return envelope(const {});
  }

  /// As duas passadas de A5. Com saldo faltando e `confirmar` em `false`, sai
  /// `409 ESTOQUE_INSUFICIENTE` e **nada** é gravado — nem parcialmente.
  Map<String, dynamic> finalizarAtendimento(
    String id,
    Map<String, dynamic> body,
  ) {
    final atendimento = _atendimentos.firstWhere(
      (e) => e['id'] == id,
      orElse: () => _naoEncontrado('Atendimento'),
    );
    if (atendimento['status'] != 'agendado') {
      _erro(
        AppErrorCodes.appointmentInvalidStatus,
        status: 409,
        mensagem: 'Este atendimento não está agendado.',
      );
    }

    final materiais = (body['materiais'] as List).cast<Map<String, dynamic>>();
    final pedidos = <String, double>{};
    for (final material in materiais) {
      final itemId = material['item_estoque_id'] as String?;
      if (itemId == null) continue;
      final quantidade = (material['quantidade'] as num).toDouble();
      pedidos[itemId] = (pedidos[itemId] ?? 0) + quantidade;
    }

    final faltando = _faltantes(pedidos);
    final confirmou = body['confirmar_estoque_insuficiente'] as bool? ?? false;
    // O confirmar libera **só** a checagem de saldo. Status inválido e material
    // inexistente continuam recusando — os dois já barraram acima.
    if (faltando.isNotEmpty && !confirmou) _estoqueInsuficiente(faltando);

    final gravados = <Map<String, dynamic>>[];
    for (final material in materiais) {
      final itemId = material['item_estoque_id'] as String?;
      final quantidade = (material['quantidade'] as num).toDouble();
      if (itemId == null) {
        gravados.add({
          'item_estoque_id': null,
          'nome': material['nome'],
          'quantidade': quantidade,
          'preco': (material['preco'] as num).toDouble(),
        });
        continue;
      }
      final item = _itemPorId(itemId);
      item['quantidade_atual'] =
          (item['quantidade_atual'] as double) - quantidade;
      _movimentar(item, 'saida', quantidade, 'Atendimento', atendimentoId: id);
      gravados.add({
        'item_estoque_id': item['id'],
        'nome': item['nome'],
        'quantidade': quantidade,
        // O custo do material é o custo médio de hoje (A6), congelado na linha.
        'preco': quantidade * (item['custo_medio'] as double),
      });
    }

    atendimento['materiais'] = gravados;
    atendimento['status'] = 'finalizado';
    return envelope(const {});
  }

  Map<String, dynamic> cancelarAtendimento(String id) {
    final atendimento = _atendimentos.firstWhere(
      (e) => e['id'] == id,
      orElse: () => _naoEncontrado('Atendimento'),
    );
    if (atendimento['status'] == 'cancelado') {
      _erro(
        AppErrorCodes.appointmentInvalidStatus,
        status: 409,
        mensagem: 'Este atendimento já está cancelado.',
      );
    }

    // Cancelar um atendimento já finalizado estorna a baixa que a finalização
    // deu — senão o estoque fica devendo material que nunca foi usado.
    if (atendimento['status'] == 'finalizado') {
      for (final e in (atendimento['materiais'] as List)) {
        final material = e as Map<String, dynamic>;
        final itemId = material['item_estoque_id'] as String?;
        if (itemId == null) continue;
        final item = _itemPorId(itemId);
        final quantidade = (material['quantidade'] as num).toDouble();
        item['quantidade_atual'] =
            (item['quantidade_atual'] as double) + quantidade;
        _movimentar(
          item,
          'entrada',
          quantidade,
          'Estorno — atendimento cancelado',
          atendimentoId: id,
        );
      }
      atendimento['materiais'] = <Map<String, dynamic>>[];
    }

    atendimento['status'] = 'cancelado';
    return envelope(const {});
  }

  // ── gastos ─────────────────────────────────────────────────────────────────

  Map<String, dynamic> getGastos(int ano, int mes) {
    final lista = _gastos
        .where((e) =>
            _noMes(DateTime.parse(e['prazo_pagamento'] as String), ano, mes))
        .map(_gastoToApi)
        .toList()
      ..sort((a, b) => (a['prazo_pagamento'] as String)
          .compareTo(b['prazo_pagamento'] as String));

    return envelope(
      {
        'total_pendente': lista
            .where((e) => e['pago'] == false)
            .fold<double>(0, (soma, e) => soma + (e['valor'] as double)),
        'total_pago_mes': lista
            .where((e) => e['pago'] == true)
            .fold<double>(0, (soma, e) => soma + (e['valor'] as double)),
        'gastos': lista,
      },
      total: lista.length,
    );
  }

  Map<String, dynamic> createGasto(Map<String, dynamic> body) {
    _gastos.add({
      'id': _novoId('gasto'),
      'nome': body['nome'],
      'valor': (body['valor'] as num).toDouble(),
      'prazo_pagamento': body['prazo_pagamento'],
      'forma_pagamento': body['forma_pagamento'],
      'categoria': body['categoria'],
      'pago': false,
      'pago_em': null,
      'itens': body['itens'] ?? const [],
    });
    return envelope(const {});
  }

  Map<String, dynamic> pagarGasto(String id) {
    final gasto = _gastos.firstWhere(
      (e) => e['id'] == id,
      orElse: () => _naoEncontrado('Gasto'),
    );
    if (gasto['pago'] == true) {
      _erro(
        AppErrorCodes.expenseAlreadyPaid,
        status: 409,
        mensagem: 'Este gasto já está pago.',
      );
    }
    gasto['pago'] = true;
    gasto['pago_em'] = DateTime.now().toIso8601String();
    return envelope(const {});
  }

  Map<String, dynamic> deleteGasto(String id) {
    _gastos.removeWhere((e) => e['id'] == id);
    return envelope(const {});
  }

  // ── estoque ────────────────────────────────────────────────────────────────

  Map<String, dynamic> getItens() {
    final lista = _itens
        .where((e) => e['ativo'] == true)
        .map(_itemToApi)
        .toList()
      ..sort((a, b) => (a['nome'] as String).compareTo(b['nome'] as String));

    return envelope(
      {
        'total_alertas': lista.where((e) => e['status'] != 'ok').length,
        'valor_total': lista.fold<double>(
          0,
          (soma, e) =>
              soma +
              (e['quantidade_atual'] as double) * (e['custo_medio'] as double),
        ),
        'itens': lista,
      },
      total: lista.length,
    );
  }

  Map<String, dynamic> createItem(Map<String, dynamic> body) {
    final quantidade = (body['quantidade_atual'] as num).toDouble();
    final custo = (body['custo_unitario'] as num).toDouble();
    final item = {
      'id': _novoId('item'),
      'nome': body['nome'],
      'unidade': body['unidade'],
      'categoria': body['categoria'],
      'quantidade_atual': quantidade,
      'quantidade_minima': (body['quantidade_minima'] as num).toDouble(),
      'custo_medio': custo,
      'custo_ultima_compra': custo,
      'ativo': true,
    };
    _itens.add(item);
    if (quantidade > 0) {
      _movimentar(item, 'entrada', quantidade, 'Cadastro do item');
    }
    return envelope(const {});
  }

  Map<String, dynamic> deleteItem(String id) {
    final item = _itemPorId(id);

    // Item que compõe kit não sai: apagar deixaria o kit sem custo e sem
    // composição.
    final emKit = _kits.any((kit) => (kit['itens'] as List).any(
          (e) => (e as Map<String, dynamic>)['item_estoque_id'] == id,
        ));
    if (emKit) {
      _erro(
        AppErrorCodes.itemInUse,
        status: 409,
        mensagem: 'Este item faz parte de um kit.',
      );
    }

    // Com movimentação, é soft delete — apagar quebraria o histórico de custo
    // dos atendimentos que já usaram o item.
    if (_movimentacoes.any((e) => e['item_id'] == id)) {
      item['ativo'] = false;
    } else {
      _itens.remove(item);
    }
    return envelope(const {});
  }

  /// Média ponderada móvel (A6): uma compra cara ou promocional move o custo na
  /// proporção do que entrou, em vez de reescrever o saldo parado.
  Map<String, dynamic> createMovimentacao(
    String itemId,
    Map<String, dynamic> body,
  ) {
    final item = _itemPorId(itemId);
    final tipo = body['tipo'] as String;
    final quantidade = (body['quantidade'] as num).toDouble();
    final custoUnitario = (body['custo_unitario'] as num?)?.toDouble();
    final saldo = item['quantidade_atual'] as double;

    switch (tipo) {
      case 'entrada':
        if (custoUnitario != null) {
          final medio = item['custo_medio'] as double;
          item['custo_medio'] = saldo <= 0
              ? custoUnitario
              : (saldo * medio + quantidade * custoUnitario) /
                  (saldo + quantidade);
          item['custo_ultima_compra'] = custoUnitario;
        }
        item['quantidade_atual'] = saldo + quantidade;
      case 'saida':
        item['quantidade_atual'] = saldo - quantidade;
      // `ajuste` é contagem: define o saldo. O app não emite este tipo hoje —
      // só `entrada`, pela tela de estoque.
      default:
        item['quantidade_atual'] = quantidade;
    }

    _movimentar(item, tipo, quantidade, body['motivo'] as String? ?? '');
    return envelope(const {});
  }

  Map<String, dynamic> getMovimentacoes(String? itemId) {
    final lista = _movimentacoes
        .where((e) => itemId == null || e['item_id'] == itemId)
        .toList();
    return envelope({'movimentacoes': lista}, total: lista.length);
  }

  // ── kits ───────────────────────────────────────────────────────────────────

  Map<String, dynamic> getKits() {
    final lista = _kits.map(_kitToApi).toList();
    return envelope({'kits': lista}, total: lista.length);
  }

  Map<String, dynamic> createKit(Map<String, dynamic> body) {
    _kits.add({
      'id': _novoId('kit'),
      'nome': body['nome'],
      'preco_venda': (body['preco_venda'] as num).toDouble(),
      'quantidade_montada': 0.0,
      'itens': (body['itens'] as List)
          .map((e) => {
                'item_estoque_id':
                    (e as Map<String, dynamic>)['item_estoque_id'],
                'quantidade': (e['quantidade'] as num).toDouble(),
              })
          .toList(),
    });
    return envelope(const {});
  }

  Map<String, dynamic> deleteKit(String id) {
    _kits.removeWhere((e) => e['id'] == id);
    return envelope(const {});
  }

  /// Montar consome insumo e passa pelo aviso de A5, igual à finalização.
  Map<String, dynamic> montarKit(String id, Map<String, dynamic> body) {
    final kit = _kitPorId(id);
    final quantidade = (body['quantidade'] as num).toDouble();
    final confirmou = body['confirmar_estoque_insuficiente'] as bool? ?? false;

    final pedidos = <String, double>{};
    for (final e in (kit['itens'] as List)) {
      final linha = e as Map<String, dynamic>;
      final itemId = linha['item_estoque_id'] as String;
      pedidos[itemId] =
          (pedidos[itemId] ?? 0) + (linha['quantidade'] as double) * quantidade;
    }

    final faltando = _faltantes(pedidos);
    if (faltando.isNotEmpty && !confirmou) _estoqueInsuficiente(faltando);

    for (final pedido in pedidos.entries) {
      final item = _itemPorId(pedido.key);
      item['quantidade_atual'] =
          (item['quantidade_atual'] as double) - pedido.value;
      _movimentar(item, 'saida', pedido.value, 'Montagem de kit');
    }

    kit['quantidade_montada'] =
        (kit['quantidade_montada'] as double) + quantidade;
    return envelope(const {});
  }

  /// Vender **não** tem segunda passada (A7): um kit que não foi montado não
  /// existe para vender.
  Map<String, dynamic> venderKit(String id, Map<String, dynamic> body) {
    final kit = _kitPorId(id);
    final quantidade = (body['quantidade'] as num).toDouble();
    final montada = kit['quantidade_montada'] as double;

    if (quantidade > montada) {
      _erro(
        AppErrorCodes.kitNotAssembled,
        status: 409,
        mensagem: 'Você tem menos kits montados do que está vendendo.',
      );
    }

    kit['quantidade_montada'] = montada - quantidade;
    _kitVendas.add({
      'kit_id': kit['id'],
      'nome': kit['nome'],
      'quantidade': quantidade,
      'preco_unitario':
          (body['preco_unitario'] as num?)?.toDouble() ?? kit['preco_venda'],
      'custo_unitario': _custoDoKit(kit),
      'forma_pagamento': body['forma_pagamento'],
      'data': DateTime.now().toIso8601String(),
    });
    return envelope(const {});
  }

  // ── perfil e serviços ──────────────────────────────────────────────────────

  Map<String, dynamic> getPerfil() => envelope({'salao': _perfil});

  Map<String, dynamic> updatePerfil(Map<String, dynamic> body) {
    _perfil = {..._perfil, ...body};
    return envelope(const {});
  }

  Map<String, dynamic> getCustosFixos() => envelope(
        {
          'total_mensal': _custosFixos.fold<double>(
            0,
            (soma, e) => soma + (e['valor'] as double),
          ),
          'custos': _custosFixos,
        },
        total: _custosFixos.length,
      );

  Map<String, dynamic> createCustoFixo(Map<String, dynamic> body) {
    _custosFixos.add({
      'id': _novoId('custo'),
      'descricao': body['descricao'],
      'valor': (body['valor'] as num).toDouble(),
    });
    return envelope(const {});
  }

  Map<String, dynamic> deleteCustoFixo(String id) {
    _custosFixos.removeWhere((e) => e['id'] == id);
    return envelope(const {});
  }

  Map<String, dynamic> getServicos() =>
      envelope({'servicos': _servicos}, total: _servicos.length);

  Map<String, dynamic> createServico(Map<String, dynamic> body) {
    _servicos.add({
      'id': _novoId('servico'),
      'nome': body['nome'],
      'preco': (body['preco'] as num).toDouble(),
      'produtos_padrao':
          (body['produtos_padrao'] as List? ?? const []).map((e) {
        final linha = e as Map<String, dynamic>;
        final item = _itemPorId(linha['item_estoque_id'] as String);
        return {
          'item_estoque_id': item['id'],
          'nome': item['nome'],
          'quantidade': (linha['quantidade'] as num).toDouble(),
          'unidade': item['unidade'],
        };
      }).toList(),
    });
    return envelope(const {});
  }

  Map<String, dynamic> deleteServico(String id) {
    _servicos.removeWhere((e) => e['id'] == id);
    return envelope(const {});
  }

  // ── resumo ─────────────────────────────────────────────────────────────────

  double _saldoDoMes(int ano, int mes) =>
      _resumo(ano, mes, comparar: false)['saldo_final'] as double;

  Map<String, dynamic> getResumoMensal(int ano, int mes) =>
      envelope(_resumo(ano, mes, comparar: true));

  /// Toda a conta do mês em um lugar. O app não soma nada disso (S7).
  Map<String, dynamic> _resumo(int ano, int mes, {required bool comparar}) {
    final finalizados = _atendimentos
        .where((e) =>
            e['status'] == 'finalizado' &&
            _noMes(DateTime.parse(e['data'] as String), ano, mes))
        .map(_atendimentoToApi)
        .toList();

    final totalServicos = finalizados.fold<double>(
      0,
      (soma, e) => soma + (e['total_servicos'] as double),
    );
    final totalInsumos = finalizados.fold<double>(
      0,
      (soma, e) => soma + (e['total_materiais'] as double),
    );

    // Ranking por nome do serviço, não por id: serviço avulso também conta.
    final ranking = <String, Map<String, dynamic>>{};
    for (final atendimento in finalizados) {
      for (final e in (atendimento['servicos'] as List)) {
        final servico = e as Map<String, dynamic>;
        final nome = servico['nome'] as String;
        final linha = ranking.putIfAbsent(
          nome,
          () => {'nome': nome, 'quantidade': 0, 'total_receita': 0.0},
        );
        linha['quantidade'] = (linha['quantidade'] as int) + 1;
        linha['total_receita'] =
            (linha['total_receita'] as double) + (servico['preco'] as double);
      }
    }
    final maisRealizados = ranking.values.toList()
      ..sort((a, b) => (b['total_receita'] as double)
          .compareTo(a['total_receita'] as double));
    for (final servico in maisRealizados) {
      final receita = servico['total_receita'] as double;
      final custoRateado =
          totalServicos == 0 ? 0.0 : totalInsumos * (receita / totalServicos);
      servico['lucro'] = receita - custoRateado;
    }

    final vendas = _kitVendas
        .where((e) => _noMes(DateTime.parse(e['data'] as String), ano, mes))
        .toList();
    final totalKits = vendas.fold<double>(
      0,
      (soma, e) =>
          soma + (e['quantidade'] as double) * (e['preco_unitario'] as double),
    );
    final quantidadeKits = vendas.fold<double>(
      0,
      (soma, e) => soma + (e['quantidade'] as double),
    );
    final custoKits = vendas.fold<double>(
      0,
      (soma, e) =>
          soma + (e['quantidade'] as double) * (e['custo_unitario'] as double),
    );

    // Custo fixo é o compromisso recorrente do perfil. O gasto de categoria
    // `fixo` é a materialização dele no mês — contar os dois somaria o mesmo
    // aluguel duas vezes.
    final totalCustosFixos = _custosFixos.fold<double>(
      0,
      (soma, e) => soma + (e['valor'] as double),
    );
    final totalVariaveis = _gastos
        .where((e) =>
            e['categoria'] != 'fixo' &&
            _noMes(DateTime.parse(e['prazo_pagamento'] as String), ano, mes))
        .fold<double>(0, (soma, e) => soma + (e['valor'] as double));

    // Venda de kit é receita e entra no `entrou`. O custo do kit **não** entra
    // no `saiu`: já saiu quando o insumo foi comprado (regra 5 da entrega).
    final entrou = totalServicos + totalKits;
    final saiu = totalCustosFixos + totalVariaveis;
    final saldoFinal = entrou - saiu;

    final anterior = comparar
        ? _saldoDoMes(mes == 1 ? ano - 1 : ano, mes == 1 ? 12 : mes - 1)
        : 0.0;

    final historico = comparar
        ? List.generate(6, (index) {
            final periodo = DateTime(ano, mes - (5 - index));
            final resumo = _resumo(
              periodo.year,
              periodo.month,
              comparar: false,
            );
            return {
              'ano': periodo.year,
              'mes': periodo.month,
              'receitas': resumo['entrou'],
              'despesas': resumo['saiu'],
            };
          })
        : const <Map<String, dynamic>>[];

    return {
      'ano': ano,
      'mes': mes,
      'saldo_final': saldoFinal,
      'entrou': entrou,
      'saiu': saiu,
      'historico_seis_meses': historico,
      'meta_faturamento_mensal': 9000.0,
      'receita': {
        'total_servicos': totalServicos,
        'total_insumos': totalInsumos,
        'liquido_atendimentos': totalServicos - totalInsumos,
        'quantidade_atendimentos': finalizados.length,
        'total_kits': totalKits,
        'quantidade_kits_vendidos': quantidadeKits.toInt(),
        'custo_kits_vendidos': custoKits,
        'servicos_mais_realizados': maisRealizados.take(5).toList(),
      },
      'gastos': {
        'total_custos_fixos': totalCustosFixos,
        'total_gastos_variaveis': totalVariaveis,
        'total_saiu': saiu,
      },
      'insights': {
        // Kit não é atendimento e diluiria o ticket que ela usa para precificar.
        'ticket_medio':
            finalizados.isEmpty ? 0.0 : totalServicos / finalizados.length,
        'margem_lucro_percentual':
            entrou == 0 ? 0.0 : saldoFinal / entrou * 100,
        'variacao_percentual_mes_anterior': anterior == 0
            ? 0.0
            : (saldoFinal - anterior) / anterior.abs() * 100,
        'saldo_mes_anterior': anterior,
        'servico_mais_lucrativo': maisRealizados.isEmpty
            ? null
            : {
                'nome': maisRealizados.first['nome'],
                'lucro': maisRealizados.first['total_receita'],
              },
      },
      // Trabalhou o mês e sobrou quase nada: o "zero a zero" do protótipo.
      'alerta_zero_a_zero': entrou > 0 && saldoFinal >= 0 && saldoFinal < 200,
    };
  }

  // ── alertas ────────────────────────────────────────────────────────────────

  /// Em produção quem gera é o job do backend. Aqui os alertas são derivados do
  /// estado a cada leitura — por isso o id é estável (`tipo:referencia`): é o
  /// que faz "marcar como lido" continuar valendo quando a lista é refeita.
  List<Map<String, dynamic>> _gerarAlertas() {
    final agora = DateTime.now().toIso8601String();
    final lista = <Map<String, dynamic>>[];

    void adicionar({
      required String tipo,
      required String severidade,
      required String titulo,
      required String mensagem,
      String? referenciaTipo,
      String? referenciaId,
    }) {
      final id = '$tipo:${referenciaId ?? 'geral'}';
      lista.add({
        'id': id,
        'tipo': tipo,
        'severidade': severidade,
        'titulo': titulo,
        'mensagem': mensagem,
        'referencia_tipo': referenciaTipo,
        'referencia_id': referenciaId,
        'criado_em': agora,
        'lido_em': _alertasLidos.contains(id) ? agora : null,
      });
    }

    for (final item in _itens.where((e) => e['ativo'] == true)) {
      final atual = item['quantidade_atual'] as double;
      final minima = item['quantidade_minima'] as double;
      final nome = item['nome'];
      final unidade = item['unidade'];
      final status = _statusDoItem(atual, minima);
      if (status == 'ok') continue;

      adicionar(
        tipo: switch (status) {
          'negativo' => 'estoque_negativo',
          'critico' => 'estoque_critico',
          _ => 'estoque_baixo',
        },
        severidade: status == 'alerta' ? 'alerta' : 'critico',
        titulo: switch (status) {
          'negativo' => '$nome está com saldo negativo',
          'critico' => '$nome acabou',
          _ => '$nome está no mínimo',
        },
        mensagem: 'Saldo $atual $unidade, mínimo $minima $unidade.',
        referenciaTipo: 'estoque_item',
        referenciaId: item['id'] as String,
      );
    }

    for (final gasto in _gastos.where((e) => e['pago'] == false)) {
      final dias = DateTime.parse(gasto['prazo_pagamento'] as String)
          .difference(_hoje())
          .inDays;
      if (dias > 3) continue;
      adicionar(
        tipo: dias < 0 ? 'gasto_vencido' : 'gasto_a_vencer',
        severidade: dias < 0 ? 'critico' : 'alerta',
        titulo: dias < 0
            ? '${gasto['nome']} venceu'
            : '${gasto['nome']} vence em $dias dia(s)',
        mensagem: 'Valor de ${gasto['valor']}.',
        referenciaTipo: 'gasto',
        referenciaId: gasto['id'] as String,
      );
    }

    final agoraData = DateTime.now();
    final saldo = _saldoDoMes(agoraData.year, agoraData.month);
    if (saldo < 0) {
      adicionar(
        tipo: 'saldo_negativo',
        severidade: 'critico',
        titulo: 'O mês está negativo',
        mensagem: 'Saiu mais do que entrou até agora.',
      );
    }

    return lista;
  }

  Map<String, dynamic> getAlertas(bool? apenasNaoLidos) {
    final todos = _gerarAlertas();
    final naoLidos = todos.where((e) => e['lido_em'] == null).toList();
    final lista = apenasNaoLidos == true ? naoLidos : todos;

    return envelope(
      {
        'total_nao_lidos': naoLidos.length,
        'resumo': {
          'critico': naoLidos.where((e) => e['severidade'] == 'critico').length,
          'alerta': naoLidos.where((e) => e['severidade'] == 'alerta').length,
        },
        'alertas': lista,
      },
      total: lista.length,
    );
  }

  Map<String, dynamic> marcarLido(String id) {
    _alertasLidos.add(id);
    return envelope(const {});
  }

  Map<String, dynamic> marcarTodosLidos() {
    _alertasLidos.addAll(_gerarAlertas().map((e) => e['id'] as String));
    return envelope(const {});
  }

  // ── seed ───────────────────────────────────────────────────────────────────

  /// Mantém a data dentro do mês corrente. As telas filtram por mês, e um seed
  /// relativo ("3 dias atrás") cairia no mês anterior nos primeiros dias — o
  /// app abriria vazio justamente quando alguém foi ver a demo.
  static DateTime _nesteMes(int dias) {
    final hoje = _hoje();
    final alvo = _dias(dias);
    if (alvo.month == hoje.month && alvo.year == hoje.year) return alvo;

    // Nos primeiros dias do mês quase todo o seed cairia no mês anterior.
    // Espalhar pelos dias que já existem é melhor do que empilhar tudo em hoje.
    final ultimoDia = DateTime(hoje.year, hoje.month + 1, 0).day;
    final dia = dias < 0
        ? math.max(1, hoje.day - (dias.abs() % hoje.day))
        : math.min(ultimoDia, hoje.day + 1);
    return DateTime(hoje.year, hoje.month, dia);
  }

  /// Espelho de `database/migrations/002_seed_teste.sql`: um item em cada
  /// estado de estoque, um gasto vencido, um a vencer e um pago, um atendimento
  /// finalizado e um agendado. É o que faz cada cor da tela aparecer.
  void _semear() {
    _perfil = {
      'id': 'demo-salao',
      'nome': 'Thamires Borges Beauty',
      'proprietaria': 'Thamires Borges',
      'foto_url': null,
      'telefone_whatsapp': '5511999990000',
    };

    Map<String, dynamic> item(
      String nome,
      String unidade,
      String categoria,
      double atual,
      double minima,
      double medio,
      double ultima,
    ) {
      final row = {
        'id': _novoId('item'),
        'nome': nome,
        'unidade': unidade,
        'categoria': categoria,
        'quantidade_atual': atual,
        'quantidade_minima': minima,
        'custo_medio': medio,
        'custo_ultima_compra': ultima,
        'ativo': true,
      };
      _itens.add(row);
      return row;
    }

    final fio = item('Fio mink 0.07', 'cx', 'cilios', 8, 3, 42, 45);
    final removedor =
        item('Removedor de cola', 'ml', 'cilios', 120, 50, 0.35, 0.40);
    final micropore =
        item('Fita micropore', 'cx', 'descartavel', 2, 2, 6.50, 6.50);
    final cola = item('Cola adesiva para cílios', 'un', 'cilios', 0, 2, 28, 30);
    final pinca = item('Pinça curva', 'un', 'sobrancelha', -1, 1, 35, 35);

    _movimentar(fio, 'entrada', 10, 'Compra — fornecedor');
    _movimentar(removedor, 'entrada', 150, 'Compra — fornecedor');
    _movimentar(pinca, 'saida', 1, 'Atendimento — saldo confirmado');

    _servicos.addAll([
      {
        'id': _novoId('servico'),
        'nome': 'Extensão de cílios',
        'preco': 180.0,
        'produtos_padrao': [
          {
            'item_estoque_id': fio['id'],
            'nome': fio['nome'],
            'quantidade': 1.0,
            'unidade': fio['unidade'],
          },
          {
            'item_estoque_id': cola['id'],
            'nome': cola['nome'],
            'quantidade': 1.0,
            'unidade': cola['unidade'],
          },
          {
            'item_estoque_id': micropore['id'],
            'nome': micropore['nome'],
            'quantidade': 2.0,
            'unidade': micropore['unidade'],
          },
        ],
      },
      {
        'id': _novoId('servico'),
        'nome': 'Manutenção de cílios',
        'preco': 100.0,
        'produtos_padrao': const [],
      },
      {
        'id': _novoId('servico'),
        'nome': 'Sobrancelha fio a fio',
        'preco': 120.0,
        'produtos_padrao': const [],
      },
    ]);

    _custosFixos.addAll([
      {'id': _novoId('custo'), 'descricao': 'Aluguel', 'valor': 1200.0},
      {'id': _novoId('custo'), 'descricao': 'Internet', 'valor': 99.0},
      {
        'id': _novoId('custo'),
        'descricao': 'App de agendamento',
        'valor': 49.0,
      },
    ]);

    final kit = {
      'id': _novoId('kit'),
      'nome': 'Kit cuidado pós-cílios',
      'preco_venda': 45.0,
      'quantidade_montada': 3.0,
      'itens': [
        {'item_estoque_id': removedor['id'], 'quantidade': 30.0},
        {'item_estoque_id': micropore['id'], 'quantidade': 1.0},
      ],
    };
    _kits.add(kit);

    _kitVendas.addAll([
      {
        'kit_id': kit['id'],
        'nome': kit['nome'],
        'quantidade': 1.0,
        'preco_unitario': 45.0,
        'custo_unitario': 17.0,
        'forma_pagamento': 'pix',
        'data': _nesteMes(-4).toIso8601String(),
      },
      {
        'kit_id': kit['id'],
        'nome': kit['nome'],
        'quantidade': 2.0,
        'preco_unitario': 45.0,
        'custo_unitario': 17.0,
        'forma_pagamento': 'a_vista',
        'data': _nesteMes(-9).toIso8601String(),
      },
    ]);

    // Um mês inteiro de trabalho, para o resumo ter o que consolidar: sem
    // histórico, a tela mais importante do app abre vazia.
    //
    // Só a Ana Paula consome material do estoque — o saldo dos itens acima já
    // está líquido dela, como no seed do banco. Os outros usam material avulso
    // (`item_estoque_id` nulo), que entra no custo do atendimento sem mexer no
    // estoque.
    void atendimento(
      String cliente,
      String telefone,
      int dias,
      String status,
      List<int> servicos, {
      List<Map<String, dynamic>> materiais = const [],
    }) {
      _atendimentos.add({
        'id': _novoId('atendimento'),
        'cliente_nome': cliente,
        'cliente_telefone': telefone,
        'data': _nesteMes(dias).toIso8601String(),
        'status': status,
        'servicos': servicos
            .map((i) => {
                  'servico_id': _servicos[i]['id'],
                  'nome': _servicos[i]['nome'],
                  'preco': _servicos[i]['preco'],
                })
            .toList(),
        'materiais': materiais,
      });
    }

    const avulso = [
      {
        'item_estoque_id': null,
        'nome': 'Insumos da aplicação',
        'quantidade': 1.0,
        'preco': 35.0,
      },
    ];

    atendimento(
      'Ana Paula',
      '(11) 99999-0001',
      -2,
      'finalizado',
      [0, 2],
      materiais: [
        {
          'item_estoque_id': fio['id'],
          'nome': fio['nome'],
          'quantidade': 1.0,
          'preco': 42.0,
        },
        {
          'item_estoque_id': micropore['id'],
          'nome': micropore['nome'],
          'quantidade': 2.0,
          'preco': 13.0,
        },
        {
          'item_estoque_id': null,
          'nome': 'Máscara de argila',
          'quantidade': 1.0,
          'preco': 9.0,
        },
      ],
    );
    atendimento('Bruna Lima', '(11) 99999-0003', -3, 'finalizado', [0],
        materiais: avulso);
    atendimento('Juliana Reis', '(11) 99999-0004', -5, 'finalizado', [1, 2]);
    atendimento('Marina Costa', '(11) 99999-0005', -7, 'finalizado', [0],
        materiais: avulso);
    atendimento('Patrícia Alves', '(11) 99999-0006', -9, 'finalizado', [2]);
    atendimento('Renata Dias', '(11) 99999-0007', -11, 'finalizado', [0],
        materiais: avulso);
    atendimento('Sofia Martins', '(11) 99999-0008', -13, 'finalizado', [1]);
    atendimento('Tatiane Rocha', '(11) 99999-0009', -15, 'finalizado', [0, 2]);
    atendimento('Vanessa Luz', '(11) 99999-0010', -18, 'finalizado', [0],
        materiais: avulso);
    atendimento('Yara Nunes', '(11) 99999-0011', -21, 'finalizado', [1, 2]);
    atendimento('Beatriz Faria', '(11) 99999-0012', -24, 'finalizado', [0]);
    atendimento('Carla Mendes', '(11) 98888-0002', 1, 'agendado', [1]);

    _gastos.addAll([
      {
        'id': _novoId('gasto'),
        'nome': 'Fios e colas (extensão)',
        'valor': 340.0,
        'prazo_pagamento': _nesteMes(-3).toIso8601String(),
        'forma_pagamento': 'credito',
        'categoria': 'material',
        'pago': false,
        'pago_em': null,
        'itens': const [],
      },
      {
        'id': _novoId('gasto'),
        'nome': 'Aluguel sala',
        'valor': 1200.0,
        'prazo_pagamento': _nesteMes(2).toIso8601String(),
        'forma_pagamento': 'pix',
        'categoria': 'fixo',
        'pago': false,
        'pago_em': null,
        'itens': const [],
      },
      {
        'id': _novoId('gasto'),
        'nome': 'Pinças e acessórios',
        'valor': 85.0,
        'prazo_pagamento': _nesteMes(-10).toIso8601String(),
        'forma_pagamento': 'a_vista',
        'categoria': 'material',
        'pago': true,
        'pago_em': _nesteMes(-10).toIso8601String(),
        'itens': const [],
      },
    ]);
  }
}
