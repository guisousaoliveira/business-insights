# 12 — Receita: nova feature

Exemplo: **listar produtos com filtro e cadastrar um produto novo.** Sempre na mesma
ordem, de baixo para cima. As formas de código estão nos capítulos citados — aqui fica
só a sequência e o que é específico de cada passo.

## 1. Endpoints — `settings/app_api.dart`

```dart
static const getProductsPath = '/Produto/buscar-produtos';
static const postProductPath = '/Produto/adicionar-produto';
```

## 2. Models — `models/product/` ([05](05-models.md))

- `get_products_request_model.dart` → getter `toQuery`
- `product_model.dart` → `_xKey` privadas + `fromResponse(Map)`
- `get_products_response_model.dart` → estende `ResponseModel`, converte a lista:
  ```dart
  products: (map[ResponseModel.resultkey] as List)
      .map((e) => ProductModel.fromResponse(e)).toList(),
  ```
- `register_product_request/response_model.dart` → mesmo molde, `toBody` no request

## 3. Repository — `repositories/product_repository.dart` ([04](04-repositories.md))

Interface **e** implementação no mesmo arquivo, um método por endpoint, sem
`try/catch`, sempre `Model.fromResponse(response.data)`.

## 4–5. Estado e cubit — `cubits/product/` ([02](02-gerenciamento-de-estado.md))

`product_state.dart`: um `BlocSubState` por operação (`getProductsSubState`,
`registerProductSubState`), `copyWith` com `x ?? this.x` em todos os campos.

`product_cubit.dart`: repository injetado no construtor com default, e o template de
5 passos (loading → `try` → sucesso → `on DioException` → `catch`) em cada método.

## 6. Teste do cubit — **antes da tela** ([14](14-testes.md))

```dart
blocTest<ProductCubit, ProductState>(
  'emite loading e depois completed com a lista',
  build: () => ProductCubit(repository: mockRepository),
  act: (cubit) => cubit.getProducts(storeId: '1', page: 1),
  expect: () => [
    isA<ProductState>().having((s) => s.getProductsSubState.isLoading, 'loading', true),
    isA<ProductState>().having(
      (s) => s.getProductsSubState.value<GetProductsResponseModel>()?.products.length,
      'produtos', 2),
  ],
);
```

## 7–8. Registro e rota

```dart
BlocProvider(create: (_) => ProductCubit()),                 // main.dart

static const productsRoute = '/products';                    // app_routes.dart
productsRoute: (context) =>
    globals.isLogged ? const ProductsScreen() : const LoginScreen(),
```

Se houver menu lateral: novo valor em `AppCurrentRoute` + entrada em
`AppSideMenuUtils._indexToRouteMap`.

## 9. Tela — `ui/screens/product/products_screen.dart` ([08](08-ui-design-system.md))

`StatefulWidget` com controllers em `initState`/`dispose`, `_fetch()` no `initState`,
`MultiBlocListener` para os efeitos e `BlocBuilder` + `AppSubStateBuilder` para o
conteúdo. O listener de cadastro é o trecho que se repete em toda tela de lista:

```dart
BlocListener<ProductCubit, ProductState>(
  listenWhen: (p, c) => p.registerProductSubState != c.registerProductSubState,
  listener: (context, state) {
    final sub = state.registerProductSubState;
    if (!sub.isCompleted) return;
    if (sub.hasError) {
      AppSnackBar.showSnackbar(context, sub.error!.message, SnackBarStatus.error);
    } else {
      AppSnackBar.showSnackbar(context,
          sub.value<RegisterProductResponseModel>()!.message, SnackBarStatus.sucess);
      _fetch();                                    // recarrega a lista
    }
  },
),
```

E o diálogo de cadastro devolve `true` quando algo mudou:

```dart
final reload = await AppDialog.show<bool>(context: context, dialog: …);
if (reload ?? false) _fetch();
```

## Checklist final

- [ ] Paths em `AppApi` — nenhuma string solta na tela ou no repository
- [ ] Models com `_xKey` privadas, `fromResponse(Map<String, dynamic>)`, nenhum
      `dynamic` público
- [ ] Repository com **interface + Impl**, sem `try/catch` e sem lógica
- [ ] Cubit `<Modulo>Cubit` com repository **injetado no construtor**
- [ ] Um `BlocSubState` por operação; módulo com ≤ ~8 operações
- [ ] `copyWith` usando `x ?? this.x` em **todos** os campos
- [ ] Cubit com os 5 passos (loading → try → `on DioException` → `catch`)
- [ ] Teste do cubit escrito (sucesso + erro)
- [ ] Cubit registrado no `MultiBlocProvider`
- [ ] Rota + `AppCurrentRoute` + menu lateral
- [ ] `buildWhen`/`listenWhen` comparando **o sub-estado específico**
- [ ] Controllers criados em `initState` e liberados em `dispose`
- [ ] Loading, erro e vazio tratados via `AppSubStateBuilder`
- [ ] Strings visíveis no ARB; erros de negócio em `AppErrorCodes`
- [ ] Após criar/editar/excluir: recarregar a lista
