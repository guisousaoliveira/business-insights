import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../cubits/atendimentos/atendimentos_cubit.dart';
import '../../../../cubits/estoque/estoque_cubit.dart';
import '../../../../cubits/servicos/servicos_cubit.dart';
import '../../../../models/atendimentos/atendimento_model.dart';
import '../../../../models/atendimentos/material_atendimento_model.dart';
import '../../../../models/dropdown_model.dart';
import '../../../../models/error_model.dart';
import '../../../../models/estoque/estoque_faltante_model.dart';
import '../../../../models/estoque/get_estoque_itens_response_model.dart';
import '../../../../models/estoque/item_estoque_model.dart';
import '../../../../models/servicos/servico_model.dart';
import '../../../../settings/app_assets.dart';
import '../../../../settings/app_enums.dart';
import '../../../../settings/app_error_codes.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../../settings/app_validators.dart';
import '../../../components/app_button.dart';
import '../../../components/app_card.dart';
import '../../../components/app_dropdown.dart';
import '../../../components/app_icon.dart';
import '../../../components/app_input.dart';
import '../../../components/app_tappable.dart';
import '../../../dialogs/estoque_insuficiente_dialog.dart';

/// Uma linha de material consumido, com a quantidade editável.
///
/// A quantidade vive num controller, e não num `double` no estado, porque o
/// que ela digita só vira número na hora de finalizar — no meio da digitação
/// `1,` não é número nenhum.
class _Linha {
  final String itemEstoqueId;
  final String nome;
  final UnidadeEstoque unidade;
  final AppInputController quantidade;

  _Linha({
    required this.itemEstoqueId,
    required this.nome,
    required this.unidade,
    required double quantidadeInicial,
  }) : quantidade = AppInputController(
          initialValue: AppUtils.quantityToString(quantidadeInicial),
          validator: AppValidators.validateQuantity,
        );
}

/// Confirmação de consumo: a baixa de estoque que a finalização vai gerar.
///
/// A lista já vem preenchida com os `produtos_padrao` dos serviços do
/// atendimento. O papel desta tela é o ajuste — o dia em que gastou duas
/// ampolas em vez de uma, ou nenhuma — e não o preenchimento do zero.
class FinalizarAtendimentoDialog extends StatefulWidget {
  final AtendimentoModel atendimento;

  const FinalizarAtendimentoDialog({super.key, required this.atendimento});

  @override
  State<FinalizarAtendimentoDialog> createState() =>
      _FinalizarAtendimentoDialogState();
}

class _FinalizarAtendimentoDialogState
    extends State<FinalizarAtendimentoDialog> {
  final List<_Linha> _linhas = [];
  late final AppDropdownController _itemController;
  bool _isPrefilled = false;

  @override
  void initState() {
    super.initState();
    _itemController = AppDropdownController(isRequired: false);
    // O catálogo de estoque alimenta o "adicionar material": o que ela gastou
    // fora do padrão do serviço também precisa dar baixa.
    BlocProvider.of<EstoqueCubit>(context).getItens();
  }

  @override
  void dispose() {
    _itemController.dispose();
    for (final linha in _linhas) {
      linha.quantidade.dispose();
    }
    super.dispose();
  }

  /// Roda uma vez, quando o catálogo de serviços já está em memória. Não dá
  /// para fazer no `initState` porque depende do estado de outro cubit.
  void _prefill(List<ServicoModel> catalogo) {
    if (_isPrefilled || catalogo.isEmpty) return;
    _isPrefilled = true;

    for (final servico in widget.atendimento.servicos) {
      final doCatalogo = catalogo.where((e) => e.id == servico.servicoId);
      if (doCatalogo.isEmpty) continue;

      for (final produto in doCatalogo.first.produtosPadrao) {
        // Dois serviços do mesmo atendimento podem pedir o mesmo material: a
        // baixa é uma só, com as quantidades somadas.
        final existente = _linhas
            .where((e) => e.itemEstoqueId == produto.itemEstoqueId)
            .toList();
        if (existente.isNotEmpty) {
          final atual =
              AppValidators.parseMoney(existente.first.quantidade.text) ?? 0;
          existente.first.quantidade.text =
              AppUtils.quantityToString(atual + produto.quantidade);
          continue;
        }

        _linhas.add(
          _Linha(
            itemEstoqueId: produto.itemEstoqueId,
            nome: produto.nome,
            unidade: produto.unidade,
            quantidadeInicial: produto.quantidade,
          ),
        );
      }
    }
  }

  void _adicionar(List<ItemEstoqueModel> disponiveis) {
    final id = _itemController.selectedValue as String?;
    if (id == null) return;

    final item = disponiveis.firstWhere((e) => e.id == id);
    setState(() {
      _linhas.add(
        _Linha(
          itemEstoqueId: item.id,
          nome: item.nome,
          unidade: item.unidade,
          quantidadeInicial: 1,
        ),
      );
      _itemController.select(null);
    });
  }

  void _remover(int index) => setState(() {
        _linhas.removeAt(index).quantidade.dispose();
      });

  /// Finaliza em duas passadas.
  ///
  /// A primeira vai sem confirmação: se faltar saldo, o servidor recusa com
  /// `ESTOQUE_INSUFICIENTE` **sem gravar nada** e devolve o que falta. Aí
  /// mostramos o aviso e, se ela confirmar, repetimos a mesma chamada com
  /// `confirmar_estoque_insuficiente: true` — o saldo fica negativo e o
  /// servidor gera o alerta.
  Future<void> _submit({bool confirmarEstoqueInsuficiente = false}) async {
    setState(() {
      for (final linha in _linhas) {
        linha.quantidade.validate();
      }
    });
    if (_linhas.any((e) => e.quantidade.hasError)) return;

    final cubit = BlocProvider.of<AtendimentosCubit>(context);
    final navigator = Navigator.of(context);
    final materiais = [
      for (final linha in _linhas)
        MaterialAtendimentoModel(
          itemEstoqueId: linha.itemEstoqueId,
          nome: linha.nome,
          quantidade: AppValidators.parseMoney(linha.quantidade.text)!,
          preco: 0,
        ),
    ];

    await cubit.finalizarAtendimento(
      id: widget.atendimento.id,
      materiais: materiais,
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
              const SizedBox(height: 4),
              Text(
                context.l10n.confirmConsumptionHint,
                style: AppFonts.captionSmall(context),
              ),
              const SizedBox(height: 10),
              if (_linhas.isEmpty)
                Text(
                  context.l10n.emptyList,
                  style: AppFonts.caption(context),
                )
              else
                AppCard(
                  child: Column(
                    children: List.generate(
                      _linhas.length,
                      (index) => AppCardRow(
                        isFirst: index == 0,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _linhas[index].nome,
                                style: AppFonts.rowTitle(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 76,
                              child: AppInput(
                                controller: _linhas[index].quantidade,
                                label: AppUtils.unidadeEstoqueToString(
                                  _linhas[index].unidade,
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d.,]'),
                                  ),
                                ],
                              ),
                            ),
                            AppTappable(
                              minSize: 32,
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _remover(index),
                              child: const AppIcon(AppAssets.close, size: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              _buildSeletor(context),
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

  Widget _buildSeletor(BuildContext context) =>
      BlocBuilder<EstoqueCubit, EstoqueState>(
        buildWhen: (p, c) => p.getItensSubState != c.getItensSubState,
        builder: (context, state) {
          final itens = state.getItensSubState
                  .value<GetEstoqueItensResponseModel>()
                  ?.itens ??
              const <ItemEstoqueModel>[];

          if (itens.isEmpty) {
            return Text(
              context.l10n.noStockItemsToLink,
              style: AppFonts.caption(context),
            );
          }

          // Item já na lista sai do seletor: gastou mais é aumentar a
          // quantidade da linha, não criar uma segunda baixa do mesmo item.
          final disponiveis = itens
              .where((item) =>
                  item.ativo && !_linhas.any((e) => e.itemEstoqueId == item.id))
              .toList();

          // Atribuição direta em vez de `setItems`: este builder roda durante o
          // `build`, e `setItems` chama de volta o `setState` do dropdown.
          _itemController.items = [
            for (final item in disponiveis)
              DropdownModel(key: item.nome, value: item.id),
          ];
          if (!disponiveis.any((e) => e.id == _itemController.selectedValue)) {
            _itemController.selectedValue = null;
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AppDropdown(
                  controller: _itemController,
                  label: context.l10n.stockItemLabel,
                ),
              ),
              const SizedBox(width: 8),
              AppButton(
                label: context.l10n.addMaterialAction,
                type: AppButtonType.outlined,
                onPressed:
                    disponiveis.isEmpty ? null : () => _adicionar(disponiveis),
              ),
            ],
          );
        },
      );
}
