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
import '../../../settings/app_colors.dart';
import '../../../settings/app_enums.dart';
import '../../../settings/app_error_codes.dart';
import '../../../settings/app_extensions.dart';
import '../../../settings/app_fonts.dart';
import '../../../settings/app_utils.dart';
import '../../components/app_dialog.dart';
import '../../components/app_button.dart';
import '../../components/app_empty_list_warning.dart';
import '../../components/app_error_retry.dart';
import '../../components/app_metric_card.dart';
import '../../components/app_scaffold.dart';
import '../../components/app_segmented_control.dart';
import '../../components/app_section_label.dart';
import '../../components/app_snackbar.dart';
import '../../components/app_sub_state_builder.dart';
import 'dialogs/entrada_estoque_dialog.dart';
import 'dialogs/historico_estoque_dialog.dart';
import 'dialogs/montar_kit_dialog.dart';
import 'dialogs/novo_kit_dialog.dart';
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
  SecaoEstoque _section = SecaoEstoque.produtos;

  @override
  void initState() {
    super.initState();
    _fetch();
    BlocProvider.of<KitsCubit>(context).getKits();
    BlocProvider.of<EstoqueCubit>(context).getMovimentacoes();
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

  Future<void> _openNovoKit() async {
    final reload = await AppDialog.show<bool>(
      context: context,
      title: context.l10n.newKit,
      child: const NovoKitDialog(),
    );
    if (reload ?? false) _fetchKits();
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
            listenWhen: (p, c) => p.createKitSubState != c.createKitSubState,
            listener: (context, state) =>
                _handleKitWrite(context, state.createKitSubState),
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
              alertCount: alertasState.badgeCount,
              child: AppSubStateBuilder<GetEstoqueItensResponseModel>(
                subState: state.getItensSubState,
                onError: (error) =>
                    AppErrorRetry(message: error.message, onRetry: _fetch),
                onData: (data) => BlocBuilder<KitsCubit, KitsState>(
                  buildWhen: (p, c) => p.getKitsSubState != c.getKitsSubState,
                  builder: (context, kitsState) {
                    final kits = kitsState.getKitsSubState
                            .value<GetKitsResponseModel>()
                            ?.kits ??
                        const [];
                    return _buildBody(context, data, kits);
                  },
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildMetrics(
    BuildContext context,
    GetEstoqueItensResponseModel data,
    List<KitModel> kits,
  ) {
    final cards = [
      AppMetricCard.danger(
          label: context.l10n.itemsInAlert, value: '${data.totalAlertas}'),
      AppMetricCard.neutral(
          label: context.l10n.productsLabel, value: '${data.itens.length}'),
      AppMetricCard.neutral(
          label: context.l10n.stockValue,
          value: AppUtils.numToMoney(data.valorTotal)),
      AppMetricCard.success(
        label: context.l10n.readyKits,
        value: AppUtils.quantityToString(
            kits.fold<double>(0, (sum, kit) => sum + kit.quantidadeMontada)),
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

  Widget _buildBody(
    BuildContext context,
    GetEstoqueItensResponseModel data,
    List<KitModel> kits,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMetrics(context, data, kits),
          const SizedBox(height: 16),
          AppSegmentedControl<SecaoEstoque>(
            value: _section,
            segments: [
              AppSegment(SecaoEstoque.produtos, context.l10n.productsLabel),
              AppSegment(SecaoEstoque.kits, context.l10n.resaleKitsTab),
              AppSegment(
                  SecaoEstoque.movimentacoes, context.l10n.movementsLabel),
            ],
            onChanged: (value) => setState(() => _section = value),
          ),
          const SizedBox(height: 16),
          switch (_section) {
            SecaoEstoque.produtos => _buildListas(context, data),
            SecaoEstoque.kits => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSectionLabel(
                    context.l10n.resaleKitsTab,
                    trailing: AppButton(
                      label: context.l10n.newKit,
                      type: AppButtonType.outlined,
                      isDense: true,
                      onPressed: _openNovoKit,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildKits(context),
                ],
              ),
            SecaoEstoque.movimentacoes => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSectionLabel(context.l10n.movementsLabel),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.movementsHint,
                    style: AppFonts.captionSmall(context),
                  ),
                  const SizedBox(height: 8),
                  const HistoricoEstoqueDialog(),
                ],
              ),
          },
        ],
      );

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
