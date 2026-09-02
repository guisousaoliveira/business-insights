import '../response_model.dart';
import 'alerta_model.dart';

class GetAlertasResponseModel extends ResponseModel {
  static const _totalNaoLidosKey = 'total_nao_lidos';
  static const _resumoKey = 'resumo';
  static const _criticoKey = 'critico';
  static const _alertaKey = 'alerta';
  static const _alertasKey = 'alertas';

  final int totalNaoLidos;

  /// O número do badge: crítico + alerta. Vem do servidor porque a mesma regra
  /// alimenta o push e o n8n (S7) — o app não recalcula.
  final int totalCritico;
  final int totalAlerta;
  final List<AlertaModel> alertas;

  const GetAlertasResponseModel({
    required super.total,
    required super.message,
    required this.totalNaoLidos,
    required this.totalCritico,
    required this.totalAlerta,
    required this.alertas,
  });

  int get badgeCount => totalCritico + totalAlerta;

  factory GetAlertasResponseModel.fromResponse(Map<String, dynamic> map) {
    final result =
        map[ResponseModel.resultKey] as Map<String, dynamic>? ?? const {};
    final resumo = result[_resumoKey] as Map<String, dynamic>? ?? const {};

    return GetAlertasResponseModel(
      total: ResponseModel.totalFrom(map),
      message: ResponseModel.messageFrom(map),
      totalNaoLidos: (result[_totalNaoLidosKey] as num?)?.toInt() ?? 0,
      totalCritico: (resumo[_criticoKey] as num?)?.toInt() ?? 0,
      totalAlerta: (resumo[_alertaKey] as num?)?.toInt() ?? 0,
      alertas: (result[_alertasKey] as List? ?? const [])
          .map((e) => AlertaModel.fromResponse(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory GetAlertasResponseModel.empty() => const GetAlertasResponseModel(
        total: 0,
        message: '',
        totalNaoLidos: 0,
        totalCritico: 0,
        totalAlerta: 0,
        alertas: [],
      );
}
