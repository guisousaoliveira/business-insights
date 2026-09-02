import '../../settings/app_enums.dart';
import '../../settings/app_utils.dart';

class ItemEstoqueModel {
  static const _idKey = 'id';
  static const _nomeKey = 'nome';
  static const _unidadeKey = 'unidade';
  static const _categoriaKey = 'categoria';
  static const _quantidadeAtualKey = 'quantidade_atual';
  static const _quantidadeMinimaKey = 'quantidade_minima';
  static const _custoMedioKey = 'custo_medio';
  static const _custoUltimaCompraKey = 'custo_ultima_compra';
  static const _statusKey = 'status';
  static const _deficitKey = 'deficit';
  static const _ativoKey = 'ativo';

  final String id;
  final String nome;
  final UnidadeEstoque unidade;
  final CategoriaEstoque categoria;
  final double quantidadeAtual;
  final double quantidadeMinima;

  /// Média ponderada móvel, calculada no servidor a cada entrada (§5 de
  /// `endpoints-backend.md`). É este o custo usado em margem de kit, custo de
  /// atendimento e valor total do estoque.
  final double custoMedio;

  /// Quanto ela pagou na última compra. Informativo — não entra em conta
  /// nenhuma, existe para ela reconhecer o preço.
  final double custoUltimaCompra;

  /// [status] e [deficit] vêm **do servidor** (S7). O app não recalcula
  /// `quantidade <= minima`: a mesma regra alimenta o push e o n8n, e duplicar
  /// o cálculo garante que um dia as versões discordem.
  final StatusEstoque status;
  final double deficit;
  final bool ativo;

  const ItemEstoqueModel({
    required this.id,
    required this.nome,
    required this.unidade,
    required this.categoria,
    required this.quantidadeAtual,
    required this.quantidadeMinima,
    required this.custoMedio,
    this.custoUltimaCompra = 0,
    required this.status,
    required this.deficit,
    required this.ativo,
  });

  bool get emAlerta => status != StatusEstoque.ok;

  String get unidadeLabel => AppUtils.unidadeEstoqueToString(unidade);

  factory ItemEstoqueModel.fromResponse(Map<String, dynamic> map) =>
      ItemEstoqueModel(
        id: map[_idKey] as String? ?? '',
        nome: map[_nomeKey] as String? ?? '',
        unidade: AppUtils.decodeUnidadeEstoque(map[_unidadeKey] as String?),
        categoria:
            AppUtils.decodeCategoriaEstoque(map[_categoriaKey] as String?),
        quantidadeAtual: (map[_quantidadeAtualKey] as num?)?.toDouble() ?? 0,
        quantidadeMinima: (map[_quantidadeMinimaKey] as num?)?.toDouble() ?? 0,
        custoMedio: (map[_custoMedioKey] as num?)?.toDouble() ?? 0,
        custoUltimaCompra:
            (map[_custoUltimaCompraKey] as num?)?.toDouble() ?? 0,
        status: AppUtils.decodeStatusEstoque(map[_statusKey] as String?),
        deficit: (map[_deficitKey] as num?)?.toDouble() ?? 0,
        ativo: map[_ativoKey] as bool? ?? true,
      );
}
