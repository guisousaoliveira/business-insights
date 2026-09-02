import 'package:flutter/material.dart' show CircularProgressIndicator;
import 'package:flutter/widgets.dart';

import '../../settings/app_colors.dart';

class AppLoading extends StatelessWidget {
  final double size;
  final Color color;

  /// Ocupa a altura do conteúdo em vez de centralizar na tela inteira — usado
  /// dentro de um cartão que já tem altura própria.
  final bool isInline;

  const AppLoading({
    super.key,
    this.size = 22,
    this.color = AppColors.primary,
    this.isInline = false,
  });

  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );

    if (isInline) return Center(child: indicator);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(child: indicator),
    );
  }
}
