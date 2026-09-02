import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubits/alertas/alertas_cubit.dart';
import '../../../cubits/bloc_substate.dart';
import '../../../cubits/atendimentos/atendimentos_cubit.dart';
import '../../../cubits/servicos/servicos_cubit.dart';
import '../../../models/atendimentos/atendimento_model.dart';
import '../../../models/atendimentos/get_atendimentos_response_model.dart';
import '../../../settings/app_enums.dart';
import '../../../settings/app_extensions.dart';
import '../../../settings/app_media_querys.dart';
import '../../components/app_dialog.dart';
import '../../components/app_error_retry.dart';
import '../../components/app_scaffold.dart';
import '../../components/app_snackbar.dart';
import '../../components/app_sub_state_builder.dart';
import 'dialogs/finalizar_atendimento_dialog.dart';
import 'dialogs/novo_atendimento_dialog.dart';
import 'widgets/atendimento_list_widget.dart';
import 'widgets/atendimento_saldo_card.dart';
import 'widgets/atendimento_table_widget.dart';

class AtendimentosScreen extends StatefulWidget {
  const AtendimentosScreen({super.key});

  @override
  State<AtendimentosScreen> createState() => _AtendimentosScreenState();
}

class _AtendimentosScreenState extends State<AtendimentosScreen> {
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
    final now = DateTime.now();
    BlocProvider.of<AtendimentosCubit>(context).getAtendimentos(
      inicio: DateTime(now.year, now.month),
      // Dia 0 do mês seguinte é o último dia deste mês — evita o erro clássico
      // de assumir 30 dias.
      fim: DateTime(now.year, now.month + 1, 0),
    );
  }

  Future<void> _openNovoAtendimento() async {
    final reload = await AppDialog.show<bool>(
      context: context,
      title: context.l10n.scheduleButton,
      child: const NovoAtendimentoDialog(),
    );
    if (reload ?? false) _fetch();
  }

  Future<void> _openAcoes(AtendimentoModel atendimento) async {
    if (atendimento.isCancelado) return;

    if (atendimento.isFinalizado) {
      final confirmed = await AppDialog.confirm(
        context: context,
        title: context.l10n.cancelAppointment,
        message: context.l10n.cancelAppointmentQuestion(
          atendimento.clienteNome,
        ),
      );
      if (confirmed && mounted) {
        BlocProvider.of<AtendimentosCubit>(context)
            .cancelarAtendimento(atendimento.id);
      }
      return;
    }

    final reload = await AppDialog.show<bool>(
      context: context,
      title: context.l10n.finishAppointment,
      child: FinalizarAtendimentoDialog(atendimento: atendimento),
    );
    if (reload ?? false) _fetch();
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
          buildWhen: (p, c) => p.getAlertasSubState != c.getAlertasSubState,
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
              child: AppSubStateBuilder<GetAtendimentosResponseModel>(
                subState: state.getAtendimentosSubState,
                onError: (error) =>
                    AppErrorRetry(message: error.message, onRetry: _fetch),
                onData: (data) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AtendimentoSaldoCard(
                      saldoLiquido: data.saldoLiquido,
                      quantidade: data.quantidade,
                    ),
                    const SizedBox(height: 12),
                    if (isWideLayout(context))
                      AtendimentoTableWidget(
                        atendimentos: data.atendimentos,
                        onTap: _openAcoes,
                      )
                    else
                      AtendimentoListWidget(
                        atendimentos: data.atendimentos,
                        onTap: _openAcoes,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  /// Toda escrita termina igual: erro vira snackbar, sucesso recarrega a lista.
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
