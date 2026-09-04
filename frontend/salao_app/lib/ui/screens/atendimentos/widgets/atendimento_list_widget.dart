import 'package:flutter/widgets.dart';

import '../../../../models/atendimentos/atendimento_model.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_media_querys.dart';
import '../../../components/app_empty_list_warning.dart';
import 'atendimento_card_widget.dart';

/// A lista de atendimentos nas duas cascas: **os mesmos cartões**, empilhados
/// no mobile e em duas colunas na web.
///
/// A tabela que existia aqui na web saiu: o cartão carrega ação (finalizar,
/// editar, cancelar) e detalhe que abre no lugar, e nada disso cabe numa
/// célula de tabela sem virar outro fluxo.
class AtendimentoListWidget extends StatelessWidget {
  static const _gap = 12.0;

  final List<AtendimentoModel> atendimentos;

  /// O atendimento com escrita em voo, se houver. Só os botões **dele** ficam
  /// travados — os outros cartões seguem clicáveis.
  final String? busyId;

  final void Function(AtendimentoModel atendimento) onFinalizar;
  final void Function(AtendimentoModel atendimento) onEditar;
  final void Function(AtendimentoModel atendimento) onCancelar;

  const AtendimentoListWidget({
    super.key,
    required this.atendimentos,
    required this.onFinalizar,
    required this.onEditar,
    required this.onCancelar,
    this.busyId,
  });

  AtendimentoCardWidget _card(AtendimentoModel atendimento) =>
      AtendimentoCardWidget(
        key: ValueKey(atendimento.id),
        atendimento: atendimento,
        isBusy: busyId == atendimento.id,
        onFinalizar: () => onFinalizar(atendimento),
        onEditar: atendimento.isCancelado ? null : () => onEditar(atendimento),
        onCancelar: () => onCancelar(atendimento),
      );

  @override
  Widget build(BuildContext context) {
    if (atendimentos.isEmpty) {
      return AppEmptyListWarning(
        message: context.l10n.noAppointmentsInFilter,
      );
    }

    if (!isWideLayout(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final atendimento in atendimentos) ...[
            _card(atendimento),
            const SizedBox(height: _gap),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - _gap) / 2;

        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: atendimentos
              .map(
                (atendimento) => SizedBox(
                  width: width,
                  child: _card(atendimento),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
