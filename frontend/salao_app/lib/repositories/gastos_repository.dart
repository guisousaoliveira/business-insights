import '../models/gastos/create_gasto_request_model.dart';
import '../models/gastos/get_gastos_response_model.dart';
import '../settings/app_api.dart';

abstract interface class GastosRepository {
  Future<GetGastosResponseModel> getGastos(
      {required int ano, required int mes});
  Future<void> createGasto(CreateGastoRequestModel model);
  Future<void> pagarGasto(String id);
  Future<void> deleteGasto(String id);
}

class GastosRepositoryImpl implements GastosRepository {
  const GastosRepositoryImpl();

  @override
  Future<GetGastosResponseModel> getGastos({
    required int ano,
    required int mes,
  }) async {
    final response = await AppApi.get(
      AppApi.getGastosPath,
      queryParameters: {'ano': ano, 'mes': mes},
    );
    return GetGastosResponseModel.fromResponse(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<void> createGasto(CreateGastoRequestModel model) async {
    await AppApi.post(AppApi.postGastoPath, data: model.toBody);
  }

  @override
  Future<void> pagarGasto(String id) async {
    await AppApi.patch('${AppApi.payGastoPath}/$id/pagar');
  }

  @override
  Future<void> deleteGasto(String id) async {
    await AppApi.delete('${AppApi.deleteGastoPath}/$id');
  }
}
