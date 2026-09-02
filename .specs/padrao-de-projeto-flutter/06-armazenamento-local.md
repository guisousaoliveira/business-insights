# 06 — Armazenamento local (`AppStorage`)

`lib/settings/app_storage.dart` — wrapper estático único sobre **Hive**, com
`SharedPreferences` também inicializado e exposto para casos pontuais.

```dart
class AppStorage {
  static bool _isInitializing = false;
  static bool _isInitialized  = false;
  static late final SharedPreferences sharedPreferences;

  static const _storageBoxName = 'box';
  static Box<Map>? _storageBox;

  // CHAVES: todas declaradas aqui, nunca strings soltas
  static const bearerToken   = 'bearerToken';
  static const refreshToken  = 'refreshToken';
  static const headerInfoKey = 'header_info';
  // ...

  static Future<void> initialize() async {
    if (_isInitializing || _isInitialized) return;
    _isInitializing = true;
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      Hive.initFlutter();
      _storageBox = await Hive.openBox(_storageBoxName);
    } catch (e) {
      _isInitialized = false;
      _isInitializing = false;
      rethrow;
    }
    _isInitialized = true;
    _isInitializing = false;
  }

  static T? read<T>(String key) {
    if (!_isInitialized) return null;
    final map = _storageBox!.get(key, defaultValue: {'value': null})
        ?.cast<String, dynamic>();
    return map?['value'];
  }

  static Future<void> write<T>(String key, T value) async {
    if (_isInitialized) await _storageBox!.put(key, {'value': value});
  }

  static Future<void> clear() async {
    if (_isInitialized) await _storageBox!.clear();
  }
}
```

| Decisão | Motivo |
|---------|--------|
| **Uma única box** | Sem `TypeAdapter`, sem `build_runner`, sem migração de schema |
| **Valor embrulhado em `{'value': x}`** | Uniformiza e distingue "chave ausente" de "valor nulo" |
| **`read` síncrono** | Hive mantém a box em memória — dá para ler em `initState`, em getters globais e no `build` |
| **`write` assíncrono** | Persistência em disco/IndexedDB |
| **Flags de inicialização** | `initialize()` idempotente, nunca abre a box duas vezes |
| **Falha silenciosa se não inicializado** | `read` devolve `null`, `write` não faz nada, em vez de lançar |

## O que se guarda

Apenas **primitivos ou mapas/listas de primitivos** — Hive sem adapters não
serializa objetos Dart. Por isso os models expõem `toStorage`/`fromStorage`.

```dart
await AppStorage.write(AppStorage.bearerToken, response.token);           // String
await AppStorage.write(AppStorage.managerTypeKey, type.index);            // int (enum!)
await AppStorage.write(AppStorage.headerInfoKey, headerModel.toStorage);  // Map

final token = AppStorage.read<String>(AppStorage.bearerToken);
final header = HeaderModel.fromStorage(
  (AppStorage.read(AppStorage.headerInfoKey) as Map).cast<String, dynamic>(),
);
```

> Mapas lidos do Hive voltam como `Map<dynamic, dynamic>`. **Sempre**
> `.cast<String, dynamic>()` antes de passar para `fromStorage`.

## Papéis que o storage cumpre

1. **Sessão** — token e tipo de usuário.
2. **Cache de dados de sessão** — nome, foto, listas gravadas no login para popular
   header e dropdowns sem nova requisição.
3. **Parâmetro entre telas** — a tela A grava, a tela B lê no `initState`
   (ver [07](07-navegacao-e-rotas.md)).
4. **Route guard** — `globals.isLogged` deriva do token.

## Getters globais (`app_globals.dart`)

Como `read` é síncrono, o estado de sessão vira getter de biblioteca, importado com
prefixo `globals`:

```dart
bool get isLogged =>
    AppStorage.read<String>(AppStorage.bearerToken)?.isNotEmpty == true;

/// Único ponto do app que resolve tradução fora de widget — ver 09-i18n.md.
AppLocalizations? get l10n =>
    AppLocalizations.of(AppRoutes.navigatorKey.currentContext!);
```

```dart
import 'package:meu_app/settings/app_globals.dart' as globals;
if (globals.isLogged) { … }
Text(globals.l10n!.homeTitle);
```

## Logout e bootstrap

```dart
static void logout() async {
  await AppStorage.clear();   // um clear() derruba sessão e caches
  await AppRoutes.push(AppRoutes.defaultRoute, removeUntil: (route) => false);
}
```

Chamado pelo menu lateral e pelo interceptor de 401.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStorage.initialize();   // ← ANTES do runApp
  runApp(const MainApp());
}
```

Se inverter a ordem, `globals.isLogged` retorna `false` na primeira rota e o usuário
logado cai no login.

## Adaptando

- Chave sensível (token) em mobile: troque para `flutter_secure_storage` mantendo a
  mesma fachada `AppStorage.read/write`.
- Precisa de consulta/query? Este wrapper não serve — use Drift ou Isar. Este padrão
  é para **estado de sessão e cache chave-valor**.
- `AppStorage.sharedPreferences` fica como escape hatch para plugins que o exigem.
