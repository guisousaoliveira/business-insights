# 13 — Convenções e trade-offs

## As 14 regras de camada

1. Nenhuma string de URL fora de `AppApi`; nenhuma `baseUrl` fixa no código (use
   `--dart-define`).
2. Nenhuma chave de storage fora de `AppStorage`.
3. Nenhuma cor ou `TextStyle` literal fora de `AppColors`/`AppFonts`.
4. Nenhuma string visível ao usuário fora do ARB.
5. Nenhum enum fora de `app_enums.dart`.
6. Conversão `int ↔ enum` só em `AppUtils` (`decodeXType` / `xTypeToString`).
7. `navigatorKey` só aparece em `app_globals.dart` e `app_routes.dart`.
8. Nada em `settings/` que dependa de `l10n` ou `MediaQuery` pode ser campo `static`
   — tem que ser função.
9. Repository não trata exceção; o cubit trata as três (sucesso, `DioException`,
   genérico) e **sempre** termina em `completed`.
10. `copyWith` usa `x ?? this.x` em todos os campos, sem exceção.
11. `buildWhen`/`listenWhen` sempre presentes, comparando o sub-estado específico.
12. Erro de negócio se identifica por **código**, nunca por texto de mensagem.
13. Widget usado por 2+ módulos vira `App*` em `ui/components/`.
14. Módulo com mais de ~8 operações deve ser dividido.

Nomenclatura completa em [00 § Convenção de nomes](00-visao-geral.md). Chave de JSON:
`static const _<campo>Key = 'nomeNoBackend';` dentro do model. Persistência:
`factory fromStorage` + `get toStorage`, com chaves **em inglês**.

## Divergências deliberadas do `seed_web`

Se estiver portando código de lá, estes são os ajustes:

| `seed_web` | Aqui | Motivo |
|-----------|------|--------|
| Repositories com métodos `static` | interface + `Impl` injetado no cubit | tornava o cubit impossível de testar; custo: 3 linhas |
| `fromResponse` ora `Response`, ora `Map` | **sempre `Map<String, dynamic>`** | model não conhece o Dio; parse testável com JSON literal |
| `Cubit` nomeado `<Modulo>Bloc`, pasta `blocs/` | `<Modulo>Cubit`, pasta `cubits/` | o nome deve dizer a verdade |
| 3 formas de acessar `l10n` | `context` no `build`, `globals.l10n` fora | evita espalhar `navigatorKey` |
| URL de API fixa, alternativa comentada | `String.fromEnvironment` | build depende de flag, não de qual linha estava descomentada |
| Compara mensagem literal do backend | `AppErrorCodes` compara **código** | mensagem muda, não traduz, quebra em silêncio |
| Um cubit com classes de estado, o resto com `BlocSubState` | `BlocSubState` para tudo com I/O | um padrão só |
| Estado com 19 sub-estados | dividir acima de ~8 operações | o módulo já virou três |
| `AppFonts`/`AppConstants` como campo `static` | funções que recebem `context` | campo estático não responde a resize nem a troca de idioma |
| Ternário triplo em toda tela | `AppSubStateBuilder<T>` | mesmo comportamento, sem repetição e sem `as` |
| `refreshToken` salvo e nunca usado | interceptor tenta refresh antes do logout | sessão renovável não deve derrubar o usuário |

O que **não** mudou, e é intencional: erro como tipo de dado, ausência de
`Equatable`, cubits globais no `main`, `navigatorKey` global, storage como via de
passagem entre telas, parse manual sem code-gen.

## Trade-offs conscientes

| Escolha | Custo | Quando reconsiderar |
|---------|-------|---------------------|
| **Cubit em vez de Bloc com eventos** | sem rastro de eventos para auditoria/replay | event sourcing |
| **`data` como `Object?`** | sem type safety no campo; mitigado por `value<T>()` | garantia em compilação → `sealed class Result<T>` |
| **Sem `Equatable`** | `copyWith` mal escrito quebra o filtro **em silêncio** | equipe grande → `Equatable` em `BlocSubState` **e** nos models |
| **Cubits globais no `main`** | estado sobrevive à saída da tela; memória cresce | módulo grande ou raro → prover na rota |
| **Sem container de DI** | injeção manual repository a repository | acima de ~15 módulos, `get_it` encaixa sem mudar mais nada |
| **Sem code-gen nos models** | verboso; erro de chave só em runtime | mitigado por testar 100% dos `fromResponse` |
| **Storage como parâmetro entre telas** | acoplamento oculto; duas telas podem brigar pela mesma chave | mobile puro → prefira `arguments` de rota |
| **`navigatorKey.currentContext!`** | `null` antes do primeiro frame e em teste unitário | ver a seção de `l10n` em [14](14-testes.md) |
| **Validação por `Controller.validate()`** | precisa de `setState` manual, não integra com `Form` | formulário muito grande → `Form` + `FormField` |
| **Navigator 1.0 imperativo** | deep link e URL exigem código manual | muitos deep links → `go_router` |

## O que o padrão não cobre

- **Offline-first / sincronização** — `AppStorage` é cache de sessão, não banco.
  Precisa de query? Drift ou Isar.
- **Analytics e monitoramento de erros** — o lugar natural é o `catch` do cubit e o
  interceptor do Dio (`AppTelemetry.captureError` dentro de
  `ErrorModel.fromDioException`).
- **Feature flags / configuração remota.**
- **Paginação infinita** — o padrão assume paginação por página; scroll infinito
  exige acumular listas no estado, o que o `BlocSubState` (que substitui o `data`
  inteiro a cada emit) não faz sozinho.
