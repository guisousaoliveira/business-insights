import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubits/alertas/alertas_cubit.dart';
import '../../../cubits/auth/auth_cubit.dart';
import '../../../cubits/bloc_substate.dart';
import '../../../cubits/perfil/perfil_cubit.dart';
import '../../../cubits/servicos/servicos_cubit.dart';
import '../../../models/perfil/custo_fixo_model.dart';
import '../../../models/perfil/perfil_model.dart';
import '../../../models/servicos/servico_model.dart';
import '../../../settings/app_assets.dart';
import '../../../settings/app_colors.dart';
import '../../../settings/app_enums.dart';
import '../../../settings/app_extensions.dart';
import '../../../settings/app_fonts.dart';
import '../../../settings/app_routes.dart';
import '../../../settings/app_utils.dart';
import '../../components/app_card.dart';
import '../../components/app_checkbox.dart';
import '../../components/app_dialog.dart';
import '../../components/app_empty_list_warning.dart';
import '../../components/app_icon.dart';
import '../../components/app_scaffold.dart';
import '../../components/app_section_label.dart';
import '../../components/app_snackbar.dart';
import '../../components/app_sub_state_builder.dart';
import '../../components/app_tappable.dart';
import 'dialogs/novo_custo_fixo_dialog.dart';
import 'dialogs/novo_servico_dialog.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  @override
  void initState() {
    super.initState();
    _fetch();
    BlocProvider.of<AlertasCubit>(context).getAlertas();
  }

  void _fetch() {
    final cubit = BlocProvider.of<PerfilCubit>(context);
    cubit.getPerfil();
    cubit.getCustosFixos();
    BlocProvider.of<ServicosCubit>(context).getServicos();
  }

  Future<void> _openCustoFixo([CustoFixoModel? custoFixo]) async {
    final reload = await AppDialog.show<bool>(
      context: context,
      title: custoFixo == null
          ? context.l10n.newFixedCostTitle
          : context.l10n.editFixedCostTitle,
      child: NovoCustoFixoDialog(custoFixo: custoFixo),
    );
    if ((reload ?? false) && mounted) {
      BlocProvider.of<PerfilCubit>(context).getCustosFixos();
    }
  }

  Future<void> _openServico([ServicoModel? servico]) async {
    final reload = await AppDialog.show<bool>(
      context: context,
      title: servico == null
          ? context.l10n.newServiceTitle
          : context.l10n.editServiceTitle,
      child: NovoServicoDialog(servico: servico),
    );
    if ((reload ?? false) && mounted) {
      BlocProvider.of<ServicosCubit>(context).getServicos();
    }
  }

  Future<void> _logout() async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: context.l10n.logout,
      message: context.l10n.logoutQuestion,
      confirmLabel: context.l10n.logout,
    );
    if (confirmed && mounted) {
      BlocProvider.of<AuthCubit>(context).logout();
    }
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
        listeners: [
          BlocListener<AuthCubit, AuthState>(
            listenWhen: (p, c) => p.logoutSubState != c.logoutSubState,
            listener: (context, state) {
              if (state.logoutSubState.isCompleted) {
                AppRoutes.push(AppRoutes.loginRoute, removeUntil: (_) => false);
              }
            },
          ),
          BlocListener<PerfilCubit, PerfilState>(
            listenWhen: (p, c) =>
                p.createCustoFixoSubState != c.createCustoFixoSubState,
            listener: (context, state) => _handleWrite(
              context,
              state.createCustoFixoSubState,
              () => BlocProvider.of<PerfilCubit>(context).getCustosFixos(),
            ),
          ),
          BlocListener<PerfilCubit, PerfilState>(
            listenWhen: (p, c) =>
                p.editCustoFixoSubState != c.editCustoFixoSubState,
            listener: (context, state) => _handleWrite(
              context,
              state.editCustoFixoSubState,
              () => BlocProvider.of<PerfilCubit>(context).getCustosFixos(),
            ),
          ),
          BlocListener<PerfilCubit, PerfilState>(
            listenWhen: (p, c) =>
                p.pagarCustoFixoSubState != c.pagarCustoFixoSubState,
            listener: (context, state) => _handleWrite(
              context,
              state.pagarCustoFixoSubState,
              () => BlocProvider.of<PerfilCubit>(context).getCustosFixos(),
            ),
          ),
          BlocListener<PerfilCubit, PerfilState>(
            listenWhen: (p, c) =>
                p.deleteCustoFixoSubState != c.deleteCustoFixoSubState,
            listener: (context, state) => _handleWrite(
              context,
              state.deleteCustoFixoSubState,
              () => BlocProvider.of<PerfilCubit>(context).getCustosFixos(),
            ),
          ),
          BlocListener<ServicosCubit, ServicosState>(
            listenWhen: (p, c) =>
                p.createServicoSubState != c.createServicoSubState,
            listener: (context, state) => _handleWrite(
              context,
              state.createServicoSubState,
              () => BlocProvider.of<ServicosCubit>(context).getServicos(),
            ),
          ),
          BlocListener<ServicosCubit, ServicosState>(
            listenWhen: (p, c) =>
                p.editServicoSubState != c.editServicoSubState,
            listener: (context, state) => _handleWrite(
              context,
              state.editServicoSubState,
              () => BlocProvider.of<ServicosCubit>(context).getServicos(),
            ),
          ),
          BlocListener<ServicosCubit, ServicosState>(
            listenWhen: (p, c) =>
                p.deleteServicoSubState != c.deleteServicoSubState,
            listener: (context, state) => _handleWrite(
              context,
              state.deleteServicoSubState,
              () => BlocProvider.of<ServicosCubit>(context).getServicos(),
            ),
          ),
        ],
        child: BlocBuilder<AlertasCubit, AlertasState>(
          buildWhen: (p, c) => p.badgeCount != c.badgeCount,
          builder: (context, alertasState) => AppScaffold(
            currentPage: AppCurrentRoute.perfil,
            title: context.l10n.profileTitle,
            subtitle: context.l10n.profileSubtitle,
            alertCount: alertasState.badgeCount,
            trailingIcon: AppAssets.logout,
            onTrailingAction: _logout,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPerfilCard(context),
                const SizedBox(height: 16),
                _buildCustosFixos(context),
                const SizedBox(height: 16),
                _buildServicos(context),
              ],
            ),
          ),
        ),
      );

  Widget _buildPerfilCard(BuildContext context) =>
      BlocBuilder<PerfilCubit, PerfilState>(
        buildWhen: (p, c) => p.getPerfilSubState != c.getPerfilSubState,
        builder: (context, state) => AppSubStateBuilder<GetPerfilResponseModel>(
          subState: state.getPerfilSubState,
          onData: (data) => AppCard(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const AppIcon(
                    AppAssets.perfil,
                    size: 24,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data.perfil.nome,
                        style:
                            AppFonts.pageTitle(context).copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.perfil.proprietaria.isEmpty
                            ? context.l10n.ownerLabel
                            : data.perfil.proprietaria,
                        style: AppFonts.caption(context).copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const AppIcon(AppAssets.edit, size: 16),
              ],
            ),
          ),
        ),
      );

  Widget _buildCustosFixos(BuildContext context) =>
      BlocBuilder<PerfilCubit, PerfilState>(
        buildWhen: (p, c) =>
            p.getCustosFixosSubState != c.getCustosFixosSubState,
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionLabel(
              context.l10n.monthlyFixedCosts,
              trailing: _AddAction(onTap: _openCustoFixo),
            ),
            const SizedBox(height: 8),
            AppSubStateBuilder<GetCustosFixosResponseModel>(
              subState: state.getCustosFixosSubState,
              onData: (data) => data.custos.isEmpty
                  ? const AppEmptyListWarning()
                  : AppCard(
                      child: Column(
                        children: [
                          ...List.generate(
                            data.custos.length,
                            (index) => _buildCustoFixoRow(
                              context,
                              data.custos[index],
                              isFirst: index == 0,
                            ),
                          ),
                          _KeyValueRow(
                            label: context.l10n.monthlyTotal,
                            value: AppUtils.numToMoney(data.totalMensal),
                            isTotal: true,
                          ),
                          _KeyValueRow(
                            label: context.l10n.monthlyPending,
                            value: AppUtils.numToMoney(data.totalPendente),
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      );

  /// A linha de um custo fixo do mês corrente.
  ///
  /// O check é de duas vias, diferente do gasto: lá o pagamento é um fato
  /// lançado, aqui é uma marcação do mês. Um toque errado no celular não pode
  /// calar o alerta do aluguel até a virada do mês.
  Widget _buildCustoFixoRow(
    BuildContext context,
    CustoFixoModel custo, {
    required bool isFirst,
  }) {
    final pagoEm = custo.pagoEm;

    return _KeyValueRow(
      label: custo.descricao,
      leading: AppCheckBox(
        value: custo.pago,
        onChanged: (marcado) =>
            BlocProvider.of<PerfilCubit>(context).pagarCustoFixo(
          id: custo.id,
          competencia: custo.competencia,
          pago: marcado,
        ),
      ),
      caption: switch ((custo.pago, custo.isVencido)) {
        (true, _) when pagoEm != null =>
          context.l10n.paidOnShort(AppUtils.dateToShort(pagoEm)),
        (true, _) => context.l10n.paidThisMonthLabel,
        (_, true) => context.l10n.overdueDayShort(custo.diaVencimento),
        _ => context.l10n.dueDayShort(custo.diaVencimento),
      },
      captionColor: custo.isVencido ? AppColors.danger : null,
      value: AppUtils.numToMoney(custo.valor),
      isFirst: isFirst,
      onTap: () => _openCustoFixo(custo),
    );
  }

  Widget _buildServicos(BuildContext context) =>
      BlocBuilder<ServicosCubit, ServicosState>(
        buildWhen: (p, c) => p.getServicosSubState != c.getServicosSubState,
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionLabel(
              context.l10n.serviceTable,
              trailing: _AddAction(onTap: _openServico),
            ),
            const SizedBox(height: 8),
            AppSubStateBuilder<GetServicosResponseModel>(
              subState: state.getServicosSubState,
              onData: (data) => data.servicos.isEmpty
                  ? const AppEmptyListWarning()
                  : AppCard(
                      child: Column(
                        children: List.generate(
                          data.servicos.length,
                          (index) => AppCardRow(
                            isFirst: index == 0,
                            child: AppTappable(
                              minSize: 0,
                              borderRadius: BorderRadius.circular(6),
                              onTap: () => _openServico(data.servicos[index]),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: const AppIcon(
                                      AppAssets.scissors,
                                      size: 15,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          data.servicos[index].nome,
                                          style: AppFonts.rowTitle(context)
                                              .copyWith(
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        // O que ele consome é o que explica a
                                        // margem: fica na linha, não escondido
                                        // dentro da edição.
                                        Text(
                                          context.l10n.materialsCount(
                                            data.servicos[index].produtosPadrao
                                                .length,
                                          ),
                                          style: AppFonts.captionSmall(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    AppUtils.numToMoney(
                                      data.servicos[index].preco,
                                    ),
                                    style: AppFonts.rowValue(context).copyWith(
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const AppIcon(
                                    AppAssets.chevronRight,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      );

  void _handleWrite(
    BuildContext context,
    BlocSubState subState,
    VoidCallback onSuccess,
  ) {
    if (!subState.isCompleted) return;

    if (subState.hasError) {
      AppSnackBar.showSnackbar(
        context,
        subState.error!.message,
        SnackBarStatus.error,
      );
      return;
    }

    onSuccess();
  }
}

class _AddAction extends StatelessWidget {
  final VoidCallback onTap;

  const _AddAction({required this.onTap});

  @override
  Widget build(BuildContext context) => AppTappable(
        onTap: onTap,
        minSize: 32,
        borderRadius: BorderRadius.circular(8),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          context.l10n.addAction,
          style: AppFonts.caption(context).copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.primaryDark,
          ),
        ),
      );
}

class _KeyValueRow extends StatelessWidget {
  final String label;

  /// Segunda linha do rótulo — hoje o "vence dia 5" do custo fixo.
  final String? caption;
  final Color? captionColor;
  final String value;
  final bool isFirst;
  final bool isTotal;

  /// Fica fora da área de toque da linha: marcar como pago e abrir a edição
  /// são coisas diferentes, e o check é o alvo menor dos dois.
  final Widget? leading;

  /// Quando existe, a linha inteira abre a edição. É a linha toda que é o alvo
  /// de toque: um lápis de 16px ao lado do valor não se acerta com o polegar.
  final VoidCallback? onTap;

  const _KeyValueRow({
    required this.label,
    required this.value,
    this.caption,
    this.captionColor,
    this.leading,
    this.isFirst = false,
    this.isTotal = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppFonts.rowTitle(context).copyWith(
                  fontWeight: isTotal ? FontWeight.w500 : FontWeight.w400,
                  color: isTotal ? AppColors.text2 : AppColors.text1,
                ),
              ),
              if (caption != null)
                Text(
                  caption!,
                  style: AppFonts.captionSmall(context)
                      .copyWith(color: captionColor),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: AppFonts.rowValue(context).copyWith(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            color: AppColors.danger,
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 6),
          const AppIcon(AppAssets.chevronRight, size: 16),
        ],
      ],
    );

    final conteudo = onTap == null
        ? row
        : AppTappable(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: row,
          );

    return AppCardRow(
      isFirst: isFirst,
      background: isTotal ? AppColors.surface2 : null,
      child: leading == null
          ? conteudo
          : Row(
              children: [
                leading!,
                const SizedBox(width: 10),
                Expanded(child: conteudo),
              ],
            ),
    );
  }
}
