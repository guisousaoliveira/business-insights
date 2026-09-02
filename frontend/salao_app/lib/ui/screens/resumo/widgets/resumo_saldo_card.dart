import 'package:flutter/widgets.dart';

import '../../../../models/resumo/get_resumo_mensal_response_model.dart';
import '../../../../settings/app_assets.dart';
import '../../../../settings/app_colors.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../components/app_card.dart';
import '../../../components/app_icon.dart';

/// O número que responde a pergunta principal do app: lucro ou prejuízo.
class ResumoSaldoCard extends StatelessWidget {
  final GetResumoMensalResponseModel resumo;

  const ResumoSaldoCard({super.key, required this.resumo});

  @override
  Widget build(BuildContext context) {
    final isPositivo = resumo.isPositivo;
    final foreground = isPositivo ? AppColors.success : AppColors.danger;
    final background =
        isPositivo ? AppColors.successLight : AppColors.dangerLight;

    return AppCard.tinted(
      background: background,
      radius: 22,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                (isPositivo ? context.l10n.monthProfit : context.l10n.monthLoss)
                    .toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
              AppIcon(
                isPositivo ? AppAssets.trendingUp : AppAssets.trendingDown,
                size: 20,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            AppUtils.numToMoney(resumo.saldoFinal),
            style: AppFonts.displayBalance(context).copyWith(color: foreground),
          ),
          const SizedBox(height: 8),
          Text(
            resumo.variacaoPercentualMesAnterior == 0
                ? context.l10n.noPreviousComparison
                : context.l10n.vsPreviousMonth,
            style: AppFonts.caption(context),
          ),
        ],
      ),
    );
  }
}
