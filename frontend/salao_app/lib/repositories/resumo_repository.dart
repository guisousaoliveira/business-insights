import '../models/resumo/get_resumo_mensal_response_model.dart';
import '../settings/app_api.dart';

abstract interface class ResumoRepository {
  Future<GetResumoMensalResponseModel> getResumoMensal({
    required int ano,
    required int mes,
  });
}

class ResumoRepositoryImpl implements ResumoRepository {
  const ResumoRepositoryImpl();

  @override
  Future<GetResumoMensalResponseModel> getResumoMensal({
    required int ano,
    required int mes,
  }) async {
    final response = await AppApi.get(
      AppApi.getResumoMensalPath,
      queryParameters: {'ano': ano, 'mes': mes},
    );
    return GetResumoMensalResponseModel.fromResponse(
      response.data as Map<String, dynamic>,
    );
  }
}
