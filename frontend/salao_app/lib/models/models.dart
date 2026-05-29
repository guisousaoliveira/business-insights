// ── Modelos de dados ──────────────────────────────────────────────

class Servico {
  final String id;
  final String nome;
  final double preco;

  const Servico({required this.id, required this.nome, required this.preco});
}

class InsumoUsado {
  final String nome;
  final double preco;

  const InsumoUsado({required this.nome, required this.preco});
}

class Atendimento {
  final String id;
  final String nomeCliente;
  final String telefoneCliente;
  final DateTime data;
  final List<Servico> servicos;
  final List<InsumoUsado> insumos;

  const Atendimento({
    required this.id,
    required this.nomeCliente,
    required this.telefoneCliente,
    required this.data,
    required this.servicos,
    required this.insumos,
  });

  double get totalServicos =>
      servicos.fold(0, (s, e) => s + e.preco);

  double get totalInsumos =>
      insumos.fold(0, (s, e) => s + e.preco);

  double get saldo => totalServicos - totalInsumos;
}

class Gasto {
  final String id;
  final String descricao;
  final double valor;
  final DateTime prazo;
  final String formaPagamento; // 'à vista' | 'cartão'
  final String prioridade; // 'alta' | 'média' | 'baixa'
  final bool pago;

  const Gasto({
    required this.id,
    required this.descricao,
    required this.valor,
    required this.prazo,
    required this.formaPagamento,
    required this.prioridade,
    this.pago = false,
  });
}

class CustoFixo {
  final String id;
  final String descricao;
  final double valor;

  const CustoFixo({
    required this.id,
    required this.descricao,
    required this.valor,
  });
}

enum StatusEstoque { ok, alerta, critico }

enum CategoriaEstoque {
  cilios,
  sobrancelha,
  limpezaPele,
  descartavel,
  outro,
}

extension CategoriaEstoqueExt on CategoriaEstoque {
  String get label {
    switch (this) {
      case CategoriaEstoque.cilios:
        return 'Cílios';
      case CategoriaEstoque.sobrancelha:
        return 'Sobrancelha';
      case CategoriaEstoque.limpezaPele:
        return 'Limpeza de pele';
      case CategoriaEstoque.descartavel:
        return 'Descartável';
      case CategoriaEstoque.outro:
        return 'Outro';
    }
  }
}

class ItemEstoque {
  final String id;
  final String nome;
  final String unidade; // 'un.' | 'ml' | 'g' | 'cx.'
  final CategoriaEstoque categoria;
  final double quantidadeAtual;
  final double quantidadeMinima;
  final double custoUnitario;
  final bool ativo;

  const ItemEstoque({
    required this.id,
    required this.nome,
    required this.unidade,
    required this.categoria,
    required this.quantidadeAtual,
    required this.quantidadeMinima,
    required this.custoUnitario,
    this.ativo = true,
  });

  StatusEstoque get status {
    if (quantidadeAtual == 0) return StatusEstoque.critico;
    if (quantidadeAtual <= quantidadeMinima) return StatusEstoque.alerta;
    return StatusEstoque.ok;
  }

  double get deficit =>
      (quantidadeMinima - quantidadeAtual).clamp(0, double.infinity);

  bool get emAlerta => status != StatusEstoque.ok;

  ItemEstoque copyWith({
    double? quantidadeAtual,
    double? quantidadeMinima,
    double? custoUnitario,
    bool? ativo,
  }) {
    return ItemEstoque(
      id: id,
      nome: nome,
      unidade: unidade,
      categoria: categoria,
      quantidadeAtual: quantidadeAtual ?? this.quantidadeAtual,
      quantidadeMinima: quantidadeMinima ?? this.quantidadeMinima,
      custoUnitario: custoUnitario ?? this.custoUnitario,
      ativo: ativo ?? this.ativo,
    );
  }
}

enum TipoMovimentacao { entrada, saida }

class MovimentacaoEstoque {
  final String id;
  final String itemId;
  final TipoMovimentacao tipo;
  final double quantidade;
  final String motivo;
  final DateTime criadoEm;
  final String? atendimentoId;

  const MovimentacaoEstoque({
    required this.id,
    required this.itemId,
    required this.tipo,
    required this.quantidade,
    required this.motivo,
    required this.criadoEm,
    this.atendimentoId,
  });
}

// ── Dados de exemplo ───────────────────────────────────────────────

final List<Atendimento> atendimentosExemplo = [
  Atendimento(
    id: '1',
    nomeCliente: 'Ana Paula',
    telefoneCliente: '(11) 99999-0001',
    data: DateTime(2025, 5, 12),
    servicos: const [
      Servico(id: 's1', nome: 'Extensão de cílios', preco: 180),
      Servico(id: 's2', nome: 'Sobrancelha fio a fio', preco: 120),
    ],
    insumos: const [
      InsumoUsado(nome: 'Fio mink 0.07', preco: 12),
      InsumoUsado(nome: 'Cola adesiva', preco: 8),
      InsumoUsado(nome: 'Fita micropore', preco: 2),
    ],
  ),
  Atendimento(
    id: '2',
    nomeCliente: 'Carla Mendes',
    telefoneCliente: '(11) 98888-0002',
    data: DateTime(2025, 5, 10),
    servicos: const [
      Servico(id: 's3', nome: 'Limpeza de pele', preco: 150),
    ],
    insumos: const [
      InsumoUsado(nome: 'Máscara de argila', preco: 9),
      InsumoUsado(nome: 'Protetor solar descartável', preco: 4),
    ],
  ),
  Atendimento(
    id: '3',
    nomeCliente: 'Fernanda Lima',
    telefoneCliente: '(11) 97777-0003',
    data: DateTime(2025, 5, 8),
    servicos: const [
      Servico(id: 's4', nome: 'Extensão de cílios', preco: 180),
    ],
    insumos: const [
      InsumoUsado(nome: 'Fio mink 0.07', preco: 12),
      InsumoUsado(nome: 'Cola adesiva', preco: 8),
    ],
  ),
];

final List<Gasto> gastosExemplo = [
  Gasto(
    id: 'g1',
    descricao: 'Aluguel sala',
    valor: 1200,
    prazo: DateTime(2025, 5, 15),
    formaPagamento: 'à vista',
    prioridade: 'alta',
    pago: false,
  ),
  Gasto(
    id: 'g2',
    descricao: 'Fios e colas (extensão)',
    valor: 340,
    prazo: DateTime(2025, 5, 18),
    formaPagamento: 'cartão',
    prioridade: 'alta',
    pago: false,
  ),
  Gasto(
    id: 'g3',
    descricao: 'Produtos limpeza de pele',
    valor: 210,
    prazo: DateTime(2025, 5, 20),
    formaPagamento: 'cartão',
    prioridade: 'média',
    pago: true,
  ),
  Gasto(
    id: 'g4',
    descricao: 'Pinças e acessórios',
    valor: 85,
    prazo: DateTime(2025, 5, 22),
    formaPagamento: 'à vista',
    prioridade: 'baixa',
    pago: false,
  ),
];

final List<CustoFixo> custosFixosExemplo = [
  CustoFixo(id: 'cf1', descricao: 'Aluguel', valor: 1200),
  CustoFixo(id: 'cf2', descricao: 'Internet', valor: 99),
  CustoFixo(id: 'cf3', descricao: 'App de agendamento', valor: 49),
];

final List<Servico> servicosExemplo = [
  Servico(id: 'sv1', nome: 'Extensão de cílios', preco: 180),
  Servico(id: 'sv2', nome: 'Sobrancelha fio a fio', preco: 120),
  Servico(id: 'sv3', nome: 'Limpeza de pele', preco: 150),
  Servico(id: 'sv4', nome: 'Design de sobrancelha', preco: 60),
  Servico(id: 'sv5', nome: 'Manutenção de cílios', preco: 100),
];

final List<ItemEstoque> estoqueExemplo = [
  // Críticos (quantidade zero)
  const ItemEstoque(
    id: 'e1',
    nome: 'Cola adesiva para cílios',
    unidade: 'un.',
    categoria: CategoriaEstoque.cilios,
    quantidadeAtual: 0,
    quantidadeMinima: 2,
    custoUnitario: 28,
  ),

  // Em alerta (abaixo do mínimo)
  const ItemEstoque(
    id: 'e2',
    nome: 'Fio mink 0.07',
    unidade: 'un.',
    categoria: CategoriaEstoque.cilios,
    quantidadeAtual: 1,
    quantidadeMinima: 3,
    custoUnitario: 35,
  ),
  const ItemEstoque(
    id: 'e3',
    nome: 'Fita micropore',
    unidade: 'cx.',
    categoria: CategoriaEstoque.descartavel,
    quantidadeAtual: 2,
    quantidadeMinima: 5,
    custoUnitario: 8,
  ),

  // Ok
  const ItemEstoque(
    id: 'e4',
    nome: 'Máscara de argila',
    unidade: 'un.',
    categoria: CategoriaEstoque.limpezaPele,
    quantidadeAtual: 8,
    quantidadeMinima: 3,
    custoUnitario: 22,
  ),
  const ItemEstoque(
    id: 'e5',
    nome: 'Protetor solar descartável',
    unidade: 'un.',
    categoria: CategoriaEstoque.descartavel,
    quantidadeAtual: 15,
    quantidadeMinima: 10,
    custoUnitario: 5,
  ),
  const ItemEstoque(
    id: 'e6',
    nome: 'Henna para sobrancelha',
    unidade: 'g',
    categoria: CategoriaEstoque.sobrancelha,
    quantidadeAtual: 30,
    quantidadeMinima: 10,
    custoUnitario: 3,
  ),
  const ItemEstoque(
    id: 'e7',
    nome: 'Removedor de cílios',
    unidade: 'ml',
    categoria: CategoriaEstoque.cilios,
    quantidadeAtual: 45,
    quantidadeMinima: 20,
    custoUnitario: 1.5,
  ),
  const ItemEstoque(
    id: 'e8',
    nome: 'Luvas descartáveis',
    unidade: 'cx.',
    categoria: CategoriaEstoque.descartavel,
    quantidadeAtual: 3,
    quantidadeMinima: 2,
    custoUnitario: 18,
  ),
];

final List<MovimentacaoEstoque> movimentacoesExemplo = [
  MovimentacaoEstoque(
    id: 'm1',
    itemId: 'e1',
    tipo: TipoMovimentacao.saida,
    quantidade: 1,
    motivo: 'Atendimento — Ana Paula',
    criadoEm: DateTime(2025, 5, 12),
    atendimentoId: '1',
  ),
  MovimentacaoEstoque(
    id: 'm2',
    itemId: 'e2',
    tipo: TipoMovimentacao.saida,
    quantidade: 1,
    motivo: 'Atendimento — Ana Paula',
    criadoEm: DateTime(2025, 5, 12),
    atendimentoId: '1',
  ),
  MovimentacaoEstoque(
    id: 'm3',
    itemId: 'e4',
    tipo: TipoMovimentacao.entrada,
    quantidade: 10,
    motivo: 'Compra — fornecedor',
    criadoEm: DateTime(2025, 5, 10),
  ),
];
