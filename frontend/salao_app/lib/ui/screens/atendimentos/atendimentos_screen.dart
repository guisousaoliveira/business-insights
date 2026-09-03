import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubits/alertas/alertas_cubit.dart';
import '../../../cubits/atendimentos/atendimentos_cubit.dart';
import '../../../cubits/bloc_substate.dart';
import '../../../cubits/servicos/servicos_cubit.dart';
import '../../../models/alertas/get_alertas_response_model.dart';
import '../../../models/atendimentos/atendimento_model.dart';
import '../../../models/atendimentos/get_atendimentos_response_model.dart';
import '../../../settings/app_assets.dart';
import '../../../settings/app_colors.dart';
import '../../../settings/app_enums.dart';
import '../../../settings/app_extensions.dart';
import '../../../settings/app_fonts.dart';
import '../../../settings/app_routes.dart';
import '../../../settings/app_utils.dart';
import '../../components/app_alert_banner.dart';
import '../../components/app_dialog.dart';
import '../../components/app_error_retry.dart';
import '../../components/app_icon.dart';
import '../../components/app_scaffold.dart';
import '../../components/app_snackbar.dart';
import '../../components/app_sub_state_builder.dart';
import 'dialogs/finalizar_atendimento_dialog.dart';
import 'dialogs/novo_atendimento_dialog.dart';
import 'widgets/atendimento_filtros_widget.dart';
import 'widgets/atendimento_list_widget.dart';

class AtendimentosScreen extends StatefulWidget {
  const AtendimentosScreen({super.key});

  @override
  State<AtendimentosScreen> createState() => _AtendimentosScreenState();
}

class _AtendimentosScreenState extends State<AtendimentosScreen> {
  /// Os dois filtros da tela. Moram aqui, e não no cubit, porque são escolha
  /// de leitura: o cubit guarda o que o servidor devolveu, não como ela pediu.
  PeriodoAtendimentos _periodo = PeriodoAtendimentos.esteMes;
  StatusAtendimento? _status;

  /// O atendimento cuja escrita está em voo — trava os botões só do cartão
  /// dele.
  String? _busyId;

  /// Cubits são globais e o estado sobrevive à saída da tela — então o fetch
  /// vai sempre no `initState`, sem confiar no que ficou da visita anterior.
  @override
  void initState() {
    super.initState();
    _fetch();
    BlocProvider.of<ServicosCubit>(context).getServicos();
    BlocProvider.of<AlertasCubit>(context).getAlertas();
  }

  void _fetch() {
    final (inicio, fim) = AppUtils.rangeDoPeriodo(_periodo);

    BlocProvider.of<AtendimentosCubit>(context).getAtendimentos(
      inicio: inicio,
      fim: fim,
      // O status filtra no servidor, não na lista já baixada: é o que faz o
      // saldo do período bater com o que está na tela.
      status: _status == null ? const [] : [_status!],
    );
  }

  void _onPeriodoChanged(PeriodoAtendimentos periodo) {
    setState(() => _periodo = periodo);
    _fetch();
  }

  void _onStatusChanged(StatusAtendimento? status) {
    setState(() => _status = status);
    _fetch();
  }

  Future<void> _openNovoAtendimento() async {
    final reload = await AppDialog.show<bool>(
      context: context,
      title: context.l10n.scheduleButton,
      child: const NovoAtendimentoDialog(),
    );
    if (reload ?? false) _fetch();
  }

  Future<void> _editar(AtendimentoModel atendimento) async {
    setState(() => _busyId = atendimento.id);

    final reload = await AppDialog.show<bool>(
      context: context,
      title: context.l10n.editAppointmentTitle,
      child: NovoAtendimentoDialog(atendimento: atendimento),
    );

    if (!mounted) return;
    // Confirmado, a escrita segue em voo e quem destrava é o `_handleWrite`.
    if (!(reload ?? false)) setState(() => _busyId = null);
  }

  Future<void> _finalizar(AtendimentoModel atendimento) async {
    setState(() => _busyId = atendimento.id);

    final reload = await AppDialog.show<bool>(
      context: context,
      title: context.l10n.confirmConsumptionTitle,
      child: FinalizarAtendimentoDialog(atendimento: atendimento),
    );

    if (!mounted) return;
    if (!(reload ?? false)) setState(() => _busyId = null);
  }

  Future<void> _cancelar(AtendimentoModel atendimento) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: context.l10n.cancelAppointment,
      message: context.l10n.cancelAppointmentQuestion(atendimento.clienteNome),
    );

    if (!confirmed || !mounted) return;

    setState(() => _busyId = atendimento.id);
    BlocProvider.of<AtendimentosCubit>(context)
        .cancelarAtendimento(atendimento.id);
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
        listeners: [
          BlocListener<AtendimentosCubit, AtendimentosState>(
            listenWhen: (p, c) =>
                p.createAtendimentoSubState != c.createAtendimentoSubState,
            listener: (context, state) =>
                _handleWrite(context, state.createAtendimentoSubState),
          ),
          BlocListener<AtendimentosCubit, AtendimentosState>(
            listenWhen: (p, c) =>
                p.editAtendimentoSubState != c.editAtendimentoSubState,
            listener: (context, state) =>
                _handleWrite(context, state.editAtendimentoSubState),
          ),
          BlocListener<AtendimentosCubit, AtendimentosState>(
            listenWhen: (p, c) =>
                p.finalizarAtendimentoSubState !=
                c.finalizarAtendimentoSubState,
            listener: (context, state) =>
                _handleWrite(context, state.finalizarAtendimentoSubState),
          ),
          BlocListener<AtendimentosCubit, AtendimentosState>(
            listenWhen: (p, c) =>
                p.cancelarAtendimentoSubState != c.cancelarAtendimentoSubState,
            listener: (context, state) =>
                _handleWrite(context, state.cancelarAtendimentoSubState),
          ),
        ],
        child: BlocBuilder<AlertasCubit, AlertasState>(
          builder: (context, alertasState) =>
              BlocBuilder<AtendimentosCubit, AtendimentosState>(
            buildWhen: (p, c) =>
                p.getAtendimentosSubState != c.getAtendimentosSubState,
            builder: (context, state) => AppScaffold(
              currentPage: AppCurrentRoute.atendimentos,
              title: context.l10n.appointmentsTitle,
              primaryActionLabel: context.l10n.scheduleButton,
              onPrimaryAction: _openNovoAtendimento,
              alertCount: alertasState.badgeCount,
              headerLeading: _buildHeaderAvatar(),
              headerTitle: _buildHeaderTitle(context),
              child: AppSubStateBuilder<GetAtendimentosResponseModel>(
                subState: state.getAtendimentosSubState,
                onError: (error) =>
                    AppErrorRetry(message: error.message, onRetry: _fetch),
                onData: (data) => _buildBody(context, data, alertasState),
              ),
            ),
          ),
        ),
      );

  Widget _buildHeaderAvatar() => Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const AppIcon(
          AppAssets.atendimentos,
          size: 17,
          color: AppColors.white,
        ),
      );

  Widget _buildHeaderTitle(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.appointmentsTitle,
            style: AppFonts.pageTitle(context),
          ),
          Text(
            context.l10n.appointmentsSubtitle,
            style: AppFonts.captionSmall(context),
          ),
        ],
      );

  Widget _buildBody(
    BuildContext context,
    GetAtendimentosResponseModel data,
    AlertasState alertasState,
  ) {
    final alerta = alertasState.getAlertasSubState
        .value<GetAlertasResponseModel>()
        ?.alertas
        .where((item) => !item.isLido)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (alerta != null) ...[
          AppAlertBanner(
            title: alerta.titulo,
            message: alerta.mensagem,
            onTap: () => AppRoutes.push(AppRoutes.alertasRoute),
          ),
          const SizedBox(height: 12),
        ],
        AtendimentoFiltrosWidget(
          periodo: _periodo,
          status: _status,
          saldoLiquido: data.saldoLiquido,
          quantidade: data.quantidade,
          onPeriodoChanged: _onPeriodoChanged,
          onStatusChanged: _onStatusChanged,
        ),
        const SizedBox(height: 12),
        AtendimentoListWidget(
          atendimentos: data.atendimentos,
          busyId: _busyId,
          onFinalizar: _finalizar,
          onEditar: _editar,
          onCancelar: _cancelar,
        ),
      ],
    );
  }

  /// Toda escrita termina igual: erro vira snackbar, sucesso recarrega a lista.
  void _handleWrite(BuildContext context, BlocSubState subState) {
    if (!subState.isCompleted) return;

    setState(() => _busyId = null);

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
