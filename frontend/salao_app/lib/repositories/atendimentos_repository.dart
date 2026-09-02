import '../models/atendimentos/create_atendimento_request_model.dart';
import '../models/atendimentos/finalizar_atendimento_request_model.dart';
import '../models/atendimentos/get_atendimentos_response_model.dart';
import '../settings/app_api.dart';
import '../settings/app_utils.dart';

abstract interface class AtendimentosRepository {
  Future<GetAtendimentosResponseModel> getAtendimentos({
    required DateTime inicio,
    required DateTime fim,
  });
  Future<void> createAtendimento(CreateAtendimentoRequestModel model);
  Future<void> finalizarAtendimento(FinalizarAtendimentoRequestModel model);
  Future<void> cancelarAtendimento(String id);
}

class AtendimentosRepositoryImpl implements AtendimentosRepository {
  const AtendimentosRepositoryImpl();

  @override
  Future<GetAtendimentosResponseModel> getAtendimentos({
    required DateTime inicio,
    required DateTime fim,
  }) async {
    final response = await AppApi.get(
      AppApi.getAtendimentosPath,
      queryParameters: {
        'inicio': AppUtils.dateToApi(inicio),
        'fim': AppUtils.dateToApi(fim),
      },
    );
    return GetAtendimentosResponseModel.fromResponse(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<void> createAtendimento(CreateAtendimentoRequestModel model) async {
    await AppApi.post(AppApi.postAtendimentoPath, data: model.toBody);
  }

  @override
  Future<void> finalizarAtendimento(
    FinalizarAtendimentoRequestModel model,
  ) async {
    await AppApi.patch(
      '${AppApi.finalizeAtendimentoPath}/${model.id}/finalizar',
      data: model.toBody,
    );
  }

  @override
  Future<void> cancelarAtendimento(String id) async {
    await AppApi.patch('${AppApi.cancelAtendimentoPath}/$id/cancelar');
  }
}
