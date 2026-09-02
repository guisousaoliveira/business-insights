import 'package:flutter/widgets.dart';

import '../../settings/app_colors.dart';

/// A barrinha de proporção do ranking de serviços.
class AppProgressBar extends StatelessWidget {
  /// 0.0 a 1.0.
  final double value;
  final Color color;
  final double height;

  const AppProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.primary,
    this.height = 5,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: height,
          color: AppColors.surface2,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(color: color),
          ),
        ),
      );
}

/// A barra dividida entre entrou (verde) e saiu (vermelho) do cartão de saldo.
class AppSplitBar extends StatelessWidget {
  final double positiveRatio;
  final double height;

  const AppSplitBar({
    super.key,
    required this.positiveRatio,
    this.height = 7,
  });

  @override
  Widget build(BuildContext context) {
    final positive = positiveRatio.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              flex: (positive * 1000).round(),
              child: Container(color: AppColors.success),
            ),
            Expanded(
              flex: ((1 - positive) * 1000).round(),
              child: Container(color: AppColors.dangerMid),
            ),
          ],
        ),
      ),
    );
  }
}
