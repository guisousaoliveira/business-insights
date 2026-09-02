import 'package:flutter/widgets.dart';

import '../../../../models/atendimentos/atendimento_model.dart';
import '../../../../settings/app_colors.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../components/app_avatar.dart';
import '../../../components/app_empty_list_warning.dart';
import '../../../components/app_table.dart';
import '../../../components/app_tag.dart';

/// Casca web: a mesma lista com densidade de tabela. Mesmo dado do
/// [AtendimentoListWidget], não outra tela.
class AtendimentoTableWidget extends StatelessWidget {
  final List<AtendimentoModel> atendimentos;
  final void Function(AtendimentoModel atendimento) onTap;

  const AtendimentoTableWidget({
    super.key,
    required this.atendimentos,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => AppTable(
        emptyState: const AppEmptyListWarning(),
        columns: [
          AppTableColumn(label: context.l10n.clientLabel, flex: 32),
          AppTableColumn(label: context.l10n.dateLabel, flex: 22),
          AppTableColumn(label: context.l10n.statusLabel, flex: 22),
          AppTableColumn(
            label: context.l10n.valueLabel,
            flex: 24,
            alignment: Alignment.centerRight,
          ),
        ],
        rows: atendimentos
            .map(
              (atendimento) => AppTableRow(
                onTap: () => onTap(atendimento),
                cells: [
                  _buildClient(context, atendimento),
                  Text(
                    AppUtils.dateToRelative(atendimento.data),
                    style: AppFonts.caption(context).copyWith(fontSize: 12),
                  ),
                  AppTag.statusAtendimento(
                    atendimento.status,
                    AppUtils.statusAtendimentoToString(atendimento.status),
                  ),
                  Text(
                    atendimento.isCancelado
                        ? '—'
                        : AppUtils.numToMoney(atendimento.saldo),
                    style: AppFonts.rowValue(context).copyWith(
                      color: atendimento.isCancelado
                          ? AppColors.text3
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      );

  Widget _buildClient(BuildContext context, AtendimentoModel atendimento) {
    final avatar = atendimento.isCancelado
        ? AppAvatar.neutral(name: atendimento.clienteNome, size: 26)
        : atendimento.isAgendado
            ? AppAvatar.warning(name: atendimento.clienteNome, size: 26)
            : AppAvatar(name: atendimento.clienteNome, size: 26);

    return Row(
      children: [
        avatar,
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            atendimento.clienteNome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.rowTitle(context).copyWith(
              color:
                  atendimento.isCancelado ? AppColors.text3 : AppColors.text1,
              decoration:
                  atendimento.isCancelado ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ],
    );
  }
}
