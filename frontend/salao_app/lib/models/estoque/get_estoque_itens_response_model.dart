import '../response_model.dart';
import 'item_estoque_model.dart';

class GetEstoqueItensResponseModel extends ResponseModel {
  static const _totalAlertasKey = 'total_alertas';
  static const _valorTotalKey = 'valor_total';
  static const _itensKey = 'itens';

  final int totalAlertas;
  final double valorTotal;
  final List<ItemEstoqueModel> itens;

  const GetEstoqueItensResponseModel({
    required super.total,
    required super.message,
    required this.totalAlertas,
    required this.valorTotal,
    required this.itens,
  });

  /// A tela separa em dois blocos — "precisam de reposição" e "estoque ok" —
  /// mas a ordenação por severidade é do app: é decisão de apresentação, não
  /// regra de negócio.
  List<ItemEstoqueModel> get emAlerta =>
      itens.where((item) => item.emAlerta && item.ativo).toList()
        ..sort((a, b) => b.status.index.compareTo(a.status.index));

  List<ItemEstoqueModel> get emOk =>
      itens.where((item) => !item.emAlerta && item.ativo).toList();

  factory GetEstoqueItensResponseModel.fromResponse(Map<String, dynamic> map) {
    final result =
        map[ResponseModel.resultKey] as Map<String, dynamic>? ?? const {};

    return GetEstoqueItensResponseModel(
      total: ResponseModel.totalFrom(map),
      message: ResponseModel.messageFrom(map),
      totalAlertas: (result[_totalAlertasKey] as num?)?.toInt() ?? 0,
      valorTotal: (result[_valorTotalKey] as num?)?.toDouble() ?? 0,
      itens: (result[_itensKey] as List? ?? const [])
          .map((e) => ItemEstoqueModel.fromResponse(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
