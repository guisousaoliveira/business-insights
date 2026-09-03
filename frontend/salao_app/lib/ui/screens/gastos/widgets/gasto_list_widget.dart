import 'package:flutter/widgets.dart';

import '../../../../models/gastos/gasto_model.dart';
import '../../../../settings/app_colors.dart';
import '../../../../settings/app_enums.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../components/app_card.dart';
import '../../../components/app_checkbox.dart';
import '../../../components/app_icon.dart';
import '../../../components/app_tag.dart';
import '../../../components/app_tappable.dart';
import '../../../../settings/app_assets.dart';

/// A lista de gastos: pendentes e pagos usam a mesma linha, empilhada.
class GastoListWidget extends StatelessWidget {
  final List<GastoModel> gastos;
  final void Function(GastoModel gasto) onTogglePago;
  final void Function(GastoModel gasto) onEdit;
  final void Function(GastoModel gasto) onDelete;

  const GastoListWidget({
    super.key,
    required this.gastos,
    required this.onTogglePago,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: gastos
            .map((gasto) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _Row(
                    gasto: gasto,
                    onTogglePago: () => onTogglePago(gasto),
                    onEdit: () => onEdit(gasto),
                    onDelete: () => onDelete(gasto),
                  ),
                ))
            .toList(),
      );
}

class _Row extends StatelessWidget {
  final GastoModel gasto;
  final VoidCallback onTogglePago;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _Row({
    required this.gasto,
    required this.onTogglePago,
    required this.onEdit,
    required this.onDelete,
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
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppUtils.numToMoney(gasto.valor),
                  style: AppFonts.rowValue(context).copyWith(
                    color: gasto.pago ? AppColors.text2 : AppColors.text1,
                    decoration: gasto.pago ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    AppTappable(
                      onTap: onEdit,
                      minSize: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: const AppIcon(AppAssets.edit, size: 16),
                    ),
                    AppTappable(
                      onTap: onDelete,
                      minSize: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: const AppIcon(
                        AppAssets.delete,
                        size: 16,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
}
