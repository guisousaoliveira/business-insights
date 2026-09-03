import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../cubits/estoque/estoque_cubit.dart';
import '../../../../models/dropdown_model.dart';
import '../../../../models/estoque/item_estoque_model.dart';
import '../../../../settings/app_enums.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../../settings/app_validators.dart';
import '../../../components/app_button.dart';
import '../../../components/app_dropdown.dart';
import '../../../components/app_input.dart';

class MovimentarEstoqueDialog extends StatefulWidget {
  final ItemEstoqueModel item;

  const MovimentarEstoqueDialog({super.key, required this.item});

  @override
  State<MovimentarEstoqueDialog> createState() =>
      _MovimentarEstoqueDialogState();
}

class _MovimentarEstoqueDialogState extends State<MovimentarEstoqueDialog> {
  late final AppDropdownController _tipo;
  late final AppInputController _quantidade;
  late final AppInputController _motivo;

  @override
  void initState() {
    super.initState();
    _tipo = AppDropdownController(selectedValue: TipoMovimentacao.saida);
    _quantidade = AppInputController(validator: AppValidators.validateQuantity);
    _motivo = AppInputController(isRequired: false);
  }

  @override
  void dispose() {
    _tipo.dispose();
    _quantidade.dispose();
    _motivo.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _quantidade.validate());
    if (_quantidade.hasError) return;

    final tipo = _tipo.selectedValue! as TipoMovimentacao;
    final motivo = _motivo.text.trim();
    BlocProvider.of<EstoqueCubit>(context).registrarMovimentacao(
      itemId: widget.item.id,
      tipo: tipo,
      quantidade: AppValidators.parseMoney(_quantidade.text)!,
      motivo: motivo.isEmpty ? AppUtils.tipoMovimentacaoToString(tipo) : motivo,
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    _tipo.items = [
      DropdownModel(
        key: context.l10n.stockExitOption,
        value: TipoMovimentacao.saida,
      ),
      DropdownModel(
        key: context.l10n.stockAdjustmentOption,
        value: TipoMovimentacao.ajuste,
      ),
    ];
    return Column(
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
        AppDropdown(
          controller: _tipo,
          label: context.l10n.movementTypeLabel,
        ),
        const SizedBox(height: 14),
        AppInput(
          controller: _quantidade,
          label: context.l10n.quantityLabel,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ],
          autofocus: true,
        ),
        const SizedBox(height: 14),
        AppInput(controller: _motivo, label: context.l10n.reasonLabel),
        const SizedBox(height: 20),
        AppButton(
          label: context.l10n.confirm,
          isExpanded: true,
          onPressed: _submit,
        ),
      ],
    );
  }
}
