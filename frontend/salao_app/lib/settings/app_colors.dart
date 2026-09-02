import 'package:flutter/painting.dart';

/// Paleta do protótipo `design-todas-telas.html`.
///
/// **Verde, vermelho e âmbar não são decoração — são significado** (S6 da
/// adaptação): saldo positivo/negativo, pago/pendente, estoque ok/alerta.
/// Um número financeiro nunca é roxo; um botão nunca é verde.
class AppColors {
  const AppColors._();

  // ── Identidade e ação ──────────────────────────────────────────────────────
  static const primary = Color(0xFFBD6DF2);
  static const primaryDark = Color(0xFF896393);
  static const primaryAccent = Color(0xFFBD4EBF);
  static const primaryMid = Color(0xFFC9A0F2);
  static const primaryLight = Color(0xFFEAE6E5);

  /// Sombra do botão e do FAB primários — `rgba(189,109,242,.32/.42)`.
  static const primaryShadow = Color(0x52BD6DF2);

  // ── Positivo: valor que entra, gasto quitado, estoque saudável ─────────────
  static const success = Color(0xFF3B6D11);
  static const successLight = Color(0xFFEAF3DE);
  static const successMid = Color(0xFFC0DD97);

  // ── Negativo: valor que sai, pendência, estoque crítico ────────────────────
  static const danger = Color(0xFFA32D2D);
  static const dangerLight = Color(0xFFFCEBEB);
  static const dangerMid = Color(0xFFF09595);

  // ── Meio-termo: agendado, estoque em alerta, vencimento próximo ────────────
  static const amber = Color(0xFF854F0B);
  static const amberLight = Color(0xFFFAEEDA);

  // ── Texto ──────────────────────────────────────────────────────────────────
  static const text1 = Color(0xFF1A1A1A);
  static const text2 = Color(0xFF6B6B6B);
  static const text3 = Color(0xFF9E9E9E);

  // ── Superfícies ────────────────────────────────────────────────────────────
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF7F7F5);
  static const border = Color(0xFFEAE6E5);

  /// Fundo da página, atrás dos cartões. Branco: o protótipo trazia um lilás
  /// claro (#F1EDF0), trocado por decisão do dono do projeto. Os cartões
  /// continuam se distinguindo pela borda e pela sombra, não pelo contraste
  /// com o fundo.
  static const scaffold = Color(0xFFFFFFFF);

  static const white = Color(0xFFFFFFFF);
  static const transparent = Color(0x00000000);

  /// Sombra dos cartões — `rgba(0,0,0,.05)`.
  static const cardShadow = Color(0x0D000000);

  /// Fundo da linha de atendimento agendado — `rgba(250,238,218,.4)`.
  static const amberRowTint = Color(0x66FAEEDA);

  /// Fundo do chip de "mais lucrativo" — `rgba(189,78,191,.14)`.
  static const accentTint = Color(0x24BD4EBF);

  /// Fundo do chip de categoria fixa — `rgba(133,79,11,.1)`.
  static const amberTint = Color(0x1A854F0B);
}
