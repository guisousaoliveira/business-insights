import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../cubits/estoque/estoque_cubit.dart';
import '../../../../models/estoque/item_estoque_model.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../../settings/app_validators.dart';
import '../../../components/app_button.dart';
import '../../../components/app_input.dart';

/// Reposição de um item. O custo unitário é opcional: informado, atualiza o
/// custo do item; em branco, mantém o que já estava.
class EntradaEstoqueDialog extends StatefulWidget {
  final ItemEstoqueModel item;

  const EntradaEstoqueDialog({super.key, required this.item});

  @override
  State<EntradaEstoqueDialog> createState() => _EntradaEstoqueDialogState();
}

class _EntradaEstoqueDialogState extends State<EntradaEstoqueDialog> {
  late final AppInputController _quantidadeController;
  late final AppInputController _custoController;
  late final AppInputController _motivoController;

  @override
  void initState() {
    super.initState();
    _quantidadeController = AppInputController(
      validator: AppValidators.validateMoney,
    );
    _custoController = AppInputController(
      isRequired: false,
      validator: AppValidators.validateMoney,
    );
    _motivoController = AppInputController(isRequired: false);
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _custoController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _quantidadeController.validate();
      _custoController.validate();
    });

    if (_quantidadeController.hasError || _custoController.hasError) return;

    final motivo = _motivoController.text.trim();

    BlocProvider.of<EstoqueCubit>(context).registrarEntrada(
      itemId: widget.item.id,
      quantidade: AppValidators.parseMoney(_quantidadeController.text)!,
      motivo: motivo.isEmpty ? context.l10n.stockEntryTitle : motivo,
      custoUnitario: AppValidators.parseMoney(_custoController.text),
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.item.nome, style: AppFonts.rowTitle(context)),
          const SizedBox(height: 2),
          Text(
            context.l10n.currentQuantity(
              AppUtils.quantityToString(widget.item.quantidadeAtual),
              widget.item.unidadeLabel,
            ),
            style: AppFonts.caption(context),
          ),
          const SizedBox(height: 16),
          AppInput(
            controller: _quantidadeController,
            label: context.l10n.quantityLabel,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            autofocus: true,
          ),
          const SizedBox(height: 14),
          AppInput(
            controller: _custoController,
            label: context.l10n.unitCostLabel,
            hint: AppUtils.numToMoney(widget.item.custoMedio),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
          ),
          const SizedBox(height: 14),
          AppInput(
            controller: _motivoController,
            label: context.l10n.reasonLabel,
          ),
          const SizedBox(height: 20),
          AppButton(
            label: context.l10n.confirm,
            isExpanded: true,
            onPressed: _submit,
          ),
        ],
      );
}
