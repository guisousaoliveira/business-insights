# 10 — Tratamento de erros

**Erro não é um estado; é um tipo de dado.** Toda operação termina em
`BlocDataState.completed`, e o tipo em `BlocSubState.data` diz o que aconteceu:

```dart
sub.value<XResponseModel>() != null  // sucesso
sub.hasError                         // falha (sub.error!.message já traduzida)
```

## `ErrorModel` — a normalização

`lib/models/error_model.dart` converte qualquer falha em
`{ statusCode, code, message }`, com mensagem **já traduzida e pronta para exibir**.
Precedência: **código de negócio traduzido > mensagem do backend > status específico >
faixa de status > genérico.**

```dart
class ErrorModel {
  final int statusCode;   // 0 quando não houve resposta (timeout, offline)
  final String? code;     // código de negócio do backend; null se não informado
  final String message;   // pronta para exibir

  const ErrorModel({this.statusCode = 0, this.code, required this.message});

  factory ErrorModel.generic() => ErrorModel(message: globals.l10n!.unknownError);

  factory ErrorModel.fromDioException(DioException? e) {
    if (e?.response?.statusCode == null) {            // timeout, DNS, offline
      return ErrorModel(message: globals.l10n!.connectionError);
    }

    final statusCode = e!.response!.statusCode!;
    final data = e.response!.data;
    final String? code = data is Map ? data[ResponseModel.errorCodeKey] : null;

    // 1. código de negócio conhecido → mensagem traduzida do app
    final traduzida = AppErrorCodes.messageFor(code);
    if (traduzida != null) {
      return ErrorModel(statusCode: statusCode, code: code, message: traduzida);
    }

    // 2. mensagem enviada pelo backend
    if (data is String && data.isNotEmpty) {
      return ErrorModel(statusCode: statusCode, code: code, message: data);
    }
    if (data is Map && data[ResponseModel.messageKey] is String) {
      return ErrorModel(statusCode: statusCode, code: code,
                        message: data[ResponseModel.messageKey]);
    }

    // 3. status específicos, depois 4. faixa
    final l10n = globals.l10n!;
    final message = switch (statusCode) {
      401 || 403 => l10n.unauthorizedError,
      404        => l10n.unknownPageError,
      _ => switch (statusCode ~/ 100) {
             4 => l10n.requestError,
             5 => l10n.responseError,
             _ => l10n.unknownError,
           },
    };
    return ErrorModel(statusCode: statusCode, code: code, message: message);
  }
}
```

## `AppErrorCodes` — códigos, não strings de mensagem

> **Identifique erro de negócio por código.** Comparar a mensagem literal do backend
> quebra quando corrigem uma vírgula, e é intraduzível. Se a API ainda não devolve
> códigos, peça — é mudança pequena no backend e elimina uma classe inteira de bugs.
> Comparação por mensagem só vale como medida temporária, marcada com
> `// TODO: substituir por código`.

```dart
class AppErrorCodes {
  static const invalidCredentials = 'AUTH_INVALID_CREDENTIALS';
  static const goalAlreadyExists  = 'GOAL_ALREADY_EXISTS_FOR_MONTH';
  static const noDayOffFound      = 'DAYOFF_NOT_FOUND';   // "vazio" devolvido como erro

  /// Códigos com mensagem própria traduzida. Null = desconhecido, vale a do backend.
  static String? messageFor(String? code) {
    final l10n = globals.l10n!;
    switch (code) {
      case invalidCredentials: return l10n.emailOrPasswordIncorrectError;
      case goalAlreadyExists:  return l10n.goalAlreadyRegisteredThisMonthError;
      default: return null;
    }
  }
}
```

Com isso **o cubit quase nunca trata erro de negócio caso a caso** — a tradução já
aconteceu no `ErrorModel`. Só escreva um `if` no cubit quando o código exigir
*comportamento* diferente, não só mensagem diferente:

```dart
} on DioException catch (e) {
  final error = ErrorModel.fromDioException(e);

  // "nenhuma folga encontrada" não é erro para a UI: é lista vazia
  if (error.code == AppErrorCodes.noDayOffFound) {
    emit(state.copyWith(getDayOffsSubState: BlocSubState(
      state: BlocDataState.completed, data: GetDayOffsResponseModel.empty())));
    return;
  }

  emit(state.copyWith(getDayOffsSubState: BlocSubState(
    state: BlocDataState.completed, data: error)));
}
```

## Os 4 níveis

| Nível | Onde | O quê |
|-------|------|-------|
| 1. Sessão expirada (401) | interceptor em `app_api.dart` | refresh ou `AppUtils.logout()` — global, nenhum cubit vê |
| 2. Erro de negócio | `AppErrorCodes.messageFor` dentro do `ErrorModel` | mensagem traduzida, automática |
| 3. Erro HTTP genérico | cubit, `on DioException` | `ErrorModel.fromDioException(e)` |
| 4. Erro inesperado | cubit, `catch (e)` | `ErrorModel.generic()` |

## Consumo na UI

Feedback pontual → `BlocListener` com `AppSnackBar.showSnackbar(context,
sub.error!.message, SnackBarStatus.error)`. Erro que vira estado da tela →
`AppSubStateBuilder` com `onError: (error) => AppErrorRetry(message: error.message,
onRetry: _fetch)`.

## Checklist de operação nova

- [ ] O cubit emite `loading` **antes** do `try`.
- [ ] Existem os três caminhos: sucesso, `on DioException`, `catch`.
- [ ] Os três emitem `completed` — nunca deixe a UI presa em `loading`.
- [ ] A UI trata erro (snackbar, estado vazio, retry ou os três).
- [ ] Códigos de negócio registrados em `AppErrorCodes` **e** com chave no ARB.
- [ ] Nenhuma comparação por texto de mensagem.
