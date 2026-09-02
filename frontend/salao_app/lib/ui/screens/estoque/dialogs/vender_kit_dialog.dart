import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../cubits/kits/kits_cubit.dart';
import '../../../../models/kits/kit_model.dart';
import '../../../../settings/app_constants.dart';
import '../../../../settings/app_enums.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../../settings/app_validators.dart';
import '../../../components/app_button.dart';
import '../../../components/app_dropdown.dart';
import '../../../components/app_input.dart';

/// Venda avulsa de kit, fora do atendimento. Baixa do saldo de kits montados e
/// vira receita do mês.
///
/// O preço vem preenchido com o do cadastro, mas é editável: desconto de balcão
/// acontece, e o servidor guarda o preço da venda como snapshot.
class VenderKitDialog extends StatefulWidget {
  final KitModel kit;

  const VenderKitDialog({super.key, required this.kit});

  @override
  State<VenderKitDialog> createState() => _VenderKitDialogState();
}

class _VenderKitDialogState extends State<VenderKitDialog> {
  late final AppInputController _quantidadeController;
  late final AppInputController _precoController;
  late final AppDropdownController _formaController;

  @override
  void initState() {
    super.initState();
    _quantidadeController = AppInputController(
      initialValue: '1',
      validator: AppValidators.validateMoney,
    );
    _precoController = AppInputController(
      initialValue: AppUtils.numToInput(widget.kit.precoVenda),
      validator: AppValidators.validateMoney,
    );
    _formaController = AppDropdownController(selectedValue: FormaPagamento.pix);
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _precoController.dispose();
    _formaController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _quantidadeController.validate();
      _precoController.validate();
      _formaController.validate();
    });

    if (_quantidadeController.hasError ||
        _precoController.hasError ||
        _formaController.hasError) {
      return;
    }

    BlocProvider.of<KitsCubit>(context).venderKit(
      id: widget.kit.id,
      quantidade: AppValidators.parseMoney(_quantidadeController.text)!,
      formaPagamento: _formaController.selectedValue as FormaPagamento,
      precoUnitario: AppValidators.parseMoney(_precoController.text),
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    _formaController.items = AppConstants.formasPagamento(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.kit.nome, style: AppFonts.rowTitle(context)),
        const SizedBox(height: 2),
        Text(
          context.l10n.assembledQuantity(
            AppUtils.quantityToString(widget.kit.quantidadeMontada),
          ),
          style: AppFonts.caption(context),
        ),
        const SizedBox(height: 16),
        AppInput(
          controller: _quantidadeController,
          label: context.l10n.quantityToSellLabel,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ],
          autofocus: true,
        ),
        const SizedBox(height: 14),
        AppInput(
          controller: _precoController,
          label: context.l10n.unitPriceLabel,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ],
        ),
        const SizedBox(height: 14),
        AppDropdown(
          controller: _formaController,
          label: context.l10n.paymentMethodLabel,
        ),
        const SizedBox(height: 20),
        AppButton(
          label: context.l10n.sellKit,
          isExpanded: true,
          onPressed: _submit,
        ),
      ],
    );
  }
}
