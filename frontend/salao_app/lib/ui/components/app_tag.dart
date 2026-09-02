import 'package:flutter/widgets.dart';

import '../../settings/app_colors.dart';
import '../../settings/app_enums.dart';
import '../../settings/app_fonts.dart';
import 'app_icon.dart';

/// Chip pequeno de status: `Agendado`, `crítico`, `material`, `2×`.
///
/// Os construtores nomeados são o contrato de cor semântica (S6): quem escreve
/// a tela escolhe o **significado**, não a cor.
class AppTag extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final Color? borderColor;

  const AppTag({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.borderColor,
  });

  /// Positivo: pago, finalizado, estoque saudável.
  const AppTag.success(this.label, {super.key, this.icon, this.borderColor})
      : background = AppColors.successLight,
        foreground = AppColors.success;

  /// Negativo: vencido, crítico, cancelado com prejuízo.
  const AppTag.danger(this.label, {super.key, this.icon, this.borderColor})
      : background = AppColors.dangerLight,
        foreground = AppColors.danger;

  /// Meio-termo: agendado, estoque em alerta, vencimento próximo.
  const AppTag.warning(this.label, {super.key, this.icon, this.borderColor})
      : background = AppColors.amberLight,
        foreground = AppColors.amber;

  /// Identidade — contagem, categoria. **Nunca** para indicar resultado.
  const AppTag.primary(this.label, {super.key, this.icon, this.borderColor})
      : background = AppColors.primaryLight,
        foreground = AppColors.primaryDark;

  /// Identidade com mais peso: o roxo cheio do protótipo, para o status que
  /// ainda vai acontecer. Continua sendo identidade, não resultado.
  const AppTag.accent(this.label, {super.key, this.icon, this.borderColor})
      : background = AppColors.accentTint,
        foreground = AppColors.primaryAccent;

  /// Inerte: cancelado, inativo.
  const AppTag.neutral(this.label, {super.key, this.icon, this.borderColor})
      : background = AppColors.surface2,
        foreground = AppColors.text3;

  factory AppTag.statusEstoque(StatusEstoque status, String label) =>
      switch (status) {
        StatusEstoque.negativo || StatusEstoque.critico => AppTag.danger(label),
        StatusEstoque.alerta => AppTag.warning(label),
        StatusEstoque.ok => AppTag.success(label),
      };

  /// Agendado é **roxo**, não âmbar: âmbar no app significa prazo apertado
  /// (gasto a vencer, estoque em alerta), e um horário marcado não é risco.
  /// Finalizado segue verde porque é a linha que entrou no caixa.
  factory AppTag.statusAtendimento(StatusAtendimento status, String label) =>
      switch (status) {
        StatusAtendimento.finalizado => AppTag.success(label),
        StatusAtendimento.agendado => AppTag.accent(label),
        StatusAtendimento.cancelado => AppTag.neutral(label),
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
          border: borderColor != null ? Border.all(color: borderColor!) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              AppIcon(icon!, size: 10, color: foreground),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: AppFonts.tag(context).copyWith(color: foreground),
            ),
          ],
        ),
      );
}
