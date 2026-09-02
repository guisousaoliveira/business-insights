import '../../settings/app_enums.dart';
import '../../settings/app_utils.dart';

/// Um item sem saldo suficiente, como o servidor devolve em
/// `result.faltantes` quando recusa com `ESTOQUE_INSUFICIENTE`.
///
/// É o que o aviso mostra antes de perguntar se ela quer finalizar mesmo
/// assim (§2 de `endpoints-backend.md`). Sem esta lista o aviso seria só um
/// "faltou material" — sem dizer qual, ela não tem como decidir.
class EstoqueFaltanteModel {
  static const _itemEstoqueIdKey = 'item_estoque_id';
  static const _nomeKey = 'nome';
  static const _unidadeKey = 'unidade';
  static const _quantidadeSolicitadaKey = 'quantidade_solicitada';
  static const _quantidadeDisponivelKey = 'quantidade_disponivel';
  static const _deficitKey = 'deficit';

  /// Chave do `result` do envelope de erro que carrega a lista.
  static const faltantesKey = 'faltantes';

  final String itemEstoqueId;
  final String nome;
  final UnidadeEstoque unidade;
  final double quantidadeSolicitada;
  final double quantidadeDisponivel;
  final double deficit;

  const EstoqueFaltanteModel({
    required this.itemEstoqueId,
    required this.nome,
    required this.unidade,
    required this.quantidadeSolicitada,
    required this.quantidadeDisponivel,
    required this.deficit,
  });

  factory EstoqueFaltanteModel.fromResponse(Map<String, dynamic> map) =>
      EstoqueFaltanteModel(
        itemEstoqueId: map[_itemEstoqueIdKey] as String? ?? '',
        nome: map[_nomeKey] as String? ?? '',
        unidade: AppUtils.decodeUnidadeEstoque(map[_unidadeKey] as String?),
        quantidadeSolicitada:
            (map[_quantidadeSolicitadaKey] as num?)?.toDouble() ?? 0,
        quantidadeDisponivel:
            (map[_quantidadeDisponivelKey] as num?)?.toDouble() ?? 0,
        deficit: (map[_deficitKey] as num?)?.toDouble() ?? 0,
      );

  /// Extrai a lista do `result` cru de um [ErrorModel]. Devolve vazia quando o
  /// formato não bate — o aviso ainda aparece, só sem o detalhamento, o que é
  /// melhor do que estourar em cima de um erro.
  static List<EstoqueFaltanteModel> listFrom(Object? result) {
    if (result is! Map) return const [];

    final faltantes = result[faltantesKey];
    if (faltantes is! List) return const [];

    return faltantes
        .whereType<Map<String, dynamic>>()
        .map(EstoqueFaltanteModel.fromResponse)
        .toList();
  }

  /// "pedi 2 un., tenho 0 un." — o par que ela precisa ver junto.
  String get resumo =>
      '${AppUtils.quantityToString(quantidadeSolicitada)} '
      '${AppUtils.unidadeEstoqueToString(unidade)} · '
      '${AppUtils.quantityToString(quantidadeDisponivel)} '
      '${AppUtils.unidadeEstoqueToString(unidade)}';
}
