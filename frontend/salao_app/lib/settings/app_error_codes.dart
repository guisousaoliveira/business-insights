import 'app_globals.dart' as globals;

/// Códigos de erro de negócio do FastAPI — espelho da §11 de
/// `.specs/endpoints-backend.md`.
///
/// **Erro de negócio se identifica por código, nunca por texto de mensagem**
/// (regra 12). Mensagem muda quando alguém corrige uma vírgula; código não.
///
/// Todo código aqui tem chave correspondente no ARB. Código novo no backend sem
/// entrada aqui cai na mensagem genérica do `ErrorModel`.
class AppErrorCodes {
  const AppErrorCodes._();

  static const invalidCredentials = 'AUTH_CREDENCIAIS_INVALIDAS';
  static const invalidRefresh = 'AUTH_REFRESH_INVALIDO';
  static const missingToken = 'AUTH_TOKEN_AUSENTE';
  static const invalidValidation = 'VALIDACAO_INVALIDA';
  static const notFound = 'RECURSO_NAO_ENCONTRADO';
  static const appointmentInvalidStatus = 'ATENDIMENTO_STATUS_INVALIDO';
  static const insufficientStock = 'ESTOQUE_INSUFICIENTE';
  static const kitNotAssembled = 'KIT_NAO_MONTADO';
  static const itemInUse = 'ITEM_EM_USO';
  static const expenseAlreadyPaid = 'GASTO_JA_PAGO';
  static const rateLimit = 'LIMITE_EXCEDIDO';

  /// Códigos com mensagem própria traduzida.
  /// `null` = desconhecido; vale a mensagem que o backend mandou.
  static String? messageFor(String? code) {
    final l10n = globals.l10n;
    if (l10n == null || code == null) return null;

    return switch (code) {
      invalidCredentials => l10n.invalidCredentialsError,
      invalidRefresh || missingToken => l10n.sessionExpiredError,
      invalidValidation => l10n.validationError,
      notFound => l10n.notFoundError,
      appointmentInvalidStatus => l10n.appointmentStatusError,
      insufficientStock => l10n.insufficientStockError,
      kitNotAssembled => l10n.kitNotAssembledError,
      itemInUse => l10n.itemInUseError,
      expenseAlreadyPaid => l10n.expenseAlreadyPaidError,
      rateLimit => l10n.rateLimitError,
      _ => null,
    };
  }
}
