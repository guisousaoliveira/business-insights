import '../response_model.dart';

class CustoFixoModel {
  static const _idKey = 'id';
  static const _descricaoKey = 'descricao';
  static const _valorKey = 'valor';

  final String id;
  final String descricao;
  final double valor;

  const CustoFixoModel({
    required this.id,
    required this.descricao,
    required this.valor,
  });

  factory CustoFixoModel.fromResponse(Map<String, dynamic> map) =>
      CustoFixoModel(
        id: map[_idKey] as String? ?? '',
        descricao: map[_descricaoKey] as String? ?? '',
        valor: (map[_valorKey] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> get toBody => {
        _descricaoKey: descricao,
        _valorKey: valor,
      };
}

class GetCustosFixosResponseModel extends ResponseModel {
  static const _totalMensalKey = 'total_mensal';
  static const _custosKey = 'custos';

  final double totalMensal;
  final List<CustoFixoModel> custos;

  const GetCustosFixosResponseModel({
    required super.total,
    required super.message,
    required this.totalMensal,
    required this.custos,
  });

  factory GetCustosFixosResponseModel.fromResponse(Map<String, dynamic> map) {
    final result =
        map[ResponseModel.resultKey] as Map<String, dynamic>? ?? const {};

    return GetCustosFixosResponseModel(
      total: ResponseModel.totalFrom(map),
      message: ResponseModel.messageFrom(map),
      totalMensal: (result[_totalMensalKey] as num?)?.toDouble() ?? 0,
      custos: (result[_custosKey] as List? ?? const [])
          .map((e) => CustoFixoModel.fromResponse(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
