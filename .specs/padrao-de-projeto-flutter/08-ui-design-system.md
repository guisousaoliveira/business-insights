# 08 — UI e Design System

## Princípios

1. **Nenhum widget do Material aparece direto nas telas.** Toda tela usa
   `AppScaffold`, `AppButton`, `AppInput`, `AppDropdown`, `AppDialog`… O Material
   fica encapsulado em `ui/components/`.
2. **Design tokens em classes estáticas** (`AppColors`, `AppFonts`, `AppAssets`).
   Nada de `Color(0xFF…)` ou `TextStyle(…)` inline numa tela.
3. **Componentes complexos têm um `Controller` próprio**, o que evita `setState`
   espalhado e centraliza validação.
4. **Telas são `StatefulWidget`** — precisam de `initState` para o fetch e os
   controllers.

## Design tokens

```dart
class AppColors {          // paleta plana, nomes por matiz+intensidade
  static const grey300 = Color(0xFF8899A2);
  static const primary = Color(0xFFE5187A);
}

class AppAssets {          // caminhos como const
  static const addIconPath = 'assets/icons/add.svg';
}
```

**`AppFonts` são funções que recebem `context`, nunca campos `static final`** — campo
estático é avaliado uma vez, não reage a resize e depende de o `navigatorKey` já ter
contexto:

```dart
class AppFonts {
  static TextStyle titleLarge(BuildContext context) => TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: deviceType(context) == DeviceType.desktop ? 24 : 18,
        color: AppColors.black,
      );
}

Text(context.l10n.goalTitle, style: AppFonts.titleLarge(context))
```

Mesma regra do [09-i18n.md](09-i18n.md): **nada em `settings/` que dependa de
`MediaQuery` ou de `l10n` pode ser campo `static`.**

## Responsividade

`lib/settings/app_media_querys.dart` — **funções de nível superior**, sem classe:

```dart
enum DeviceType { desktop, smallDesktop, tablet, tabletLandscape, mobile }

DeviceType deviceType(BuildContext context) {
  final width = deviceWidth(context);
  if (width <= 640)  return DeviceType.mobile;
  if (width <= 1024) return deviceOrientation(context) == Orientation.landscape
      ? DeviceType.tabletLandscape : DeviceType.tablet;
  if (width <= 1280) return DeviceType.smallDesktop;
  return DeviceType.desktop;
}
```

Breakpoints: `≤640` mobile · `≤1024` tablet · `≤1280` small desktop · `>1280` desktop.

## `AppScaffold` — a casca de toda tela

Resolve de uma vez app bar com dados do usuário (lidos do `AppStorage`), menu
lateral, padding responsivo e scroll. Telas de autenticação passam
`hasAppBar: false, hasSideMenu: false, isPadded: false`.

```dart
AppScaffold(
  currentPage: AppCurrentRoute.products,  // marca o item ativo no menu
  hasAppBar: true, hasLeading: true, hasSideMenu: true,
  isScrollable: true, isPadded: true,
  title: 'Produtos',
  fixedBottomWidget: …,   // barra fixa de ações
  child: Column(…),
)
```

> Ao criar uma tela nova: adicione a rota em `AppRoutes`, o valor em
> `AppCurrentRoute` e a entrada em `AppSideMenuUtils._indexToRouteMap`.

## O padrão "Controller" de componente

Componente com estado interno (input, dropdown, tabela, paginação) = **uma classe
`Controller` + o `Widget`, no mesmo arquivo**.

```dart
class AppInputController {
  final String? Function(String val)? validator;
  late final TextEditingController _textEditingController;
  late final FocusNode _focusNode;
  late String? _error;
  late bool _isDisposed;
  bool _isRequired;

  void Function()? onValueChangedSetState;   // o Widget injeta para se redesenhar

  AppInputController({bool isRequired = true, this.validator, String? initialValue}) { … }

  String get text   => _textEditingController.text;
  String? get error => _error;
  bool get hasError => _error != null;

  void validate() {
    if (_isDisposed) return;
    if (_isRequired && _textEditingController.text.isEmpty) {
      _error = globals.l10n?.requiredInputError;
    } else {
      _error = validator?.call(_textEditingController.text);
    }
  }

  void dispose() { … }
}
```

**Validação de formulário é `validate()` em cada controller dentro de um `setState`**
— não `Form` + `GlobalKey<FormState>`:

```dart
void _submit() {
  setState(() {
    _emailController.validate();
    _passwordController.validate();
  });
  if (!_emailController.hasError && !_passwordController.hasError) {
    BlocProvider.of<AuthCubit>(context)
        .login(user: _emailController.text, pass: _passwordController.text);
  }
}
```

`AppDropdownController` é análogo (`items`, `selectedValue`, `onValueSelected`,
`validate()`). Repare que **o filtro dispara a busca direto do callback do
controller** — não existe botão "aplicar filtros".

## Validadores

```dart
abstract class AppValidators {
  static String? validateEmail(String text) =>
      text.contains(RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$'))
          ? null : globals.l10n?.emailError;
}
```

Assinatura `String? Function(String)`, devolve `null` se válido. "Obrigatório" **não**
é validador — é a flag `isRequired` do controller.

## Diálogos e snackbars

```dart
final bool? recarregar = await AppDialog.show<bool>(context: context, dialog: …);
AppSnackBar.showSnackbar(context, mensagem, SnackBarStatus.error);  // sucess|error|alert
```

O `MaterialApp` é envolvido por `ScaffoldMessenger` no `main.dart` para o snackbar
funcionar de qualquer rota. **Padrão de diálogo:** ele executa a ação e devolve
`true`; a tela que o abriu recarrega a lista.

## Anatomia de uma tela

```dart
class _ProductsScreenState extends State<ProductsScreen> {
  late final AppInputController _searchController;
  late final String storeId;

  void _fetch() => BlocProvider.of<ProductCubit>(context)
      .getProducts(storeId: storeId, page: 1, search: _searchController.text);

  @override
  void initState() {
    _searchController = AppInputController(isRequired: false);   // 1. controllers
    storeId = AppStorage.read(AppStorage.storeIdKey);            // 2. contexto do storage
    _fetch();                                                    // 3. fetch inicial
    super.initState();
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => MultiBlocListener(       // 4. efeitos
    listeners: [
      BlocListener<ProductCubit, ProductState>(
        listenWhen: (p, c) => p.registerProductSubState != c.registerProductSubState,
        listener: (context, state) {
          final sub = state.registerProductSubState;
          if (sub.hasError) {
            AppSnackBar.showSnackbar(context, sub.error!.message, SnackBarStatus.error);
          } else if (sub.isCompleted) {
            _fetch();
          }
        },
      ),
    ],
    child: BlocBuilder<ProductCubit, ProductState>(               // 5. render
      buildWhen: (p, c) => p.getProductsSubState != c.getProductsSubState,
      builder: (context, state) => AppScaffold(
        currentPage: AppCurrentRoute.products,
        child: Column(children: [
          // 6. conteúdo: loading → dado → erro → vazio, sem ternário aninhado
          AppSubStateBuilder<GetProductsResponseModel>(
            subState: state.getProductsSubState,
            onData: (data) => ProductsTableWidget(products: data.products),
            onError: (error) => AppErrorRetry(message: error.message, onRetry: _fetch),
          ),
        ]),
      ),
    ),
  );
}
```

## Inventário de componentes

| Componente | Papel |
|-----------|-------|
| `AppScaffold` | casca da tela: app bar + menu + padding + scroll |
| `AppSubStateBuilder` | loading / dado / erro / vazio a partir de um `BlocSubState` |
| `AppButton` | tipos (`filled`/`outlined`), tamanhos, `isLoading` interno |
| `AppInput`, `AppDropdown` (+ controllers) | campo de texto e seleção com validação |
| `AppCheckBox`, `AppSwitch` | booleanos |
| `AppDatePicker`, `AppDateRangePicker` | datas e períodos |
| `AppTable`, `AppPagination` (+ controllers) | tabela com ordenação e paginação |
| `AppDialog`, `AppSnackBar` | diálogo com retorno tipado e feedback |
| `AppLoading`, `AppEmptyListWarning`, `AppErrorRetry` | estados de conteúdo |
| `AppExportButton` | exportação (xlsx/csv) |
| `AppTappable` | área clicável sem ripple do Material |
| `AppTooltip`, `AppDivider`, `AppProfilePic`, `AppAlert`, `AppTabBar` | auxiliares |
| `AppSideMenu` | menu lateral + `AppCurrentRoute` |

## Exportação de arquivos

Fluxo: cubit chama o endpoint `export*` com `responseType: ResponseType.bytes` →
recebe `Uint8List` → `AppUtils.exportDataToExcel(bytes, nome)`. Na web usa
`universal_html` (Blob + anchor). Em mobile, troque a implementação por
`path_provider` + `share_plus`, **mantendo a mesma assinatura**.
