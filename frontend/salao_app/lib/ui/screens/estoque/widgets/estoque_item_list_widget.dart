import 'package:flutter/widgets.dart';

import '../../../../models/estoque/item_estoque_model.dart';
import '../../../../settings/app_assets.dart';
import '../../../../settings/app_colors.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../components/app_card.dart';
import '../../../components/app_icon.dart';
import '../../../components/app_tag.dart';
import '../../../components/app_tappable.dart';

/// Lista de itens do estoque.
///
/// Em alerta, a linha termina com a **tag de severidade** (crítico/alerta);
/// no bloco "ok", termina com o **+** que registra entrada. É a mesma linha com
/// finais diferentes, porque a ação útil muda com o estado do item.
class EstoqueItemListWidget extends StatelessWidget {
  final List<ItemEstoqueModel> itens;
  final bool showStatusTag;
  final void Function(ItemEstoqueModel item) onEntrada;

  const EstoqueItemListWidget({
    super.key,
    required this.itens,
    required this.onEntrada,
    this.showStatusTag = false,
  });

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          children: List.generate(
            itens.length,
            (index) => _Row(
              item: itens[index],
              isFirst: index == 0,
              showStatusTag: showStatusTag,
              onEntrada: () => onEntrada(itens[index]),
            ),
          ),
        ),
      );
}

class _Row extends StatelessWidget {
  final ItemEstoqueModel item;
  final bool isFirst;
  final bool showStatusTag;
  final VoidCallback onEntrada;

  const _Row({
    required this.item,
    required this.isFirst,
    required this.showStatusTag,
    required this.onEntrada,
  });

  String _subtitle(BuildContext context) {
    final quantidade = context.l10n.currentQuantity(
      AppUtils.quantityToString(item.quantidadeAtual),
      item.unidadeLabel,
    );

    // O custo só aparece onde ajuda a decidir a compra — nos itens em alerta.
    if (!showStatusTag) return quantidade;
    return '$quantidade (${context.l10n.unitCost(AppUtils.numToMoney(item.custoMedio))})';
  }

  @override
  Widget build(BuildContext context) => AppCardRow(
        isFirst: isFirst,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.nome, style: AppFonts.rowTitle(context)),
                  const SizedBox(height: 2),
                  Text(_subtitle(context), style: AppFonts.caption(context)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (showStatusTag)
              AppTag.statusEstoque(
                item.status,
                AppUtils.statusEstoqueToString(item.status),
              )
            else
              AppTappable(
                onTap: onEntrada,
                minSize: 40,
                borderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: const AppIcon(
                  AppAssets.add,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      );
}
