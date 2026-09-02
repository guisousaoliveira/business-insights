import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../cubits/servicos/servicos_cubit.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_validators.dart';
import '../../../components/app_button.dart';
import '../../../components/app_input.dart';

/// Cadastro de serviço. Os `produtos_padrao` (materiais que o serviço consome)
/// ficam de fora deste formulário por ora — dependem de escolher itens do
/// estoque, e a tela de Perfil do protótipo não mostra esse passo.
class NovoServicoDialog extends StatefulWidget {
  const NovoServicoDialog({super.key});

  @override
  State<NovoServicoDialog> createState() => _NovoServicoDialogState();
}

class _NovoServicoDialogState extends State<NovoServicoDialog> {
  late final AppInputController _nomeController;
  late final AppInputController _precoController;

  @override
  void initState() {
    super.initState();
    _nomeController = AppInputController();
    _precoController = AppInputController(
      validator: AppValidators.validateMoney,
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _nomeController.validate();
      _precoController.validate();
    });

    if (_nomeController.hasError || _precoController.hasError) return;

    BlocProvider.of<ServicosCubit>(context).createServico(
      nome: _nomeController.text.trim(),
      preco: AppValidators.parseMoney(_precoController.text)!,
    );

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
          const SizedBox(height: 20),
          AppButton(
            label: context.l10n.save,
            isExpanded: true,
            onPressed: _submit,
          ),
        ],
      );
}
