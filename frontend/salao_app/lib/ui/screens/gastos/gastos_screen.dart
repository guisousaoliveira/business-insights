import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubits/alertas/alertas_cubit.dart';
import '../../../cubits/bloc_substate.dart';
import '../../../cubits/gastos/gastos_cubit.dart';
import '../../../models/gastos/gasto_model.dart';
import '../../../models/gastos/get_gastos_response_model.dart';
import '../../../settings/app_colors.dart';
import '../../../settings/app_enums.dart';
import '../../../settings/app_fonts.dart';
import '../../../settings/app_extensions.dart';
import '../../../settings/app_utils.dart';
import '../../components/app_dialog.dart';
import '../../components/app_empty_list_warning.dart';
import '../../components/app_error_retry.dart';
import '../../components/app_metric_card.dart';
import '../../components/app_scaffold.dart';
import '../../components/app_segmented_control.dart';
import '../../components/app_section_label.dart';
import '../../components/app_snackbar.dart';
import '../../components/app_sub_state_builder.dart';
import '../../components/app_tappable.dart';
import 'dialogs/novo_gasto_dialog.dart';
import 'widgets/gasto_list_widget.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _FilterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FilterButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => AppTappable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(label, style: AppFonts.caption(context)),
        ),
      );
}

class _GastosScreenState extends State<GastosScreen> {
  DateTime _periodo = DateTime(DateTime.now().year, DateTime.now().month);
  FiltroSituacaoGasto _situacao = FiltroSituacaoGasto.todos;
  CategoriaGasto? _categoria;

  @override
  void initState() {
    super.initState();
    _fetch();
    BlocProvider.of<AlertasCubit>(context).getAlertas();
  }

  void _fetch() {
    BlocProvider.of<GastosCubit>(context)
        .getGastos(ano: _periodo.year, mes: _periodo.month);
  }

  Future<void> _openNovoGasto() async {
    final reload = await AppDialog.show<bool>(
      context: context,
      title: context.l10n.newExpenseButton,
      child: const NovoGastoDialog(),
    );
    if (reload ?? false) _fetch();
  }

  Future<void> _openEditarGasto(GastoModel gasto) async {
    final reload = await AppDialog.show<bool>(
      context: context,
      title: context.l10n.editExpenseTitle,
      child: NovoGastoDialog(gasto: gasto),
    );
    if (reload ?? false) _fetch();
  }

  Future<void> _delete(GastoModel gasto) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: context.l10n.deleteExpense,
      message: context.l10n.deleteExpenseQuestion(gasto.nome),
    );
    if (confirmed && mounted) {
      BlocProvider.of<GastosCubit>(context).deleteGasto(gasto.id);
    }
  }

  void _pagar(GastoModel gasto) =>
      BlocProvider.of<GastosCubit>(context).pagarGasto(gasto.id);

  @override
  Widget build(BuildContext context) => MultiBlocListener(
        listeners: [
          BlocListener<GastosCubit, GastosState>(
            listenWhen: (p, c) =>
                p.createGastoSubState != c.createGastoSubState,
            listener: (context, state) =>
                _handleWrite(context, state.createGastoSubState),
          ),
          BlocListener<GastosCubit, GastosState>(
            listenWhen: (p, c) => p.editGastoSubState != c.editGastoSubState,
            listener: (context, state) =>
                _handleWrite(context, state.editGastoSubState),
          ),
          BlocListener<GastosCubit, GastosState>(
            listenWhen: (p, c) =>
                p.deleteGastoSubState != c.deleteGastoSubState,
            listener: (context, state) =>
                _handleWrite(context, state.deleteGastoSubState),
          ),
          BlocListener<GastosCubit, GastosState>(
            listenWhen: (p, c) => p.pagarGastoSubState != c.pagarGastoSubState,
            listener: (context, state) =>
                _handleWrite(context, state.pagarGastoSubState),
          ),
        ],
        child: BlocBuilder<AlertasCubit, AlertasState>(
          buildWhen: (p, c) => p.badgeCount != c.badgeCount,
          builder: (context, alertasState) =>
              BlocBuilder<GastosCubit, GastosState>(
            buildWhen: (p, c) => p.getGastosSubState != c.getGastosSubState,
            builder: (context, state) => AppScaffold(
              currentPage: AppCurrentRoute.gastos,
              title: context.l10n.expensesTitle,
              subtitle: context.l10n.expensesSubtitle(
                AppUtils.dateToMonthName(_periodo),
              ),
              primaryActionLabel: context.l10n.newExpenseButton,
              onPrimaryAction: _openNovoGasto,
              alertCount: alertasState.badgeCount,
              child: AppSubStateBuilder<GetGastosResponseModel>(
                subState: state.getGastosSubState,
                onError: (error) =>
                    AppErrorRetry(message: error.message, onRetry: _fetch),
                onData: (data) => _buildBody(context, data),
              ),
            ),
          ),
        ),
      );

  Widget _buildMetrics(BuildContext context, GetGastosResponseModel data) {
    final total = data.gastos.fold<double>(0, (sum, item) => sum + item.valor);
    final vencido = data.gastos
        .where((item) => item.isVencido)
        .fold<double>(0, (sum, item) => sum + item.valor);
    final cards = [
      AppMetricCard.neutral(
        label: context.l10n.totalInPeriod,
        value: AppUtils.numToMoney(total),
      ),
      AppMetricCard.success(
        label: context.l10n.paidThisMonthLabel,
        value: AppUtils.numToMoney(data.totalPagoMes),
      ),
      AppMetricCard.warning(
        label: context.l10n.pendingLabel,
        value: AppUtils.numToMoney(data.totalPendente),
      ),
      AppMetricCard.danger(
        label: context.l10n.overdueTotal,
        value: AppUtils.numToMoney(vencido),
      ),
    ];

    return Column(
      children: [
        Row(children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 10),
          Expanded(child: cards[1]),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: cards[2]),
          const SizedBox(width: 10),
          Expanded(child: cards[3]),
        ]),
      ],
    );
  }

  Widget _buildBody(BuildContext context, GetGastosResponseModel data) {
    final lista = data.gastos.where((gasto) {
      final statusOk = switch (_situacao) {
        FiltroSituacaoGasto.todos => true,
        FiltroSituacaoGasto.pendentes => !gasto.pago && !gasto.isVencido,
        FiltroSituacaoGasto.pagos => gasto.pago,
        FiltroSituacaoGasto.vencidos => gasto.isVencido,
      };
      return statusOk && (_categoria == null || gasto.categoria == _categoria);
    }).toList()
      ..sort((a, b) => b.prazoPagamento.compareTo(a.prazoPagamento));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMetrics(context, data),
        const SizedBox(height: 16),
        AppSegmentedControl<FiltroSituacaoGasto>(
          value: _situacao,
          segments: [
            AppSegment(FiltroSituacaoGasto.todos, context.l10n.allExpenses),
            AppSegment(
                FiltroSituacaoGasto.pendentes, context.l10n.pendingExpenses),
            AppSegment(FiltroSituacaoGasto.pagos, context.l10n.paidExpenses),
            AppSegment(
                FiltroSituacaoGasto.vencidos, context.l10n.overdueExpenses),
          ],
          onChanged: (value) => setState(() => _situacao = value),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterButton(
              label: _categoria == null
                  ? context.l10n.categoryLabel
                  : AppUtils.categoriaGastoToString(_categoria!),
              onTap: _selectCategoria,
            ),
            _FilterButton(
              label: AppUtils.dateToMonthName(_periodo),
              onTap: _selectMonth,
            ),
            _FilterButton(label: '${_periodo.year}', onTap: _selectYear),
          ],
        ),
        const SizedBox(height: 16),
        AppSectionLabel(
          context.l10n.entriesTitle,
          trailing: Text(
            context.l10n.entriesCount(lista.length),
            style: AppFonts.captionSmall(context),
          ),
        ),
        const SizedBox(height: 8),
        if (lista.isEmpty)
          const AppEmptyListWarning()
        else
          GastoListWidget(
            gastos: lista,
            onTogglePago: _pagar,
            onEdit: _openEditarGasto,
            onDelete: _delete,
          ),
      ],
    );
  }

  Future<void> _selectCategoria() async {
    final selected = await _showOptions<CategoriaGasto?>([
      MapEntry(null, context.l10n.allLabel),
      ...CategoriaGasto.values.map(
        (value) => MapEntry(value, AppUtils.categoriaGastoToString(value)),
      ),
    ]);
    if (mounted) setState(() => _categoria = selected);
  }

  Future<void> _selectMonth() async {
    final selected = await _showOptions<int>(List.generate(
      12,
      (index) => MapEntry(
        index + 1,
        AppUtils.dateToMonthName(DateTime(2024, index + 1)),
      ),
    ));
    if (selected != null && mounted) {
      setState(() => _periodo = DateTime(_periodo.year, selected));
      _fetch();
    }
  }

  Future<void> _selectYear() async {
    final now = DateTime.now().year;
    final selected = await _showOptions<int>([
      MapEntry(now - 1, '${now - 1}'),
      MapEntry(now, '$now'),
    ]);
    if (selected != null && mounted) {
      setState(() => _periodo = DateTime(selected, _periodo.month));
      _fetch();
    }
  }

  Future<T?> _showOptions<T>(List<MapEntry<T, String>> options) =>
      AppDialog.show<T>(
        context: context,
        title: context.l10n.expensesTitle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map((option) => AppTappable(
                    onTap: () => Navigator.of(context).pop(option.key),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child:
                          Text(option.value, style: AppFonts.rowTitle(context)),
                    ),
                  ))
              .toList(),
        ),
      );

  void _handleWrite(BuildContext context, BlocSubState subState) {
    if (!subState.isCompleted) return;

    if (subState.hasError) {
      AppSnackBar.showSnackbar(
        context,
        subState.error!.message,
        SnackBarStatus.error,
      );
      return;
    }

    _fetch();
    BlocProvider.of<AlertasCubit>(context).getAlertas();
  }
}
