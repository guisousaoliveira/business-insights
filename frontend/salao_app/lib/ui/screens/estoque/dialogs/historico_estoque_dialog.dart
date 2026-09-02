import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../cubits/estoque/estoque_cubit.dart';
import '../../../../models/estoque/get_movimentacoes_response_model.dart';
import '../../../../settings/app_colors.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../components/app_card.dart';
import '../../../components/app_sub_state_builder.dart';

/// Histórico de movimentações — o relógio na app bar de Estoque.
///
/// Entrada em verde, saída em vermelho: aqui a cor não é estética, é a direção
/// do estoque.
class HistoricoEstoqueDialog extends StatelessWidget {
  const HistoricoEstoqueDialog({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<EstoqueCubit, EstoqueState>(
        buildWhen: (p, c) =>
            p.getMovimentacoesSubState != c.getMovimentacoesSubState,
        builder: (context, state) =>
            AppSubStateBuilder<GetMovimentacoesResponseModel>(
          subState: state.getMovimentacoesSubState,
          onData: (data) => AppCard(
            child: Column(
              children: List.generate(
                data.movimentacoes.length,
                (index) {
                  final movimentacao = data.movimentacoes[index];
                  final color = movimentacao.isEntrada
                      ? AppColors.success
                      : AppColors.danger;

                  return AppCardRow(
                    isFirst: index == 0,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                movimentacao.itemNome,
                                style: AppFonts.rowTitle(context),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${movimentacao.motivo} · '
                                '${AppUtils.dateToRelative(movimentacao.criadoEm)}',
                                style: AppFonts.captionSmall(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${movimentacao.isEntrada ? '+' : '−'}'
                          '${AppUtils.quantityToString(movimentacao.quantidade)}',
                          style:
                              AppFonts.rowValue(context).copyWith(color: color),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
}
