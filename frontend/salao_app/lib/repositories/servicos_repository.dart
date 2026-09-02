import '../models/servicos/servico_model.dart';
import '../settings/app_api.dart';

abstract interface class ServicosRepository {
  Future<GetServicosResponseModel> getServicos();
  Future<void> createServico(ServicoModel model);
  Future<void> deleteServico(String id);
}

class ServicosRepositoryImpl implements ServicosRepository {
  const ServicosRepositoryImpl();

  @override
  Future<GetServicosResponseModel> getServicos() async {
    final response = await AppApi.get(AppApi.getServicosPath);
    return GetServicosResponseModel.fromResponse(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<void> createServico(ServicoModel model) async {
    await AppApi.post(AppApi.postServicoPath, data: model.toBody);
  }

  @override
  Future<void> deleteServico(String id) async {
    await AppApi.delete('${AppApi.deleteServicoPath}/$id');
  }
}
