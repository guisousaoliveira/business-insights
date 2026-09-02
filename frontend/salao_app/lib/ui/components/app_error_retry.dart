import 'package:flutter/widgets.dart';

import '../../settings/app_assets.dart';
import '../../settings/app_colors.dart';
import '../../settings/app_extensions.dart';
import '../../settings/app_fonts.dart';
import 'app_button.dart';
import 'app_icon.dart';

/// Erro que virou estado da tela (e não snackbar): mostra a mensagem já
/// traduzida do `ErrorModel` e devolve o caminho de volta.
class AppErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AppErrorRetry({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(AppAssets.error, size: 28, color: AppColors.danger),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.caption(context),
            ),
            const SizedBox(height: 14),
            AppButton(
              label: context.l10n.retry,
              onPressed: onRetry,
              type: AppButtonType.outlined,
            ),
          ],
        ),
      );
}
