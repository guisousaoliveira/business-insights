import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubits/alertas/alertas_cubit.dart';
import '../../../models/alertas/alerta_model.dart';
import '../../../models/alertas/get_alertas_response_model.dart';
import '../../../settings/app_assets.dart';
import '../../../settings/app_colors.dart';
import '../../../settings/app_enums.dart';
import '../../../settings/app_extensions.dart';
import '../../../settings/app_fonts.dart';
import '../../../settings/app_routes.dart';
import '../../../settings/app_utils.dart';
import '../../components/app_card.dart';
import '../../components/app_empty_list_warning.dart';
import '../../components/app_error_retry.dart';
import '../../components/app_icon.dart';
import '../../components/app_scaffold.dart';
import '../../components/app_section_label.dart';
import '../../components/app_sub_state_builder.dart';
import '../../components/app_tappable.dart';

/// Central de alertas. O app **não** calcula nada aqui: lista o que o servidor
/// devolveu com severidade pronta (S7), e o toque leva para a tela do assunto.
class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() => BlocProvider.of<AlertasCubit>(context).getAlertas();

  void _open(AlertaModel alerta) {
    if (!alerta.isLido) {
      BlocProvider.of<AlertasCubit>(context).marcarLido(alerta.id);
    }
    AppRoutes.replace(alerta.rota);
  }

  void _marcarTodos() {
    BlocProvider.of<AlertasCubit>(context).marcarTodosLidos();
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<AlertasCubit, AlertasState>(
        listenWhen: (p, c) =>
            p.marcarTodosLidosSubState != c.marcarTodosLidosSubState,
        listener: (context, state) {
          if (state.marcarTodosLidosSubState.isCompleted &&
              !state.marcarTodosLidosSubState.hasError) {
            _fetch();
          }
        },
        child: BlocBuilder<AlertasCubit, AlertasState>(
          buildWhen: (p, c) => p.getAlertasSubState != c.getAlertasSubState,
          builder: (context, state) => AppScaffold(
            currentPage: AppCurrentRoute.alertas,
            title: context.l10n.alertsTitle,
            subtitle: context.l10n.alertsSubtitle(state.badgeCount),
            alertCount: state.badgeCount,
            child: AppSubStateBuilder<GetAlertasResponseModel>(
              subState: state.getAlertasSubState,
              onError: (error) =>
                  AppErrorRetry(message: error.message, onRetry: _fetch),
              onData: (data) => data.alertas.isEmpty
                  ? AppEmptyListWarning(message: context.l10n.noAlerts)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSectionLabel(
                          context.l10n.unreadAlerts(data.totalNaoLidos),
                          trailing: data.totalNaoLidos == 0
                              ? null
                              : AppTappable(
                                  onTap: _marcarTodos,
                                  minSize: 32,
                                  borderRadius: BorderRadius.circular(8),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    context.l10n.markAllAsRead,
                                    style: AppFonts.caption(context).copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 8),
                        AppCard(
                          child: Column(
                            children: List.generate(
                              data.alertas.length,
                              (index) => _AlertaRow(
                                alerta: data.alertas[index],
                                isFirst: index == 0,
                                onTap: () => _open(data.alertas[index]),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
}

class _AlertaRow extends StatelessWidget {
  final AlertaModel alerta;
  final bool isFirst;
  final VoidCallback onTap;

  const _AlertaRow({
    required this.alerta,
    required this.isFirst,
    required this.onTap,
  });

  (Color, Color, IconData) get _severity => switch (alerta.severidade) {
        SeveridadeAlerta.critico => (
            AppColors.dangerLight,
            AppColors.danger,
            AppAssets.warning,
          ),
        SeveridadeAlerta.alerta => (
            AppColors.amberLight,
            AppColors.amber,
            AppAssets.warning,
          ),
        SeveridadeAlerta.info => (
            AppColors.primaryLight,
            AppColors.primaryDark,
            AppAssets.alert,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = _severity;

    return AppTappable(
      onTap: onTap,
      minSize: 0,
      child: AppCardRow(
        isFirst: isFirst,
        // Lido fica no fundo cinza: continua consultável, mas sai do caminho.
        background: alerta.isLido ? AppColors.surface2 : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: AppIcon(icon, size: 15, color: foreground),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    alerta.titulo,
                    style: AppFonts.rowTitle(context).copyWith(
                      color: alerta.isLido ? AppColors.text2 : AppColors.text1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(alerta.mensagem, style: AppFonts.caption(context)),
                  const SizedBox(height: 2),
                  Text(
                    AppUtils.dateToRelative(alerta.criadoEm),
                    style: AppFonts.captionSmall(context),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const AppIcon(AppAssets.chevronRight, size: 16),
          ],
        ),
      ),
    );
  }
}
