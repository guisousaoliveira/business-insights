import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubits/alertas/alertas_cubit.dart';
import '../../../cubits/bloc_substate.dart';
import '../../../cubits/gastos/gastos_cubit.dart';
import '../../../models/gastos/gasto_model.dart';
import '../../../models/gastos/get_gastos_response_model.dart';
import '../../../settings/app_enums.dart';
import '../../../settings/app_extensions.dart';
import '../../../settings/app_media_querys.dart';
import '../../../settings/app_utils.dart';
import '../../components/app_dialog.dart';
import '../../components/app_empty_list_warning.dart';
import '../../components/app_error_retry.dart';
import '../../components/app_metric_card.dart';
import '../../components/app_scaffold.dart';
import '../../components/app_section_label.dart';
import '../../components/app_snackbar.dart';
import '../../components/app_sub_state_builder.dart';
import 'dialogs/novo_gasto_dialog.dart';
import 'widgets/gasto_list_widget.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  @override
  void initState() {
    super.initState();
    _fetch();
    BlocProvider.of<AlertasCubit>(context).getAlertas();
  }

  void _fetch() {
    final now = DateTime.now();
    BlocProvider.of<GastosCubit>(context)
        .getGastos(ano: now.year, mes: now.month);
  }

  Future<void> _openNovoGasto() async {
    final reload = await AppDialog.show<bool>(
      context: context,
      title: context.l10n.newExpenseButton,
      child: const NovoGastoDialog(),
    );
    if (reload ?? false) _fetch();
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
              primaryActionLabel: context.l10n.newExpenseButton,
              onPrimaryAction: _openNovoGasto,
              alertCount: alertasState.badgeCount,
              child: AppSubStateBuilder<GetGastosResponseModel>(
                subState: state.getGastosSubState,
                onError: (error) =>
                    AppErrorRetry(message: error.message, onRetry: _fetch),
                onData: (data) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMetrics(context, data),
                    const SizedBox(height: 16),
                    if (isWideLayout(context))
                      _buildWideLists(context, data)
                    else
                      _buildNarrowLists(context, data),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildMetrics(BuildContext context, GetGastosResponseModel data) {
    final pendente = AppMetricCard.danger(
      label: context.l10n.pendingLabel,
      value: AppUtils.numToMoney(data.totalPendente),
    );
    final pago = AppMetricCard.success(
      label: context.l10n.paidThisMonthLabel,
      value: AppUtils.numToMoney(data.totalPagoMes),
    );

    // Na web os cartões têm largura fixa e sobra espaço; no mobile eles dividem
    // a linha igualmente.
    if (isWideLayout(context)) {
      return Row(
        children: [
          SizedBox(width: 220, child: pendente),
          const SizedBox(width: 12),
          SizedBox(width: 220, child: pago),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: pendente),
        const SizedBox(width: 10),
        Expanded(child: pago),
      ],
    );
  }

  Widget _buildNarrowLists(BuildContext context, GetGastosResponseModel data) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionLabel(context.l10n.pendingAndUpcoming),
          const SizedBox(height: 8),
          if (data.pendentes.isEmpty)
            const AppEmptyListWarning()
          else
            GastoListWidget(gastos: data.pendentes, onTogglePago: _pagar),
          const SizedBox(height: 16),
          AppSectionLabel(context.l10n.alreadyPaid),
          const SizedBox(height: 8),
          if (data.pagos.isEmpty)
            const AppEmptyListWarning()
          else
            GastoListWidget(gastos: data.pagos, onTogglePago: _pagar),
        ],
      );

  Widget _buildWideLists(BuildContext context, GetGastosResponseModel data) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSectionLabel(context.l10n.pendingAndUpcoming),
                const SizedBox(height: 8),
                if (data.pendentes.isEmpty)
                  const AppEmptyListWarning()
                else
                  GastoListWidget(gastos: data.pendentes, onTogglePago: _pagar),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSectionLabel(context.l10n.alreadyPaid),
                const SizedBox(height: 8),
                if (data.pagos.isEmpty)
                  const AppEmptyListWarning()
                else
                  GastoListWidget(gastos: data.pagos, onTogglePago: _pagar),
              ],
            ),
          ),
        ],
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
