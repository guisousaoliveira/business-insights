import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../models/estoque/item_estoque_model.dart';
import '../../../../models/gastos/gasto_model.dart';
import '../../../../models/resumo/get_resumo_mensal_response_model.dart';
import '../../../../models/resumo/resumo_historico_model.dart';
import '../../../../settings/app_assets.dart';
import '../../../../settings/app_colors.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../components/app_card.dart';
import '../../../components/app_icon.dart';
import '../../../components/app_tag.dart';
import '../../../components/app_tappable.dart';

class ResumoHistoryCard extends StatefulWidget {
  final List<ResumoHistoricoModel> historico;

  const ResumoHistoryCard({super.key, required this.historico});

  @override
  State<ResumoHistoryCard> createState() => _ResumoHistoryCardState();
}

class _ResumoHistoryCardState extends State<ResumoHistoryCard> {
  int? _highlightedIndex;

  @override
  Widget build(BuildContext context) {
    final maior = widget.historico.fold<double>(
      1,
      (value, item) => math.max(value, math.max(item.receitas, item.despesas)),
    );

    return AppCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.revenuesAndExpenses,
              style: AppFonts.sectionTitle(context).copyWith(fontSize: 18)),
          Text(context.l10n.lastSixMonths, style: AppFonts.caption(context)),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(widget.historico.length, (index) {
                final item = widget.historico[index];
                final selected = _highlightedIndex == index;
                return Expanded(
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _highlightedIndex = index),
                    onExit: (_) => setState(() => _highlightedIndex = null),
                    child: AppTappable(
                      minSize: 0,
                      padding: EdgeInsets.zero,
                      onTap: () => setState(
                          () => _highlightedIndex = selected ? null : index),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 145,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.bottomCenter,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _Bar(
                                      height: 145 * item.receitas / maior,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 3),
                                    _Bar(
                                      height: 145 * item.despesas / maior,
                                      color: AppColors.primaryLight,
                                    ),
                                  ],
                                ),
                                if (selected)
                                  Positioned(
                                    bottom: 12,
                                    child: _ChartTooltip(
                                      key: ValueKey('chart-tooltip-$index'),
                                      item: item,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            AppUtils.dateToMonthShort(
                              DateTime(item.ano, item.mes),
                            ),
                            style: AppFonts.captionSmall(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(
                  color: AppColors.primary, label: context.l10n.revenuesLabel),
              const SizedBox(width: 14),
              _Legend(
                  color: AppColors.primaryLight,
                  label: context.l10n.expensesLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartTooltip extends StatelessWidget {
  final ResumoHistoricoModel item;
  const _ChartTooltip({super.key, required this.item});

  @override
  Widget build(BuildContext context) => Container(
        width: 150,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppUtils.dateToMonthShort(DateTime(item.ano, item.mes)),
              style: AppFonts.rowTitle(context),
            ),
            const SizedBox(height: 5),
            Text(
              '${context.l10n.revenuesLabel}: ${AppUtils.numToMoney(item.receitas)}',
              style: AppFonts.captionSmall(context)
                  .copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 3),
            Text(
              '${context.l10n.expensesLabel}: ${AppUtils.numToMoney(item.despesas)}',
              style: AppFonts.captionSmall(context),
            ),
          ],
        ),
      );
}

class _Bar extends StatelessWidget {
  final double height;
  final Color color;
  const _Bar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: math.max(2, height),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label, style: AppFonts.captionSmall(context)),
        ],
      );
}

class ResumoKnowledgeCard extends StatelessWidget {
  final GetResumoMensalResponseModel resumo;
  final int restockCount;

  const ResumoKnowledgeCard({
    super.key,
    required this.resumo,
    required this.restockCount,
  });

  @override
  Widget build(BuildContext context) {
    final meta = resumo.metaFaturamentoMensal;
    final percentual = meta <= 0 ? 0 : resumo.entrou / meta * 100;
    return AppCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.forYouToKnow,
              style: AppFonts.sectionTitle(context).copyWith(fontSize: 18)),
          Text(context.l10n.generatedFromYourNumbers,
              style: AppFonts.caption(context)),
          const SizedBox(height: 12),
          if (resumo.servicoMaisLucrativo != null)
            _KnowledgeRow(
              text: context.l10n.mostProfitableInsight(
                resumo.servicoMaisLucrativo!,
              ),
            ),
          _KnowledgeRow(
              text: context.l10n.restockProductsInsight(restockCount)),
          if (meta > 0)
            _KnowledgeRow(
              text: context.l10n.revenueGoalInsight(
                percentual.toStringAsFixed(0),
                AppUtils.numToMoney(meta),
              ),
            ),
        ],
      ),
    );
  }
}

class _KnowledgeRow extends StatelessWidget {
  final String text;
  const _KnowledgeRow({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppIcon(AppAssets.lightbulb,
                size: 17, color: AppColors.primaryAccent),
            const SizedBox(width: 9),
            Expanded(child: Text(text, style: AppFonts.caption(context))),
          ],
        ),
      );
}

class ResumoUpcomingExpensesCard extends StatelessWidget {
  final List<GastoModel> gastos;
  final VoidCallback onViewAll;

  const ResumoUpcomingExpensesCard({
    super.key,
    required this.gastos,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final items = gastos.where((e) => !e.pago).toList()
      ..sort((a, b) => a.venceEmDias.compareTo(b.venceEmDias));
    if (items.isEmpty) return const SizedBox.shrink();
    return AppCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SectionHeader(
              title: context.l10n.upcomingExpenses,
              action: context.l10n.viewAll,
              onTap: onViewAll),
          const SizedBox(height: 10),
          ...items.take(3).map((gasto) => AppCardRow(
                isFirst: gasto == items.first,
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  children: [
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(gasto.nome, style: AppFonts.rowTitle(context)),
                        Text(
                            context.l10n.dueOn(
                                AppUtils.dateToFull(gasto.prazoPagamento)),
                            style: AppFonts.captionSmall(context)),
                      ],
                    )),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(AppUtils.numToMoney(gasto.valor),
                              style: AppFonts.rowValue(context)),
                          const SizedBox(height: 4),
                          gasto.isVencido
                              ? AppTag.danger(context.l10n.overdueLabel)
                              : AppTag.warning(context.l10n.pendingLabel),
                        ]),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class ResumoRestockCard extends StatelessWidget {
  final List<ItemEstoqueModel> itens;
  final VoidCallback onViewStock;
  const ResumoRestockCard(
      {super.key, required this.itens, required this.onViewStock});

  @override
  Widget build(BuildContext context) {
    if (itens.isEmpty) return const SizedBox.shrink();
    return AppCard.tinted(
      background: AppColors.amberLight,
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _SectionHeader(
            title: context.l10n.stockToRestock,
            action: context.l10n.viewStock,
            onTap: onViewStock),
        const SizedBox(height: 10),
        ...itens.take(4).map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                const AppIcon(AppAssets.box, size: 16, color: AppColors.amber),
                const SizedBox(width: 9),
                Expanded(
                    child: Text(item.nome, style: AppFonts.caption(context))),
                Text(
                    '${AppUtils.quantityToString(item.quantidadeAtual)} ${item.unidadeLabel}',
                    style: AppFonts.captionSmall(context)
                        .copyWith(color: AppColors.amber)),
              ]),
            )),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onTap;
  const _SectionHeader(
      {required this.title, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Text(title,
                style: AppFonts.sectionTitle(context).copyWith(fontSize: 18))),
        AppTappable(
            onTap: onTap,
            minSize: 32,
            child: Text(action,
                style: AppFonts.caption(context)
                    .copyWith(color: AppColors.primaryAccent))),
      ]);
}
