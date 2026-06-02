// ─────────────────────────────────────────────────────────────────────────────
// models/atendimento.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:intl/intl.dart';

enum StatusAtendimento { agendado, finalizado, cancelado }

class Atendimento {
  final String id;
  final String clienteNome;
  final String clienteTelefone;
  final DateTime data;
  final List<ServicoAtendimento> servicos;
  final List<MaterialAtendimento> materiais;
  final StatusAtendimento status; // NOVO CAMPO

  const Atendimento({
    required this.id,
    required this.clienteNome,
    required this.clienteTelefone,
    required this.data,
    required this.servicos,
    required this.materiais,
    this.status = StatusAtendimento.finalizado, // Padrão para manter compatibilidade
  });

  bool get isAgendado => status == StatusAtendimento.agendado;
  bool get isFinalizado => status == StatusAtendimento.finalizado;
  bool get isCancelado => status == StatusAtendimento.cancelado;

  // Se estiver cancelado, não contabiliza lucro nem gasto
  double get totalGanho => isCancelado ? 0.0 : servicos.fold(0.0, (a, s) => a + s.preco);
  double get totalMateriais => isCancelado ? 0.0 : materiais.fold(0.0, (a, m) => a + m.preco);
  double get lucroBruto => totalGanho - totalMateriais;
  String get dataFormatada => DateFormat('dd/MM', 'pt_BR').format(data);

  factory Atendimento.fromJson(Map<String, dynamic> j) => Atendimento(
        id: j['id'] as String,
        clienteNome: j['cliente_nome'] as String,
        clienteTelefone: j['cliente_telefone'] as String,
        data: DateTime.parse(j['data'] as String),
        status: StatusAtendimento.values.firstWhere((e) => e.name == (j['status'] ?? 'finalizado'), orElse: () => StatusAtendimento.finalizado),
        servicos: (j['servicos'] as List<dynamic>?)?.map((s) => ServicoAtendimento.fromJson(s)).toList() ?? [],
        materiais: (j['materiais'] as List<dynamic>?)?.map((m) => MaterialAtendimento.fromJson(m)).toList() ?? [],
      );

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'cliente_nome': clienteNome,
        'cliente_telefone': clienteTelefone,
        'data': data.toIso8601String(),
        'status': status.name,
        'servicos': servicos.map((s) => s.toJson()).toList(),
        'materiais': materiais.map((m) => m.toJson()).toList(),
      };

  Atendimento copyWith({
    String? id,
    String? clienteNome,
    String? clienteTelefone,
    DateTime? data,
    List<ServicoAtendimento>? servicos,
    List<MaterialAtendimento>? materiais,
    StatusAtendimento? status,
  }) {
    return Atendimento(
      id: id ?? this.id,
      clienteNome: clienteNome ?? this.clienteNome,
      clienteTelefone: clienteTelefone ?? this.clienteTelefone,
      data: data ?? this.data,
      servicos: servicos ?? this.servicos,
      materiais: materiais ?? this.materiais,
      status: status ?? this.status,
    );
  }
}

class ServicoAtendimento {
  final String nome;
  final double preco;
  const ServicoAtendimento({required this.nome, required this.preco});
  factory ServicoAtendimento.fromJson(Map<String, dynamic> j) => ServicoAtendimento(nome: j['nome'] as String, preco: (j['preco'] as num).toDouble());
  Map<String, dynamic> toJson() => {'nome': nome, 'preco': preco};
}

class MaterialAtendimento {
  final String nome;
  final double preco;
  const MaterialAtendimento({required this.nome, required this.preco});
  factory MaterialAtendimento.fromJson(Map<String, dynamic> j) => MaterialAtendimento(nome: j['nome'] as String, preco: (j['preco'] as num).toDouble());
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
  bool get venceEm3Dias => prazoPagamento.difference(DateTime.now()).inDays <= 3 && !pago;

  factory Gasto.fromJson(Map<String, dynamic> j) => Gasto(
        id: j['id'] as String,
        nome: j['nome'] as String,
        valor: (j['valor'] as num).toDouble(),
        prazoPagamento: DateTime.parse(j['prazo_pagamento'] as String),
        formaPagamento: FormaPagamento.values.firstWhere(
          (e) => e.name == j['forma_pagamento'],
          orElse: () => FormaPagamento.pix,
        ),
        categoria: CategoriaGasto.values.firstWhere(
          (e) => e.name == j['categoria'],
          orElse: () => CategoriaGasto.outros,
        ),
        pago: j['pago'] as bool? ?? false,
        itens: (j['itens_gasto'] as List? ?? []).map((i) => ItemGasto.fromJson(i as Map<String, dynamic>)).toList(),
      );
}

class ItemGasto {
  final String nome;
  final double preco;
  const ItemGasto({required this.nome, required this.preco});

  factory ItemGasto.fromJson(Map<String, dynamic> j) => ItemGasto(
        nome: j['nome'] as String,
        preco: (j['preco'] as num).toDouble(),
      );
}

// ── Relatório mensal (retornado pelo FastAPI /relatorio/mensal) ───────────────

class RelatorioMensal {
  final int mes, ano, totalAtendimentos;
  final double receitaServicos, custoMateriais, gastosVariaveis, custoFixos, resultadoLiquido;
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
        mes: j['mes'] as int,
        ano: j['ano'] as int,
        totalAtendimentos: j['total_atendimentos'] as int,
        receitaServicos: (j['receita_servicos'] as num).toDouble(),
        custoMateriais: (j['custo_materiais'] as num).toDouble(),
        gastosVariaveis: (j['gastos_variaveis'] as num).toDouble(),
        custoFixos: (j['custos_fixos'] as num).toDouble(),
        resultadoLiquido: (j['resultado_liquido'] as num).toDouble(),
        vencimentosProximos: List<Map<String, dynamic>>.from(
          j['vencimentos_proximos'] ?? [],
        ),
      );
}
