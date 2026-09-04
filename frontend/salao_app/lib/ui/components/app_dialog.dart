import 'package:flutter/material.dart'
    show Dialog, showDialog, showModalBottomSheet;
import 'package:flutter/widgets.dart';

import '../../settings/app_assets.dart';
import '../../settings/app_colors.dart';
import '../../settings/app_extensions.dart';
import '../../settings/app_fonts.dart';
import '../../settings/app_media_querys.dart';
import 'app_button.dart';
import 'app_icon.dart';
import 'app_tappable.dart';

/// Contêiner de formulário e de confirmação.
///
/// **A mesma chamada rende as duas cascas**: bottom sheet no mobile (como no
/// protótipo, onde o polegar alcança) e diálogo centrado na web. A tela não
/// escolhe — só descreve o conteúdo.
///
/// Padrão de retorno do capítulo 07: o diálogo executa a ação e devolve `true`;
/// quem o abriu decide recarregar a lista.
class AppDialog {
  const AppDialog._();

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    if (isWideLayout(context)) {
      return showDialog<T>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: AppColors.surface,
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: _DialogFrame(title: title, child: child),
          ),
        ),
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => Padding(
        // Sobe junto com o teclado, senão o campo em foco fica coberto.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _DialogFrame(title: title, child: child),
      ),
    );
  }

  /// Confirmação destrutiva. Devolve `true` se a usuária confirmou.
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmLabel,
    bool isDestructive = true,
  }) async {
    final result = await show<bool>(
      context: context,
      title: title,
      child: _ConfirmContent(
        message: message,
        confirmLabel: confirmLabel,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }
}

class _DialogFrame extends StatelessWidget {
  final String title;
  final Widget child;

  const _DialogFrame({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: AppFonts.pageTitle(context)),
                  ),
                  AppTappable(
                    onTap: () => Navigator.of(context).pop(),
                    minSize: 32,
                    borderRadius: BorderRadius.circular(16),
                    child: const AppIcon(AppAssets.close, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      );
}

class _ConfirmContent extends StatelessWidget {
  final String message;
  final String? confirmLabel;
  final bool isDestructive;

  const _ConfirmContent({
    required this.message,
    this.confirmLabel,
    required this.isDestructive,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: AppFonts.caption(context)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: context.l10n.cancel,
                type: AppButtonType.text,
                onPressed: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(width: 8),
              AppButton(
                label: confirmLabel ?? context.l10n.confirm,
                type:
                    isDestructive ? AppButtonType.danger : AppButtonType.filled,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ],
      );
}
