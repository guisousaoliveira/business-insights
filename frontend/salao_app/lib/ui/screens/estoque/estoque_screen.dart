import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubits/alertas/alertas_cubit.dart';
import '../../../cubits/bloc_substate.dart';
import '../../../cubits/estoque/estoque_cubit.dart';
import '../../../cubits/kits/kits_cubit.dart';
import '../../../models/estoque/get_estoque_itens_response_model.dart';
import '../../../models/estoque/item_estoque_model.dart';
import '../../../models/kits/get_kits_response_model.dart';
import '../../../models/kits/kit_model.dart';
import '../../../settings/app_assets.dart';
import '../../../settings/app_colors.dart';
import '../../../settings/app_enums.dart';
import '../../../settings/app_error_codes.dart';
import '../../../settings/app_extensions.dart';
import '../../../settings/app_utils.dart';
import '../../components/app_dialog.dart';
import '../../components/app_empty_list_warning.dart';
import '../../components/app_error_retry.dart';
import '../../components/app_metric_card.dart';
import '../../components/app_scaffold.dart';
import '../../components/app_section_label.dart';
import '../../components/app_snackbar.dart';
import '../../components/app_sub_state_builder.dart';
import 'dialogs/entrada_estoque_dialog.dart';
import 'dialogs/historico_estoque_dialog.dart';
import 'dialogs/montar_kit_dialog.dart';
import 'dialogs/novo_item_dialog.dart';
import 'dialogs/vender_kit_dialog.dart';
import 'widgets/estoque_item_list_widget.dart';
import 'widgets/kit_list_widget.dart';

class EstoqueScreen extends StatefulWidget {
  const EstoqueScreen({super.key});

  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  @override
  void initState() {
    super.initState();
    _fetch();
    BlocProvider.of<KitsCubit>(context).getKits();
    BlocProvider.of<AlertasCubit>(context).getAlertas();
  }

  void _fetch() => BlocProvider.of<EstoqueCubit>(context).getItens();

  Future<void> _openNovoItem() async {
    final reload = await AppDialog.show<bool>(
      context: context,
      title: context.l10n.newItemButton,
      child: const NovoItemDialog(),
    );
    if (reload ?? false) _fetch();
  }

  Future<void> _openEntrada(ItemEstoqueModel item) async {
    final reload = await AppDialog.show<bool>(
      context: context,
      title: context.l10n.stockEntryTitle,
      child: EntradaEstoqueDialog(item: item),
    );
    if (reload ?? false) _fetch();
  }

  Future<void> _openMontarKit(KitModel kit) async {
    final reload = await AppDialog.show<bool>(
      context: context,
      title: context.l10n.assembleKitTitle,
      child: MontarKitDialog(kit: kit),
    );
    // Montar consome insumo: recarrega o estoque junto com os kits.
    if (reload ?? false) _fetchKits(alsoEstoque: true);
  }

  Future<void> _openVenderKit(KitModel kit) async {
    final reload = await AppDialog.show<bool>(
      context: context,
      title: context.l10n.sellKitTitle,
      child: VenderKitDialog(kit: kit),
    );
    if (reload ?? false) _fetchKits();
  }

  void _fetchKits({bool alsoEstoque = false}) {
    BlocProvider.of<KitsCubit>(context).getKits();
    if (alsoEstoque) _fetch();
  }

  void _openHistorico() {
    BlocProvider.of<EstoqueCubit>(context).getMovimentacoes();
    AppDialog.show<void>(
      context: context,
      title: context.l10n.stockHistory,
      child: const HistoricoEstoqueDialog(),
    );
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
        listeners: [
          BlocListener<EstoqueCubit, EstoqueState>(
            listenWhen: (p, c) => p.createItemSubState != c.createItemSubState,
            listener: (context, state) =>
                _handleWrite(context, state.createItemSubState),
          ),
          BlocListener<EstoqueCubit, EstoqueState>(
            listenWhen: (p, c) =>
                p.createMovimentacaoSubState != c.createMovimentacaoSubState,
            listener: (context, state) =>
                _handleWrite(context, state.createMovimentacaoSubState),
          ),
          BlocListener<KitsCubit, KitsState>(
            listenWhen: (p, c) => p.montarKitSubState != c.montarKitSubState,
            listener: (context, state) =>
                _handleKitWrite(context, state.montarKitSubState),
          ),
          BlocListener<KitsCubit, KitsState>(
            listenWhen: (p, c) => p.venderKitSubState != c.venderKitSubState,
            listener: (context, state) =>
                _handleKitWrite(context, state.venderKitSubState),
          ),
        ],
        child: BlocBuilder<AlertasCubit, AlertasState>(
          buildWhen: (p, c) => p.badgeCount != c.badgeCount,
          builder: (context, alertasState) =>
              BlocBuilder<EstoqueCubit, EstoqueState>(
            buildWhen: (p, c) => p.getItensSubState != c.getItensSubState,
            builder: (context, state) => AppScaffold(
              currentPage: AppCurrentRoute.estoque,
              title: context.l10n.stockTitle,
              subtitle: context.l10n.stockSubtitle,
              primaryActionLabel: context.l10n.newItemButton,
              onPrimaryAction: _openNovoItem,
              trailingIcon: AppAssets.history,
              onTrailingAction: _openHistorico,
              alertCount: alertasState.badgeCount,
              child: AppSubStateBuilder<GetEstoqueItensResponseModel>(
                subState: state.getItensSubState,
                onError: (error) =>
                    AppErrorRetry(message: error.message, onRetry: _fetch),
                onData: (data) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMetrics(context, data),
                    const SizedBox(height: 16),
                    _buildListas(context, data),
                    const SizedBox(height: 16),
                    AppSectionLabel(context.l10n.resaleKits),
                    const SizedBox(height: 8),
                    _buildKits(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildMetrics(
    BuildContext context,
    GetEstoqueItensResponseModel data,
  ) {
    final alertas = AppMetricCard.danger(
      label: context.l10n.itemsInAlert,
      value: '${data.totalAlertas}',
    );
    // Valor em estoque é patrimônio, não resultado — por isso roxo, não verde.
    final valor = AppMetricCard.neutral(
      label: context.l10n.stockValue,
      value: AppUtils.numToMoney(data.valorTotal),
    );

    return Row(
      children: [
        Expanded(child: alertas),
        const SizedBox(width: 10),
        Expanded(child: valor),
      ],
    );
  }

  Widget _buildListas(
    BuildContext context,
    GetEstoqueItensResponseModel data,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAlertaSection(context, data),
          const SizedBox(height: 16),
          _buildOkSection(context, data),
        ],
      );

  Widget _buildAlertaSection(
    BuildContext context,
    GetEstoqueItensResponseModel data,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionLabel(
            context.l10n.needRestock(data.emAlerta.length),
            color: AppColors.danger,
          ),
          const SizedBox(height: 8),
          if (data.emAlerta.isEmpty)
            const AppEmptyListWarning()
          else
            EstoqueItemListWidget(
              itens: data.emAlerta,
              showStatusTag: true,
              onEntrada: _openEntrada,
            ),
        ],
      );

  Widget _buildOkSection(
    BuildContext context,
    GetEstoqueItensResponseModel data,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionLabel(
            context.l10n.stockOk(data.emOk.length),
            color: AppColors.success,
          ),
          const SizedBox(height: 8),
          if (data.emOk.isEmpty)
            const AppEmptyListWarning()
          else
            EstoqueItemListWidget(itens: data.emOk, onEntrada: _openEntrada),
        ],
      );

  Widget _buildKits(BuildContext context) => BlocBuilder<KitsCubit, KitsState>(
        buildWhen: (p, c) => p.getKitsSubState != c.getKitsSubState,
        builder: (context, state) => AppSubStateBuilder<GetKitsResponseModel>(
          subState: state.getKitsSubState,
          onLoading: const SizedBox.shrink(),
          onData: (data) => data.kits.isEmpty
              ? const AppEmptyListWarning()
              : KitListWidget(
                  kits: data.kits,
                  onMontar: _openMontarKit,
                  onVender: _openVenderKit,
                ),
        ),
      );

  /// Igual ao [_handleWrite], menos o `ESTOQUE_INSUFICIENTE`: esse não é erro
  /// para mostrar em snackbar — é a pergunta que o diálogo de montagem já fez.
  void _handleKitWrite(BuildContext context, BlocSubState subState) {
    if (!subState.isCompleted) return;

    if (subState.hasError) {
      if (subState.error!.code == AppErrorCodes.insufficientStock) return;
      AppSnackBar.showSnackbar(
        context,
        subState.error!.message,
        SnackBarStatus.error,
      );
      return;
    }

    _fetchKits(alsoEstoque: true);
    BlocProvider.of<AlertasCubit>(context).getAlertas();
  }

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
