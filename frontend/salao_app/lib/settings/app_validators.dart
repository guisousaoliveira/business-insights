import 'app_globals.dart' as globals;

/// Assinatura única: `String? Function(String)`, devolvendo `null` se válido.
///
/// **"Obrigatório" não é validador** — é a flag `isRequired` do
/// `AppInputController` (capítulo 08 do padrão).
abstract class AppValidators {
  static String? validateEmail(String text) =>
      RegExp(r'^[\w\-.+]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(text)
          ? null
          : globals.l10n?.emailError;

  static String? validatePassword(String text) =>
      text.length >= 6 ? null : globals.l10n?.passwordTooShortError;

  /// Aceita o que a usuária digita de verdade: `1.234,56` ou `1234.56`.
  static String? validateMoney(String text) {
    final value = parseMoney(text);
    if (value == null) return globals.l10n?.invalidNumberError;
    if (value <= 0) return globals.l10n?.positiveValueError;
    return null;
  }

  /// Quantidade de estoque pode ser zero (item que acabou), então só recusa
  /// negativo e texto ilegível.
  static String? validateQuantity(String text) {
    final value = parseMoney(text);
    if (value == null) return globals.l10n?.invalidNumberError;
    if (value < 0) return globals.l10n?.invalidNumberError;
    return null;
  }

  static String? validatePhone(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 && digits.length <= 13
        ? null
        : globals.l10n?.invalidPhoneError;
  }

  /// `1.234,56` → `1234.56`. Devolve `null` se não for número.
  ///
  /// Mora aqui, e não no `AppUtils`, porque só a validação e os formulários a
  /// usam — é a inversa de `AppUtils.numToMoney`.
  ///
  /// A vírgula decide quem é separador decimal: se ela existe, o ponto é
  /// milhar (`1.234,56`); se não existe, o ponto é o decimal (`1234.56`), que é
  /// o que sai de um teclado numérico. Sem essa distinção, `1234.56` viraria
  /// `123456` — erro de duas ordens de grandeza num campo de dinheiro.
  static double? parseMoney(String text) {
    var cleaned = text.replaceAll(RegExp(r'[^\d,.\-]'), '');
    if (cleaned.isEmpty) return null;

    if (cleaned.contains(',')) {
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(cleaned);
  }
}
