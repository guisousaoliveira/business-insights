import 'package:flutter/widgets.dart';

import '../../settings/app_assets.dart';
import '../../settings/app_colors.dart';
import 'app_icon.dart';
import 'app_tappable.dart';

/// O quadradinho de "gasto pago" do protótipo: vazio com borda quando pendente,
/// verde com o check quando quitado.
///
/// Verde aqui é significado, não estilo — marcar um gasto como pago é um evento
/// financeiro positivo (S6).
class AppCheckBox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;

  const AppCheckBox({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) => AppTappable(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        borderRadius: BorderRadius.circular(6),
        minSize: 44,
        child: Center(
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: value ? AppColors.success : AppColors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? AppColors.success : AppColors.border,
                width: 1.5,
              ),
            ),
            child: value
                ? const AppIcon(
                    AppAssets.check,
                    size: 12,
                    color: AppColors.white,
                  )
                : null,
          ),
        ),
      );
}
