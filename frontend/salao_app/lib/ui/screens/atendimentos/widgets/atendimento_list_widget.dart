import 'package:flutter/widgets.dart';

import '../../../../models/atendimentos/atendimento_model.dart';
import '../../../../settings/app_colors.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../components/app_avatar.dart';
import '../../../components/app_card.dart';
import '../../../components/app_tag.dart';
import '../../../components/app_tappable.dart';

/// Casca mobile: cartões empilhados, um por atendimento.
class AtendimentoListWidget extends StatelessWidget {
  final List<AtendimentoModel> atendimentos;
  final void Function(AtendimentoModel atendimento) onTap;

  const AtendimentoListWidget({
    super.key,
    required this.atendimentos,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          children: List.generate(
            atendimentos.length,
            (index) => _Row(
              atendimento: atendimentos[index],
              isFirst: index == 0,
              onTap: () => onTap(atendimentos[index]),
            ),
          ),
        ),
      );
}

class _Row extends StatelessWidget {
  final AtendimentoModel atendimento;
  final bool isFirst;
  final VoidCallback onTap;

  const _Row({
    required this.atendimento,
    required this.isFirst,
    required this.onTap,
  });

  /// Cada status tem sua leitura de relance: agendado ganha fundo âmbar,
  /// cancelado fica apagado com o nome riscado.
  Color? get _background => switch (atendimento.status) {
        _ when atendimento.isAgendado => AppColors.amberRowTint,
        _ when atendimento.isCancelado => AppColors.surface2,
        _ => null,
      };

  Widget _buildAvatar() {
    if (atendimento.isCancelado) {
      return AppAvatar.neutral(name: atendimento.clienteNome);
    }
    if (atendimento.isAgendado) {
      return AppAvatar.warning(name: atendimento.clienteNome);
    }
    return AppAvatar(name: atendimento.clienteNome);
  }

  @override
  Widget build(BuildContext context) {
    final isCancelado = atendimento.isCancelado;

    return AppTappable(
      onTap: onTap,
      minSize: 0,
      child: AppCardRow(
        isFirst: isFirst,
        background: _background,
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          atendimento.clienteNome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.rowTitle(context).copyWith(
                            color: isCancelado
                                ? AppColors.text3
                                : AppColors.text1,
                            decoration: isCancelado
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (!atendimento.isFinalizado) ...[
                        const SizedBox(width: 6),
                        AppTag.statusAtendimento(
                          atendimento.status,
                          AppUtils.statusAtendimentoToString(
                            atendimento.status,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppUtils.dateToRelative(atendimento.data),
                    style: AppFonts.caption(context),
                  ),
                ],
              ),
            ),
            if (!isCancelado) ...[
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppUtils.numToMoney(atendimento.saldo),
                    style: AppFonts.rowValue(context)
                        .copyWith(color: AppColors.success),
                  ),
                  Text(
                    atendimento.isAgendado
                        ? context.l10n.forecastLabel
                        : context.l10n.netLabel,
                    style: AppFonts.captionSmall(context),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
