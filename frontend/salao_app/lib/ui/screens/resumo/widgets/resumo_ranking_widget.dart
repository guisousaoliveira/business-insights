import 'package:flutter/widgets.dart';

import '../../../../models/resumo/servico_ranking_model.dart';
import '../../../../settings/app_colors.dart';
import '../../../../settings/app_assets.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../components/app_card.dart';
import '../../../components/app_empty_list_warning.dart';
import '../../../components/app_icon.dart';

/// Destaca o campeão e explicita a colocação dos demais serviços.
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

    final primeiro = servicos.first;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accentTint,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const AppIcon(AppAssets.crown,
                  size: 22, color: AppColors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(primeiro.nome, style: AppFonts.rowTitle(context)),
                const SizedBox(height: 2),
                Text(
                  context.l10n.profitableServiceDetail(
                    primeiro.quantidade,
                    AppUtils.numToMoney(primeiro.lucro),
                  ),
                  style: AppFonts.captionSmall(context),
                ),
              ],
            )),
          ]),
        ),
        const SizedBox(height: 5),
        ...List.generate(servicos.length - 1, (offset) {
          final index = offset + 1;
          final servico = servicos[index];
          return AppCardRow(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              SizedBox(
                width: 30,
                child: Text('${index + 1}º',
                    style: AppFonts.rowTitle(context)
                        .copyWith(color: AppColors.primaryDark)),
              ),
              Expanded(
                  child: Text(servico.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.caption(context))),
              const SizedBox(width: 8),
              Text(AppUtils.numToMoney(servico.lucro),
                  style: AppFonts.rowValue(context)
                      .copyWith(fontSize: 12, color: AppColors.success)),
            ]),
          );
        }),
      ]),
    );
  }
}
