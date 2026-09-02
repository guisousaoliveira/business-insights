import 'package:flutter/widgets.dart';

import '../../settings/app_colors.dart';
import '../../settings/app_fonts.dart';

/// O rótulo cinza maiúsculo que abre cada bloco: "PENDENTES / PRÓXIMOS",
/// "SERVIÇOS MAIS REALIZADOS".
///
/// [color] existe porque o protótipo tinge o rótulo quando ele próprio é um
/// sinal — vermelho em "Precisam de reposição", verde em "Estoque ok".
class AppSectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  final Widget? trailing;

  const AppSectionLabel(
    this.label, {
    super.key,
    this.color = AppColors.text3,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label.toUpperCase(),
      style: AppFonts.sectionLabel(context).copyWith(color: color),
    );

    if (trailing == null) return text;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [text, trailing!],
    );
  }
}
