// ─────────────────────────────────────────────────────────────────────────────
// models/atendimento.dart — Modelos de domínio
//
// Cada classe tem:
//   fromJson() — desserializa resposta do Supabase/FastAPI
//   toJson()   — serializa para envio ao FastAPI
//   getters    — cálculos derivados usados diretamente na UI
// ─────────────────────────────────────────────────────────────────────────────

import 'package:intl/intl.dart';

// ── Atendimento ───────────────────────────────────────────────────────────────

class Atendimento {
  final String id;
  final String clienteNome;
  final String clienteTelefone;
  final DateTime data;
  final List<ServicoAtendimento> servicos;
  final List<MaterialAtendimento> materiais;

  const Atendimento({
    required this.id,
    required this.clienteNome,
    required this.clienteTelefone,
    required this.data,
    required this.servicos,
    required this.materiais,
  });

  // Getters computados — a UI usa diretamente, sem lógica extra nas telas
  double get totalGanho     => servicos.fold(0.0, (a, s) => a + s.preco);
  double get totalMateriais => materiais.fold(0.0, (a, m) => a + m.preco);
  double get lucroBruto     => totalGanho - totalMateriais;
  String get dataFormatada  => DateFormat('dd/MM', 'pt_BR').format(data);

  factory Atendimento.fromJson(Map<String, dynamic> json) => Atendimento(
    id:              json['id'] as String,
    clienteNome:     json['cliente_nome'] as String,
    clienteTelefone: json['cliente_telefone'] as String? ?? '',
    data:            DateTime.parse(json['data'] as String),
    // Supabase retorna filhos via select com join aninhado (uma única query)
    servicos: (json['servicos_atendimento'] as List? ?? [])
        .map((s) => ServicoAtendimento.fromJson(s as Map<String, dynamic>))
        .toList(),
    materiais: (json['materiais_atendimento'] as List? ?? [])
        .map((m) => MaterialAtendimento.fromJson(m as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'cliente_nome':     clienteNome,
    'cliente_telefone': clienteTelefone,
    'data':             data.toIso8601String(),
    'servicos':  servicos.map((s) => s.toJson()).toList(),
    'materiais': materiais.map((m) => m.toJson()).toList(),
  };
}

class ServicoAtendimento {
  final String nome;
  final double preco;
  const ServicoAtendimento({required this.nome, required this.preco});

  factory ServicoAtendimento.fromJson(Map<String, dynamic> j) =>
      ServicoAtendimento(
        nome:  j['nome'] as String,
        preco: (j['preco'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'nome': nome, 'preco': preco};
}

// Somente materiais com custo por sessão (fios, adesivo, dose de henna).
// Materiais reutilizáveis (pinças, camas) ficam nos custos fixos do perfil.
class MaterialAtendimento {
  final String nome;
  final double preco;
  const MaterialAtendimento({required this.nome, required this.preco});

  factory MaterialAtendimento.fromJson(Map<String, dynamic> j) =>
      MaterialAtendimento(
        nome:  j['nome'] as String,
        preco: (j['preco'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'nome': nome, 'preco': preco};
}

// ── Gasto ─────────────────────────────────────────────────────────────────────

enum FormaPagamento { avista, credito, debito, pix }
enum CategoriaGasto { material, fixo, outros }

class Gasto {
  final String id;
  final String nome;
  final double valor;
  final DateTime prazoPagamento;
  final FormaPagamento formaPagamento;
  final CategoriaGasto categoria;
  final bool pago;
  final List<ItemGasto> itens;

  const Gasto({
    required this.id,
    required this.nome,
    required this.valor,
    required this.prazoPagamento,
    required this.formaPagamento,
    required this.categoria,
    required this.pago,
    required this.itens,
  });

  String get prazoFormatado => DateFormat('dd/MM', 'pt_BR').format(prazoPagamento);

  // Urgente = vence em ≤ 3 dias e ainda não pago
  bool get venceEm3Dias =>
      prazoPagamento.difference(DateTime.now()).inDays <= 3 && !pago;

  factory Gasto.fromJson(Map<String, dynamic> j) => Gasto(
    id:             j['id'] as String,
    nome:           j['nome'] as String,
    valor:          (j['valor'] as num).toDouble(),
    prazoPagamento: DateTime.parse(j['prazo_pagamento'] as String),
    formaPagamento: FormaPagamento.values.firstWhere(
      (e) => e.name == j['forma_pagamento'],
      orElse: () => FormaPagamento.pix,
    ),
    categoria: CategoriaGasto.values.firstWhere(
      (e) => e.name == j['categoria'],
      orElse: () => CategoriaGasto.outros,
    ),
    pago:  j['pago'] as bool? ?? false,
    itens: (j['itens_gasto'] as List? ?? [])
        .map((i) => ItemGasto.fromJson(i as Map<String, dynamic>))
        .toList(),
  );
}

class ItemGasto {
  final String nome;
  final double preco;
  const ItemGasto({required this.nome, required this.preco});

  factory ItemGasto.fromJson(Map<String, dynamic> j) =>
      ItemGasto(
        nome:  j['nome'] as String,
        preco: (j['preco'] as num).toDouble(),
      );
}

// ── Relatório mensal (retornado pelo FastAPI /relatorio/mensal) ───────────────

class RelatorioMensal {
  final int mes, ano, totalAtendimentos;
  final double receitaServicos, custoMateriais, gastosVariaveis,
      custoFixos, resultadoLiquido;
  final List<Map<String, dynamic>> vencimentosProximos;

  const RelatorioMensal({
    required this.mes,
    required this.ano,
    required this.totalAtendimentos,
    required this.receitaServicos,
    required this.custoMateriais,
    required this.gastosVariaveis,
    required this.custoFixos,
    required this.resultadoLiquido,
    required this.vencimentosProximos,
  });

  bool get isPositivo => resultadoLiquido >= 0;

  factory RelatorioMensal.fromJson(Map<String, dynamic> j) => RelatorioMensal(
    mes:               j['mes'] as int,
    ano:               j['ano'] as int,
    totalAtendimentos: j['total_atendimentos'] as int,
    receitaServicos:   (j['receita_servicos']  as num).toDouble(),
    custoMateriais:    (j['custo_materiais']   as num).toDouble(),
    gastosVariaveis:   (j['gastos_variaveis']  as num).toDouble(),
    custoFixos:        (j['custos_fixos']      as num).toDouble(),
    resultadoLiquido:  (j['resultado_liquido'] as num).toDouble(),
    vencimentosProximos: List<Map<String, dynamic>>.from(
      j['vencimentos_proximos'] ?? [],
    ),
  );
}
