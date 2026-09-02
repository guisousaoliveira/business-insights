import '../response_model.dart';
import 'atendimento_model.dart';

class GetAtendimentosResponseModel extends ResponseModel {
  static const _saldoLiquidoKey = 'saldo_liquido';
  static const _quantidadeKey = 'quantidade';
  static const _atendimentosKey = 'atendimentos';

  /// O cabeçalho verde da tela precisa do agregado; ele vem junto da lista para
  /// não custar uma segunda requisição.
  final double saldoLiquido;
  final int quantidade;
  final List<AtendimentoModel> atendimentos;

  const GetAtendimentosResponseModel({
    required super.total,
    required super.message,
    required this.saldoLiquido,
    required this.quantidade,
    required this.atendimentos,
  });

  factory GetAtendimentosResponseModel.fromResponse(Map<String, dynamic> map) {
    final result =
        map[ResponseModel.resultKey] as Map<String, dynamic>? ?? const {};

    return GetAtendimentosResponseModel(
      total: ResponseModel.totalFrom(map),
      message: ResponseModel.messageFrom(map),
      saldoLiquido: (result[_saldoLiquidoKey] as num?)?.toDouble() ?? 0,
      quantidade: (result[_quantidadeKey] as num?)?.toInt() ?? 0,
      atendimentos: (result[_atendimentosKey] as List? ?? const [])
          .map((e) => AtendimentoModel.fromResponse(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
