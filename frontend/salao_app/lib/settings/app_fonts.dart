import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Tipografia do protótipo.
///
/// **São funções que recebem `context`, nunca campos `static final`** — campo
/// estático é avaliado uma vez, não reage a resize e não responde a troca de
/// idioma (regra 8 do padrão).
///
/// O protótipo usa a fonte do sistema. Não declaramos `fontFamily` para não
/// mentir sobre um asset que não existe; adicionar Inter depois é acrescentar
/// `fontFamily: 'Inter'` aqui e a fonte no `pubspec.yaml`.
class AppFonts {
  const AppFonts._();

  /// Saldo do mês — o maior número da tela de Resumo.
  static TextStyle displayBalance(BuildContext context) => const TextStyle(
        fontSize: 27,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.text1,
      );

  /// Valor dos cartões de métrica (Pendente, Pago no mês, Itens em alerta).
  static TextStyle metricValue(BuildContext context) => const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.text1,
      );

  /// Título da página no cabeçalho.
  static TextStyle pageTitle(BuildContext context) => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.text1,
      );

  static TextStyle sectionTitle(BuildContext context) => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.text1,
      );

  /// Título da app bar mobile.
  static TextStyle appBarTitle(BuildContext context) => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.text1,
      );

  /// Rótulo de seção — sempre em maiúsculas, cinza claro.
  static TextStyle sectionLabel(BuildContext context) => const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.text3,
      );

  /// Nome de cliente, de item, de gasto — o texto principal de uma linha.
  static TextStyle rowTitle(BuildContext context) => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.text1,
      );

  /// Valor monetário ao final de uma linha.
  static TextStyle rowValue(BuildContext context) => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.text1,
      );

  /// Subtítulo de linha: "2 dias atrás", "Atual: 30 g".
  static TextStyle caption(BuildContext context) => const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.text2,
      );

  /// Legenda menor: "líquido", "previsto", "pix · até 03/06".
  static TextStyle captionSmall(BuildContext context) => const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: AppColors.text3,
      );

  /// Texto dentro de uma tag/chip.
  static TextStyle tag(BuildContext context) => const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
      );

  /// Rótulo de botão e de FAB.
  static TextStyle button(BuildContext context) => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      );

  /// Valor grande dos cartões de insight (Ticket médio, Margem).
  static TextStyle insightValue(BuildContext context) => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.text1,
      );

  /// Campo de formulário.
  static TextStyle input(BuildContext context) => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.text1,
      );
}
