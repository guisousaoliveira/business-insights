import 'package:flutter/widgets.dart';

import '../../../../settings/app_colors.dart';
import '../../../../settings/app_enums.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../components/app_filter_pill.dart';

/// A faixa de filtros da tela de atendimentos, com o total do período colado
/// nela.
///
/// O saldo mora aqui e não num cartão verde separado porque ele **é** a soma do
/// que está listado: mudar o filtro muda o número, e ver os dois juntos é o que
/// deixa isso óbvio.
class AtendimentoFiltrosWidget extends StatelessWidget {
  final PeriodoAtendimentos periodo;
  final StatusAtendimento? status;
  final double saldoLiquido;
  final int quantidade;
  final ValueChanged<PeriodoAtendimentos> onPeriodoChanged;
  final ValueChanged<StatusAtendimento?> onStatusChanged;

  const AtendimentoFiltrosWidget({
    super.key,
    required this.periodo,
    required this.status,
    required this.saldoLiquido,
    required this.quantidade,
    required this.onPeriodoChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppFilterPill<PeriodoAtendimentos>(
          title: l10n.periodLabel,
          value: periodo,
          isActive: periodo != PeriodoAtendimentos.esteMes,
          onChanged: onPeriodoChanged,
          options: [
            AppFilterOption(
              value: PeriodoAtendimentos.esteMes,
              label: l10n.filterThisMonth,
            ),
            AppFilterOption(
              value: PeriodoAtendimentos.mesPassado,
              label: l10n.filterLastMonth,
            ),
            AppFilterOption(
              value: PeriodoAtendimentos.ultimosTresMeses,
              label: l10n.filterLastThreeMonths,
            ),
            AppFilterOption(
              value: PeriodoAtendimentos.todos,
              label: l10n.filterAllPeriod,
            ),
          ],
        ),
        AppFilterPill<StatusAtendimento?>(
          title: l10n.statusLabel,
          value: status,
          isActive: status != null,
          onChanged: onStatusChanged,
          options: [
            AppFilterOption(value: null, label: l10n.filterAllStatus),
            ...StatusAtendimento.values.map(
              (value) => AppFilterOption(
                value: value,
                label: AppUtils.statusAtendimentoToString(value),
              ),
            ),
          ],
        ),
        _Resumo(saldoLiquido: saldoLiquido, quantidade: quantidade),
      ],
    );
  }
}

class _Resumo extends StatelessWidget {
  final double saldoLiquido;
  final int quantidade;

  const _Resumo({required this.saldoLiquido, required this.quantidade});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppUtils.numToMoney(saldoLiquido),
              style: AppFonts.rowValue(context).copyWith(
                fontSize: 15,
                color: saldoLiquido >= 0 ? AppColors.success : AppColors.danger,
              ),
            ),
            Text(
              context.l10n.appointmentsCount(quantidade),
              style: AppFonts.captionSmall(context),
            ),
          ],
        ),
      );
}
