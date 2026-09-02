import 'package:flutter/widgets.dart';

import '../../settings/app_colors.dart';

/// Círculo com a inicial do nome da cliente.
///
/// A cor de fundo é semântica, não decorativa: cinza em cancelado, âmbar em
/// agendado, roxo no resto — é o que faz a lista ser lida de relance.
class AppAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color background;
  final Color foreground;

  const AppAvatar({
    super.key,
    required this.name,
    this.size = 34,
    this.background = AppColors.primaryLight,
    this.foreground = AppColors.primaryDark,
  });

  const AppAvatar.warning({
    super.key,
    required this.name,
    this.size = 34,
  })  : background = AppColors.amberLight,
        foreground = AppColors.amber;

  const AppAvatar.neutral({
    super.key,
    required this.name,
    this.size = 34,
  })  : background = AppColors.border,
        foreground = AppColors.text3;

  String get _initial =>
      name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Text(
          _initial,
          style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      );
}
