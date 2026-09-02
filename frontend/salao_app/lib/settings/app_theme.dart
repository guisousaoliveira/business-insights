import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema **mínimo**, de propósito.
///
/// O design system deste app vive em `AppColors` / `AppFonts` e nos componentes
/// `App*`, não no `ThemeData`: as telas não usam widget Material direto, então
/// não há o que tematizar. O que sobra aqui é o que o Flutter exige antes de
/// qualquer widget existir — cor de fundo, cor de seleção de texto e o
/// `ColorScheme` que o Material usa em diálogos e no cursor.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.scaffold,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.white,
          secondary: AppColors.primaryAccent,
          surface: AppColors.surface,
          onSurface: AppColors.text1,
          error: AppColors.danger,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.primary,
          selectionColor: AppColors.primaryMid,
          selectionHandleColor: AppColors.primary,
        ),
        splashFactory: NoSplash.splashFactory,
        highlightColor: AppColors.transparent,
      );
}
