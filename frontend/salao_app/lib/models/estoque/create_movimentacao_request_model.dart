import '../../settings/app_enums.dart';
import '../../settings/app_utils.dart';

class CreateMovimentacaoRequestModel {
  final String itemId;
  final TipoMovimentacao tipo;
  final double quantidade;
  final String motivo;

  /// Só em entrada: atualiza o custo do item. Ausente, mantém o custo atual.
  final double? custoUnitario;

  const CreateMovimentacaoRequestModel({
    required this.itemId,
    required this.tipo,
    required this.quantidade,
    required this.motivo,
    this.custoUnitario,
  });

  Map<String, dynamic> get toBody => {
        'tipo': AppUtils.tipoMovimentacaoToApi(tipo),
        'quantidade': quantidade,
        'motivo': motivo,
        if (custoUnitario != null) 'custo_unitario': custoUnitario,
      };
}
