import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubits/alertas/alertas_cubit.dart';
import '../../../cubits/resumo/resumo_cubit.dart';
import '../../../models/resumo/get_resumo_mensal_response_model.dart';
import '../../../settings/app_colors.dart';
import '../../../settings/app_constants.dart';
import '../../../settings/app_enums.dart';
import '../../../settings/app_extensions.dart';
import '../../../settings/app_fonts.dart';
import '../../../settings/app_media_querys.dart';
import '../../../settings/app_utils.dart';
import '../../components/app_card.dart';
import '../../components/app_dialog.dart';
import '../../components/app_dropdown.dart';
import '../../components/app_error_retry.dart';
import '../../components/app_scaffold.dart';
import '../../components/app_section_label.dart';
import '../../components/app_sub_state_builder.dart';
import '../../components/app_tappable.dart';
import 'widgets/resumo_insights_grid.dart';
import 'widgets/resumo_ranking_widget.dart';
import 'widgets/resumo_saldo_card.dart';

class ResumoScreen extends StatefulWidget {
  const ResumoScreen({super.key});

  @override
  State<ResumoScreen> createState() => _ResumoScreenState();
}

class _ResumoScreenState extends State<ResumoScreen> {
  @override
  void initState() {
    super.initState();
    _fetch();
    BlocProvider.of<AlertasCubit>(context).getAlertas();
  }

  void _fetch({DateTime? periodo}) =>
      BlocProvider.of<ResumoCubit>(context).getResumoMensal(periodo: periodo);

  Future<void> _openPeriodoPicker() async {
    final periodos = AppConstants.periodos(context);

    final selected = await AppDialog.show<DateTime>(
      context: context,
      title: context.l10n.summaryTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: periodos
            .map(
              (periodo) => AppTappable(
                onTap: () =>
                    Navigator.of(context).pop(periodo.value as DateTime),
                borderRadius: BorderRadius.circular(8),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(periodo.key, style: AppFonts.rowTitle(context)),
                ),
              ),
            )
            .toList(),
      ),
    );

    if (selected != null) _fetch(periodo: selected);
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AlertasCubit, AlertasState>(
        buildWhen: (p, c) => p.getAlertasSubState != c.getAlertasSubState,
        builder: (context, alertasState) =>
            BlocBuilder<ResumoCubit, ResumoState>(
          buildWhen: (p, c) =>
              p.getResumoMensalSubState != c.getResumoMensalSubState,
          builder: (context, state) => AppScaffold(
            currentPage: AppCurrentRoute.resumo,
            title: context.l10n.summaryTitle,
            alertCount: alertasState.badgeCount,
            headerTrailing: AppChipSelect(
              label: AppUtils.dateToMonthYear(state.periodo),
              onTap: _openPeriodoPicker,
            ),
            child: AppSubStateBuilder<GetResumoMensalResponseModel>(
              subState: state.getResumoMensalSubState,
              onError: (error) =>
                  AppErrorRetry(message: error.message, onRetry: _fetch),
              onData: (data) => isWideLayout(context)
                  ? _buildWide(context, data)
                  : _buildNarrow(context, data),
            ),
          ),
        ),
      );

  // ── Mobile: tudo empilhado, saldo primeiro ─────────────────────────────────

  Widget _buildNarrow(
    BuildContext context,
    GetResumoMensalResponseModel data,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResumoSaldoCard(resumo: data),
          const SizedBox(height: 16),
          AppSectionLabel(context.l10n.periodInsights),
          const SizedBox(height: 8),
          ResumoInsightsGrid(resumo: data),
          const SizedBox(height: 16),
          AppSectionLabel(context.l10n.mostPerformedServices),
          const SizedBox(height: 8),
          ResumoRankingWidget(
            servicos: data.servicosMaisRealizados,
            maiorReceita: data.maiorReceitaDoRanking,
          ),
          const SizedBox(height: 16),
          _buildBreakdown(context, data),
        ],
      );

  // ── Web: insights em cima, saldo e ranking lado a lado ─────────────────────

  Widget _buildWide(
    BuildContext context,
    GetResumoMensalResponseModel data,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResumoInsightsGrid(resumo: data),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ResumoSaldoCard(resumo: data),
                    const SizedBox(height: 12),
                    _buildBreakdown(context, data),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSectionLabel(context.l10n.mostPerformedServices),
                    const SizedBox(height: 8),
                    ResumoRankingWidget(
                      servicos: data.servicosMaisRealizados,
                      maiorReceita: data.maiorReceitaDoRanking,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );

  /// De onde saiu o dinheiro. Valores com o sinal negativo explícito — ler
  /// "− R$ 1.348,00" numa lista de saídas é menos ambíguo que só a cor.
  Widget _buildBreakdown(
    BuildContext context,
    GetResumoMensalResponseModel data,
  ) =>
      AppCard(
        child: Column(
          children: [
            _BreakdownRow(
              label: context.l10n.fixedCosts,
              value: data.totalCustosFixos,
              isFirst: true,
            ),
            _BreakdownRow(
              label: context.l10n.purchasesAndRestock,
              value: data.totalGastosVariaveis,
            ),
          ],
        ),
      );
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isFirst;

  const _BreakdownRow({
    required this.label,
    required this.value,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) => AppCardRow(
        isFirst: isFirst,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppFonts.caption(context).copyWith(fontSize: 12),
            ),
            Text(
              '− ${AppUtils.numToMoney(value)}',
              style: AppFonts.rowValue(context).copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      );
}
