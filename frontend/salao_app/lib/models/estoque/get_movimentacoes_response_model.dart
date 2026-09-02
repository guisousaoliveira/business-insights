import '../response_model.dart';
import 'movimentacao_model.dart';

class GetMovimentacoesResponseModel extends ResponseModel {
  static const _movimentacoesKey = 'movimentacoes';

  final List<MovimentacaoModel> movimentacoes;

  const GetMovimentacoesResponseModel({
    required super.total,
    required super.message,
    required this.movimentacoes,
  });

  factory GetMovimentacoesResponseModel.fromResponse(
    Map<String, dynamic> map,
  ) {
    final result =
        map[ResponseModel.resultKey] as Map<String, dynamic>? ?? const {};

    return GetMovimentacoesResponseModel(
      total: ResponseModel.totalFrom(map),
      message: ResponseModel.messageFrom(map),
      movimentacoes: (result[_movimentacoesKey] as List? ?? const [])
          .map((e) => MovimentacaoModel.fromResponse(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
