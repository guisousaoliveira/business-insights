import '../models/kits/get_kits_response_model.dart';
import '../models/kits/kit_model.dart';
import '../settings/app_api.dart';
import '../settings/app_enums.dart';
import '../settings/app_utils.dart';

abstract interface class KitsRepository {
  Future<GetKitsResponseModel> getKits();
  Future<void> createKit({
    required String nome,
    required double precoVenda,
    required List<KitItemModel> itens,
  });
  Future<void> deleteKit(String id);
  Future<void> montarKit({
    required String id,
    required double quantidade,
    bool confirmarEstoqueInsuficiente,
  });
  Future<void> venderKit({
    required String id,
    required double quantidade,
    required FormaPagamento formaPagamento,
    double? precoUnitario,
  });
}

class KitsRepositoryImpl implements KitsRepository {
  const KitsRepositoryImpl();

  @override
  Future<GetKitsResponseModel> getKits() async {
    final response = await AppApi.get(AppApi.getKitsPath);
    return GetKitsResponseModel.fromResponse(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<void> createKit({
    required String nome,
    required double precoVenda,
    required List<KitItemModel> itens,
  }) async {
    await AppApi.post(
      AppApi.postKitPath,
      data: {
        'nome': nome,
        'preco_venda': precoVenda,
        'itens': itens.map((e) => e.toBody).toList(),
      },
    );
  }

  @override
  Future<void> deleteKit(String id) async {
    await AppApi.delete('${AppApi.deleteKitPath}/$id');
  }

  @override
  Future<void> montarKit({
    required String id,
    required double quantidade,
    bool confirmarEstoqueInsuficiente = false,
  }) async {
    await AppApi.post(
      '${AppApi.montarKitPath}/$id/montar',
      data: {
        'quantidade': quantidade,
        'confirmar_estoque_insuficiente': confirmarEstoqueInsuficiente,
      },
    );
  }

  @override
  Future<void> venderKit({
    required String id,
    required double quantidade,
    required FormaPagamento formaPagamento,
    double? precoUnitario,
  }) async {
    await AppApi.post(
      '${AppApi.venderKitPath}/$id/vender',
      data: {
        'quantidade': quantidade,
        'forma_pagamento': AppUtils.formaPagamentoToApi(formaPagamento),
        if (precoUnitario != null) 'preco_unitario': precoUnitario,
      },
    );
  }
}
