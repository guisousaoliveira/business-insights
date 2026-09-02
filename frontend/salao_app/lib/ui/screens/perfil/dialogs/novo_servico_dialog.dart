import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../cubits/estoque/estoque_cubit.dart';
import '../../../../cubits/servicos/servicos_cubit.dart';
import '../../../../models/dropdown_model.dart';
import '../../../../models/estoque/get_estoque_itens_response_model.dart';
import '../../../../models/estoque/item_estoque_model.dart';
import '../../../../models/servicos/servico_model.dart';
import '../../../../settings/app_assets.dart';
import '../../../../settings/app_enums.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../../settings/app_validators.dart';
import '../../../components/app_button.dart';
import '../../../components/app_card.dart';
import '../../../components/app_dialog.dart';
import '../../../components/app_dropdown.dart';
import '../../../components/app_icon.dart';
import '../../../components/app_input.dart';
import '../../../components/app_tappable.dart';

/// Uma linha de material vinculado. Guarda o controller da quantidade junto do
/// item: é o que deixa editar várias linhas sem um mapa de controllers paralelo
/// à lista, que sai de sincronia na primeira remoção.
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

/// Cadastro **e** edição de serviço, com os materiais que ele consome.
///
/// O vínculo com o estoque é o que faz a finalização de atendimento já vir
/// preenchida: o serviço diz o que gasta, e a baixa aparece pronta para
/// conferir em vez de ser lembrada do zero.
class NovoServicoDialog extends StatefulWidget {
  final ServicoModel? servico;

  const NovoServicoDialog({super.key, this.servico});

  @override
  State<NovoServicoDialog> createState() => _NovoServicoDialogState();
}

class _NovoServicoDialogState extends State<NovoServicoDialog> {
  late final AppInputController _nomeController;
  late final AppInputController _precoController;
  late final AppDropdownController _itemController;
  late final List<_Linha> _linhas;

  ServicoModel? get _servico => widget.servico;

  bool get _isEdicao => _servico != null;

  @override
  void initState() {
    super.initState();
    _nomeController = AppInputController(initialValue: _servico?.nome);
    _precoController = AppInputController(
      initialValue:
          _servico == null ? null : AppUtils.numToInput(_servico!.preco),
      validator: AppValidators.validateMoney,
    );
    _itemController = AppDropdownController(isRequired: false);
    _linhas = [
      for (final produto
          in _servico?.produtosPadrao ?? const <ProdutoPadraoModel>[])
        _Linha(
          itemEstoqueId: produto.itemEstoqueId,
          nome: produto.nome,
          unidade: produto.unidade,
          quantidadeInicial: produto.quantidade,
        ),
    ];

    // O catálogo de estoque não é buscado pela tela de Perfil: sem isto o
    // seletor de material abre vazio na primeira vez.
    BlocProvider.of<EstoqueCubit>(context).getItens();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    _itemController.dispose();
    for (final linha in _linhas) {
      linha.quantidade.dispose();
    }
    super.dispose();
  }

  void _vincular(List<ItemEstoqueModel> disponiveis) {
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

  void _submit() {
    setState(() {
      _nomeController.validate();
      _precoController.validate();
      for (final linha in _linhas) {
        linha.quantidade.validate();
      }
    });

    if (_nomeController.hasError ||
        _precoController.hasError ||
        _linhas.any((e) => e.quantidade.hasError)) {
      return;
    }

    final cubit = BlocProvider.of<ServicosCubit>(context);
    final nome = _nomeController.text.trim();
    final preco = AppValidators.parseMoney(_precoController.text)!;
    final produtos = [
      for (final linha in _linhas)
        ProdutoPadraoModel(
          itemEstoqueId: linha.itemEstoqueId,
          nome: linha.nome,
          quantidade: AppValidators.parseMoney(linha.quantidade.text)!,
          unidade: linha.unidade,
        ),
    ];

    if (_isEdicao) {
      cubit.editServico(
        id: _servico!.id,
        nome: nome,
        preco: preco,
        produtosPadrao: produtos,
      );
    } else {
      cubit.createServico(nome: nome, preco: preco, produtosPadrao: produtos);
    }

    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: context.l10n.delete,
      message: context.l10n.deleteServiceQuestion(_servico!.nome),
      confirmLabel: context.l10n.delete,
    );

    if (!confirmed || !mounted) return;

    BlocProvider.of<ServicosCubit>(context).deleteServico(_servico!.id);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInput(
            controller: _nomeController,
            label: context.l10n.serviceNameLabel,
            autofocus: true,
          ),
          const SizedBox(height: 14),
          AppInput(
            controller: _precoController,
            label: context.l10n.priceLabel,
            hint: '0,00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            context.l10n.defaultProductsLabel.toUpperCase(),
            style: AppFonts.sectionLabel(context),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.defaultProductsHint,
            style: AppFonts.captionSmall(context),
          ),
          const SizedBox(height: 10),
          if (_linhas.isEmpty)
            Text(
              context.l10n.noDefaultProducts,
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
                            keyboardType: const TextInputType.numberWithOptions(
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
          AppButton(
            label: _isEdicao ? context.l10n.saveChanges : context.l10n.save,
            isExpanded: true,
            onPressed: _submit,
          ),
          if (_isEdicao) ...[
            const SizedBox(height: 8),
            AppButton(
              label: context.l10n.delete,
              type: AppButtonType.text,
              isExpanded: true,
              onPressed: _delete,
            ),
          ],
        ],
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

          // Item já vinculado sai da lista: duas linhas do mesmo item viram
          // duas baixas, e ninguém confere isso na hora de finalizar.
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
                label: context.l10n.linkProductAction,
                type: AppButtonType.outlined,
                onPressed:
                    disponiveis.isEmpty ? null : () => _vincular(disponiveis),
              ),
            ],
          );
        },
      );
}
