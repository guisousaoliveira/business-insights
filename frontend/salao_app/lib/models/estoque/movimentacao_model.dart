import '../../settings/app_enums.dart';
import '../../settings/app_utils.dart';

class MovimentacaoModel {
  static const _idKey = 'id';
  static const _itemIdKey = 'item_id';
  static const _itemNomeKey = 'item_nome';
  static const _tipoKey = 'tipo';
  static const _quantidadeKey = 'quantidade';
  static const _motivoKey = 'motivo';
  static const _atendimentoIdKey = 'atendimento_id';
  static const _criadoEmKey = 'criado_em';

  final String id;
  final String itemId;
  final String itemNome;
  final TipoMovimentacao tipo;
  final double quantidade;
  final String motivo;

  /// Preenchido quando a baixa veio da finalização de um atendimento — é o que
  /// liga o custo do material ao serviço que o consumiu.
  final String? atendimentoId;
  final DateTime criadoEm;

  const MovimentacaoModel({
    required this.id,
    required this.itemId,
    required this.itemNome,
    required this.tipo,
    required this.quantidade,
    required this.motivo,
    this.atendimentoId,
    required this.criadoEm,
  });

  bool get isEntrada => tipo == TipoMovimentacao.entrada;

  factory MovimentacaoModel.fromResponse(Map<String, dynamic> map) =>
      MovimentacaoModel(
        id: map[_idKey] as String? ?? '',
        itemId: map[_itemIdKey] as String? ?? '',
        itemNome: map[_itemNomeKey] as String? ?? '',
        tipo: AppUtils.decodeTipoMovimentacao(map[_tipoKey] as String?),
        quantidade: (map[_quantidadeKey] as num?)?.toDouble() ?? 0,
        motivo: map[_motivoKey] as String? ?? '',
        atendimentoId: map[_atendimentoIdKey] as String?,
        criadoEm: DateTime.tryParse(map[_criadoEmKey] as String? ?? '') ??
            DateTime.now(),
      );
}
