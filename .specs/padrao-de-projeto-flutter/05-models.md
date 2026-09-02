# 05 — Models

`lib/models/`, subdividido pelos mesmos módulos de `cubits/`. Models transversais
(`error_model.dart`, `response_model.dart`, `dropdown_model.dart`) ficam na raiz.

**Sem code generation** — nada de `json_serializable`, `freezed` ou `build_runner`
para models. Parse manual e explícito.

> **Regra única de assinatura: `factory X.fromResponse(Map<String, dynamic> map)`.**
> Nunca receba o `Response` do Dio — o model não conhece a camada de transporte.
> É o que torna o parse testável com um JSON literal, sem HTTP.

## O envelope da API

Toda resposta tem a mesma forma
(`{ "total": 12, "mensagem": "ok", "codigo": null, "result": {…} }`), codificada uma
vez só. Backend com outro envelope? Altere **apenas** este arquivo.

```dart
// lib/models/response_model.dart
abstract class ResponseModel {
  final int total;
  final String message;

  const ResponseModel({required this.total, required this.message});

  static const totalKey     = "total";
  static const messageKey   = "mensagem";
  static const resultkey    = "result";
  static const errorCodeKey = "codigo";   // usado por ErrorModel
}
```

## Os 4 tipos de model

**1. Request** — só carrega dados e expõe getters de serialização, sem `fromX`:

```dart
class LoginRequestModel {
  final String user;
  final String pass;

  const LoginRequestModel({required this.user, required this.pass});

  Map<String, dynamic> get toBody => {'email': user, 'senha': pass};
}
```

| Getter | Vai para |
|--------|----------|
| `toBody` | corpo JSON de POST/PUT |
| `toQuery` | `queryParameters` |
| `toStorage` | `AppStorage` |

São **getters**, não métodos. Evite `toMap` genérico — ele não diz para onde o dado vai.

**2. Response** — estende `ResponseModel`, chaves do JSON como `static const`
privadas, fábrica `fromResponse(Map)`. Com muitos campos, extraia o `result` numa
variável local:

```dart
class LoginResponseModel extends ResponseModel {
  static const _tokenKey       = 'token';
  static const _managerTypeKey = 'tipoGestor';

  final String token;
  final ManagerType managerType;

  LoginResponseModel({required super.total, required super.message,
                      required this.token, required this.managerType});

  factory LoginResponseModel.fromResponse(Map<String, dynamic> map) {
    final result = map[ResponseModel.resultkey] as Map<String, dynamic>;
    final entity = result['entitie'] as Map<String, dynamic>;

    return LoginResponseModel(
      total:       map[ResponseModel.totalKey],
      message:     map[ResponseModel.messageKey],
      token:       result[_tokenKey],
      // int do backend → enum do app, via AppUtils
      managerType: AppUtils.decodeManagerType(entity[_managerTypeKey]),
    );
  }
}
```

As `static const _xKey` isolam as strings do JSON num lugar só: o backend renomeia
um campo, você muda uma linha e o compilador te leva a todos os usos.

**3. Entity** — entidade de domínio reutilizada. Não estende `ResponseModel`; costuma
ter várias conversões, porque circula entre API, storage e telas.

**4. Storage** — par `fromStorage` / `toStorage`. As chaves de storage são **em inglês
e independentes das da API**, para que mudança no backend não invalide o que já está
salvo no aparelho:

```dart
class HeaderModel {
  static const _userNameKey = 'userName';
  final String username;

  const HeaderModel({required this.username});

  factory HeaderModel.fromStorage(Map<String, dynamic> map) =>
      HeaderModel(username: map[_userNameKey]);

  Map<String, dynamic> get toStorage => {_userNameKey: username};
}
```

## `int` do backend → `enum` do app

Centralizado em `AppUtils`, **nunca espalhado nos models**. Trio de convenção:
`decodeXType(int)`, `xTypeToString(X)` e o `.index` do enum para salvar no storage.

```dart
// lib/settings/app_utils.dart
static FeedbackType? decodeFeedbackType(int code) => switch (code) {
      0 => FeedbackType.praise,
      1 => FeedbackType.guidance,
      _ => null,
    };

static String feedbackTypeToString(FeedbackType type) {   // → texto traduzido
  switch (type) {
    case FeedbackType.praise:   return globals.l10n!.praise;
    case FeedbackType.guidance: return globals.l10n!.orientation;
  }
}
```

> Se você controla o backend, prefira **strings** a inteiros no contrato
> (`"tipoGestor": "storeManager"`): reordenar o enum deixa de ser quebra silenciosa.

## `DropdownModel`

Par rótulo/valor usado por todo componente de seleção:

```dart
class DropdownModel {
  final String key;    // texto exibido
  final Object value;  // valor real (id, enum, DateTime…)

  const DropdownModel({required this.key, required this.value});
}
```

## Regras

- Todos os campos `final`; construtor `const` sempre que possível.
- Campo que o backend pode omitir é anulável (`String?`) — **não** invente default
  silencioso.
- Nunca `dynamic` como tipo de campo público; converta no `fromResponse`.
- Model não faz requisição, não lê storage e não navega. **Pode** usar `AppUtils` e
  `globals.l10n`.
