# Padrão de Projeto Flutter — Especificação

Padrão arquitetural para aplicativos Flutter (web, mobile ou ambos), derivado do
projeto `seed_web` e já normalizado onde o original era inconsistente.

> **Fonte da verdade.** Onde diverge do `seed_web`, esta especificação vence — as
> divergências estão em [13-convencoes-e-tradeoffs.md](13-convencoes-e-tradeoffs.md).

## Índice

| # | Documento | Assunto |
|---|-----------|---------|
| 00 | [Visão geral](00-visao-geral.md) | Filosofia, camadas, fluxo de dados ponta a ponta |
| 01 | [Estrutura de pastas](01-estrutura-de-pastas.md) | Onde cada coisa mora e por quê |
| 02 | [Gerenciamento de estado](02-gerenciamento-de-estado.md) | Cubit + `BlocSubState` + `copyWith` |
| 03 | [Camada de API](03-camada-de-api.md) | `AppApi` com Dio, ambientes, token, interceptors |
| 04 | [Repositories](04-repositories.md) | Interface + implementação, injetáveis e mockáveis |
| 05 | [Models](05-models.md) | Request/Response, `fromResponse`, `toBody`, `toStorage` |
| 06 | [Armazenamento local](06-armazenamento-local.md) | `AppStorage` (Hive + SharedPreferences) |
| 07 | [Navegação e rotas](07-navegacao-e-rotas.md) | `AppRoutes`, navigatorKey global, route guard |
| 08 | [UI e Design System](08-ui-design-system.md) | `App*` components, padrão Controller, responsividade |
| 09 | [Internacionalização](09-i18n.md) | ARB + `AppLocalizations` + regra única de acesso |
| 10 | [Tratamento de erros](10-tratamento-de-erros.md) | `ErrorModel`, códigos de erro, snackbars |
| 11 | [Receita: novo app do zero](11-receita-novo-app.md) | Passo a passo + esqueleto copiável |
| 12 | [Receita: nova feature](12-receita-nova-feature.md) | Checklist de uma feature completa |
| 13 | [Convenções e trade-offs](13-convencoes-e-tradeoffs.md) | Regras, custos, divergências do `seed_web` |
| 14 | [Testes](14-testes.md) | Como testar cubits, repositories e models |

## Resumo de uma linha

> **Cubit por módulo → `BlocSubState` por operação → Repository injetado (interface + impl) → `AppApi` (Dio) → Model com `fromResponse(Map)` → estado emitido com `copyWith`; persistência via `AppStorage` (Hive); navegação e i18n acessíveis globalmente por `navigatorKey`.**

## As três assinaturas do padrão

Se você entender só três coisas, que sejam estas:

1. **Erro não é estado, é tipo de dado.** `BlocDataState` tem apenas
   `idle/loading/completed`. O que diferencia sucesso de falha é o **tipo** do
   que está em `BlocSubState.data`. A UI decide tudo com um único `is`.
2. **Não se usa `Equatable`.** O filtro `buildWhen: (p,c) => p.xSubState != c.xSubState`
   funciona por **identidade de instância**: `copyWith` só troca o campo alterado,
   então os demais continuam sendo o mesmo objeto. Isso é o que faz o filtro
   funcionar — e é frágil, por isso há uma regra dura sobre `copyWith` em
   [02](02-gerenciamento-de-estado.md#a-regra-dura-do-copywith).
3. **`navigatorKey` global** é o que permite traduzir, navegar e ler `MediaQuery`
   de dentro de models, utils e do interceptor do Dio, sem carregar `BuildContext`.

## Stack de referência

```yaml
dependencies:
  flutter_bloc: ^8.1.5      # estado (usado só como Cubit)
  dio: ^5.4.3+1             # HTTP
  hive: ^2.2.3              # storage local (chave/valor)
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.3
  intl: any                 # formatação
  flutter_localizations:    # i18n (ARB)
    sdk: flutter
  flutter_svg: ^2.0.10+1    # ícones

dev_dependencies:
  bloc_test: ^9.1.7         # testes de cubit
  mocktail: ^1.0.4          # mocks sem code-gen
```

Sem injeção de dependência por container (get_it), sem code-gen de models
(freezed/json_serializable), sem router declarativo (go_router). Isso é
intencional — os custos estão em [13](13-convencoes-e-tradeoffs.md).
