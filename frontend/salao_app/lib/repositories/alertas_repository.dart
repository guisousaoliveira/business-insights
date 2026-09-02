import '../models/alertas/get_alertas_response_model.dart';
import '../settings/app_api.dart';

abstract interface class AlertasRepository {
  Future<GetAlertasResponseModel> getAlertas({bool? apenasNaoLidos});
  Future<void> marcarLido(String id);
  Future<void> marcarTodosLidos();
}

class AlertasRepositoryImpl implements AlertasRepository {
  const AlertasRepositoryImpl();

  @override
  Future<GetAlertasResponseModel> getAlertas({bool? apenasNaoLidos}) async {
    final response = await AppApi.get(
      AppApi.getAlertasPath,
      queryParameters: {
        if (apenasNaoLidos != null) 'apenas_nao_lidos': apenasNaoLidos,
      },
    );
    return GetAlertasResponseModel.fromResponse(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<void> marcarLido(String id) async {
    await AppApi.patch('${AppApi.readAlertaPath}/$id/lido');
  }

  @override
  Future<void> marcarTodosLidos() async {
    await AppApi.patch(AppApi.readAllAlertasPath);
  }
}
