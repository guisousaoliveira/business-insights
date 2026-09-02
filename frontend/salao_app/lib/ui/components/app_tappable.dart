import 'package:flutter/material.dart'
    show InkWell, Material, MaterialType, NoSplash;
import 'package:flutter/widgets.dart';

import '../../settings/app_colors.dart';

/// Área clicável sem o ripple do Material, com cursor de mão na web.
///
/// Toda interação do app passa por aqui: é o que garante o alvo de toque mínimo
/// de 44dp no mobile (S3) sem repetir `constraints` em cada tela.
class AppTappable extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double minSize;
  final EdgeInsets? padding;

  const AppTappable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.minSize = 44,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return Padding(padding: padding ?? EdgeInsets.zero, child: child);
    }

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        splashFactory: NoSplash.splashFactory,
        hoverColor: AppColors.surface2,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minSize),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }
}
