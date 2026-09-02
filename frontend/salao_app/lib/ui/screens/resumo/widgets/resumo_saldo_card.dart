import 'package:flutter/widgets.dart';

import '../../../../models/resumo/get_resumo_mensal_response_model.dart';
import '../../../../settings/app_assets.dart';
import '../../../../settings/app_colors.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../components/app_card.dart';
import '../../../components/app_progress_bar.dart';
import '../../../components/app_tag.dart';

/// O cartão principal do Resumo: saldo do mês, variação contra o mês anterior,
/// quanto entrou, quanto saiu, e a barra que mostra a proporção entre os dois.
class ResumoSaldoCard extends StatelessWidget {
  final GetResumoMensalResponseModel resumo;

  const ResumoSaldoCard({super.key, required this.resumo});

  @override
  Widget build(BuildContext context) {
    final isPositivo = resumo.isPositivo;
    final foreground = isPositivo ? AppColors.success : AppColors.danger;
    final background =
        isPositivo ? AppColors.successLight : AppColors.dangerLight;

    final subiu = resumo.variacaoPercentualMesAnterior >= 0;

    return AppCard.tinted(
      background: background,
      radius: 14,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                context.l10n.monthBalance,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
              const SizedBox(width: 7),
              AppTag(
                label: AppUtils.numToSignedPercent(
                  resumo.variacaoPercentualMesAnterior,
                  decimals: 0,
                ),
                icon: subiu ? AppAssets.arrowUp : AppAssets.arrowDown,
                background: background,
                foreground: foreground,
                borderColor:
                    subiu ? AppColors.successMid : AppColors.dangerMid,
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            AppUtils.numToMoney(resumo.saldoFinal),
            style: AppFonts.displayBalance(context).copyWith(color: foreground),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Amount(
                label: context.l10n.cameIn,
                value: resumo.entrou,
                color: AppColors.success,
              ),
              const SizedBox(width: 18),
              _Amount(
                label: context.l10n.wentOut,
                value: resumo.saiu,
                color: AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppSplitBar(positiveRatio: resumo.proporcaoEntrada),
          // Kit é a única receita que não vem de atendimento. Sem essa linha,
          // ela some dentro do "Entrou" e o mês parece ter rendido mais serviço
          // do que rendeu.
          if (resumo.temVendaDeKit) ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.kitsRevenueLine(
                AppUtils.numToMoney(resumo.totalKits),
                resumo.quantidadeKitsVendidos,
              ),
              style: TextStyle(
                fontSize: 10,
                color: AppColors.success.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _Amount({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.6)),
          ),
          Text(
            AppUtils.numToMoney(value),
            style: AppFonts.rowValue(context).copyWith(color: color),
          ),
        ],
      );
}
