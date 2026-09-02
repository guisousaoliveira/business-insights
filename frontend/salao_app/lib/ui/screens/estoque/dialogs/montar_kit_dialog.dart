import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../cubits/kits/kits_cubit.dart';
import '../../../../models/error_model.dart';
import '../../../../models/estoque/estoque_faltante_model.dart';
import '../../../../models/kits/kit_model.dart';
import '../../../../settings/app_colors.dart';
import '../../../../settings/app_error_codes.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../../settings/app_validators.dart';
import '../../../components/app_button.dart';
import '../../../components/app_input.dart';
import '../../../dialogs/estoque_insuficiente_dialog.dart';

/// Montagem: consome os insumos do estoque e soma ao saldo de kits prontos.
///
/// Passa pelo mesmo aviso de estoque insuficiente da finalização de
/// atendimento — é a mesma baixa de estoque, e a mesma decisão da usuária.
class MontarKitDialog extends StatefulWidget {
  final KitModel kit;

  const MontarKitDialog({super.key, required this.kit});

  @override
  State<MontarKitDialog> createState() => _MontarKitDialogState();
}

class _MontarKitDialogState extends State<MontarKitDialog> {
  late final AppInputController _quantidadeController;

  @override
  void initState() {
    super.initState();
    _quantidadeController = AppInputController(
      initialValue: '1',
      validator: AppValidators.validateMoney,
    );
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    super.dispose();
  }

  Future<void> _submit({bool confirmarEstoqueInsuficiente = false}) async {
    setState(_quantidadeController.validate);
    if (_quantidadeController.hasError) return;

    final cubit = BlocProvider.of<KitsCubit>(context);
    final navigator = Navigator.of(context);

    await cubit.montarKit(
      id: widget.kit.id,
      quantidade: AppValidators.parseMoney(_quantidadeController.text)!,
      confirmarEstoqueInsuficiente: confirmarEstoqueInsuficiente,
    );
    if (!mounted) return;

    final data = cubit.state.montarKitSubState.data;
    if (data is ErrorModel && data.code == AppErrorCodes.insufficientStock) {
      final confirmou = await EstoqueInsuficienteDialog.show(
        context: context,
        faltantes: EstoqueFaltanteModel.listFrom(data.result),
      );
      if (confirmou && mounted) {
        await _submit(confirmarEstoqueInsuficiente: true);
      }
      return;
    }

    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.kit.nome, style: AppFonts.rowTitle(context)),
          const SizedBox(height: 2),
          Text(widget.kit.resumoItens, style: AppFonts.caption(context)),
          const SizedBox(height: 10),
          Text(
            context.l10n.assemblableQuantity(
              AppUtils.quantityToString(widget.kit.quantidadeMontavel),
            ),
            style: AppFonts.caption(context).copyWith(
              color: widget.kit.podeMontar
                  ? AppColors.success
                  : AppColors.danger,
            ),
          ),
          const SizedBox(height: 16),
          AppInput(
            controller: _quantidadeController,
            label: context.l10n.quantityToAssembleLabel,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            autofocus: true,
          ),
          const SizedBox(height: 20),
          BlocBuilder<KitsCubit, KitsState>(
            buildWhen: (p, c) => p.montarKitSubState != c.montarKitSubState,
            builder: (context, state) => AppButton(
              label: context.l10n.assembleKit,
              isExpanded: true,
              isLoading: state.montarKitSubState.isLoading,
              onPressed: _submit,
            ),
          ),
        ],
      );
}
