import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../cubits/perfil/perfil_cubit.dart';
import '../../../../models/perfil/perfil_model.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_validators.dart';
import '../../../components/app_button.dart';
import '../../../components/app_input.dart';

class EditarPerfilDialog extends StatefulWidget {
  final PerfilModel perfil;

  const EditarPerfilDialog({super.key, required this.perfil});

  @override
  State<EditarPerfilDialog> createState() => _EditarPerfilDialogState();
}

class _EditarPerfilDialogState extends State<EditarPerfilDialog> {
  late final AppInputController _nome;
  late final AppInputController _proprietaria;
  late final AppInputController _whatsapp;
  late final AppInputController _meta;

  @override
  void initState() {
    super.initState();
    _nome = AppInputController(initialValue: widget.perfil.nome);
    _proprietaria =
        AppInputController(initialValue: widget.perfil.proprietaria);
    _whatsapp = AppInputController(
      initialValue: widget.perfil.telefoneWhatsapp ?? '',
      isRequired: false,
    );
    _meta = AppInputController(
      initialValue: '${widget.perfil.metaFaturamentoMensal}',
      validator: AppValidators.validateMoney,
    );
  }

  @override
  void dispose() {
    _nome.dispose();
    _proprietaria.dispose();
    _whatsapp.dispose();
    _meta.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _nome.validate();
      _proprietaria.validate();
      _meta.validate();
    });
    if (_nome.hasError || _proprietaria.hasError || _meta.hasError) return;
    BlocProvider.of<PerfilCubit>(context).updatePerfil(
      PerfilModel(
        id: widget.perfil.id,
        nome: _nome.text.trim(),
        proprietaria: _proprietaria.text.trim(),
        telefoneWhatsapp: _whatsapp.text.trim(),
        fotoUrl: widget.perfil.fotoUrl,
        metaFaturamentoMensal: AppValidators.parseMoney(_meta.text)!,
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInput(controller: _nome, label: context.l10n.salonNameLabel),
          const SizedBox(height: 12),
          AppInput(
              controller: _proprietaria, label: context.l10n.ownerNameLabel),
          const SizedBox(height: 12),
          AppInput(controller: _whatsapp, label: context.l10n.whatsappLabel),
          const SizedBox(height: 12),
          AppInput(
            controller: _meta,
            label: context.l10n.monthlyGoal,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
          ),
          const SizedBox(height: 20),
          AppButton(
              label: context.l10n.save, isExpanded: true, onPressed: _submit),
        ],
      );
}
