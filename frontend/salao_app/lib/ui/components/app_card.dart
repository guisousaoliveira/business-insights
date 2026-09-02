import 'package:flutter/widgets.dart';

import '../../settings/app_colors.dart';

/// O cartão branco com borda de meio pixel e sombra suave que estrutura todas
/// as telas do protótipo.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color background;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.background = AppColors.surface,
    this.radius = 12,
  });

  /// Variante colorida (saldo verde, métrica vermelha) — sem borda, porque a
  /// própria cor de fundo já separa do plano de fundo.
  const AppCard.tinted({
    super.key,
    required this.child,
    required this.background,
    this.padding,
    this.radius = 12,
  });

  bool get _hasBorder => background == AppColors.surface;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
          border: _hasBorder ? Border.all(color: AppColors.border, width: 0.5) : null,
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        padding: padding,
        child: child,
      );
}

/// Uma linha dentro de um [AppCard], com o divisor de meio pixel que separa da
/// anterior. `isFirst` evita o divisor no topo.
class AppCardRow extends StatelessWidget {
  final Widget child;
  final bool isFirst;
  final Color? background;
  final EdgeInsets padding;

  const AppCardRow({
    super.key,
    required this.child,
    this.isFirst = false,
    this.background,
    this.padding = const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: background,
          border: isFirst
              ? null
              : const Border(
                  top: BorderSide(color: AppColors.border, width: 0.5),
                ),
        ),
        padding: padding,
        child: child,
      );
}
