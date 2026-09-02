import 'package:flutter/material.dart'
    show ScaffoldMessenger, SnackBar, SnackBarBehavior;
import 'package:flutter/widgets.dart';

import '../../settings/app_colors.dart';
import '../../settings/app_enums.dart';
import 'app_icon.dart';
import '../../settings/app_assets.dart';

/// Feedback pontual. Funciona de qualquer rota porque o `MaterialApp` é
/// envolvido por um `ScaffoldMessenger` no `main.dart`.
class AppSnackBar {
  const AppSnackBar._();

  static void showSnackbar(
    BuildContext context,
    String message,
    SnackBarStatus status,
  ) {
    final (background, foreground, icon) = switch (status) {
      SnackBarStatus.sucess => (
          AppColors.successLight,
          AppColors.success,
          AppAssets.check,
        ),
      SnackBarStatus.error => (
          AppColors.dangerLight,
          AppColors.danger,
          AppAssets.warning,
        ),
      SnackBarStatus.alert => (
          AppColors.amberLight,
          AppColors.amber,
          AppAssets.warning,
        ),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: background,
          behavior: SnackBarBehavior.floating,
          elevation: 2,
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              AppIcon(icon, size: 16, color: foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
