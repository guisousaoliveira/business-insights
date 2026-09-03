import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../cubits/gastos/gastos_cubit.dart';
import '../../../../models/gastos/gasto_model.dart';
import '../../../../settings/app_constants.dart';
import '../../../../settings/app_enums.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_validators.dart';
import '../../../components/app_button.dart';
import '../../../components/app_date_picker.dart';
import '../../../components/app_dropdown.dart';
import '../../../components/app_input.dart';

class NovoGastoDialog extends StatefulWidget {
  final GastoModel? gasto;

  const NovoGastoDialog({super.key, this.gasto});

  @override
  State<NovoGastoDialog> createState() => _NovoGastoDialogState();
}

class _NovoGastoDialogState extends State<NovoGastoDialog> {
  late final AppInputController _nomeController;
  late final AppInputController _valorController;
  late final AppDatePickerController _prazoController;
  late final AppDropdownController _formaController;
  late final AppDropdownController _categoriaController;

  @override
  void initState() {
    super.initState();
    _nomeController =
        AppInputController(initialValue: widget.gasto?.nome ?? '');
    _valorController = AppInputController(
      initialValue: widget.gasto == null ? '' : '${widget.gasto!.valor}',
      validator: AppValidators.validateMoney,
    );
    _prazoController = AppDatePickerController(
      selectedDate: widget.gasto?.prazoPagamento ?? DateTime.now(),
    );
    _formaController = AppDropdownController(
      selectedValue: widget.gasto?.formaPagamento ?? FormaPagamento.pix,
    );
    _categoriaController = AppDropdownController(
      selectedValue: widget.gasto?.categoria ?? CategoriaGasto.material,
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _valorController.dispose();
    _prazoController.dispose();
    _formaController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _nomeController.validate();
      _valorController.validate();
      _prazoController.validate();
      _formaController.validate();
      _categoriaController.validate();
    });

    if (_nomeController.hasError ||
        _valorController.hasError ||
        _prazoController.hasError ||
        _formaController.hasError ||
        _categoriaController.hasError) {
      return;
    }

    final cubit = BlocProvider.of<GastosCubit>(context);
    final gasto = widget.gasto;
    if (gasto == null) {
      cubit.createGasto(
        nome: _nomeController.text.trim(),
        valor: AppValidators.parseMoney(_valorController.text)!,
        prazoPagamento: _prazoController.selectedDate!,
        formaPagamento: _formaController.selectedValue as FormaPagamento,
        categoria: _categoriaController.selectedValue as CategoriaGasto,
      );
    } else {
      cubit.editGasto(
        id: gasto.id,
        nome: _nomeController.text.trim(),
        valor: AppValidators.parseMoney(_valorController.text)!,
        prazoPagamento: _prazoController.selectedDate!,
        formaPagamento: _formaController.selectedValue as FormaPagamento,
        categoria: _categoriaController.selectedValue as CategoriaGasto,
        itens: gasto.itens,
      );
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    _formaController.items = AppConstants.formasPagamento(context);
    _categoriaController.items = AppConstants.categoriasGasto(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppInput(
          controller: _nomeController,
          label: context.l10n.descriptionLabel,
          autofocus: true,
        ),
        const SizedBox(height: 14),
        AppInput(
          controller: _valorController,
          label: context.l10n.valueLabel,
          hint: '0,00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ],
        ),
        const SizedBox(height: 14),
        AppDatePicker(
          controller: _prazoController,
          label: context.l10n.dueDateLabel,
        ),
        const SizedBox(height: 14),
        AppDropdown(
          controller: _formaController,
          label: context.l10n.paymentMethodLabel,
        ),
        const SizedBox(height: 14),
        AppDropdown(
          controller: _categoriaController,
          label: context.l10n.categoryLabel,
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
