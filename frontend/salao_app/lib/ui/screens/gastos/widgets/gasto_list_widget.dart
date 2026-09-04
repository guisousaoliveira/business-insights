import 'package:flutter/widgets.dart';

import '../../../../models/gastos/gasto_model.dart';
import '../../../../settings/app_colors.dart';
import '../../../../settings/app_enums.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../components/app_card.dart';
import '../../../components/app_checkbox.dart';
import '../../../components/app_tag.dart';

/// A lista de gastos, igual nas duas cascas — o que muda é onde ela é
/// colocada: empilhada no mobile, lado a lado na web.
class GastoListWidget extends StatelessWidget {
  final List<GastoModel> gastos;
  final void Function(GastoModel gasto) onTogglePago;

  const GastoListWidget({
    super.key,
    required this.gastos,
    required this.onTogglePago,
  });

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          children: List.generate(
            gastos.length,
            (index) => _Row(
              gasto: gastos[index],
              isFirst: index == 0,
              onTogglePago: () => onTogglePago(gastos[index]),
            ),
          ),
        ),
      );
}

class _Row extends StatelessWidget {
  final GastoModel gasto;
  final bool isFirst;
  final VoidCallback onTogglePago;

  const _Row({
    required this.gasto,
    required this.isFirst,
    required this.onTogglePago,
  });

  AppTag _buildCategoriaTag(BuildContext context) {
    final label = AppUtils.categoriaGastoToString(gasto.categoria);
    // Categoria é vocabulário, não resultado: material puxa o roxo da
    // identidade, fixo e outros ficam no âmbar neutro.
    return gasto.categoria == CategoriaGasto.material
        ? AppTag.primary(label)
        : AppTag(
            label: label,
            background: AppColors.amberTint,
            foreground: AppColors.amber,
          );
  }

  @override
  Widget build(BuildContext context) => AppCardRow(
        isFirst: isFirst,
        padding: const EdgeInsets.fromLTRB(4, 4, 13, 4),
        child: Row(
          children: [
            AppCheckBox(
              value: gasto.pago,
              onChanged: gasto.pago ? null : (_) => onTogglePago(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    gasto.nome,
                    style: AppFonts.rowTitle(context).copyWith(
                      color: gasto.pago ? AppColors.text2 : AppColors.text1,
                      decoration:
                          gasto.pago ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _buildCategoriaTag(context),
                      if (!gasto.pago) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${AppUtils.formaPagamentoToString(gasto.formaPagamento)} · '
                            '${context.l10n.dueBy(AppUtils.dateToShort(gasto.prazoPagamento))}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.captionSmall(context).copyWith(
                              color: gasto.isVencido
                                  ? AppColors.danger
                                  : AppColors.text3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppUtils.numToMoney(gasto.valor),
              style: AppFonts.rowValue(context).copyWith(
                color: gasto.pago ? AppColors.text2 : AppColors.danger,
                decoration: gasto.pago ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      );
}
