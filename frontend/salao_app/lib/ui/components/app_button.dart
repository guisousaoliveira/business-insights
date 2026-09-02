import 'package:flutter/widgets.dart';

import '../../settings/app_colors.dart';
import '../../settings/app_fonts.dart';
import 'app_icon.dart';
import 'app_loading.dart';
import 'app_tappable.dart';

enum AppButtonType { filled, outlined, text, danger }

/// Botão do design system, com `isLoading` interno.
///
/// `isLoading` desabilita o toque sozinho: é o que impede o duplo envio de
/// formulário sem cada tela ter que lembrar de fazer isso.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = AppButtonType.filled,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
  });

  bool get _isEnabled => onPressed != null && !isLoading;

  Color get _background => switch (type) {
        AppButtonType.filled => AppColors.primary,
        AppButtonType.danger => AppColors.danger,
        AppButtonType.outlined || AppButtonType.text => AppColors.transparent,
      };

  Color get _foreground => switch (type) {
        AppButtonType.filled || AppButtonType.danger => AppColors.white,
        AppButtonType.outlined => AppColors.primaryDark,
        AppButtonType.text => AppColors.primaryDark,
      };

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          AppLoading(size: 14, color: _foreground, isInline: true)
        else ...[
          if (icon != null) ...[
            AppIcon(icon!, size: 15, color: _foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppFonts.button(context).copyWith(color: _foreground),
          ),
        ],
      ],
    );

    return Opacity(
      opacity: _isEnabled ? 1 : 0.5,
      child: AppTappable(
        onTap: _isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(9),
        minSize: 44,
        child: Container(
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(9),
            border: type == AppButtonType.outlined
                ? Border.all(color: AppColors.border)
                : null,
            boxShadow: type == AppButtonType.filled && _isEnabled
                ? const [
                    BoxShadow(
                      color: AppColors.primaryShadow,
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: content,
        ),
      ),
    );
  }
}
