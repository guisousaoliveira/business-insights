import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../cubits/estoque/estoque_cubit.dart';
import '../../../../cubits/kits/kits_cubit.dart';
import '../../../../models/dropdown_model.dart';
import '../../../../models/estoque/get_estoque_itens_response_model.dart';
import '../../../../models/estoque/item_estoque_model.dart';
import '../../../../models/kits/kit_model.dart';
import '../../../../settings/app_assets.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_validators.dart';
import '../../../components/app_button.dart';
import '../../../components/app_card.dart';
import '../../../components/app_dropdown.dart';
import '../../../components/app_icon.dart';
import '../../../components/app_input.dart';
import '../../../components/app_tappable.dart';

class _KitLine {
  final ItemEstoqueModel item;
  final AppInputController quantidade;

  _KitLine(this.item)
      : quantidade = AppInputController(
          initialValue: '1',
          validator: AppValidators.validateQuantity,
        );
}

class NovoKitDialog extends StatefulWidget {
  const NovoKitDialog({super.key});

  @override
  State<NovoKitDialog> createState() => _NovoKitDialogState();
}

class _NovoKitDialogState extends State<NovoKitDialog> {
  late final AppInputController _nome;
  late final AppInputController _preco;
  late final AppDropdownController _item;
  final List<_KitLine> _lines = [];

  @override
  void initState() {
    super.initState();
    _nome = AppInputController();
    _preco = AppInputController(validator: AppValidators.validateMoney);
    _item = AppDropdownController(isRequired: false);
  }

  @override
  void dispose() {
    _nome.dispose();
    _preco.dispose();
    _item.dispose();
    for (final line in _lines) {
      line.quantidade.dispose();
    }
    super.dispose();
  }

  void _add(List<ItemEstoqueModel> available) {
    final id = _item.selectedValue as String?;
    if (id == null) return;
    setState(() {
      _lines.add(_KitLine(available.firstWhere((item) => item.id == id)));
      _item.select(null);
    });
  }

  void _submit() {
    setState(() {
      _nome.validate();
      _preco.validate();
      for (final line in _lines) {
        line.quantidade.validate();
      }
    });
    if (_nome.hasError ||
        _preco.hasError ||
        _lines.isEmpty ||
        _lines.any((line) => line.quantidade.hasError)) {
      return;
    }
    BlocProvider.of<KitsCubit>(context).createKit(
      nome: _nome.text.trim(),
      precoVenda: AppValidators.parseMoney(_preco.text)!,
      itens: _lines
          .map((line) => KitItemModel(
                itemEstoqueId: line.item.id,
                nome: line.item.nome,
                quantidade: AppValidators.parseMoney(line.quantidade.text)!,
                unidade: line.item.unidade,
              ))
          .toList(),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInput(controller: _nome, label: context.l10n.kitNameLabel),
          const SizedBox(height: 12),
          AppInput(
            controller: _preco,
            label: context.l10n.unitPriceLabel,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
          ),
          const SizedBox(height: 16),
          Text(context.l10n.kitComposition,
              style: AppFonts.sectionLabel(context)),
          const SizedBox(height: 8),
          if (_lines.isNotEmpty)
            AppCard(
              child: Column(
                children: List.generate(_lines.length, (index) {
                  final line = _lines[index];
                  return AppCardRow(
                    isFirst: index == 0,
                    child: Row(children: [
                      Expanded(child: Text(line.item.nome)),
                      SizedBox(
                        width: 76,
                        child: AppInput(
                          controller: line.quantidade,
                          label: line.item.unidadeLabel,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                      AppTappable(
                        onTap: () => setState(
                            () => _lines.removeAt(index).quantidade.dispose()),
                        child: const AppIcon(AppAssets.close, size: 16),
                      ),
                    ]),
                  );
                }),
              ),
            ),
          const SizedBox(height: 10),
          _selector(context),
          const SizedBox(height: 20),
          AppButton(
            label: context.l10n.save,
            isExpanded: true,
            onPressed: _lines.isEmpty ? null : _submit,
          ),
        ],
      );

  Widget _selector(BuildContext context) =>
      BlocBuilder<EstoqueCubit, EstoqueState>(
        buildWhen: (p, c) => p.getItensSubState != c.getItensSubState,
        builder: (context, state) {
          final items = state.getItensSubState
                  .value<GetEstoqueItensResponseModel>()
                  ?.itens ??
              const <ItemEstoqueModel>[];
          final available = items
              .where((item) => !_lines.any((line) => line.item.id == item.id))
              .toList();
          _item.items = available
              .map((item) => DropdownModel(key: item.nome, value: item.id))
              .toList();
          return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: AppDropdown(
                controller: _item,
                label: context.l10n.stockItemLabel,
              ),
            ),
            const SizedBox(width: 8),
            AppButton(
              label: context.l10n.add,
              type: AppButtonType.outlined,
              onPressed: available.isEmpty ? null : () => _add(available),
            ),
          ]);
        },
      );
}
