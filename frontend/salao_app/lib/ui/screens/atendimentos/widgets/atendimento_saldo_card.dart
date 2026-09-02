import 'package:flutter/widgets.dart';

import '../../../../settings/app_colors.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_media_querys.dart';
import '../../../../settings/app_utils.dart';
import '../../../components/app_card.dart';

/// O cabeçalho verde de Atendimentos: saldo líquido do período e quantidade.
///
/// Fica vermelho quando o saldo é negativo — a cor é o dado, não a decoração.
class AtendimentoSaldoCard extends StatelessWidget {
  final double saldoLiquido;
  final int quantidade;

  const AtendimentoSaldoCard({
    super.key,
    required this.saldoLiquido,
    required this.quantidade,
  });

  bool get _isPositivo => saldoLiquido >= 0;

  @override
  Widget build(BuildContext context) {
    final foreground = _isPositivo ? AppColors.success : AppColors.danger;
    final background =
        _isPositivo ? AppColors.successLight : AppColors.dangerLight;

    final label = Text(
      context.l10n.netBalanceInPeriod,
      style: TextStyle(
        fontSize: isWideLayout(context) ? 12 : 11,
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
    );

    final value = Text(
      AppUtils.numToMoney(saldoLiquido),
      style: TextStyle(
        fontSize: isWideLayout(context) ? 20 : 19,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
    );

    final count = Text(
      context.l10n.appointmentsCount(quantidade),
      style: TextStyle(
          fontSize: isWideLayout(context) ? 12 : 11, color: foreground),
    );

    return AppCard.tinted(
      background: background,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      child: isWideLayout(context)
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [label, value, count],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [label, const SizedBox(height: 3), value],
                ),
                count,
              ],
            ),
    );
  }
}
