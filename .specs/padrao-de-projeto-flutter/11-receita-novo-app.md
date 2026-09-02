# 11 — Receita: novo app do zero

## 1. Projeto e dependências

```yaml
# pubspec.yaml
environment: {sdk: '>=3.3.3 <4.0.0'}

dependencies:
  flutter: {sdk: flutter}
  flutter_localizations: {sdk: flutter}
  flutter_bloc: ^8.1.5
  dio: ^5.4.3+1
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.3
  intl: any
  flutter_svg: ^2.0.10+1
  # web: flutter_web_plugins (sdk) e universal_html

dev_dependencies:
  flutter_test: {sdk: flutter}
  flutter_lints: ^3.0.0
  bloc_test: ^9.1.7
  mocktail: ^1.0.4

flutter:
  generate: true
  uses-material-design: true
  assets: [assets/icons/, assets/images/]
```

```bash
mkdir -p lib/{cubits,models,repositories,settings,l10n,ui/components,ui/screens}
mkdir -p test/{cubits,models,repositories} env
```

## 2. Infra (`lib/settings/`) — nesta ordem

| Arquivo | O que copiar |
|---|---|
| `app_enums.dart` | `BlocDataState {idle, loading, completed}`, `SnackBarStatus {sucess, error, alert}` + enums de domínio |
| `app_storage.dart` | [06](06-armazenamento-local.md), trocando as chaves. Mantenha `bearerToken` e `refreshToken` |
| `app_routes.dart` | [07](07-navegacao-e-rotas.md): `navigatorKey`, `routeList` com guard, `onGenerateRoute`, `push`/`pop` |
| `app_globals.dart` | `isLogged` (deriva do token) e `l10n` |
| `app_api.dart` | [03](03-camada-de-api.md): `_baseUrl` via `String.fromEnvironment`, paths, verbos, interceptor |
| `app_error_codes.dart` | [10](10-tratamento-de-erros.md): códigos + `messageFor` |
| tokens e helpers | `app_colors`, `app_fonts` (**funções com `context`**), `app_assets`, `app_media_querys` (copiável literal), `app_validators`, `app_utils`, `app_constants` (**funções**) |

`env/dev.json`, `env/hml.json`, `env/prod.json` com `{"API_BASE_URL": "…"}` →
`flutter build web --dart-define-from-file=env/prod.json`.

## 3. Base de estado, models e i18n

`lib/cubits/bloc_substate.dart` ([02](02-gerenciamento-de-estado.md)),
`lib/models/response_model.dart` ([05](05-models.md)) e `error_model.dart`
([10](10-tratamento-de-erros.md)), ajustando as chaves do envelope ao seu backend.

`l10n.yaml` + `lib/l10n/app_pt.arb`, começando pelas chaves de erro obrigatórias:

```json
{
  "@@locale": "pt",
  "unknownError": "Ocorreu um erro inesperado.",
  "connectionError": "Sem conexão. Verifique sua internet.",
  "unauthorizedError": "Sessão expirada.",
  "unknownPageError": "Recurso não encontrado.",
  "requestError": "Não foi possível completar a solicitação.",
  "responseError": "Erro no servidor. Tente novamente.",
  "requiredInputError": "Campo obrigatório.",
  "emailError": "E-mail inválido."
}
```

## 4. `main.dart`

Estrutura completa em [02 § Registro global](02-gerenciamento-de-estado.md). Em app
**web**, acrescente `usePathUrlStrategy()` no `main()` e o `scrollBehavior` que
habilita arrastar com o mouse:

```dart
scrollBehavior: const MaterialScrollBehavior().copyWith(
  dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
  scrollbars: false,
),
```

## 5. Primeira feature: autenticação

Nesta ordem — é o esqueleto que valida a arquitetura inteira:

1. `models/auth/login_request_model.dart` → `toBody`
2. `models/auth/login_response_model.dart` → `fromResponse(Map)`
3. `repositories/auth_repository.dart` → interface + `AuthRepositoryImpl`
4. `cubits/auth/auth_state.dart` → `loginSubState` + `copyWith`
5. `cubits/auth/auth_cubit.dart` → `login()` gravando token no `AppStorage`
6. `test/cubits/auth_cubit_test.dart` → o primeiro teste ([14](14-testes.md))
7. `ui/components/` → `AppScaffold`, `AppInput`, `AppButton`, `AppSnackBar`,
   `AppLoading`, `AppSubStateBuilder`
8. `ui/screens/auth/login_screen.dart` → `BlocConsumer` + controllers

Depois disso, toda feature segue [12](12-receita-nova-feature.md).

## 6. Design system mínimo e lints

Antes da **segunda** tela tenha: `AppScaffold`, `AppSubStateBuilder`, `AppButton`,
`AppInput` (+Controller), `AppDropdown` (+Controller), `AppDialog`, `AppSnackBar`,
`AppLoading`, `AppEmptyListWarning`. Sem isso o Material vaza para as telas e o padrão
se perde.

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml
linter:
  rules:
    prefer_const_constructors: true
    prefer_final_fields: true
    avoid_print: true
    use_build_context_synchronously: true
```
