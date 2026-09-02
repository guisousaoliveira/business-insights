import 'package:dio/dio.dart';

import '../settings/app_error_codes.dart';
import '../settings/app_globals.dart' as globals;
import '../settings/app_logger.dart';
import 'response_model.dart';

/// Normaliza qualquer falha em `{ statusCode, code, message }`, com a mensagem
/// **já traduzida e pronta para exibir**.
///
/// Precedência: código de negócio traduzido > mensagem do backend > status
/// específico > faixa de status > genérico.
///
/// Este é o único tipo de erro que circula no app. `BlocSubState.data is
/// ErrorModel` é como a UI sabe que algo falhou — não existe estado de erro.
class ErrorModel {
  /// `0` quando não houve resposta (timeout, DNS, offline).
  final int statusCode;

  /// Código de negócio do backend; `null` se não informado.
  final String? code;

  final String message;

  /// `result` do envelope de erro, cru. Existe porque alguns erros de negócio
  /// carregam dado que a tela precisa mostrar — `ESTOQUE_INSUFICIENTE` traz a
  /// lista do que falta, e sem ela o aviso viraria um "não deu" sem utilidade.
  ///
  /// Fica `Object?` de propósito: tipar aqui obrigaria o `ErrorModel`, que é
  /// infra, a conhecer models de módulo. Quem consome faz o parse.
  final Object? result;

  const ErrorModel({
    this.statusCode = 0,
    this.code,
    required this.message,
    this.result,
  });

  factory ErrorModel.generic() => ErrorModel(
        message: globals.l10n?.unknownError ?? _fallbackMessage,
      );

  factory ErrorModel.fromDioException(DioException? e) {
    AppLogger.warning('Falha de rede: ${e?.requestOptions.path}', e);

    // Sem resposta: timeout, DNS, offline.
    if (e?.response?.statusCode == null) {
      return ErrorModel(
        message: globals.l10n?.connectionError ?? _fallbackMessage,
      );
    }

    final statusCode = e!.response!.statusCode!;
    final data = e.response!.data;
    final code = data is Map ? data[ResponseModel.errorCodeKey] as String? : null;
    final result = data is Map ? data[ResponseModel.resultKey] : null;

    // 1. código de negócio conhecido → mensagem traduzida do app
    final translated = AppErrorCodes.messageFor(code);
    if (translated != null) {
      return ErrorModel(
        statusCode: statusCode,
        code: code,
        message: translated,
        result: result,
      );
    }

    // 2. mensagem enviada pelo backend
    if (data is String && data.isNotEmpty) {
      return ErrorModel(statusCode: statusCode, code: code, message: data);
    }
    if (data is Map && data[ResponseModel.messageKey] is String) {
      final message = data[ResponseModel.messageKey] as String;
      if (message.isNotEmpty) {
        return ErrorModel(
          statusCode: statusCode,
          code: code,
          message: message,
          result: result,
        );
      }
    }

    // 3. status específicos, depois 4. faixa
    final l10n = globals.l10n;
    if (l10n == null) {
      return ErrorModel(
        statusCode: statusCode,
        code: code,
        message: _fallbackMessage,
        result: result,
      );
    }

    final message = switch (statusCode) {
      401 || 403 => l10n.unauthorizedError,
      404 => l10n.unknownPageError,
      _ => switch (statusCode ~/ 100) {
          4 => l10n.requestError,
          5 => l10n.responseError,
          _ => l10n.unknownError,
        },
    };

    return ErrorModel(
      statusCode: statusCode,
      code: code,
      message: message,
      result: result,
    );
  }

  /// Usada quando o `l10n` ainda não existe (antes do primeiro frame, ou em
  /// teste unitário sem `MaterialApp`). Ver §4 de `14-testes.md`.
  static const _fallbackMessage = 'Ocorreu um erro inesperado.';
}
