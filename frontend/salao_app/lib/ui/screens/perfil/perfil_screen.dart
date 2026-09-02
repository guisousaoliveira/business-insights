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
import '../../../settings/app_media_querys.dart';
import '../../../settings/app_routes.dart';
import '../../../settings/app_utils.dart';
import '../../components/app_card.dart';
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

  Future<void> _openNovoCustoFixo() async {
    final reload = await AppDialog.show<bool>(
      context: context,
      title: context.l10n.newFixedCostTitle,
      child: const NovoCustoFixoDialog(),
    );
    if ((reload ?? false) && mounted) {
      BlocProvider.of<PerfilCubit>(context).getCustosFixos();
    }
  }

  Future<void> _openNovoServico() async {
    final reload = await AppDialog.show<bool>(
      context: context,
      title: context.l10n.newServiceTitle,
      child: const NovoServicoDialog(),
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
          BlocListener<ServicosCubit, ServicosState>(
            listenWhen: (p, c) =>
                p.createServicoSubState != c.createServicoSubState,
            listener: (context, state) => _handleWrite(
              context,
              state.createServicoSubState,
              () => BlocProvider.of<ServicosCubit>(context).getServicos(),
            ),
          ),
        ],
        child: BlocBuilder<AlertasCubit, AlertasState>(
          buildWhen: (p, c) => p.badgeCount != c.badgeCount,
          builder: (context, alertasState) => AppScaffold(
            currentPage: AppCurrentRoute.perfil,
            title: context.l10n.profileTitle,
            alertCount: alertasState.badgeCount,
            trailingIcon: AppAssets.logout,
            onTrailingAction: _logout,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPerfilCard(context),
                const SizedBox(height: 16),
                if (isWideLayout(context))
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildCustosFixos(context)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildServicos(context)),
                    ],
                  )
                else ...[
                  _buildCustosFixos(context),
                  const SizedBox(height: 16),
                  _buildServicos(context),
                ],
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
          onData: (data) => ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWideLayout(context) ? 420 : double.infinity,
            ),
            child: AppCard(
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
                          style: AppFonts.pageTitle(context)
                              .copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.perfil.proprietaria.isEmpty
                              ? context.l10n.ownerLabel
                              : data.perfil.proprietaria,
                          style:
                              AppFonts.caption(context).copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const AppIcon(AppAssets.edit, size: 16),
                ],
              ),
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
              trailing: _AddAction(onTap: _openNovoCustoFixo),
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
                            (index) => _KeyValueRow(
                              label: data.custos[index].descricao,
                              value: AppUtils.numToMoney(
                                data.custos[index].valor,
                              ),
                              isFirst: index == 0,
                            ),
                          ),
                          _KeyValueRow(
                            label: context.l10n.monthlyTotal,
                            value: AppUtils.numToMoney(data.totalMensal),
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      );

  Widget _buildServicos(BuildContext context) =>
      BlocBuilder<ServicosCubit, ServicosState>(
        buildWhen: (p, c) => p.getServicosSubState != c.getServicosSubState,
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionLabel(
              context.l10n.serviceTable,
              trailing: _AddAction(onTap: _openNovoServico),
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
                                  child: Text(
                                    data.servicos[index].nome,
                                    style: AppFonts.rowTitle(context)
                                        .copyWith(fontWeight: FontWeight.w400),
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
                              ],
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
  final String value;
  final bool isFirst;
  final bool isTotal;

  const _KeyValueRow({
    required this.label,
    required this.value,
    this.isFirst = false,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) => AppCardRow(
        isFirst: isFirst,
        background: isTotal ? AppColors.surface2 : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppFonts.rowTitle(context).copyWith(
                fontWeight: isTotal ? FontWeight.w500 : FontWeight.w400,
                color: isTotal ? AppColors.text2 : AppColors.text1,
              ),
            ),
            Text(
              value,
              style: AppFonts.rowValue(context).copyWith(
                fontSize: isTotal ? 15 : 13,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      );
}
