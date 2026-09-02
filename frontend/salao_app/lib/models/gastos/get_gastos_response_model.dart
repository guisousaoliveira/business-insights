import '../response_model.dart';
import 'gasto_model.dart';

class GetGastosResponseModel extends ResponseModel {
  static const _totalPendenteKey = 'total_pendente';
  static const _totalPagoMesKey = 'total_pago_mes';
  static const _gastosKey = 'gastos';

  final double totalPendente;
  final double totalPagoMes;
  final List<GastoModel> gastos;

  const GetGastosResponseModel({
    required super.total,
    required super.message,
    required this.totalPendente,
    required this.totalPagoMes,
    required this.gastos,
  });

  List<GastoModel> get pendentes => gastos.where((g) => !g.pago).toList();
  List<GastoModel> get pagos => gastos.where((g) => g.pago).toList();

  factory GetGastosResponseModel.fromResponse(Map<String, dynamic> map) {
    final result =
        map[ResponseModel.resultKey] as Map<String, dynamic>? ?? const {};

    return GetGastosResponseModel(
      total: ResponseModel.totalFrom(map),
      message: ResponseModel.messageFrom(map),
      totalPendente: (result[_totalPendenteKey] as num?)?.toDouble() ?? 0,
      totalPagoMes: (result[_totalPagoMesKey] as num?)?.toDouble() ?? 0,
      gastos: (result[_gastosKey] as List? ?? const [])
          .map((e) => GastoModel.fromResponse(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
