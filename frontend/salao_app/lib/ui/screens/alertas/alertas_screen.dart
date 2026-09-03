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
import '../../components/app_button.dart';
import '../../components/app_card.dart';
import '../../components/app_empty_list_warning.dart';
import '../../components/app_error_retry.dart';
import '../../components/app_icon.dart';
import '../../components/app_scaffold.dart';
import '../../components/app_segmented_control.dart';
import '../../components/app_section_label.dart';
import '../../components/app_sub_state_builder.dart';
import '../../components/app_tag.dart';

/// Central de alertas. O app **não** calcula nada aqui: lista o que o servidor
/// devolveu com severidade pronta (S7), e o toque leva para a tela do assunto.
class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  bool _onlyUnread = false;

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

  void _marcarLido(AlertaModel alerta) {
    BlocProvider.of<AlertasCubit>(context).marcarLido(alerta.id);
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<AlertasCubit, AlertasState>(
        listenWhen: (p, c) =>
            p.marcarTodosLidosSubState != c.marcarTodosLidosSubState ||
            p.marcarLidoSubState != c.marcarLidoSubState,
        listener: (context, state) {
          final todos = state.marcarTodosLidosSubState;
          final um = state.marcarLidoSubState;
          if ((todos.isCompleted && !todos.hasError) ||
              (um.isCompleted && !um.hasError)) {
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
              onData: (data) {
                final alertas = _onlyUnread
                    ? data.alertas.where((item) => !item.isLido).toList()
                    : data.alertas;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppSegmentedControl<bool>(
                            value: _onlyUnread,
                            segments: [
                              AppSegment(false, context.l10n.allLabel),
                              AppSegment(true, context.l10n.unreadLabel),
                            ],
                            onChanged: (value) =>
                                setState(() => _onlyUnread = value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppButton(
                          label: context.l10n.markAllAsRead,
                          type: AppButtonType.outlined,
                          isDense: true,
                          onPressed:
                              data.totalNaoLidos == 0 ? null : _marcarTodos,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppSectionLabel(
                      context.l10n.alertsSectionTitle,
                      trailing: Text(
                        context.l10n.alertsSectionHint,
                        style: AppFonts.captionSmall(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (alertas.isEmpty)
                      AppEmptyListWarning(
                        message: context.l10n.noAlertsDescription,
                      )
                    else
                      ...alertas.map(
                        (alerta) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AlertaRow(
                            alerta: alerta,
                            onDetails: () => _open(alerta),
                            onMarkRead: () => _marcarLido(alerta),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );
}

class _AlertaRow extends StatelessWidget {
  final AlertaModel alerta;
  final VoidCallback onDetails;
  final VoidCallback onMarkRead;

  const _AlertaRow({
    required this.alerta,
    required this.onDetails,
    required this.onMarkRead,
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
    final severityTag = switch (alerta.severidade) {
      SeveridadeAlerta.critico => AppTag.danger(context.l10n.criticalLabel),
      SeveridadeAlerta.alerta => AppTag.warning(context.l10n.attentionLabel),
      SeveridadeAlerta.info => AppTag.primary(context.l10n.informationLabel),
    };

    return AppCard(
      padding: const EdgeInsets.all(14),
      // Lido fica no fundo cinza: continua consultável, mas sai do caminho.
      background: alerta.isLido ? AppColors.surface2 : AppColors.surface,
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
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    severityTag,
                    if (!alerta.isLido) AppTag.accent(context.l10n.newLabel),
                  ],
                ),
                const SizedBox(height: 6),
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
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    AppButton(
                      label: context.l10n.viewDetails,
                      type: AppButtonType.outlined,
                      isDense: true,
                      onPressed: onDetails,
                    ),
                    if (!alerta.isLido)
                      AppButton(
                        label: context.l10n.markAsRead,
                        type: AppButtonType.text,
                        isDense: true,
                        onPressed: onMarkRead,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
