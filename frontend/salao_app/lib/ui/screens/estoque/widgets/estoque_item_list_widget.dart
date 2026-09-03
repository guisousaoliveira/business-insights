import 'package:flutter/widgets.dart';

import '../../../../models/estoque/item_estoque_model.dart';
import '../../../../settings/app_assets.dart';
import '../../../../settings/app_colors.dart';
import '../../../../settings/app_constants.dart';
import '../../../../settings/app_enums.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../components/app_card.dart';
import '../../../components/app_icon.dart';
import '../../../components/app_tag.dart';
import '../../../components/app_tappable.dart';

class EstoqueItemListWidget extends StatelessWidget {
  final List<ItemEstoqueModel> itens;
  final void Function(ItemEstoqueModel item) onEntrada;
  final void Function(ItemEstoqueModel item) onMovimentacao;

  const EstoqueItemListWidget(
      {super.key,
      required this.itens,
      required this.onEntrada,
      required this.onMovimentacao});

  @override
  Widget build(BuildContext context) => Column(
        children: itens
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ItemCard(
                      item: item,
                      onEntrada: () => onEntrada(item),
                      onMovimentacao: () => onMovimentacao(item)),
                ))
            .toList(),
      );
}

class _ItemCard extends StatelessWidget {
  final ItemEstoqueModel item;
  final VoidCallback onEntrada;
  final VoidCallback onMovimentacao;

  const _ItemCard(
      {required this.item,
      required this.onEntrada,
      required this.onMovimentacao});

  Color get _quantityColor => switch (item.status) {
        StatusEstoque.negativo || StatusEstoque.critico => AppColors.danger,
        StatusEstoque.alerta => AppColors.amber,
        StatusEstoque.ok => AppColors.text1,
      };

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(item.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.rowTitle(context)),
                const SizedBox(height: 3),
                Text(
                  '${AppConstants.categoriaEstoqueLabel(item.categoria)} • ${context.l10n.minimumStock(AppUtils.quantityToString(item.quantidadeMinima), item.unidadeLabel)}',
                  style: AppFonts.captionSmall(context),
                ),
                const SizedBox(height: 9),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  AppTag.statusEstoque(
                      item.status, AppUtils.statusEstoqueToString(item.status)),
                  AppTag.neutral(context.l10n
                      .averageCost(AppUtils.numToMoney(item.custoMedio))),
                  if (item.deficit > 0)
                    AppTag.warning(context.l10n
                        .stockMissing(AppUtils.quantityToString(item.deficit))),
                ]),
              ])),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(AppUtils.quantityToString(item.quantidadeAtual),
                style: AppFonts.metricValue(context)
                    .copyWith(color: _quantityColor)),
            Text(item.unidadeLabel, style: AppFonts.captionSmall(context)),
            const SizedBox(height: 6),
            Row(children: [
              AppTappable(
                onTap: onEntrada,
                minSize: 40,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: const AppIcon(AppAssets.arrowDown,
                    size: 17, color: AppColors.success),
              ),
              AppTappable(
                onTap: onMovimentacao,
                minSize: 40,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: const AppIcon(AppAssets.arrowUp,
                    size: 17, color: AppColors.primaryAccent),
              ),
            ]),
          ]),
        ]),
      );
}
