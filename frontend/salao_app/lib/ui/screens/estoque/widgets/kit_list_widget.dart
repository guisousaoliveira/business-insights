import 'package:flutter/widgets.dart';

import '../../../../models/kits/kit_model.dart';
import '../../../../settings/app_colors.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../components/app_button.dart';
import '../../../components/app_card.dart';

class KitListWidget extends StatelessWidget {
  final List<KitModel> kits;
  final void Function(KitModel kit) onMontar;
  final void Function(KitModel kit) onVender;

  const KitListWidget({
    super.key,
    required this.kits,
    required this.onMontar,
    required this.onVender,
  });

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          children: List.generate(
            kits.length,
            (index) => AppCardRow(
              isFirst: index == 0,
              child: _Row(
                kit: kits[index],
                onMontar: onMontar,
                onVender: onVender,
              ),
            ),
          ),
        ),
      );
}

class _Row extends StatelessWidget {
  final KitModel kit;
  final void Function(KitModel kit) onMontar;
  final void Function(KitModel kit) onVender;

  const _Row({
    required this.kit,
    required this.onMontar,
    required this.onVender,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(kit.nome, style: AppFonts.rowTitle(context)),
                    const SizedBox(height: 2),
                    Text(
                      kit.resumoItens,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.captionSmall(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppUtils.numToMoney(kit.precoVenda),
                style: AppFonts.rowValue(context)
                    .copyWith(color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Os dois saldos juntos: o que está pronto para vender e o que ainda
          // dá para montar. São perguntas diferentes, e ela decide olhando o par.
          Row(
            children: [
              Text(
                context.l10n.assembledQuantity(
                    AppUtils.quantityToString(kit.quantidadeMontada)),
                style: AppFonts.captionSmall(context).copyWith(
                  color: kit.podeVender ? AppColors.success : AppColors.text3,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                context.l10n.assemblableQuantity(
                  AppUtils.quantityToString(kit.quantidadeMontavel),
                ),
                style: AppFonts.captionSmall(context)
                    .copyWith(color: AppColors.text2),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              AppButton(
                label: context.l10n.assembleKit,
                type: AppButtonType.outlined,
                onPressed: () => onMontar(kit),
              ),
              const SizedBox(width: 8),
              AppButton(
                label: context.l10n.sellKit,
                onPressed: kit.podeVender ? () => onVender(kit) : null,
              ),
            ],
          ),
        ],
      );
}
