# 07 — Navegação e rotas (`AppRoutes`)

`lib/settings/app_routes.dart` — navegação **imperativa** com `Navigator 1.0`,
centralizada numa classe estática com um `GlobalKey<NavigatorState>`. Sem
`go_router`, sem `auto_route`.

```dart
class AppRoutes {
  static final navigatorKey  = GlobalKey<NavigatorState>();
  static final routeObserver = RouteObserver<ModalRoute>();

  static const defaultRoute        = '/';
  static const loginRoute          = '/login';
  static const registerRoute       = '/register';
  static const registerSellerRoute = '$registerRoute-sellers';   // hierarquia por interpolação

  static final routeList = <String, Widget Function(BuildContext)>{ … };
  static Route onGenerateRoute(RouteSettings settings) { … }
  static Future<dynamic> push(String name, {…}) async { … }
  static Future<bool> pop({…}) async { … }
}
```

```dart
MaterialApp(
  navigatorKey: AppRoutes.navigatorKey,
  onGenerateRoute: AppRoutes.onGenerateRoute,
  navigatorObservers: [AppRoutes.routeObserver],
  initialRoute: AppRoutes.defaultRoute,
)
```

## 1. `navigatorKey` — a peça mais importante do padrão

`navigatorKey.currentContext!` dá um `BuildContext` de qualquer lugar do app: é o que
permite traduzir dentro de model, util ou validator (`globals.l10n!.unknownError`) e
navegar de dentro do interceptor do Dio (`AppUtils.logout()`).

> O `navigatorKey` deve aparecer **apenas** em `app_globals.dart` (para o `l10n`) e em
> `app_routes.dart` (para `push`/`pop`). Escrito em outro arquivo, falta um helper.

**Trade-off:** elimina o prop drilling de `BuildContext`, mas cria acoplamento global
e falha se acessado antes do primeiro frame. Nunca use em `main()` antes do `runApp`,
nem em inicializador de campo estático avaliado cedo demais.

## 2. Route guard no mapa de rotas

A proteção é feita **no builder**, ternário por ternário. Como `globals.isLogged` lê o
storage de forma síncrona, funciona sem `FutureBuilder` nem splash.

```dart
static final routeList = <String, Widget Function(BuildContext)>{
  // públicas: se já logado, manda para a home
  loginRoute: (context) => globals.isLogged ? const HomeScreen() : const LoginScreen(),
  // privadas: se não logado, cai no login
  homeRoute:  (context) => globals.isLogged ? const HomeScreen() : const LoginScreen(),
  // totalmente públicas
  inputNpsAcknowledgmentPath: (context) => const InputNpsScreenAcknowledgment(),
};
```

## 3. `onGenerateRoute`: deep link, query e transição

```dart
static Route onGenerateRoute(RouteSettings settings) {
  final uri = Uri.parse(settings.name!);

  // rotas que recebem parâmetro pela URL (deep link / e-mail)
  if (uri.path == '/redefinir-senha') {
    return PageRouteBuilder(
      pageBuilder: (context, _, __) =>
          RecoveryPasswordScreen(token: uri.queryParameters['token']!),
      settings: settings,
    );
  }

  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (context, _, __) => routeList[settings.name] != null
        ? routeList[settings.name]!.call(context)
        : routeList[loginRoute]!.call(context),          // 404 não quebra o app
    transitionDuration: const Duration(seconds: 0),      // animação de página
    reverseTransitionDuration: const Duration(seconds: 0),
    transitionsBuilder: (context, animation, secondary, child) => child,
  );
}
```

Rotas com parâmetro de URL entram no `routeList` como `Container()` (placeholder) e
são resolvidas de fato aqui. Em web, combine com `usePathUrlStrategy()`.

## 4. `push` / `pop` sem `BuildContext`

```dart
static Future<dynamic> push(String name, {Map<String, dynamic>? data,
    bool Function(Route<dynamic> route)? removeUntil}) async {
  if (removeUntil != null) {
    return await navigatorKey.currentState!
        .pushNamedAndRemoveUntil(name, removeUntil, arguments: data);
  }
  return await navigatorKey.currentState!.pushNamed(name, arguments: data);
}
```

```dart
AppRoutes.push(AppRoutes.registerGoalRoute);                        // empilha
AppRoutes.push(AppRoutes.homeRoute, removeUntil: (route) => false); // limpa a pilha
AppRoutes.pop(result: true);                                        // devolve valor
```

`removeUntil: (route) => false` = "remova tudo" — usado em login e logout.

## Passagem de dados entre telas

Duas vias: `arguments` via `AppRoutes.push(rota, data: {…})`, lido com
`ModalRoute.of(context)!.settings.arguments`; ou **`AppStorage`** — a tela A grava, a
tela B lê no `initState`. A segunda é a preferida porque sobrevive a *reload* do
navegador, onde F5 recria a rota sem os `arguments`.

## Retorno de diálogos

O diálogo executa a ação e devolve `true`; a tela decide recarregar:

```dart
final willReload = await AppDialog.show<bool>(context: context, dialog: …);
if (willReload ?? false) {
  BlocProvider.of<ProductCubit>(context).getProducts(storeId: storeId, page: 1);
}
```

`AppRoutes.routeObserver` permite que widgets usem `RouteAware` para reagir a
`didPopNext` (recarregar dados ao voltar).
