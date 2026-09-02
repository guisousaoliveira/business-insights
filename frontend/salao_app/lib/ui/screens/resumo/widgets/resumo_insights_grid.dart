import 'package:flutter/widgets.dart';

import '../../../../models/resumo/get_resumo_mensal_response_model.dart';
import '../../../../settings/app_assets.dart';
import '../../../../settings/app_colors.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_media_querys.dart';
import '../../../../settings/app_utils.dart';
import '../../../components/app_card.dart';
import '../../../components/app_icon.dart';

/// Os quatro números que respondem "como foi o mês": ticket médio, margem,
/// variação e serviço mais lucrativo.
///
/// 2×2 no mobile, 1×4 na web — é o mesmo conteúdo reflowado, não outra tela.
class ResumoInsightsGrid extends StatelessWidget {
  final GetResumoMensalResponseModel resumo;

  const ResumoInsightsGrid({super.key, required this.resumo});

  @override
  Widget build(BuildContext context) {
    final variacao = resumo.variacaoPercentualMesAnterior;

    final cards = [
      _InsightCard(
        icon: AppAssets.receipt,
        iconBackground: AppColors.primaryLight,
        iconColor: AppColors.primaryDark,
        label: context.l10n.averageTicket,
        value: AppUtils.numToMoney(resumo.ticketMedio),
      ),
      _InsightCard(
        icon: AppAssets.chartPie,
        iconBackground: AppColors.successLight,
        iconColor: AppColors.success,
        label: context.l10n.profitMargin,
        value: AppUtils.numToPercent(resumo.margemLucroPercentual),
      ),
      _InsightCard(
        icon: variacao >= 0 ? AppAssets.trendingUp : AppAssets.trendingDown,
        iconBackground:
            variacao >= 0 ? AppColors.successLight : AppColors.dangerLight,
        iconColor: variacao >= 0 ? AppColors.success : AppColors.danger,
        label: context.l10n.vsPreviousMonth,
        value: AppUtils.numToSignedPercent(variacao),
        valueColor: variacao >= 0 ? AppColors.success : AppColors.danger,
      ),
      _InsightCard(
        icon: AppAssets.star,
        iconBackground: AppColors.accentTint,
        iconColor: AppColors.primaryAccent,
        label: context.l10n.mostProfitable,
        value: resumo.servicoMaisLucrativo ?? '—',
      ),
    ];

    if (isWideLayout(context)) {
      return Row(
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            if (index > 0) const SizedBox(width: 12),
            Expanded(child: cards[index]),
          ],
        ],
      );
    }

    return Column(
      children: [
        _buildPar(cards[0], cards[1]),
        const SizedBox(height: 8),
        _buildPar(cards[2], cards[3]),
      ],
    );
  }

  /// Dois cartões lado a lado, com a altura do mais alto.
  ///
  /// O `stretch` sozinho não serve: a tela rola, então a altura que chega aqui
  /// é infinita e esticar até ela quebra o layout. O `IntrinsicHeight` fecha a
  /// altura no maior dos dois antes de o `stretch` valer — é o que faz o cartão
  /// de "Ticket médio" acompanhar o vizinho quando o texto dele quebra em duas
  /// linhas.
  Widget _buildPar(Widget esquerda, Widget direita) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: esquerda),
            const SizedBox(width: 8),
            Expanded(child: direita),
          ],
        ),
      );
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  const _InsightCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(7),
              ),
              child: AppIcon(icon, size: 13, color: iconColor),
            ),
            const SizedBox(height: 7),
            Text(label, style: AppFonts.captionSmall(context)),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.insightValue(context)
                  .copyWith(color: valueColor ?? AppColors.text1),
            ),
          ],
        ),
      );
}
