import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../cubits/perfil/perfil_cubit.dart';
import '../../../../models/dropdown_model.dart';
import '../../../../models/perfil/custo_fixo_model.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_utils.dart';
import '../../../../settings/app_validators.dart';
import '../../../components/app_button.dart';
import '../../../components/app_dialog.dart';
import '../../../components/app_dropdown.dart';
import '../../../components/app_input.dart';

/// Cadastro **e** edição de custo fixo. Devolve `true` quando algo mudou.
///
/// Sem [custoFixo] é um cadastro novo; com ele, a mesma folha vira edição e
/// ganha o botão de excluir — é onde a exclusão faz sentido, porque a linha da
/// lista já foi aberta e a usuária está olhando o que vai apagar.
class NovoCustoFixoDialog extends StatefulWidget {
  final CustoFixoModel? custoFixo;

  const NovoCustoFixoDialog({super.key, this.custoFixo});

  @override
  State<NovoCustoFixoDialog> createState() => _NovoCustoFixoDialogState();
}

class _NovoCustoFixoDialogState extends State<NovoCustoFixoDialog> {
  late final AppInputController _descricaoController;
  late final AppInputController _valorController;
  late final AppDropdownController _diaController;

  CustoFixoModel? get _custoFixo => widget.custoFixo;

  bool get _isEdicao => _custoFixo != null;

  @override
  void initState() {
    super.initState();
    _descricaoController = AppInputController(
      initialValue: _custoFixo?.descricao,
    );
    _valorController = AppInputController(
      initialValue:
          _custoFixo == null ? null : AppUtils.numToInput(_custoFixo!.valor),
      validator: AppValidators.validateMoney,
    );
    _diaController = AppDropdownController(
      selectedValue:
          _custoFixo?.diaVencimento ?? CustoFixoModel.diaVencimentoPadrao,
    );
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _diaController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _descricaoController.validate();
      _valorController.validate();
      _diaController.validate();
    });

    if (_descricaoController.hasError ||
        _valorController.hasError ||
        _diaController.hasError) {
      return;
    }

    final cubit = BlocProvider.of<PerfilCubit>(context);
    final descricao = _descricaoController.text.trim();
    final valor = AppValidators.parseMoney(_valorController.text)!;
    final dia = _diaController.selectedValue! as int;

    if (_isEdicao) {
      cubit.editCustoFixo(
        id: _custoFixo!.id,
        descricao: descricao,
        valor: valor,
        diaVencimento: dia,
      );
    } else {
      cubit.createCustoFixo(
        descricao: descricao,
        valor: valor,
        diaVencimento: dia,
      );
    }

    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: context.l10n.delete,
      message: context.l10n.deleteFixedCostQuestion(_custoFixo!.descricao),
      confirmLabel: context.l10n.delete,
    );

    if (!confirmed || !mounted) return;

    BlocProvider.of<PerfilCubit>(context).deleteCustoFixo(_custoFixo!.id);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    // Os rótulos dos dias vêm do ARB, e ler o ARB depende do `Localizations`
    // acima na árvore — coisa que o `initState` não pode fazer. Atribuição
    // direta em vez de `setItems`, que chamaria `setState` durante o `build`.
    //
    // 1 a 31: o mês curto é problema de quem cobra, não de quem cadastra.
    // Guardar "dia 31" e resolver a data na hora de avisar é o que mantém a
    // intenção da usuária intacta.
    _diaController.items = List.generate(
      31,
      (index) => DropdownModel(
        key: context.l10n.dueDayOption(index + 1),
        value: index + 1,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppInput(
          controller: _descricaoController,
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
        AppDropdown(
          controller: _diaController,
          label: context.l10n.dueDayLabel,
        ),
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
  }
}
