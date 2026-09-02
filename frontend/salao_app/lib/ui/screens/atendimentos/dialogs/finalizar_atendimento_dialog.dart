import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../cubits/atendimentos/atendimentos_cubit.dart';
import '../../../../cubits/servicos/servicos_cubit.dart';
import '../../../../models/atendimentos/atendimento_model.dart';
import '../../../../models/atendimentos/material_atendimento_model.dart';
import '../../../../models/error_model.dart';
import '../../../../models/estoque/estoque_faltante_model.dart';
import '../../../../models/servicos/servico_model.dart';
import '../../../../settings/app_assets.dart';
import '../../../../settings/app_colors.dart';
import '../../../../settings/app_error_codes.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../components/app_button.dart';
import '../../../components/app_card.dart';
import '../../../components/app_icon.dart';
import '../../../components/app_tappable.dart';
import '../../../dialogs/estoque_insuficiente_dialog.dart';


/// Finalização: confirma os materiais consumidos, que o servidor usa para dar
/// baixa no estoque.
///
/// A lista já vem preenchida com os `produtos_padrao` dos serviços do
/// atendimento — a usuária confirma ou tira, em vez de lembrar do zero.
class FinalizarAtendimentoDialog extends StatefulWidget {
  final AtendimentoModel atendimento;

  const FinalizarAtendimentoDialog({super.key, required this.atendimento});

  @override
  State<FinalizarAtendimentoDialog> createState() =>
      _FinalizarAtendimentoDialogState();
}

class _FinalizarAtendimentoDialogState
    extends State<FinalizarAtendimentoDialog> {
  late final List<MaterialAtendimentoModel> _materiais;
  bool _isPrefilled = false;

  @override
  void initState() {
    super.initState();
    _materiais = [];
  }

  /// Roda uma vez, quando o catálogo de serviços já está em memória. Não dá
  /// para fazer no `initState` porque depende do estado de outro cubit.
  void _prefill(List<ServicoModel> catalogo) {
    if (_isPrefilled) return;
    _isPrefilled = true;

    for (final servico in widget.atendimento.servicos) {
      final doCatalogo = catalogo.where((e) => e.id == servico.servicoId);
      if (doCatalogo.isEmpty) continue;

      for (final produto in doCatalogo.first.produtosPadrao) {
        _materiais.add(
          MaterialAtendimentoModel(
            itemEstoqueId: produto.itemEstoqueId,
            nome: produto.nome,
            quantidade: produto.quantidade,
            preco: 0,
          ),
        );
      }
    }
  }

  /// Finaliza em duas passadas.
  ///
  /// A primeira vai sem confirmação: se faltar saldo, o servidor recusa com
  /// `ESTOQUE_INSUFICIENTE` **sem gravar nada** e devolve o que falta. Aí
  /// mostramos o aviso e, se ela confirmar, repetimos a mesma chamada com
  /// `confirmar_estoque_insuficiente: true` — o saldo fica negativo e o
  /// servidor gera o alerta.
  Future<void> _submit({bool confirmarEstoqueInsuficiente = false}) async {
    final cubit = BlocProvider.of<AtendimentosCubit>(context);
    final navigator = Navigator.of(context);

    await cubit.finalizarAtendimento(
      id: widget.atendimento.id,
      materiais: _materiais,
      confirmarEstoqueInsuficiente: confirmarEstoqueInsuficiente,
    );
    if (!mounted) return;

    final data = cubit.state.finalizarAtendimentoSubState.data;
    if (data is ErrorModel && data.code == AppErrorCodes.insufficientStock) {
      final confirmou = await EstoqueInsuficienteDialog.show(
        context: context,
        faltantes: EstoqueFaltanteModel.listFrom(data.result),
      );
      if (confirmou && mounted) {
        await _submit(confirmarEstoqueInsuficiente: true);
      }
      return;
    }

    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ServicosCubit, ServicosState>(
        buildWhen: (p, c) => p.getServicosSubState != c.getServicosSubState,
        builder: (context, state) {
          final catalogo = state.getServicosSubState
                  .value<GetServicosResponseModel>()
                  ?.servicos ??
              const <ServicoModel>[];
          _prefill(catalogo);

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.atendimento.clienteNome,
                style: AppFonts.rowTitle(context),
              ),
              const SizedBox(height: 2),
              Text(
                AppUtils.dateToFull(widget.atendimento.data),
                style: AppFonts.caption(context),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.stockExit.toUpperCase(),
                style: AppFonts.sectionLabel(context),
              ),
              const SizedBox(height: 8),
              if (_materiais.isEmpty)
                Text(
                  context.l10n.emptyList,
                  style: AppFonts.caption(context),
                )
              else
                AppCard(
                  child: Column(
                    children: List.generate(
                      _materiais.length,
                      (index) => AppCardRow(
                        isFirst: index == 0,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _materiais[index].nome,
                                style: AppFonts.rowTitle(context),
                              ),
                            ),
                            Text(
                              AppUtils.quantityToString(
                                _materiais[index].quantidade,
                              ),
                              style: AppFonts.rowValue(context)
                                  .copyWith(color: AppColors.text2),
                            ),
                            const SizedBox(width: 4),
                            AppTappable(
                              minSize: 32,
                              borderRadius: BorderRadius.circular(16),
                              onTap: () =>
                                  setState(() => _materiais.removeAt(index)),
                              child: const AppIcon(AppAssets.close, size: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              BlocBuilder<AtendimentosCubit, AtendimentosState>(
                buildWhen: (p, c) =>
                    p.finalizarAtendimentoSubState !=
                    c.finalizarAtendimentoSubState,
                builder: (context, atendimentosState) => AppButton(
                  label: context.l10n.finishAppointment,
                  isExpanded: true,
                  isLoading:
                      atendimentosState.finalizarAtendimentoSubState.isLoading,
                  onPressed: _submit,
                ),
              ),
            ],
          );
        },
      );
}
