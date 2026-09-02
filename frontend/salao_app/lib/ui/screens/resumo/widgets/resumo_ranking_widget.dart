import 'package:flutter/widgets.dart';

import '../../../../models/resumo/servico_ranking_model.dart';
import '../../../../settings/app_colors.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../components/app_card.dart';
import '../../../components/app_empty_list_warning.dart';
import '../../../components/app_progress_bar.dart';
import '../../../components/app_tag.dart';

/// Ranking de serviços com a barrinha proporcional. A barra é relativa ao
/// primeiro colocado, não ao total — é o que dá a leitura de "quanto este é
/// menor que o campeão".
class ResumoRankingWidget extends StatelessWidget {
  final List<ServicoRankingModel> servicos;
  final double maiorReceita;

  const ResumoRankingWidget({
    super.key,
    required this.servicos,
    required this.maiorReceita,
  });

  @override
  Widget build(BuildContext context) {
    if (servicos.isEmpty) return const AppEmptyListWarning();

    return AppCard(
      child: Column(
        children: List.generate(
          servicos.length,
          (index) => AppCardRow(
            isFirst: index == 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              servicos[index].nome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.rowTitle(context)
                                  .copyWith(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 6),
                          AppTag.primary(
                            context.l10n
                                .timesPerformed(servicos[index].quantidade),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppUtils.numToMoney(servicos[index].totalReceita),
                      style: AppFonts.rowValue(context)
                          .copyWith(fontSize: 12, color: AppColors.success),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                AppProgressBar(
                  value: maiorReceita == 0
                      ? 0
                      : servicos[index].totalReceita / maiorReceita,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
