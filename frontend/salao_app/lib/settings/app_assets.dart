import 'package:flutter/material.dart' show IconData, Icons;

/// Catálogo único de ícones do app.
///
/// O protótipo usa **Tabler Icons**. Não temos os SVGs no repositório, e
/// referenciar asset inexistente quebra em runtime — então mapeamos cada ícone
/// para o equivalente mais próximo do conjunto Material, que já vem no binário.
///
/// **O ganho do padrão continua de pé:** nenhuma tela escreve `Icons.*`; o dia
/// que os SVGs da Tabler entrarem, muda só este arquivo (e o `AppIcon` passa a
/// devolver `SvgPicture`). O equivalente Tabler está em comentário ao lado.
class AppAssets {
  const AppAssets._();

  // ── Navegação ──────────────────────────────────────────────────────────────
  static const atendimentos = Icons.calendar_today_outlined; // ti-calendar
  static const atendimentosActive = Icons.calendar_today;
  static const gastos = Icons.account_balance_wallet_outlined; // ti-wallet
  static const gastosActive = Icons.account_balance_wallet;
  static const resumo = Icons.bar_chart_outlined; // ti-chart-bar
  static const resumoActive = Icons.bar_chart;
  static const estoque = Icons.inventory_2_outlined; // ti-package
  static const estoqueActive = Icons.inventory_2;
  static const perfil = Icons.storefront_outlined; // ti-building-store
  static const perfilActive = Icons.storefront;

  // ── Ações ──────────────────────────────────────────────────────────────────
  static const add = Icons.add; // ti-plus
  static const edit = Icons.edit_outlined; // ti-edit
  static const delete = Icons.delete_outline;
  static const check = Icons.check; // ti-check
  static const close = Icons.close;
  static const history = Icons.history; // ti-history
  static const chevronDown = Icons.keyboard_arrow_down; // ti-chevron-down
  static const chevronRight = Icons.keyboard_arrow_right;
  static const back = Icons.arrow_back;
  static const logout = Icons.logout;
  static const search = Icons.search;

  // ── Sinal e conteúdo ───────────────────────────────────────────────────────
  static const arrowUp = Icons.arrow_upward; // ti-arrow-up
  static const arrowDown = Icons.arrow_downward;
  static const receipt = Icons.receipt_long_outlined; // ti-receipt
  static const chartPie = Icons.pie_chart_outline; // ti-chart-pie
  static const trendingUp = Icons.trending_up; // ti-trending-up
  static const trendingDown = Icons.trending_down;
  static const star = Icons.star_border; // ti-star
  static const scissors = Icons.content_cut; // ti-cut
  static const alert = Icons.notifications_outlined;
  static const alertActive = Icons.notifications;
  static const warning = Icons.warning_amber_rounded;
  static const empty = Icons.inbox_outlined;
  static const error = Icons.cloud_off_outlined;

  /// Tipo do ícone hoje. Trocar para `String` (caminho do SVG) é a mudança que
  /// o `AppIcon` vai absorver quando os assets chegarem.
  static const IconData placeholder = Icons.circle_outlined;
}
