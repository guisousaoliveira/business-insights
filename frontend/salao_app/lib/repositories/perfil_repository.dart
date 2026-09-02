import '../models/perfil/custo_fixo_model.dart';
import '../models/perfil/perfil_model.dart';
import '../settings/app_api.dart';

abstract interface class PerfilRepository {
  Future<GetPerfilResponseModel> getPerfil();
  Future<void> updatePerfil(PerfilModel model);
  Future<GetCustosFixosResponseModel> getCustosFixos();
  Future<void> createCustoFixo(CustoFixoModel model);
  Future<void> editCustoFixo(CustoFixoModel model);
  Future<void> deleteCustoFixo(String id);

  /// Marca (ou desmarca) o pagamento de **uma competência** do custo fixo.
  /// O cadastro é o mesmo todo mês; o que muda de estado é a ocorrência.
  Future<void> pagarCustoFixo({
    required String id,
    required String competencia,
    required bool pago,
  });
}

class PerfilRepositoryImpl implements PerfilRepository {
  const PerfilRepositoryImpl();

  @override
  Future<GetPerfilResponseModel> getPerfil() async {
    final response = await AppApi.get(AppApi.getPerfilPath);
    return GetPerfilResponseModel.fromResponse(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<void> updatePerfil(PerfilModel model) async {
    await AppApi.put(AppApi.editPerfilPath, data: model.toBody);
  }

  @override
  Future<GetCustosFixosResponseModel> getCustosFixos() async {
    final response = await AppApi.get(AppApi.getCustosFixosPath);
    return GetCustosFixosResponseModel.fromResponse(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<void> createCustoFixo(CustoFixoModel model) async {
    await AppApi.post(AppApi.postCustoFixoPath, data: model.toBody);
  }

  @override
  Future<void> editCustoFixo(CustoFixoModel model) async {
    await AppApi.patch('${AppApi.editCustoFixoPath}/${model.id}',
        data: model.toBody);
  }

  @override
  Future<void> deleteCustoFixo(String id) async {
    await AppApi.delete('${AppApi.deleteCustoFixoPath}/$id');
  }

  @override
  Future<void> pagarCustoFixo({
    required String id,
    required String competencia,
    required bool pago,
  }) async {
    await AppApi.patch(
      '${AppApi.payCustoFixoPath}/$id/pagar',
      data: {'competencia': competencia, 'pago': pago},
    );
  }
}
