import 'package:flutter/widgets.dart';

import '../../settings/app_assets.dart';
import '../../settings/app_colors.dart';
import '../../settings/app_fonts.dart';
import 'app_dialog.dart';
import 'app_icon.dart';
import 'app_tappable.dart';

/// Uma opção do [AppFilterPill]: o valor e como ele se chama na tela.
class AppFilterOption<T> {
  final T value;
  final String label;

  const AppFilterOption({required this.value, required this.label});
}

/// A pílula de filtro do protótipo — rótulo do que está selecionado e uma
/// seta. Tocar abre a lista de opções no mesmo contêiner do resto do app
/// (o bottom sheet do [AppDialog]).
///
/// É componente e não widget de tela porque duas telas já pedem o mesmo objeto:
/// o período do Resumo e os dois filtros de Atendimentos.
class AppFilterPill<T> extends StatelessWidget {
  /// Título da folha de opções — "Período", "Status".
  final String title;
  final T value;
  final List<AppFilterOption<T>> options;
  final ValueChanged<T> onChanged;

  /// Realce roxo quando o filtro sai do padrão. É o que faz uma lista filtrada
  /// não parecer uma lista vazia.
  final bool isActive;

  const AppFilterPill({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    this.isActive = false,
  });

  String _labelOf(T value) => options
      .firstWhere(
        (option) => option.value == value,
        orElse: () => options.first,
      )
      .label;

  Future<void> _open(BuildContext context) async {
    final selected = await AppDialog.show<T>(
      context: context,
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: options
            .map(
              (option) => AppTappable(
                onTap: () => Navigator.of(context).pop(option.value),
                borderRadius: BorderRadius.circular(10),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option.label,
                        style: AppFonts.rowTitle(context).copyWith(
                          color: option.value == value
                              ? AppColors.primaryAccent
                              : AppColors.text1,
                        ),
                      ),
                    ),
                    if (option.value == value)
                      const AppIcon(
                        AppAssets.check,
                        size: 16,
                        color: AppColors.primaryAccent,
                      ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );

    if (selected != null && selected != value) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) => AppTappable(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(20),
        minSize: 40,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(
              color: isActive ? AppColors.primaryMid : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _labelOf(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.rowTitle(context).copyWith(
                    color: isActive ? AppColors.primaryAccent : AppColors.text1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AppIcon(
                AppAssets.chevronDown,
                size: 16,
                color: isActive ? AppColors.primaryAccent : AppColors.text2,
              ),
            ],
          ),
        ),
      );
}
