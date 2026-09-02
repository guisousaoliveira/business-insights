import '../../settings/app_enums.dart';
import '../../settings/app_utils.dart';

/// Um item do estoque dentro de um kit — quantidade consumida quando o kit é
/// montado.
class KitItemModel {
  static const _itemEstoqueIdKey = 'item_estoque_id';
  static const _nomeKey = 'nome';
  static const _quantidadeKey = 'quantidade';
  static const _unidadeKey = 'unidade';

  final String itemEstoqueId;
  final String nome;
  final double quantidade;
  final UnidadeEstoque unidade;

  const KitItemModel({
    required this.itemEstoqueId,
    required this.nome,
    required this.quantidade,
    required this.unidade,
  });

  factory KitItemModel.fromResponse(Map<String, dynamic> map) => KitItemModel(
        itemEstoqueId: map[_itemEstoqueIdKey] as String? ?? '',
        nome: map[_nomeKey] as String? ?? '',
        quantidade: (map[_quantidadeKey] as num?)?.toDouble() ?? 0,
        unidade: AppUtils.decodeUnidadeEstoque(map[_unidadeKey] as String?),
      );

  Map<String, dynamic> get toBody => {
        _itemEstoqueIdKey: itemEstoqueId,
        _quantidadeKey: quantidade,
      };

  /// "1x Removedor", "2x Fita micropore" — como o protótipo resume o kit.
  String get resumo => '${AppUtils.quantityToString(quantidade)}x $nome';
}

class KitModel {
  static const _idKey = 'id';
  static const _nomeKey = 'nome';
  static const _precoVendaKey = 'preco_venda';
  static const _custoTotalKey = 'custo_total';
  static const _margemKey = 'margem';
  static const _quantidadeMontadaKey = 'quantidade_montada';
  static const _quantidadeMontavelKey = 'quantidade_montavel';
  static const _disponivelKey = 'disponivel';
  static const _itensKey = 'itens';

  final String id;
  final String nome;
  final double precoVenda;

  /// Custo, margem e disponibilidade vêm do servidor — dependem do custo atual
  /// de cada item do estoque, que o app não acompanha.
  final double custoTotal;
  final double margem;

  /// Kits prontos na prateleira. É o saldo do kit, separado do saldo dos
  /// insumos: ela monta cinco numa tarde e vende ao longo das semanas.
  final double quantidadeMontada;

  /// Quantos ainda dá para montar com o estoque de hoje — `min(saldo do item ÷
  /// quantidade do item)` sobre a composição. Quem calcula é o servidor.
  final double quantidadeMontavel;

  final bool disponivel;
  final List<KitItemModel> itens;

  const KitModel({
    required this.id,
    required this.nome,
    required this.precoVenda,
    required this.custoTotal,
    required this.margem,
    required this.quantidadeMontada,
    required this.quantidadeMontavel,
    required this.disponivel,
    required this.itens,
  });

  String get resumoItens => itens.map((e) => e.resumo).join(', ');

  /// Só dá para vender o que está montado.
  bool get podeVender => quantidadeMontada > 0;

  /// Só dá para montar se o estoque cobre pelo menos um — mas o botão continua
  /// disponível, porque ela pode confirmar a montagem com saldo negativo.
  bool get podeMontar => quantidadeMontavel > 0;

  factory KitModel.fromResponse(Map<String, dynamic> map) => KitModel(
        id: map[_idKey] as String? ?? '',
        nome: map[_nomeKey] as String? ?? '',
        precoVenda: (map[_precoVendaKey] as num?)?.toDouble() ?? 0,
        custoTotal: (map[_custoTotalKey] as num?)?.toDouble() ?? 0,
        margem: (map[_margemKey] as num?)?.toDouble() ?? 0,
        quantidadeMontada:
            (map[_quantidadeMontadaKey] as num?)?.toDouble() ?? 0,
        quantidadeMontavel:
            (map[_quantidadeMontavelKey] as num?)?.toDouble() ?? 0,
        disponivel: map[_disponivelKey] as bool? ?? false,
        itens: (map[_itensKey] as List? ?? const [])
            .map((e) => KitItemModel.fromResponse(e as Map<String, dynamic>))
            .toList(),
      );
}
