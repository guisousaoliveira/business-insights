import '../models/estoque/create_estoque_item_request_model.dart';
import '../models/estoque/create_movimentacao_request_model.dart';
import '../models/estoque/get_estoque_itens_response_model.dart';
import '../models/estoque/get_movimentacoes_response_model.dart';
import '../settings/app_api.dart';

abstract interface class EstoqueRepository {
  Future<GetEstoqueItensResponseModel> getItens();
  Future<void> createItem(CreateEstoqueItemRequestModel model);
  Future<void> deleteItem(String id);
  Future<void> createMovimentacao(CreateMovimentacaoRequestModel model);
  Future<GetMovimentacoesResponseModel> getMovimentacoes({String? itemId});
}

class EstoqueRepositoryImpl implements EstoqueRepository {
  const EstoqueRepositoryImpl();

  @override
  Future<GetEstoqueItensResponseModel> getItens() async {
    final response = await AppApi.get(AppApi.getEstoqueItensPath);
    return GetEstoqueItensResponseModel.fromResponse(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<void> createItem(CreateEstoqueItemRequestModel model) async {
    await AppApi.post(AppApi.postEstoqueItemPath, data: model.toBody);
  }

  @override
  Future<void> deleteItem(String id) async {
    await AppApi.delete('${AppApi.deleteEstoqueItemPath}/$id');
  }

  @override
  Future<void> createMovimentacao(CreateMovimentacaoRequestModel model) async {
    await AppApi.post(
      '${AppApi.postMovimentacaoPath}/${model.itemId}/movimentacoes',
      data: model.toBody,
    );
  }

  @override
  Future<GetMovimentacoesResponseModel> getMovimentacoes({
    String? itemId,
  }) async {
    final response = await AppApi.get(
      AppApi.getMovimentacoesPath,
      queryParameters: {if (itemId != null) 'item_id': itemId},
    );
    return GetMovimentacoesResponseModel.fromResponse(
      response.data as Map<String, dynamic>,
    );
  }
}
