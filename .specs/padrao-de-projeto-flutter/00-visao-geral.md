# 00 — Visão geral

## Filosofia

1. **Sem code generation** para models — parse escrito à mão, chaves do JSON como
   `static const` privadas dentro do model.
2. **Sem container de DI** — a única dependência injetada é o repository, pelo
   construtor do cubit, com implementação padrão. Basta isso para testar.
3. **Cubit, não Bloc com eventos** — `<Modulo>Cubit` com métodos públicos
   (`cubit.getProducts(...)`), não despacho de evento.
4. **Um cubit por módulo de tela**, não por caso de uso. Cada operação tem seu
   `BlocSubState`. Passou de ~8 operações, divida o módulo.
5. **Acesso global via `navigatorKey`** — navegar, traduzir e ler contexto de
   qualquer lugar (models, utils, interceptor), sem carregar `BuildContext`.

## As 4 camadas

```
UI          ui/screens/**, ui/components/**
            StatefulWidget + BlocBuilder/Consumer/Listener; componentes App* com Controller
   ▲ state (BlocSubState)          ▼ chama método do cubit
ESTADO      cubits/**
            XCubit extends Cubit<XState> (repository injetado)
            XState = N campos BlocSubState + copyWith; sempre emite `completed`
   ▲ Model tipado                  ▼ _repository.metodo()
DADOS       repositories/** + models/**
            abstract interface XRepository + XRepositoryImpl
            Model.fromResponse(Map) / model.toBody
   ▲ Response<T> do Dio            ▼
INFRA       settings/**
            AppApi (Dio + token + interceptor 401), AppStorage, AppRoutes,
            AppColors, AppFonts, AppUtils, AppEnums…
```

## Fluxo de uma requisição

```
1. UI        cubit.getProducts(storeId: …, page: 1)            (initState)
2. CUBIT     emit(copyWith(getProductsSubState: BlocSubState(state: loading)))
             await _repository.getProducts(model)
3. REPO      AppApi.get(path, queryParameters: model.toQuery)
             → GetProductsResponseModel.fromResponse(response.data)
4. APPAPI    injeta Bearer do AppStorage; 401 → interceptor chama AppUtils.logout()
5. MODEL     fromResponse(Map) lê as chaves e converte cada item
6. CUBIT     emit(copyWith(…: BlocSubState(state: completed, data: response)))
             em erro:  data: ErrorModel.fromDioException(e)
7. UI        BlocBuilder(buildWhen: (p,c) => p.xSubState != c.xSubState)
             isLoading → AppLoading · value<Model>() → conteúdo · error → snackbar/vazio
```

**Regra de ouro:** `BlocDataState` tem só `idle`, `loading`, `completed`. **Não existe
estado de erro** — erro é o *tipo* do dado dentro de `completed` (`data is ErrorModel`).
A UI decide tudo num único ponto.

## Convenção de nomes

| Item | Padrão | Exemplo |
|------|--------|---------|
| Cubit / Estado | `<Modulo>Cubit` / `<Modulo>State` | `ProductCubit` |
| Arquivos do cubit | `<modulo>_cubit.dart` + `<modulo>_state.dart` | `product_cubit.dart` |
| Campo de sub-estado | `<operacao>SubState` | `getProductsSubState` |
| Repository | `<Modulo>Repository` (interface) + `…Impl` | `ProductRepositoryImpl` |
| Model de envio / retorno | `<Acao>RequestModel` / `<Acao>ResponseModel` | `GetProductsResponseModel` |
| Model de entidade | `<Entidade>Model` | `ProductModel` |
| Componente + controller | `App<Nome>` / `App<Nome>Controller` | `AppInput`, `AppInputController` |
| Infra | `app_<assunto>.dart` | `app_api.dart` |
| Tela / diálogo / widget | `<nome>_screen.dart` / `_dialog.dart` / `_widget.dart` | `login_screen.dart` |

> **Nunca** nomeie um `Cubit` como `<Modulo>Bloc`. A classe estende `Cubit`, e o nome
> tem que dizer a verdade.
