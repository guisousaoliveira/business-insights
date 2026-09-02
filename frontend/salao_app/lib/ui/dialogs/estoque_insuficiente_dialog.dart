import 'package:flutter/widgets.dart';

import '../../models/estoque/estoque_faltante_model.dart';
import '../../settings/app_colors.dart';
import '../../settings/app_extensions.dart';
import '../../settings/app_fonts.dart';
import '../../settings/app_utils.dart';
import '../components/app_button.dart';
import '../components/app_card.dart';
import '../components/app_dialog.dart';

/// Aviso de estoque insuficiente com a pergunta "finalizar mesmo assim?".
///
/// É a primeira metade da decisão tomada com a usuária (§2 de
/// `endpoints-backend.md`): em vez de bloquear a finalização, mostramos
/// exatamente o que falta e deixamos ela escolher. O atendimento aconteceu de
/// verdade; o estoque é que está atrasado.
///
/// Vive fora de `screens/` porque duas telas usam o mesmo aviso: a
/// finalização de atendimento e a montagem de kit consomem estoque pelo mesmo
/// caminho e falham do mesmo jeito.
///
/// Devolve `true` se ela confirmou.
class EstoqueInsuficienteDialog {
  const EstoqueInsuficienteDialog._();

  static Future<bool> show({
    required BuildContext context,
    required List<EstoqueFaltanteModel> faltantes,
  }) async {
    final confirmou = await AppDialog.show<bool>(
      context: context,
      title: context.l10n.insufficientStockTitle,
      child: _Content(faltantes: faltantes),
    );
    return confirmou ?? false;
  }
}

class _Content extends StatelessWidget {
  final List<EstoqueFaltanteModel> faltantes;

  const _Content({required this.faltantes});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.insufficientStockQuestion,
            style: AppFonts.caption(context),
          ),
          if (faltantes.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildList(context),
          ],
          const SizedBox(height: 14),
          Text(
            context.l10n.insufficientStockHint,
            style: AppFonts.caption(context).copyWith(color: AppColors.text2),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: context.l10n.cancel,
                type: AppButtonType.text,
                onPressed: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(width: 8),
              AppButton(
                label: context.l10n.finishAnyway,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ],
      );

  Widget _buildList(BuildContext context) => AppCard(
        child: Column(
          children: List.generate(
            faltantes.length,
            (index) => AppCardRow(
              isFirst: index == 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          faltantes[index].nome,
                          style: AppFonts.rowTitle(context),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.insufficientStockRow(
                            AppUtils.quantityToString(
                              faltantes[index].quantidadeSolicitada,
                            ),
                            AppUtils.quantityToString(
                              faltantes[index].quantidadeDisponivel,
                            ),
                            AppUtils.unidadeEstoqueToString(
                              faltantes[index].unidade,
                            ),
                          ),
                          style: AppFonts.caption(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '−${AppUtils.quantityToString(faltantes[index].deficit)}',
                    style: AppFonts.rowValue(context)
                        .copyWith(color: AppColors.danger),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
