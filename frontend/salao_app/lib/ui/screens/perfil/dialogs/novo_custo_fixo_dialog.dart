import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../cubits/perfil/perfil_cubit.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_validators.dart';
import '../../../components/app_button.dart';
import '../../../components/app_input.dart';

class NovoCustoFixoDialog extends StatefulWidget {
  const NovoCustoFixoDialog({super.key});

  @override
  State<NovoCustoFixoDialog> createState() => _NovoCustoFixoDialogState();
}

class _NovoCustoFixoDialogState extends State<NovoCustoFixoDialog> {
  late final AppInputController _descricaoController;
  late final AppInputController _valorController;

  @override
  void initState() {
    super.initState();
    _descricaoController = AppInputController();
    _valorController = AppInputController(
      validator: AppValidators.validateMoney,
    );
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _descricaoController.validate();
      _valorController.validate();
    });

    if (_descricaoController.hasError || _valorController.hasError) return;

    BlocProvider.of<PerfilCubit>(context).createCustoFixo(
      descricao: _descricaoController.text.trim(),
      valor: AppValidators.parseMoney(_valorController.text)!,
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Column(
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
          const SizedBox(height: 20),
          AppButton(
            label: context.l10n.save,
            isExpanded: true,
            onPressed: _submit,
          ),
        ],
      );
}
