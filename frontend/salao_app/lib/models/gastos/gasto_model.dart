import '../../settings/app_enums.dart';
import '../../settings/app_utils.dart';

class ItemGastoModel {
  static const _nomeKey = 'nome';
  static const _precoKey = 'preco';

  final String nome;
  final double preco;

  const ItemGastoModel({required this.nome, required this.preco});

  factory ItemGastoModel.fromResponse(Map<String, dynamic> map) =>
      ItemGastoModel(
        nome: map[_nomeKey] as String? ?? '',
        preco: (map[_precoKey] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> get toBody => {_nomeKey: nome, _precoKey: preco};
}

class GastoModel {
  static const _idKey = 'id';
  static const _nomeKey = 'nome';
  static const _valorKey = 'valor';
  static const _prazoPagamentoKey = 'prazo_pagamento';
  static const _formaPagamentoKey = 'forma_pagamento';
  static const _categoriaKey = 'categoria';
  static const _pagoKey = 'pago';
  static const _pagoEmKey = 'pago_em';
  static const _venceEmDiasKey = 'vence_em_dias';
  static const _itensKey = 'itens';

  final String id;
  final String nome;
  final double valor;
  final DateTime prazoPagamento;
  final FormaPagamento formaPagamento;
  final CategoriaGasto categoria;
  final bool pago;
  final DateTime? pagoEm;

  /// Vem do servidor (negativo = vencido). O app não recalcula prazo: é a mesma
  /// regra que gera o alerta de gasto a vencer.
  final int venceEmDias;
  final List<ItemGastoModel> itens;

  const GastoModel({
    required this.id,
    required this.nome,
    required this.valor,
    required this.prazoPagamento,
    required this.formaPagamento,
    required this.categoria,
    required this.pago,
    this.pagoEm,
    required this.venceEmDias,
    required this.itens,
  });

  bool get isVencido => !pago && venceEmDias < 0;
  bool get isUrgente => !pago && venceEmDias >= 0 && venceEmDias <= 3;

  factory GastoModel.fromResponse(Map<String, dynamic> map) => GastoModel(
        id: map[_idKey] as String? ?? '',
        nome: map[_nomeKey] as String? ?? '',
        valor: (map[_valorKey] as num?)?.toDouble() ?? 0,
        prazoPagamento:
            DateTime.tryParse(map[_prazoPagamentoKey] as String? ?? '') ??
                DateTime.now(),
        formaPagamento:
            AppUtils.decodeFormaPagamento(map[_formaPagamentoKey] as String?),
        categoria: AppUtils.decodeCategoriaGasto(map[_categoriaKey] as String?),
        pago: map[_pagoKey] as bool? ?? false,
        pagoEm: DateTime.tryParse(map[_pagoEmKey] as String? ?? ''),
        venceEmDias: (map[_venceEmDiasKey] as num?)?.toInt() ?? 0,
        itens: (map[_itensKey] as List? ?? const [])
            .map((e) => ItemGastoModel.fromResponse(e as Map<String, dynamic>))
            .toList(),
      );
}
