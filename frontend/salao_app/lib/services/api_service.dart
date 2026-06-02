// ─────────────────────────────────────────────────────────────────────────────
// services/api_service.dart
//
// Client "Smart": Funciona offline (Mock) se baseUrl estiver vazia.
// Transiciona para a API real automaticamente assim que a URL for inserida.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/atendimento.dart';

class ApiService {
  // 🔴 COLE A URL DA SUA API AQUI QUANDO ESTIVER PRONTA (Ex: 'http://127.0.0.1:8000')
  static const String baseUrl = '';

  static final authState = ValueNotifier<bool>(false);

  // ===========================================================================
  // MOCKS EM MEMÓRIA
  // ===========================================================================

  static final Map<String, dynamic> _perfilMock = {
    'aluguel': 900.0,
    'outros_fixos': 220.0,
    'limite_gasto_alerta': 150.0,
    'telefone_whatsapp': '+5511999999999',
  };

  static final List<Atendimento> _atendimentosMock = [
    Atendimento(
      id: 'a1',
      clienteNome: 'Maria',
      clienteTelefone: '+5511999887766',
      data: DateTime.now().subtract(const Duration(days: 2)),
      servicos: const [ServicoAtendimento(nome: 'Corte', preco: 80.0)],
      materiais: const [MaterialAtendimento(nome: 'Shampoo', preco: 12.0)],
    ),
    Atendimento(
      id: 'a2',
      clienteNome: 'Larissa',
      clienteTelefone: '+55119988776655',
      data: DateTime.now().subtract(const Duration(days: 6)),
      servicos: const [ServicoAtendimento(nome: 'Coloração', preco: 190.0)],
      materiais: const [MaterialAtendimento(nome: 'Tintura', preco: 35.0)],
    ),
  ];

  static final List<Gasto> _gastosMock = [
    Gasto(
      id: 'g1',
      nome: 'Conta de luz',
      valor: 120.00,
      prazoPagamento: DateTime.now().add(const Duration(days: 2)),
      formaPagamento: FormaPagamento.pix,
      categoria: CategoriaGasto.fixo,
      pago: false,
      itens: const [],
    ),
    Gasto(
      id: 'g2',
      nome: 'Compra de tintura',
      valor: 56.90,
      prazoPagamento: DateTime.now().add(const Duration(days: 5)),
      formaPagamento: FormaPagamento.avista,
      categoria: CategoriaGasto.material,
      pago: false,
      itens: const [ItemGasto(nome: 'Tintura rosa', preco: 56.90)],
    ),
    Gasto(
      id: 'g3',
      nome: 'Assinatura de software',
      valor: 69.90,
      prazoPagamento: DateTime.now().add(const Duration(days: 16)),
      formaPagamento: FormaPagamento.debito,
      categoria: CategoriaGasto.fixo,
      pago: false,
      itens: const [],
    ),
  ];

  // ===========================================================================
  // AUTH
  // ===========================================================================

  static Future<void> signIn({required String email, required String password}) async {
    if (baseUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!email.contains('@') || password.length < 6) {
        throw Exception('E-mail ou senha inválidos');
      }
      authState.value = true;
      return;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      authState.value = true;
      // Salvar token localmente se necessário
    } else {
      throw Exception('Falha no login');
    }
  }

  static Future<void> signOut() async {
    authState.value = false;
  }

  // ===========================================================================
  // ATENDIMENTOS
  // ===========================================================================

  static Future<List<Atendimento>> getAtendimentos({
    required DateTime inicio,
    required DateTime fim,
  }) async {
    if (baseUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 250));
      return _atendimentosMock.where((a) => a.data.isAfter(inicio.subtract(const Duration(milliseconds: 1))) && a.data.isBefore(fim)).toList()..sort((a, b) => b.data.compareTo(a.data));
    }

    final url = Uri.parse('$baseUrl/atendimentos?inicio=${inicio.toIso8601String()}&fim=${fim.toIso8601String()}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Atendimento.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar atendimentos');
    }
  }

  static Future<void> criarAtendimento({
    required String clienteNome,
    required String clienteTelefone,
    required DateTime data,
    required List<Map<String, dynamic>> servicos,
    required List<Map<String, dynamic>> materiais,
  }) async {
    if (baseUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 250));
      _atendimentosMock.add(
        Atendimento(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          clienteNome: clienteNome,
          clienteTelefone: clienteTelefone,
          data: data,
          status: StatusAtendimento.agendado,
          servicos: servicos.map((s) => ServicoAtendimento(nome: s['nome'] as String, preco: (s['preco'] as num).toDouble())).toList(),
          materiais: materiais.map((m) => MaterialAtendimento(nome: m['nome'] as String, preco: (m['preco'] as num).toDouble())).toList(),
        ),
      );
      return;
    }

    final url = Uri.parse('$baseUrl/atendimentos');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'cliente_nome': clienteNome,
        'cliente_telefone': clienteTelefone,
        'data': data.toIso8601String(),
        'servicos': servicos,
        'materiais': materiais,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Falha ao criar atendimento');
    }
  }

  static Future<void> cancelarAtendimento(String id) async {
    if (baseUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 200));
      final idx = _atendimentosMock.indexWhere((a) => a.id == id);
      if (idx != -1) {
        _atendimentosMock[idx] = _atendimentosMock[idx].copyWith(status: StatusAtendimento.cancelado);
      }
      return;
    }

    final url = Uri.parse('$baseUrl/atendimentos/$id/cancelar');
    final response = await http.patch(url);
    if (response.statusCode != 200) throw Exception('Falha ao cancelar');
  }

  static Future<void> finalizarAtendimento(String id, List<Map<String, dynamic>> materiais) async {
    if (baseUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 200));
      final idx = _atendimentosMock.indexWhere((a) => a.id == id);
      if (idx != -1) {
        _atendimentosMock[idx] = _atendimentosMock[idx].copyWith(
          status: StatusAtendimento.finalizado,
          materiais: materiais.map((m) => MaterialAtendimento(nome: m['nome'], preco: m['preco'])).toList(),
        );
      }
      return;
    }

    final url = Uri.parse('$baseUrl/atendimentos/$id/finalizar');
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'materiais': materiais}),
    );
    if (response.statusCode != 200) throw Exception('Falha ao finalizar');
  }

  // ===========================================================================
  // GASTOS
  // ===========================================================================

  static Future<List<Gasto>> getGastos({bool? apenasNaoPagos}) async {
    if (baseUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 250));
      final lista = _gastosMock.where((g) => apenasNaoPagos != true || !g.pago).toList();
      lista.sort((a, b) => a.prazoPagamento.compareTo(b.prazoPagamento));
      return lista;
    }

    final query = apenasNaoPagos == true ? '?apenas_nao_pagos=true' : '';
    final url = Uri.parse('$baseUrl/gastos$query');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Gasto.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao buscar gastos');
    }
  }

  static Future<void> registrarGasto({
    required String nome,
    required double valor,
    required String prazoPagamento,
    required String formaPagamento,
    required String categoria,
    List<Map<String, dynamic>> itens = const [],
  }) async {
    if (baseUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 250));
      final prazo = DateTime.parse(prazoPagamento);
      final forma = FormaPagamento.values.firstWhere(
        (e) => e.name == formaPagamento,
        orElse: () => FormaPagamento.pix,
      );
      final cat = CategoriaGasto.values.firstWhere(
        (e) => e.name == categoria,
        orElse: () => CategoriaGasto.outros,
      );

      _gastosMock.add(
        Gasto(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          nome: nome,
          valor: valor,
          prazoPagamento: prazo,
          formaPagamento: forma,
          categoria: cat,
          pago: false,
          itens: itens.map((i) => ItemGasto(nome: i['nome'] as String, preco: (i['preco'] as num).toDouble())).toList(),
        ),
      );
      return;
    }

    final url = Uri.parse('$baseUrl/gastos');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': nome,
        'valor': valor,
        'prazo_pagamento': prazoPagamento,
        'forma_pagamento': formaPagamento,
        'categoria': categoria,
        'itens': itens,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Falha ao registrar gasto');
    }
  }

  static Future<void> marcarGastoPago(String gastoId) async {
    if (baseUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 250));
      final index = _gastosMock.indexWhere((g) => g.id == gastoId);
      if (index == -1) throw Exception('Gasto não encontrado');

      _gastosMock[index] = Gasto(
        id: _gastosMock[index].id,
        nome: _gastosMock[index].nome,
        valor: _gastosMock[index].valor,
        prazoPagamento: _gastosMock[index].prazoPagamento,
        formaPagamento: _gastosMock[index].formaPagamento,
        categoria: _gastosMock[index].categoria,
        pago: true,
        itens: _gastosMock[index].itens,
      );
      return;
    }

    final url = Uri.parse('$baseUrl/gastos/$gastoId/pagar');
    final response = await http.patch(url); // Supondo um endpoint PATCH para atualizar status

    if (response.statusCode != 200) {
      throw Exception('Falha ao marcar gasto como pago');
    }
  }

  // ===========================================================================
  // PERFIL E CONFIGURAÇÕES
  // ===========================================================================

  static Future<Map<String, dynamic>> getPerfil() async {
    if (baseUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 150));
      return Map<String, dynamic>.from(_perfilMock);
    }

    final url = Uri.parse('$baseUrl/perfil');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao carregar perfil');
    }
  }

  static Future<void> savePerfil({
    required double aluguel,
    required double outrosFixos,
    required double limiteGastoAlerta,
    required String telefoneWhatsApp,
  }) async {
    if (baseUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 150));
      _perfilMock['aluguel'] = aluguel;
      _perfilMock['outros_fixos'] = outrosFixos;
      _perfilMock['limite_gasto_alerta'] = limiteGastoAlerta;
      _perfilMock['telefone_whatsapp'] = telefoneWhatsApp;
      return;
    }

    final url = Uri.parse('$baseUrl/perfil');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'aluguel': aluguel,
        'outros_fixos': outrosFixos,
        'limite_gasto_alerta': limiteGastoAlerta,
        'telefone_whatsapp': telefoneWhatsApp,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao salvar perfil');
    }
  }

  // ===========================================================================
  // RELATÓRIOS
  // ===========================================================================

  static Future<Map<String, dynamic>> getRelatorioMensal({int? mes, int? ano}) async {
    if (baseUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 250));
      final now = DateTime.now();
      final selectedMonth = mes ?? now.month;
      final selectedYear = ano ?? now.year;

      final atendimentosDoMes = _atendimentosMock.where((a) {
        return a.data.month == selectedMonth && a.data.year == selectedYear;
      }).toList();

      final gastosDoMes = _gastosMock.where((g) {
        return g.prazoPagamento.month == selectedMonth && g.prazoPagamento.year == selectedYear;
      }).toList();
      final atendimentosValidos = atendimentosDoMes.where((a) => a.isFinalizado).toList();

      final receitaServicos = atendimentosValidos.fold(0.0, (sum, a) => sum + a.totalGanho);
      final custoMateriais = atendimentosValidos.fold(0.0, (sum, a) => sum + a.totalMateriais);
      final gastosVariaveis = gastosDoMes.where((g) => g.categoria != CategoriaGasto.fixo).fold(0.0, (sum, g) => sum + g.valor);

      final custoFixos = (_perfilMock['aluguel'] as double) + (_perfilMock['outros_fixos'] as double);
      final resultadoLiquido = receitaServicos - custoMateriais - gastosVariaveis - custoFixos;

      final vencimentosProximos = gastosDoMes
          .where((g) => !g.pago && g.prazoPagamento.isAfter(now.subtract(const Duration(days: 1))) && g.prazoPagamento.difference(now).inDays <= 7)
          .map((g) => {
                'nome': g.nome,
                'valor': g.valor,
                'prazo_pagamento': g.prazoPagamento.toIso8601String(),
              })
          .toList();

      return {
        'mes': selectedMonth,
        'ano': selectedYear,
        'total_atendimentos': atendimentosValidos.length,
        'receita_servicos': receitaServicos,
        'custo_materiais': custoMateriais,
        'gastos_variaveis': gastosVariaveis,
        'custos_fixos': custoFixos,
        'resultado_liquido': resultadoLiquido,
        'vencimentos_proximos': vencimentosProximos,
      };
    }

    // Chamada real para API FastAPI
    final url = Uri.parse('$baseUrl/relatorio/mensal?mes=${mes ?? ""}&ano=${ano ?? ""}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao carregar relatório mensal');
    }
  }
}
