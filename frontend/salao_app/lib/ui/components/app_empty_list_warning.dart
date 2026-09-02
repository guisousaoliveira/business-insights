import 'package:flutter/widgets.dart';

import '../../settings/app_assets.dart';
import '../../settings/app_colors.dart';
import '../../settings/app_extensions.dart';
import '../../settings/app_fonts.dart';
import 'app_icon.dart';

class AppEmptyListWarning extends StatelessWidget {
  /// Mensagem específica da tela. Ausente, usa a genérica do ARB.
  final String? message;

  const AppEmptyListWarning({super.key, this.message});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(AppAssets.empty, size: 30, color: AppColors.text3),
            const SizedBox(height: 10),
            Text(
              message ?? context.l10n.emptyList,
              textAlign: TextAlign.center,
              style: AppFonts.caption(context),
            ),
          ],
        ),
      );
}
