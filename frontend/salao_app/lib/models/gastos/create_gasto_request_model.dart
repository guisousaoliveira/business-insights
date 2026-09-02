import '../../settings/app_enums.dart';
import '../../settings/app_utils.dart';
import 'gasto_model.dart';

class CreateGastoRequestModel {
  final String nome;
  final double valor;
  final DateTime prazoPagamento;
  final FormaPagamento formaPagamento;
  final CategoriaGasto categoria;
  final List<ItemGastoModel> itens;

  const CreateGastoRequestModel({
    required this.nome,
    required this.valor,
    required this.prazoPagamento,
    required this.formaPagamento,
    required this.categoria,
    this.itens = const [],
  });

  Map<String, dynamic> get toBody => {
        'nome': nome,
        'valor': valor,
        'prazo_pagamento': AppUtils.dateToApi(prazoPagamento),
        'forma_pagamento': AppUtils.formaPagamentoToApi(formaPagamento),
        'categoria': AppUtils.categoriaGastoToApi(categoria),
        'itens': itens.map((e) => e.toBody).toList(),
      };
}
