import 'package:flutter/widgets.dart';
import 'package:salon_app/l10n/app_localizations.dart';

/// A **única** extension de acesso a tradução dentro de um `build`.
/// Fora de widget, use `globals.l10n` (regra única do capítulo 09 do padrão).
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
