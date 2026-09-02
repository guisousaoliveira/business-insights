# 02 — Gerenciamento de estado

## Escolhas centrais

- **`flutter_bloc` usado exclusivamente como `Cubit`.** Sem eventos: a UI chama
  métodos públicos assíncronos direto no cubit.
- Todos os cubits são registrados **uma vez, globalmente**, no `MultiBlocProvider`
  do `main.dart`. Vivem enquanto o app viver.
- Cada cubit tem **um estado imutável** com **vários `BlocSubState`**, um por
  operação assíncrona.
- **Um único padrão de estado no app inteiro.** Nada de misturar `BlocSubState` com
  estados `sealed`/`abstract`. `BlocSubState` é obrigatório para tudo que envolva I/O.

## As duas peças

```dart
// lib/settings/app_enums.dart
enum BlocDataState { idle, loading, completed }   // não existe `error`
```

```dart
// lib/cubits/bloc_substate.dart
class BlocSubState {
  final BlocDataState state;
  final Object? data;   // um ResponseModel OU um ErrorModel

  const BlocSubState({this.state = BlocDataState.idle, this.data});

  bool get isIdle      => state == BlocDataState.idle;
  bool get isLoading   => state == BlocDataState.loading;
  bool get isCompleted => state == BlocDataState.completed;

  bool get hasError     => data is ErrorModel;
  ErrorModel? get error => data is ErrorModel ? data as ErrorModel : null;

  /// `data` tipado, ou null se for erro / ainda não carregou.
  T? value<T>() => data is T ? data as T : null;
}
```

Os getters não mudam o padrão — só tiram o `as` de dentro dos widgets:
`state.getProductsSubState.value<GetProductsResponseModel>()!.products`.

## Estado do módulo

`lib/cubits/<modulo>/<modulo>_state.dart` — todos os campos `final`, construtor
`const`, defaults `const BlocSubState()`, `copyWith` com **todos** os campos, **sem
`Equatable`**:

```dart
class ProductState {
  final BlocSubState getProductsSubState;
  final BlocSubState registerProductSubState;
  // ... um campo por operação (máximo ~8)

  const ProductState({
    this.getProductsSubState     = const BlocSubState(),
    this.registerProductSubState = const BlocSubState(),
  });

  ProductState copyWith({
    BlocSubState? getProductsSubState,
    BlocSubState? registerProductSubState,
  }) =>
      ProductState(
        getProductsSubState:     getProductsSubState     ?? this.getProductsSubState,
        registerProductSubState: registerProductSubState ?? this.registerProductSubState,
      );
}
```

## A regra dura do `copyWith`

O filtro `buildWhen: (p, c) => p.getProductsSubState != c.getProductsSubState`
compara **referência**, porque não há `Equatable`. Funciona se e somente se
`copyWith` repassar o *mesmo objeto* nos campos não alterados — o que `x ?? this.x` faz.

> ⚠️ **`copyWith` nunca constrói um `BlocSubState` novo para campo que não mudou.**
> Nada de `BlocSubState(state: x.state, data: x.data)`. Quebrar isso faz a tela
> inteira reconstruir a cada `emit`, silenciosamente — sem erro, só lentidão.

| Sintoma | Causa provável |
|---------|----------------|
| A tela reconstrói a cada operação de qualquer parte do módulo | `copyWith` recriando sub-estados intactos |
| A tela **não** atualiza mesmo com `emit` | emitiu o *mesmo* `BlocSubState` (`data` mutado no lugar) |
| `BlocListener` dispara duas vezes | dois `emit` seguidos; use `listenWhen` mais específico |

Se preferir segurança a performance, adicione `Equatable` — mas em `BlocSubState`
**e** nos models, senão o `!=` passa a dar sempre `true`.

## O template de todo método de cubit

```dart
class ProductCubit extends Cubit<ProductState> {
  // injetável com default → testável sem perder ergonomia
  ProductCubit({ProductRepository? repository})
      : _repository = repository ?? ProductRepositoryImpl(),
        super(const ProductState());

  final ProductRepository _repository;

  Future<void> getProducts({required String storeId, required int page}) async {
    emit(state.copyWith(
      getProductsSubState: const BlocSubState(state: BlocDataState.loading),
    ));

    try {
      final response = await _repository.getProducts(
        GetProductsRequestModel(storeId: storeId, page: page),
      );
      emit(state.copyWith(getProductsSubState: BlocSubState(
        state: BlocDataState.completed, data: response)));
    } on DioException catch (e) {
      emit(state.copyWith(getProductsSubState: BlocSubState(
        state: BlocDataState.completed, data: ErrorModel.fromDioException(e))));
    } catch (e) {
      emit(state.copyWith(getProductsSubState: BlocSubState(
        state: BlocDataState.completed, data: ErrorModel.generic())));
    }
  }
}
```

Esses 5 passos — loading, chamada, sucesso, `DioException`, `catch` — se repetem
literalmente em todo método de todo cubit. O repository é injetado porque método
`static` é impossível de mockar: `ProductCubit()` em produção,
`ProductCubit(repository: MockProductRepository())` no teste.

**Erro de negócio conhecido:** compare **códigos**, nunca strings de mensagem
(ver [10](10-tratamento-de-erros.md)):

```dart
} on DioException catch (e) {
  final error = ErrorModel.fromDioException(e);
  if (error.code == AppErrorCodes.invalidCredentials) {
    emit(state.copyWith(loginSubState: BlocSubState(
      state: BlocDataState.completed,
      data: ErrorModel(statusCode: error.statusCode, code: error.code,
                       message: globals.l10n!.emailOrPasswordIncorrectError))));
    return;
  }
  emit(state.copyWith(loginSubState: BlocSubState(
    state: BlocDataState.completed, data: error)));
}
```

**Efeito colateral:** o cubit **pode** escrever no `AppStorage` antes de emitir
`completed`, para que a UI reaja com o storage já consistente.

## Registro global (`main.dart`)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStorage.initialize();   // ANTES do runApp — rotas dependem dele
  runApp(const MainApp());
}

// build:
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => AuthCubit()),
    BlocProvider(create: (_) => ProductCubit()),   // um por módulo
  ],
  child: ScaffoldMessenger(                        // snackbar de qualquer lugar
    child: MaterialApp(
      navigatorKey: AppRoutes.navigatorKey,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      navigatorObservers: [AppRoutes.routeObserver],
      initialRoute: AppRoutes.defaultRoute,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  ),
)
```

> Cubits globais nunca são recriados, então **o estado persiste entre navegações**.
> Ao entrar numa tela, sempre dispare o fetch no `initState` — não confie no estado
> remanescente da visita anterior.

## Como a UI consome

```dart
BlocConsumer<AuthCubit, AuthState>(
  listenWhen: (p, c) => p.loginSubState != c.loginSubState,
  buildWhen:  (p, c) => p.loginSubState != c.loginSubState,
  listener: (context, state) {
    final sub = state.loginSubState;
    if (sub.value<LoginResponseModel>() != null) {
      AppRoutes.push(AppRoutes.homeRoute, removeUntil: (route) => false);
    }
    if (sub.hasError) {
      AppSnackBar.showSnackbar(context, sub.error!.message, SnackBarStatus.error);
    }
  },
  builder: (context, state) => AppButton(
    isLoading: state.loginSubState.isLoading,
    onPressed: () => BlocProvider.of<AuthCubit>(context).login(...),
  ),
);
```

| Widget | Usar para |
|--------|-----------|
| `BlocBuilder` | renderizar conteúdo/loading a partir do sub-estado |
| `BlocListener` | efeitos: navegar, snackbar, fechar diálogo, recarregar outra lista |
| `BlocConsumer` | quando a operação precisa das duas coisas |
| `MultiBlocListener` | tela que reage a várias operações |

**Sempre informe `buildWhen`/`listenWhen` comparando o sub-estado específico.**

## O helper de renderização

`lib/ui/components/app_sub_state_builder.dart` — evita o ternário triplo em toda tela:

```dart
class AppSubStateBuilder<T> extends StatelessWidget {
  final BlocSubState subState;
  final Widget Function(T data) onData;
  final Widget Function(ErrorModel error)? onError;
  final Widget? onEmpty;
  final Widget? onLoading;

  const AppSubStateBuilder({super.key, required this.subState, required this.onData,
                            this.onError, this.onEmpty, this.onLoading});

  @override
  Widget build(BuildContext context) {
    if (!subState.isCompleted) return onLoading ?? const AppLoading();
    final data = subState.value<T>();
    if (data != null) return onData(data);
    if (subState.hasError && onError != null) return onError!(subState.error!);
    return onEmpty ?? const AppEmptyListWarning();
  }
}
```
