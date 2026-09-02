import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../cubits/estoque/estoque_cubit.dart';
import '../../../../settings/app_constants.dart';
import '../../../../settings/app_enums.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_validators.dart';
import '../../../components/app_button.dart';
import '../../../components/app_dropdown.dart';
import '../../../components/app_input.dart';

class NovoItemDialog extends StatefulWidget {
  const NovoItemDialog({super.key});

  @override
  State<NovoItemDialog> createState() => _NovoItemDialogState();
}

class _NovoItemDialogState extends State<NovoItemDialog> {
  late final AppInputController _nomeController;
  late final AppInputController _quantidadeController;
  late final AppInputController _minimaController;
  late final AppInputController _custoController;
  late final AppDropdownController _unidadeController;
  late final AppDropdownController _categoriaController;

  @override
  void initState() {
    super.initState();
    _nomeController = AppInputController();
    _quantidadeController = AppInputController(
      validator: AppValidators.validateQuantity,
    );
    _minimaController = AppInputController(
      validator: AppValidators.validateQuantity,
    );
    _custoController = AppInputController(
      validator: AppValidators.validateMoney,
    );
    _unidadeController = AppDropdownController(
      selectedValue: UnidadeEstoque.un,
    );
    _categoriaController = AppDropdownController(
      selectedValue: CategoriaEstoque.outro,
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _quantidadeController.dispose();
    _minimaController.dispose();
    _custoController.dispose();
    _unidadeController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _nomeController.validate();
      _quantidadeController.validate();
      _minimaController.validate();
      _custoController.validate();
      _unidadeController.validate();
      _categoriaController.validate();
    });

    if (_nomeController.hasError ||
        _quantidadeController.hasError ||
        _minimaController.hasError ||
        _custoController.hasError ||
        _unidadeController.hasError ||
        _categoriaController.hasError) {
      return;
    }

    BlocProvider.of<EstoqueCubit>(context).createItem(
      nome: _nomeController.text.trim(),
      unidade: _unidadeController.selectedValue as UnidadeEstoque,
      categoria: _categoriaController.selectedValue as CategoriaEstoque,
      quantidadeAtual: AppValidators.parseMoney(_quantidadeController.text)!,
      quantidadeMinima: AppValidators.parseMoney(_minimaController.text)!,
      custoUnitario: AppValidators.parseMoney(_custoController.text)!,
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    _unidadeController.items = AppConstants.unidadesEstoque(context);
    _categoriaController.items = AppConstants.categoriasEstoque(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppInput(
          controller: _nomeController,
          label: context.l10n.itemNameLabel,
          autofocus: true,
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppDropdown(
                controller: _unidadeController,
                label: context.l10n.unitLabel,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AppDropdown(
                controller: _categoriaController,
                label: context.l10n.categoryLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppInput(
                controller: _quantidadeController,
                label: context.l10n.quantityLabel,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppInput(
                controller: _minimaController,
                label: context.l10n.minQuantityLabel,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AppInput(
          controller: _custoController,
          label: context.l10n.unitCostLabel,
          hint: '0,00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ],
        ),
        const SizedBox(height: 20),
        AppButton(
          label: context.l10n.save,
          isExpanded: true,
          onPressed: _submit,
        ),
      ],
    );
  }
}
