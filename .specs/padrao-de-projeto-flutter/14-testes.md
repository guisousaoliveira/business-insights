# 14 — Testes

Ferramentas: `bloc_test` (cenários de cubit) e `mocktail` (mocks sem code-gen). Com o
repository injetado ([04](04-repositories.md)), testar deixa de ser projeto e vira
rotina.

| Camada | Testar? | Por quê |
|--------|---------|---------|
| **Models** (`fromResponse`) | **Sempre** | é onde o contrato com o backend quebra; barato, sem mock |
| **Cubits** | **Sempre** | lógica de estado, tratamento de erro e efeitos |
| `AppUtils` | Sim | funções puras, teste trivial |
| Repositories | Raramente | 3 linhas de cola; se testar, use `DioAdapter` |
| Telas (widget test) | Só fluxos críticos | caro de manter; priorize login e formulários |

## 1. Model — sem mock nenhum

É o teste que **paga sozinho o custo de não usar code-gen**: cole o JSON real da API
e o parse manual fica verificado.

```dart
test('fromResponse converte o envelope e a lista', () {
  final model = GetProductsResponseModel.fromResponse({
    'total': 2, 'mensagem': 'ok',
    'result': [
      {'id': '1', 'nome': 'Camisa', 'preco': 99.9},
      {'id': '2', 'nome': 'Calça',  'preco': 149},
    ],
  });

  expect(model.products, hasLength(2));
  expect(model.products.last.price, 149.0);   // int no JSON → double no model
});
```

Teste também a lista vazia — `'result': []` não pode quebrar.

## 2. Cubit — dois testes por operação

Um caminho feliz e um de erro. O de erro garante a invariante mais importante do
padrão: *toda operação termina em `completed`*, e a UI nunca fica presa no loading.

```dart
class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockProductRepository repository;

  final resposta = GetProductsResponseModel(total: 1, message: 'ok',
      products: const [ProductModel(id: '1', name: 'Camisa', price: 99.9)]);

  setUpAll(() {   // necessário para o any() de tipos não primitivos
    registerFallbackValue(const GetProductsRequestModel(storeId: '1', page: 1));
  });
  setUp(() => repository = MockProductRepository());

  blocTest<ProductCubit, ProductState>(
    'sucesso: emite loading e depois completed com o model',
    build: () {
      when(() => repository.getProducts(any())).thenAnswer((_) async => resposta);
      return ProductCubit(repository: repository);
    },
    act: (cubit) => cubit.getProducts(storeId: '1', page: 1),
    expect: () => [
      isA<ProductState>().having((s) => s.getProductsSubState.isLoading, 'isLoading', true),
      isA<ProductState>()
          .having((s) => s.getProductsSubState.isCompleted, 'isCompleted', true)
          .having((s) => s.getProductsSubState.value<GetProductsResponseModel>()?.products,
                  'produtos', hasLength(1)),
    ],
  );

  blocTest<ProductCubit, ProductState>(
    'erro HTTP: termina em completed com ErrorModel (nunca preso em loading)',
    build: () {
      when(() => repository.getProducts(any())).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/produtos'),
        response: Response(requestOptions: RequestOptions(path: '/produtos'),
                           statusCode: 500)));
      return ProductCubit(repository: repository);
    },
    act: (cubit) => cubit.getProducts(storeId: '1', page: 1),
    expect: () => [
      isA<ProductState>().having((s) => s.getProductsSubState.isLoading, 'isLoading', true),
      isA<ProductState>()
          .having((s) => s.getProductsSubState.isCompleted, 'isCompleted', true)
          .having((s) => s.getProductsSubState.hasError, 'hasError', true),
    ],
  );
}
```

## 3. O teste de identidade do `copyWith`

Um por módulo, protegendo a [regra dura](02-gerenciamento-de-estado.md#a-regra-dura-do-copywith):

```dart
test('copyWith preserva a identidade dos sub-estados não alterados', () {
  const estado = ProductState();
  final novo = estado.copyWith(
    getProductsSubState: const BlocSubState(state: BlocDataState.loading));

  // o intocado tem que ser O MESMO OBJETO, senão buildWhen quebra
  expect(identical(estado.registerProductSubState, novo.registerProductSubState), isTrue);
  expect(identical(estado.getProductsSubState, novo.getProductsSubState), isFalse);
});
```

## 4. O obstáculo do `l10n`

`ErrorModel.generic()` e `AppErrorCodes.messageFor` chamam `globals.l10n!`, que
depende de `navigatorKey.currentContext` — **`null` em teste unitário**. Duas saídas:

**(a) mensagem opcional no model**, resolvida só quando há contexto:
`String get message => _message ?? globals.l10n?.unknownError ?? 'error:$code';`

**(b) resolvedor injetável**, que mantém o código de produção idêntico:

```dart
typedef L10nResolver = AppLocalizations? Function();

class AppL10n {
  static L10nResolver resolver =
      () => AppLocalizations.of(AppRoutes.navigatorKey.currentContext!);
  static AppLocalizations get current => resolver()!;
}

AppL10n.resolver = () => AppLocalizationsPt();   // no setUp do teste
```

Prefira (b) e **decida no início do projeto** — retroagir depois exige tocar em todo
`ErrorModel`.

## 5. `AppStorage` em teste

`read` devolve `null` sem box inicializada, então cubits que só *leem* funcionam sem
setup. Para os que *escrevem* (login), inicialize o Hive em memória:

```dart
setUpAll(() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Hive.init('./test/.hive');
  await AppStorage.initialize();
});
tearDown(() async => AppStorage.clear());
```

Para isolar de vez, extraia uma interface `Storage` e injete no cubit igual ao
repository.

## 6. Widget test (fluxos críticos)

`navigatorKey` precisa estar plugado no `MaterialApp` do teste — é a contrapartida do
acesso global de [07](07-navegacao-e-rotas.md):

```dart
testWidgets('login inválido mostra erro', (tester) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    navigatorKey: AppRoutes.navigatorKey,          // o l10n global depende disso
    home: BlocProvider.value(
        value: AuthCubit(repository: MockAuthRepository()), child: const LoginScreen()),
  ));

  await tester.enterText(find.byType(AppInput).first, 'nao-e-email');
  await tester.tap(find.byType(AppButton).first);
  await tester.pumpAndSettle();

  expect(find.text('E-mail inválido.'), findsOneWidget);
});
```

## Meta razoável

`flutter test` (ou `--coverage`). Não persiga cobertura total; o alvo que dá retorno:
**100% dos `fromResponse`**, **2 testes por operação de cubit**, **1 teste de
`copyWith` por módulo**, e widget test só para login e formulários com regra de
negócio.
