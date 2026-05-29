// ─────────────────────────────────────────────────────────────────────────────
// services/api_service.dart
//
// Backend mockado em memória para rodar o app sem Supabase, FastAPI ou
// variáveis de ambiente.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/atendimento.dart';

class ApiService {
  static final authState = ValueNotifier<bool>(false);

  static final Map<String, dynamic> _perfil = {
    'aluguel': 900.0,
    'outros_fixos': 220.0,
    'limite_gasto_alerta': 150.0,
    'telefone_whatsapp': '+5511999999999',
  };

  static final List<Atendimento> _atendimentos = [
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

  static final List<Gasto> _gastos = [
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

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!email.contains('@') || password.length < 6) {
      throw Exception('E-mail ou senha inválidos');
    }
    authState.value = true;
  }

  static Future<void> signOut() async {
    authState.value = false;
  }

  static Future<List<Atendimento>> getAtendimentos({
    required DateTime inicio,
    required DateTime fim,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _atendimentos
        .where((a) => a.data.isAfter(inicio.subtract(const Duration(milliseconds: 1))) && a.data.isBefore(fim))
        .toList()
      ..sort((a, b) => b.data.compareTo(a.data));
  }

  static Future<void> criarAtendimento({
    required String clienteNome,
    required String clienteTelefone,
    required DateTime data,
    required List<Map<String, dynamic>> servicos,
    required List<Map<String, dynamic>> materiais,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _atendimentos.add(
      Atendimento(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        clienteNome: clienteNome,
        clienteTelefone: clienteTelefone,
        data: data,
        servicos: servicos
            .map((s) => ServicoAtendimento(
                  nome: s['nome'] as String,
                  preco: (s['preco'] as num).toDouble(),
                ))
            .toList(),
        materiais: materiais
            .map((m) => MaterialAtendimento(
                  nome: m['nome'] as String,
                  preco: (m['preco'] as num).toDouble(),
                ))
            .toList(),
      ),
    );
  }

  static Future<List<Gasto>> getGastos({bool? apenasNaoPagos}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final lista = _gastos.where((g) => apenasNaoPagos != true || !g.pago).toList();
    lista.sort((a, b) => a.prazoPagamento.compareTo(b.prazoPagamento));
    return lista;
  }

  static Future<void> registrarGasto({
    required String nome,
    required double valor,
    required String prazoPagamento,
    required String formaPagamento,
    required String categoria,
    List<Map<String, dynamic>> itens = const [],
  }) async {
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
    _gastos.add(
      Gasto(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        nome: nome,
        valor: valor,
        prazoPagamento: prazo,
        formaPagamento: forma,
        categoria: cat,
        pago: false,
        itens: itens
            .map((i) => ItemGasto(
                  nome: i['nome'] as String,
                  preco: (i['preco'] as num).toDouble(),
                ))
            .toList(),
      ),
    );
  }

  static Future<void> marcarGastoPago(String gastoId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _gastos.indexWhere((g) => g.id == gastoId);
    if (index == -1) throw Exception('Gasto não encontrado');
    _gastos[index] = Gasto(
      id: _gastos[index].id,
      nome: _gastos[index].nome,
      valor: _gastos[index].valor,
      prazoPagamento: _gastos[index].prazoPagamento,
      formaPagamento: _gastos[index].formaPagamento,
      categoria: _gastos[index].categoria,
      pago: true,
      itens: _gastos[index].itens,
    );
  }

  static Future<Map<String, dynamic>> getPerfil() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return Map<String, dynamic>.from(_perfil);
  }

  static Future<void> savePerfil({
    required double aluguel,
    required double outrosFixos,
    required double limiteGastoAlerta,
    required String telefoneWhatsApp,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _perfil['aluguel'] = aluguel;
    _perfil['outros_fixos'] = outrosFixos;
    _perfil['limite_gasto_alerta'] = limiteGastoAlerta;
    _perfil['telefone_whatsapp'] = telefoneWhatsApp;
  }

  static Future<Map<String, dynamic>> getRelatorioMensal({
    int? mes,
    int? ano,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final now = DateTime.now();
    final selectedMonth = mes ?? now.month;
    final selectedYear = ano ?? now.year;

    final atendimentosDoMes = _atendimentos.where((a) {
      return a.data.month == selectedMonth && a.data.year == selectedYear;
    }).toList();

    final gastosDoMes = _gastos.where((g) {
      return g.prazoPagamento.month == selectedMonth &&
          g.prazoPagamento.year == selectedYear;
    }).toList();

    final receitaServicos = atendimentosDoMes
        .fold(0.0, (sum, a) => sum + a.totalGanho);
    final custoMateriais = atendimentosDoMes
        .fold(0.0, (sum, a) => sum + a.totalMateriais);
    final gastosVariaveis = gastosDoMes
        .where((g) => g.categoria != CategoriaGasto.fixo)
        .fold(0.0, (sum, g) => sum + g.valor);
    final custoFixos = (_perfil['aluguel'] as double) +
        (_perfil['outros_fixos'] as double);
    final resultadoLiquido = receitaServicos - custoMateriais - gastosVariaveis - custoFixos;

    final vencimentosProximos = gastosDoMes
        .where((g) => !g.pago &&
            g.prazoPagamento.isAfter(now.subtract(const Duration(days: 1))) &&
            g.prazoPagamento.difference(now).inDays <= 7)
        .map((g) => {
              'nome': g.nome,
              'valor': g.valor,
              'prazo_pagamento': g.prazoPagamento.toIso8601String(),
            })
        .toList();

    return {
      'mes': selectedMonth,
      'ano': selectedYear,
      'total_atendimentos': atendimentosDoMes.length,
      'receita_servicos': receitaServicos,
      'custo_materiais': custoMateriais,
      'gastos_variaveis': gastosVariaveis,
      'custos_fixos': custoFixos,
      'resultado_liquido': resultadoLiquido,
      'vencimentos_proximos': vencimentosProximos,
    };
  }
}
