import 'package:flutter/material.dart' show DropdownButton, DropdownMenuItem;
import 'package:flutter/widgets.dart';

import '../../models/dropdown_model.dart';
import '../../settings/app_assets.dart';
import '../../settings/app_colors.dart';
import '../../settings/app_fonts.dart';
import '../../settings/app_globals.dart' as globals;
import 'app_icon.dart';

/// Análogo ao `AppInputController`: itens, valor selecionado, callback e
/// `validate()`.
///
/// O callback dispara **do controller**, não de um botão "aplicar" — é o que
/// faz um filtro recarregar a lista assim que muda (capítulo 08 do padrão).
class AppDropdownController {
  List<DropdownModel> items;
  Object? selectedValue;
  final void Function(Object? value)? onValueSelected;
  final bool isRequired;

  String? _error;
  bool _isDisposed = false;

  void Function()? onValueChangedSetState;

  AppDropdownController({
    this.items = const [],
    this.selectedValue,
    this.onValueSelected,
    this.isRequired = true,
  });

  String? get error => _error;
  bool get hasError => _error != null;

  void select(Object? value) {
    if (_isDisposed) return;
    selectedValue = value;
    _error = null;
    onValueSelected?.call(value);
    onValueChangedSetState?.call();
  }

  void setItems(List<DropdownModel> value, {bool keepSelection = true}) {
    if (_isDisposed) return;
    items = value;
    if (!keepSelection || !value.any((item) => item.value == selectedValue)) {
      selectedValue = null;
    }
    onValueChangedSetState?.call();
  }

  void validate() {
    if (_isDisposed) return;
    _error = isRequired && selectedValue == null
        ? globals.l10n?.requiredInputError
        : null;
  }

  void dispose() => _isDisposed = true;
}

class AppDropdown extends StatefulWidget {
  final AppDropdownController controller;
  final String label;
  final String? hint;

  const AppDropdown({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
  });

  @override
  State<AppDropdown> createState() => _AppDropdownState();
}

class _AppDropdownState extends State<AppDropdown> {
  @override
  void initState() {
    super.initState();
    widget.controller.onValueChangedSetState = () {
      if (mounted) setState(() {});
    };
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: AppFonts.captionSmall(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.text2,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: controller.hasError ? AppColors.danger : AppColors.border,
              width: 0.5,
            ),
          ),
          child: DropdownButton<Object>(
            value: controller.selectedValue,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: const AppIcon(AppAssets.chevronDown, size: 18),
            hint: Text(
              widget.hint ?? '',
              style: AppFonts.input(context).copyWith(color: AppColors.text3),
            ),
            style: AppFonts.input(context),
            dropdownColor: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            items: controller.items
                .map(
                  (item) => DropdownMenuItem<Object>(
                    value: item.value,
                    child: Text(item.key, style: AppFonts.input(context)),
                  ),
                )
                .toList(),
            onChanged: controller.select,
          ),
        ),
        if (controller.hasError) ...[
          const SizedBox(height: 4),
          Text(
            controller.error!,
            style: AppFonts.captionSmall(context)
                .copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }
}

/// O seletor compacto de cabeçalho ("mai/2025 ▾") — mesmo dado, densidade
/// menor, sem rótulo.
class AppChipSelect extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const AppChipSelect({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppFonts.caption(context)
                    .copyWith(fontSize: 12, color: AppColors.text2),
              ),
              const SizedBox(width: 6),
              const AppIcon(AppAssets.chevronDown, size: 14),
            ],
          ),
        ),
      );
}
