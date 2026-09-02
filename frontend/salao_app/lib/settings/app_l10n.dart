import 'package:salon_app/l10n/app_localizations.dart';

import 'app_routes.dart';

typedef L10nResolver = AppLocalizations? Function();

/// Resolvedor de tradução **injetável** — a saída (b) do §4 de
/// `14-testes.md`, decidida no início do projeto porque retroagir depois
/// exigiria tocar em todo o `ErrorModel`.
///
/// Em produção resolve pelo `navigatorKey`, como o padrão manda. Em teste
/// unitário não existe `WidgetsBinding`, e `GlobalKey.currentContext` **lança**
/// em vez de devolver `null` — por isso o teste troca o resolvedor no `setUp`
/// em vez de o código de produção ficar cheio de `try/catch`.
class AppL10n {
  const AppL10n._();

  static L10nResolver resolver = _fromNavigator;

  static AppLocalizations? get current => resolver();

  /// Restaura o comportamento de produção. Útil no `tearDown` de um teste que
  /// tenha trocado o resolvedor.
  static void reset() => resolver = _fromNavigator;

  static AppLocalizations? _fromNavigator() {
    final context = AppRoutes.navigatorKey.currentContext;
    if (context == null) return null;
    return AppLocalizations.of(context);
  }
}
