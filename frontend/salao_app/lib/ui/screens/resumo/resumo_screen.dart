import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubits/alertas/alertas_cubit.dart';
import '../../../cubits/estoque/estoque_cubit.dart';
import '../../../cubits/gastos/gastos_cubit.dart';
import '../../../cubits/resumo/resumo_cubit.dart';
import '../../../models/alertas/alerta_model.dart';
import '../../../models/alertas/get_alertas_response_model.dart';
import '../../../models/auth/usuario_model.dart';
import '../../../models/estoque/get_estoque_itens_response_model.dart';
import '../../../models/gastos/get_gastos_response_model.dart';
import '../../../models/resumo/get_resumo_mensal_response_model.dart';
import '../../../settings/app_assets.dart';
import '../../../settings/app_colors.dart';
import '../../../settings/app_enums.dart';
import '../../../settings/app_extensions.dart';
import '../../../settings/app_fonts.dart';
import '../../../settings/app_media_querys.dart';
import '../../../settings/app_routes.dart';
import '../../../settings/app_storage.dart';
import '../../../settings/app_utils.dart';
import '../../components/app_alert_banner.dart';
import '../../components/app_dialog.dart';
import '../../components/app_error_retry.dart';
import '../../components/app_icon.dart';
import '../../components/app_scaffold.dart';
import '../../components/app_sub_state_builder.dart';
import '../../components/app_tappable.dart';
import 'widgets/resumo_insights_grid.dart';
import 'widgets/resumo_ranking_widget.dart';
import 'widgets/resumo_saldo_card.dart';
import 'widgets/resumo_sections.dart';

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
    BlocProvider.of<EstoqueCubit>(context).getItens();
  }

  void _fetch({DateTime? periodo}) {
    final target =
        periodo ?? BlocProvider.of<ResumoCubit>(context).state.periodo;
    BlocProvider.of<ResumoCubit>(context).getResumoMensal(periodo: target);
    BlocProvider.of<GastosCubit>(context)
        .getGastos(ano: target.year, mes: target.month);
  }

  Future<void> _selectMonth(DateTime current) async {
    final selected = await _showOptions<int>(List.generate(12, (index) {
      final month = index + 1;
      return MapEntry(
        month,
        AppUtils.dateToMonthName(DateTime(current.year, month)),
      );
    }));
    if (selected != null) _fetch(periodo: DateTime(current.year, selected));
  }

  Future<void> _selectYear(DateTime current) async {
    final now = DateTime.now().year;
    final selected = await _showOptions<int>(
      List.generate(6, (index) => MapEntry(now - index, '${now - index}')),
    );
    if (selected != null) _fetch(periodo: DateTime(selected, current.month));
  }

  Future<T?> _showOptions<T>(List<MapEntry<T, String>> options) =>
      AppDialog.show<T>(
        context: context,
        title: context.l10n.summaryTitle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map((option) => AppTappable(
                    onTap: () => Navigator.of(context).pop(option.key),
                    borderRadius: BorderRadius.circular(10),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        option.value,
                        style: AppFonts.rowTitle(context),
                      ),
                    ),
                  ))
              .toList(),
        ),
      );

  String get _firstName {
    final stored =
        AppStorage.read<Map<String, dynamic>>(AppStorage.userInfoKey);
    final name =
        stored == null ? '' : UsuarioModel.fromStorage(stored).nome.trim();
    return name.isEmpty
        ? context.l10n.userFallbackName
        : name.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AlertasCubit, AlertasState>(
        builder: (context, alertasState) =>
            BlocBuilder<ResumoCubit, ResumoState>(
          buildWhen: (p, c) =>
              p.getResumoMensalSubState != c.getResumoMensalSubState,
          builder: (context, resumoState) =>
              BlocBuilder<GastosCubit, GastosState>(
            buildWhen: (p, c) => p.getGastosSubState != c.getGastosSubState,
            builder: (context, gastosState) =>
                BlocBuilder<EstoqueCubit, EstoqueState>(
              buildWhen: (p, c) => p.getItensSubState != c.getItensSubState,
              builder: (context, estoqueState) {
                final periodo = resumoState.periodo;
                return AppScaffold(
                  currentPage: AppCurrentRoute.resumo,
                  title: context.l10n.summaryTitle,
                  alertCount: alertasState.badgeCount,
                  primaryActionLabel: context.l10n.scheduleAppointmentLong,
                  onPrimaryAction: () =>
                      AppRoutes.replace(AppRoutes.atendimentosRoute),
                  narrowHeaderLeading: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const AppIcon(
                      AppAssets.sparkles,
                      size: 18,
                      color: AppColors.white,
                    ),
                  ),
                  narrowHeaderTitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.helloUser(_firstName),
                        style: AppFonts.pageTitle(context),
                      ),
                      Text(
                        context.l10n.summaryOfPeriod(
                          AppUtils.dateToMonthYearLong(periodo),
                        ),
                        style: AppFonts.captionSmall(context),
                      ),
                    ],
                  ),
                  wideHeaderTitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.helloUser(_firstName),
                        style: AppFonts.pageTitle(context),
                      ),
                      Text(
                        context.l10n.summaryOfPeriod(
                          AppUtils.dateToMonthYearLong(periodo),
                        ),
                        style: AppFonts.captionSmall(context),
                      ),
                    ],
                  ),
                  child: AppSubStateBuilder<GetResumoMensalResponseModel>(
                    subState: resumoState.getResumoMensalSubState,
                    onError: (error) => AppErrorRetry(
                      message: error.message,
                      onRetry: _fetch,
                    ),
                    onData: (resumo) => _Dashboard(
                      resumo: resumo,
                      periodo: periodo,
                      alerta: alertasState.getAlertasSubState
                          .value<GetAlertasResponseModel>()
                          ?.alertas
                          .where((item) => !item.isLido)
                          .firstOrNull,
                      gastos: gastosState.getGastosSubState
                          .value<GetGastosResponseModel>(),
                      estoque: estoqueState.getItensSubState
                          .value<GetEstoqueItensResponseModel>(),
                      onMonth: () => _selectMonth(periodo),
                      onYear: () => _selectYear(periodo),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
}

class _Dashboard extends StatelessWidget {
  final GetResumoMensalResponseModel resumo;
  final DateTime periodo;
  final AlertaModel? alerta;
  final GetGastosResponseModel? gastos;
  final GetEstoqueItensResponseModel? estoque;
  final VoidCallback onMonth;
  final VoidCallback onYear;

  const _Dashboard({
    required this.resumo,
    required this.periodo,
    required this.alerta,
    required this.gastos,
    required this.estoque,
    required this.onMonth,
    required this.onYear,
  });

  @override
  Widget build(BuildContext context) {
    final emAlerta = estoque?.emAlerta ?? const [];
    final wide = isWideLayout(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: wide ? 1100 : 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (alerta != null) ...[
              AppAlertBanner(
                title: alerta!.titulo,
                message: alerta!.mensagem,
                onTap: () => AppRoutes.push(AppRoutes.alertasRoute),
              ),
              const SizedBox(height: 16),
            ],
            Row(children: [
              SizedBox(
                width: wide ? 150 : null,
                child: wide
                    ? _PeriodButton(
                        label: AppUtils.dateToMonthName(periodo),
                        onTap: onMonth,
                      )
                    : null,
              ),
              if (!wide)
                Expanded(
                  child: _PeriodButton(
                    label: AppUtils.dateToMonthName(periodo),
                    onTap: onMonth,
                  ),
                ),
              const SizedBox(width: 10),
              SizedBox(
                width: wide ? 110 : null,
                child: wide
                    ? _PeriodButton(label: '${periodo.year}', onTap: onYear)
                    : null,
              ),
              if (!wide)
                Expanded(
                  child: _PeriodButton(label: '${periodo.year}', onTap: onYear),
                ),
            ]),
            const SizedBox(height: 16),
            ResumoSaldoCard(resumo: resumo),
            const SizedBox(height: 16),
            ResumoInsightsGrid(resumo: resumo),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: _QuickAction(
                label: context.l10n.scheduleAppointmentLong,
                icon: AppAssets.atendimentos,
                onTap: () => AppRoutes.replace(AppRoutes.atendimentosRoute),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _QuickAction(
                label: context.l10n.newExpenseButton,
                icon: AppAssets.receipt,
                onTap: () => AppRoutes.replace(AppRoutes.gastosRoute),
              )),
            ]),
            const SizedBox(height: 16),
            ResumoHistoryCard(historico: resumo.historicoSeisMeses),
            const SizedBox(height: 16),
            if (wide)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: Column(children: [
                  _ranking(context),
                  const SizedBox(height: 16),
                  ResumoKnowledgeCard(
                      resumo: resumo, restockCount: emAlerta.length),
                ])),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(children: [
                  ResumoUpcomingExpensesCard(
                    gastos: gastos?.gastos ?? const [],
                    onViewAll: () => AppRoutes.replace(AppRoutes.gastosRoute),
                  ),
                  if (emAlerta.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ResumoRestockCard(
                      itens: emAlerta,
                      onViewStock: () =>
                          AppRoutes.replace(AppRoutes.estoqueRoute),
                    ),
                  ],
                ])),
              ])
            else ...[
              _ranking(context),
              const SizedBox(height: 16),
              ResumoKnowledgeCard(
                  resumo: resumo, restockCount: emAlerta.length),
              const SizedBox(height: 16),
              ResumoUpcomingExpensesCard(
                gastos: gastos?.gastos ?? const [],
                onViewAll: () => AppRoutes.replace(AppRoutes.gastosRoute),
              ),
              if (emAlerta.isNotEmpty) ...[
                const SizedBox(height: 16),
                ResumoRestockCard(
                  itens: emAlerta,
                  onViewStock: () => AppRoutes.replace(AppRoutes.estoqueRoute),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _ranking(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.mostProfitableService,
              style: AppFonts.sectionTitle(context)),
          const SizedBox(height: 8),
          ResumoRankingWidget(
            servicos: resumo.servicosMaisRealizados,
            maiorReceita: resumo.maiorReceitaDoRanking,
          ),
        ],
      );
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PeriodButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => AppTappable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(children: [
            Expanded(child: Text(label, style: AppFonts.rowTitle(context))),
            const AppIcon(AppAssets.chevronDown, size: 16),
          ]),
        ),
      );
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool showAdd;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.label,
      required this.icon,
      required this.onTap,
      this.showAdd = false});

  @override
  Widget build(BuildContext context) => AppTappable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.accentTint,
                shape: BoxShape.circle,
              ),
              child: AppIcon(
                icon,
                size: 17,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AppFonts.rowTitle(context),
              ),
            ),
            if (showAdd)
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const AppIcon(
                  AppAssets.add,
                  size: 25,
                  color: AppColors.white,
                ),
              ),
          ]),
        ),
      );
}
