import 'package:flutter/widgets.dart';

import '../../settings/app_assets.dart';
import '../../settings/app_colors.dart';
import '../../settings/app_fonts.dart';
import 'app_icon.dart';
import 'app_tappable.dart';

/// A faixa vermelha do topo: o alerta mais recente que ela ainda não leu.
///
/// Vermelho aqui **é** significado — estoque negativo, gasto vencido —, ao
/// contrário do contador de avisos, que é roxo por ser só contagem.
class AppAlertBanner extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onTap;

  const AppAlertBanner({
    super.key,
    required this.title,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => AppTappable(
        onTap: onTap,
        minSize: 0,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.dangerLight,
            border: Border.all(color: AppColors.dangerMid),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const AppIcon(
                AppAssets.warning,
                size: 17,
                color: AppColors.danger,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.rowTitle(context)
                          .copyWith(color: AppColors.danger),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.captionSmall(context)
                          .copyWith(color: AppColors.danger),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                const AppIcon(
                  AppAssets.chevronRight,
                  size: 18,
                  color: AppColors.danger,
                ),
              ],
            ],
          ),
        ),
      );
}
