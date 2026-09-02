import 'package:flutter/widgets.dart';

import '../../settings/app_colors.dart';

/// Único lugar do app que desenha um ícone.
///
/// Concentrar aqui é o que torna a troca para os SVGs da Tabler uma mudança de
/// um arquivo só — ver `AppAssets`.
class AppIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;

  const AppIcon(
    this.icon, {
    super.key,
    this.size = 18,
    this.color = AppColors.text2,
  });

  @override
  Widget build(BuildContext context) => Icon(icon, size: size, color: color);
}
