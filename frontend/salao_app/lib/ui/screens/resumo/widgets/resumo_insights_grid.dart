import 'package:flutter/widgets.dart';

import '../../../../models/resumo/get_resumo_mensal_response_model.dart';
import '../../../../settings/app_assets.dart';
import '../../../../settings/app_colors.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../components/app_card.dart';
import '../../../components/app_icon.dart';

/// Os cinco números principais do mês, na ordem visual do novo painel.
///
/// Sempre 2×2 mais um: cinco cartões em três linhas, do maior para o menor.
class ResumoInsightsGrid extends StatelessWidget {
  final GetResumoMensalResponseModel resumo;

  const ResumoInsightsGrid({super.key, required this.resumo});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _InsightCard(
        icon: AppAssets.wallet,
        iconBackground: AppColors.primaryLight,
        iconColor: AppColors.primary,
        label: context.l10n.revenueLabel,
        value: AppUtils.numToMoney(resumo.entrou),
      ),
      _InsightCard(
        icon: AppAssets.receipt,
        iconBackground: AppColors.dangerLight,
        iconColor: AppColors.primary,
        label: context.l10n.expensesLabel,
        value: AppUtils.numToMoney(resumo.saiu),
      ),
      _InsightCard(
        icon: AppAssets.target,
        iconBackground: AppColors.primaryLight,
        iconColor: AppColors.primary,
        label: context.l10n.profitMargin,
        value: AppUtils.numToPercent(resumo.margemLucroPercentual),
      ),
      _InsightCard(
        icon: AppAssets.trendingUp,
        iconBackground: AppColors.primaryLight,
        iconColor: AppColors.primary,
        label: context.l10n.averageTicket,
        value: AppUtils.numToMoney(resumo.ticketMedio),
      ),
      _InsightCard(
        icon: AppAssets.people,
        iconBackground: AppColors.primaryLight,
        iconColor: AppColors.primary,
        label: context.l10n.appointmentsLabel,
        value: resumo.quantidadeAtendimentos.toString(),
        helper: context.l10n.finalizedInMonth,
      ),
    ];

    return Column(
      children: [
        _buildPar(cards[0], cards[1]),
        const SizedBox(height: 8),
        _buildPar(cards[2], cards[3]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: cards[4]),
          const SizedBox(width: 8),
          const Expanded(child: SizedBox()),
        ]),
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
  final String? helper;

  const _InsightCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.label,
    required this.value,
    this.helper,
  });

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.captionSmall(context),
                  ),
                ),
                const SizedBox(width: 4),
                AppIcon(icon, size: 15, color: iconColor),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.insightValue(context),
            ),
            if (helper != null) ...[
              const SizedBox(height: 3),
              Text(helper!, style: AppFonts.captionSmall(context)),
            ],
          ],
        ),
      );
}
