import 'package:flutter/material.dart' show TextField, InputDecoration, OutlineInputBorder;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../settings/app_colors.dart';
import '../../settings/app_fonts.dart';
import '../../settings/app_globals.dart' as globals;

/// Estado e validação de um campo, fora do widget.
///
/// **"Obrigatório" não é validador** — é a flag [isRequired]. O validador só
/// roda depois que há texto, e devolve `null` quando está válido.
class AppInputController {
  final String? Function(String value)? validator;

  late final TextEditingController _textEditingController;
  late final FocusNode _focusNode;

  String? _error;
  bool _isDisposed = false;

  /// Público e mutável de propósito: há formulário que liga e desliga a
  /// obrigatoriedade de um campo conforme outro campo muda.
  bool isRequired;

  /// Injetado pelo widget para conseguir se redesenhar quando o erro muda.
  void Function()? onValueChangedSetState;

  AppInputController({
    this.isRequired = true,
    this.validator,
    String? initialValue,
  }) {
    _textEditingController = TextEditingController(text: initialValue);
    _focusNode = FocusNode();
  }

  String get text => _textEditingController.text;
  String? get error => _error;
  bool get hasError => _error != null;
  FocusNode get focusNode => _focusNode;

  set text(String value) {
    if (_isDisposed) return;
    _textEditingController.text = value;
  }

  void clear() {
    if (_isDisposed) return;
    _textEditingController.clear();
    _error = null;
  }

  void validate() {
    if (_isDisposed) return;
    if (isRequired && _textEditingController.text.trim().isEmpty) {
      _error = globals.l10n?.requiredInputError;
      return;
    }
    if (_textEditingController.text.trim().isEmpty) {
      _error = null;
      return;
    }
    _error = validator?.call(_textEditingController.text);
  }

  void dispose() {
    _isDisposed = true;
    _textEditingController.dispose();
    _focusNode.dispose();
  }
}

class AppInput extends StatefulWidget {
  final AppInputController controller;
  final String label;
  final String? hint;
  final bool isObscure;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final VoidCallback? onSubmitted;
  final bool autofocus;

  const AppInput({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.isObscure = false,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.onSubmitted,
    this.autofocus = false,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.onValueChangedSetState = () {
      if (mounted) setState(() {});
    };
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.controller.hasError;

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
        TextField(
          controller: widget.controller._textEditingController,
          focusNode: widget.controller.focusNode,
          obscureText: widget.isObscure,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.isObscure ? 1 : widget.maxLines,
          autofocus: widget.autofocus,
          style: AppFonts.input(context),
          cursorColor: AppColors.primary,
          onChanged: (_) {
            // Some com o erro assim que a usuária começa a corrigir; insistir
            // em vermelho enquanto ela digita é ruído, não ajuda.
            if (widget.controller.hasError) {
              setState(() => widget.controller._error = null);
            }
          },
          onSubmitted: (_) => widget.onSubmitted?.call(),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.surface2,
            hintText: widget.hint,
            hintStyle: AppFonts.input(context).copyWith(color: AppColors.text3),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: _border(AppColors.border),
            enabledBorder: _border(hasError ? AppColors.danger : AppColors.border),
            focusedBorder: _border(
              hasError ? AppColors.danger : AppColors.primary,
              width: 1.5,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            widget.controller.error!,
            style: AppFonts.captionSmall(context)
                .copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 0.5}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );
}
