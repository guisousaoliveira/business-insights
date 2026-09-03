import 'package:flutter/widgets.dart';

import '../../settings/app_colors.dart';
import '../../settings/app_fonts.dart';
import 'app_card.dart';

/// O par de cartões coloridos no topo de Gastos e Estoque: rótulo pequeno em
/// cima, número grande embaixo, tudo na cor do significado.
class AppMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color background;
  final Color foreground;

  const AppMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
  });

  /// Dinheiro que entrou, gasto quitado.
  const AppMetricCard.success({
    super.key,
    required this.label,
    required this.value,
  })  : background = AppColors.successLight,
        foreground = AppColors.success;

  /// Dinheiro que sai, pendência, itens em alerta.
  const AppMetricCard.danger({
    super.key,
    required this.label,
    required this.value,
  })  : background = AppColors.dangerLight,
        foreground = AppColors.danger;

  const AppMetricCard.warning({
    super.key,
    required this.label,
    required this.value,
  })  : background = AppColors.amberLight,
        foreground = AppColors.amber;

  /// Valor neutro que não é resultado — "Valor em estoque" é patrimônio, não
  /// lucro nem prejuízo, então é roxo.
  const AppMetricCard.neutral({
    super.key,
    required this.label,
    required this.value,
  })  : background = AppColors.primaryLight,
        foreground = AppColors.primaryDark;

  @override
  Widget build(BuildContext context) => AppCard.tinted(
        background: background,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: AppFonts.metricValue(context).copyWith(color: foreground),
            ),
          ],
        ),
      );
}
