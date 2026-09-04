# AGENTS.md — Thamires Borges Beauty (business-insights)

Contexto permanente do projeto. Leia antes de tocar em qualquer arquivo.

## O que é

App de gestão financeira para um salão de beleza de uma profissional autônoma
(Thamires Borges Beauty). Responde a uma pergunta só, de várias formas: **"eu estou
ganhando ou perdendo dinheiro?"** — por atendimento, por mês, por serviço.

Usuária única, não técnica, usando **celular no dia a dia** e **navegador quando senta
para fechar as contas**. Web e mobile são o mesmo app Flutter, com cascas diferentes.

## Repositório

```
business-insights/
├── AGENTS.md                      # este arquivo
├── .specs/
│   ├── 00-ENTREGA-BACKEND.md      # índice único do que entregar ao backend — comece aqui
│   ├── padrao-de-projeto-flutter/ # o padrão arquitetural (15 docs) — fonte da verdade
│   ├── padrao-flutter-salao.md    # divergências deste projeto em relação ao padrão
│   ├── endpoints-backend.md       # contrato: 52 operações que o FastAPI deve expor
│   └── pedidos-backend.md         # ordens de serviço da F4, em lotes L0–L7
├── api/                           # FastAPI — o ÚNICO backend que o app enxerga
├── database/
│   ├── schema.sql                 # Supabase/Postgres (estado antes da V1)
│   └── migrations/
│       ├── 001_v1_completo.sql    # idempotente: 11 tabelas novas + ajustes
│       └── 002_seed_teste.sql     # dados de teste (NÃO rodar em produção)
├── frontend/salao_app/            # Flutter (web + mobile)
└── n8n/                           # automações (WhatsApp, cron, resumos)
```

O padrão em `.specs/padrao-de-projeto-flutter/` é uma cópia vendorizada de
`F:\projects\FrotaOP_mobile\padrao-de-projeto-flutter` — mantida aqui para o repo ser
autocontido. Se o original mudar, atualize a cópia deliberadamente.

## Decisões de arquitetura (02/09/2026)

Estas nove foram decididas pelo dono do projeto e **não devem ser revisitadas sem
ele**. Vieram de perguntas explícitas, não de dedução.

| # | Decisão | Consequência |
|---|---|---|
| **A1** | **Tudo via FastAPI.** Uma única `baseUrl`. O Flutter **nunca** fala com o Supabase (nem PostgREST, nem RPC, nem SDK). | O FastAPI passa a ter CRUD, não só relatório. O mapa de endpoints é uma especificação de backend real. Regra de negócio (baixa de estoque ao finalizar atendimento) mora no servidor. |
| **A2** | **Módulo `auth` completo.** Login, token no `AppStorage`, interceptor 401, route guard. | É a primeira feature a subir — o padrão manda validar a arquitetura inteira com ela. Layout de login derivado da paleta (não existe no protótipo). |
| **A3** | **Alertas in-app + push agora; WhatsApp e e-mail só mapeados.** | Implementar: badge, banner, central de alertas, push. Os endpoints de WhatsApp/e-mail entram no mapa marcados como *futuro* — o n8n já tem fluxos prontos para consumi-los. |
| **A4** | **`AppStorage` só sobre `SharedPreferences`.** Sem Hive, sem drift. | Mesma fachada `read`/`write`/`delete`/chaves centralizadas do padrão. Serve para sessão e cache leve. **Não há offline-first**: escrita sem rede falha e a UI mostra erro. |
| **A5** | **Estoque insuficiente avisa, não bloqueia.** Finalizar atendimento e montar kit perguntam "quer registrar mesmo assim?". | Duas passadas no mesmo endpoint: a primeira não grava nada e devolve `409 ESTOQUE_INSUFICIENTE` com `result.faltantes`; a segunda leva `confirmar_estoque_insuficiente: true`, deixa o saldo negativo e gera alerta. `StatusEstoque` ganha `negativo`, distinto de `critico`. |
| **A6** | **Custo do item é média ponderada móvel**, não o último preço pago. | Cada entrada recalcula `custo_medio`; `custo_ultima_compra` fica ao lado, informativo. Uma compra cara ou promocional não reescreve o custo do saldo parado — a margem só se move quando o custo real se move. |
| **A7** | **Montar kit é operação real.** Ela monta kits com o estoque que já tem, e vende depois. | Montar e vender são fatos separados, em momentos diferentes: o kit tem saldo próprio (`quantidade_montada`). Montar consome insumo e passa pelo aviso de A5; vender **não** tem segunda passada — `KIT_NAO_MONTADO` é definitivo, um kit que não existe não se vende. |
| **A8** | **Bundle id `br.com.thamiresbeauty.salao`**, nome de exibição "Thamires Beauty". | `android/` e `ios/` gerados. Aplicado em `applicationId`, `namespace`, package Kotlin e `PRODUCT_BUNDLE_IDENTIFIER`. É a identidade do app nas lojas — cara de mudar depois. |
| **A9** | **Resumo é a entrada do app e segue o painel Lovable de 02/09/2026.** | É a primeira aba e a `homeRoute`. Consolida alerta, resultado mensal, histórico de seis meses, lucro por serviço, meta, próximos gastos e reposição. A bottom bar destaca o ativo só por cor/ícone/rótulo, sem fundo. |

### O que essas decisões apagam do estado atual

- `api/README.md` e o docstring de `api/app/main.py` dizem "CRUD puro → Supabase REST
  (Flutter chama diretamente)". **Isso está morto por A1** — corrija quando encostar
  nesses arquivos.
- O `schema.sql` foi desenhado para RLS com a *anon key* do Supabase, porque o Flutter
  ia bater direto. Com A1 quem bate é o FastAPI (service role). As policies de RLS
  continuam valendo como segunda barreira, mas **a autorização passa a ser do FastAPI**,
  derivada do token — nunca de um `user_id` que o cliente mande no corpo.

## O padrão de projeto

`.specs/padrao-de-projeto-flutter/` vale **integralmente**, com as divergências
registradas em `.specs/padrao-flutter-salao.md`. O resumo de uma linha:

> Cubit por módulo → `BlocSubState` por operação → Repository injetado (interface +
> impl) → `AppApi` (Dio) → Model com `fromResponse(Map)` → estado emitido com
> `copyWith`; persistência via `AppStorage`; navegação e i18n globais por
> `navigatorKey`.

As três assinaturas que não se negociam:

1. **Erro não é estado, é tipo de dado.** `BlocDataState` tem só
   `idle/loading/completed`; erro é `data is ErrorModel`.
2. **Sem `Equatable`.** `copyWith` com `?? this.x` em **todos** os campos — é o que faz
   `buildWhen` funcionar por identidade.
3. **`navigatorKey` global**, e só em `app_globals.dart` e `app_routes.dart`.

## Módulos

Os nomes valem simultaneamente em `cubits/`, `models/`, `repositories/` e `ui/screens/`.

| Módulo | Responsabilidade | Tela no protótipo |
|---|---|---|
| `auth` | login, refresh, logout, sessão, guard | — (derivada da paleta) |
| `atendimentos` | agendar, finalizar, cancelar, listar; saldo do período | Atendimentos |
| `gastos` | lançar, marcar pago, listar pendentes/pagos | Gastos |
| `resumo` | consolidação mensal, insights, precificação | Resumo |
| `estoque` | itens e movimentações | Estoque |
| `kits` | kits de revenda | Estoque (seção) |
| `perfil` | dados do salão e custos fixos | Perfil |
| `servicos` | tabela de preços e produtos padrão | Perfil (seção) |
| `alertas` | estoque baixo, gastos a vencer, central, badge, push | transversal |

Nenhum passa de ~8 operações — é por isso que `kits` sai de `estoque` e `servicos` sai
de `perfil`, embora dividam tela. Módulo é unidade de dado, não de tela.

## Design system

Paleta e layout vêm de `design-todas-telas.html` (protótipo aprovado). **A paleta é
roxa; verde e vermelho são reservados a positivo/negativo** (saldo, pago/pendente,
estoque ok/alerta) — trocar isso prejudica a leitura financeira e não deve ser feito.

```
primary        #BD6DF2    primary-dark   #896393    primary-accent #BD4EBF
primary-mid    #C9A0F2    primary-light  #EAE6E5
success #3B6D11 · success-light #EAF3DE · success-mid #C0DD97
danger  #A32D2D · danger-light  #FCEBEB · danger-mid  #F09595
amber   #854F0B · amber-light   #FAEEDA
text-1 #1A1A1A · text-2 #6B6B6B · text-3 #9E9E9E
surface #FFFFFF · surface-2 #F7F7F5 · border #EAE6E5 · scaffold #FFFFFF
```

Implementada em `settings/app_colors.dart`. O tema azul `#185FA5` do app antigo foi
removido junto com `lib/theme/`. O `scaffold` era o lilás `#F1EDF0` do protótipo e
virou branco por decisão do dono do projeto — os cartões continuam se destacando pela
borda e pela sombra, não pelo contraste com o fundo.

### Casca por dispositivo

`AppScaffold` resolve as duas, decidindo por `deviceType(context)`:

- **mobile / tablet (≤1024)** — app bar simples, **bottom nav** de 5 itens, FAB
  ("Agendar", "Novo gasto", "Novo item") no canto inferior direito.
- **desktop (>1024)** — **menu lateral** de 172px com marca e 5 itens, sem bottom nav,
  sem FAB; a ação primária vira botão no cabeçalho da página.

Regra prática do protótipo: no mobile as listas são **cartões empilhados**; na web as
mesmas listas viram **tabela** (`AppTable`) ou grid de duas colunas. É o mesmo dado com
densidade diferente, não duas telas diferentes.

### Ícones

O protótipo usa Tabler Icons. Como os SVGs não estão no repositório,
`settings/app_assets.dart` mapeia cada um para o equivalente Material mais próximo, com
o nome Tabler anotado ao lado. **Nenhuma tela escreve `Icons.*`** — só `AppAssets` +
`AppIcon`, então trocar pelos SVGs reais é mexer em um arquivo.

## Checklist de conformidade

Além dos portões do padrão, antes de marcar qualquer task como concluída:

- [ ] Nenhum widget Material direto na tela — só `App*`
- [ ] Nenhuma cor ou `TextStyle` literal fora de `AppColors` / `AppFonts`
- [ ] Nenhuma string visível ao usuário fora do ARB
- [ ] Nenhum enum fora de `app_enums.dart`
- [ ] Nenhuma string de URL fora de `AppApi`; nenhuma `baseUrl` fixa no código
- [ ] Nenhum tipo do Dio (`Response`, `DioException`) cruzando o repository
- [ ] Nenhuma chave de storage fora de `AppStorage`
- [ ] `copyWith` com `?? this.x` em **todos** os campos
- [ ] `buildWhen` / `listenWhen` presentes, comparando o sub-estado específico
- [ ] Cubit trata sucesso, `DioException` e genérico — sempre terminando em `completed`
- [ ] Repository não trata exceção e não decide autorização
- [ ] A tela funciona nas duas cascas (bottom nav e menu lateral)

## Estado da migração

O app foi **reescrito** sobre o padrão. O que existia antes — `provider` +
`ChangeNotifier`, `ApiService` com métodos `static` e mocks em memória, `http` em vez de
Dio, strings e cores literais nas telas, sem rotas nomeadas, sem i18n, sem testes — foi
removido por inteiro.

Fases, nesta ordem (cada uma é entregável e revisável sozinha):

- [x] **F0 — Contexto.** Este arquivo, `padrao-flutter-salao.md`, `endpoints-backend.md`.
- [x] **F1 — Infra.** `settings/` completo, `bloc_substate`, `response_model`,
      `error_model`, ARB, `main.dart`, rotas.
- [x] **F2 — Design system.** `ui/components/` com a paleta nova e a casca responsiva.
- [x] **F3 — Módulos** (9), de baixo para cima: model → repo → state → cubit → teste →
      tela. O código antigo (`provider`, `ApiService`, `screens/`, `theme/`, `widgets/`)
      foi removido.
- [ ] **F4 — Backend.** FastAPI implementando `endpoints-backend.md`, nos lotes de
      `.specs/pedidos-backend.md`. O SQL já está escrito (`database/migrations/`) mas
      **ainda não foi executado** no Supabase. **O app inteiro depende disto para sair
      do zero** — contra a API real ele compila, roda e não tem com quem falar.
      Enquanto isso, o **modo demo** (abaixo) mantém o app clicável de ponta a ponta.
- [ ] **F5 — Push.** `android/`/`ios/` já existem (A8). Falta o projeto Firebase —
      config que só o dono cria.

### Portões verificados

`flutter analyze` sem nenhum aviso · `flutter test` com **75 testes verdes** ·
`flutter build web --release` concluindo. Rode os três antes de fechar qualquer fase.

### Modo demo

Um servidor falso em memória por trás das mesmas interfaces de repository, para o
app ser demonstrável enquanto a F4 não sai.

```bash
flutter run -d chrome --dart-define-from-file=env/demo.json
```

- **Liga por `--dart-define`**, lido em `settings/app_environment.dart`
  (`AppEnvironment.isDemo`, `const`). `env/demo.json` é o único lugar que o marca.
- **`repositories/app_repositories.dart` é o único arquivo que sabe que a demo
  existe**: `AppRepositories.kits` devolve `DemoKitsRepository` ou
  `KitsRepositoryImpl`. Cubit, tela e teste nunca perguntam pelo modo.
- **`repositories/demo/demo_database.dart` fala o protocolo, não o modelo**:
  devolve o envelope `{total, mensagem, codigo, result}` cru, que passa pelo
  `fromResponse` de verdade, e erra lançando `DioException` com `codigo`. As duas
  passadas de A5, a média ponderada de A6 e o `KIT_NAO_MONTADO` de A7 rodam ali —
  é a especificação do backend em código executável, com 18 testes
  (`test/repositories/demo_database_test.dart`).
- **Some do build de produção**: com `isDemo` `const false`, o tree shaking
  descarta a pasta `demo/` inteira (verificado no `main.dart.js`).
- Login aceita qualquer e-mail e senha; a senha `errada` devolve
  `AUTH_CREDENCIAIS_INVALIDAS`, para testar o caminho de erro. A tela de login
  mostra um aviso âmbar quando o modo está ligado — sem ele, a demo é
  indistinguível do app real e alguém salva um dado achando que ficou gravado.

### Decisões tomadas durante a implementação

- **`AppL10n` com resolvedor injetável** (`settings/app_l10n.dart`) — a saída (b) do
  §4 de `14-testes.md`. Sem ela, `navigatorKey.currentContext` **lança** em teste
  unitário (não devolve `null`), e todo teste de caminho de erro quebrava. O padrão
  manda decidir isso no início do projeto; está decidido.
- **Ícones Material em vez dos SVGs da Tabler** (`settings/app_assets.dart`). O
  protótipo usa Tabler; não temos os arquivos, e asset inexistente quebra em runtime.
  Cada ícone tem o equivalente Tabler anotado ao lado — trocar é mexer em um arquivo.
- **`kits` separado de `estoque`, `servicos` separado de `perfil`** — juntos passariam
  de ~8 operações. Módulo é unidade de dado, não de tela.
- **No resumo, custo fixo vem do perfil e gasto variável vem de `gastos` com
  `categoria != 'fixo'`** — a demo precisou decidir isso para não somar o mesmo
  aluguel duas vezes (ele aparece nas duas tabelas no seed). **Confirmar com o
  backend**: é a única regra da demo que o `endpoints-backend.md` não fixa.
- **`lib/ui/dialogs/`** existe para o diálogo de domínio que duas telas usam
  (`EstoqueInsuficienteDialog`). Não é `components/`: lá só moram os `App*` do design
  system, e a checklist de conformidade depende dessa separação.

### Dívidas conhecidas, a resolver na migração

- ~~Dois modelos `Atendimento` e dois `Gasto` conflitantes~~ — resolvido na F3: sobrou
  um por módulo, e os arquivos antigos foram apagados.
- ~~Estoque e kits só existem no mock do Flutter~~ — `001_v1_completo.sql` cria as 11
  tabelas que faltavam. **Falta executar** no Supabase.
- **Contrato de `gastos` diverge**: o Flutter usa `forma_pagamento` ∈ {avista, credito,
  debito, pix} + `categoria` ∈ {material, fixo, outros}; o `schema.sql` usa
  {'à vista','cartão'} + `prioridade` ∈ {alta, média, baixa}. O mapa de endpoints
  define o contrato vencedor, e `001_v1_completo.sql` já converte os dados existentes.
- **`RelatorioMensal` (Flutter, plano) ≠ `ResumoMensal` (API, aninhado)**. Vence o da
  API, estendido com os insights do protótipo (ticket médio, margem, comparativo com o
  mês anterior, serviço mais lucrativo).
- **`_extrair_user_id` decodifica o JWT sem verificar assinatura**
  (`api/app/routers/relatorio.py`). Com A1 isso vira falha de segurança de verdade, não
  simplificação: qualquer um forja um `sub`. É o lote **L0.2** de
  `pedidos-backend.md`, marcado 🔴 — validar com o `SUPABASE_JWT_SECRET`.
- **4 de 52 endpoints existem.** O app está inteiro; o backend, não. `pedidos-backend.md`
  é a lista do que falta, em ordem de dependência.

## Convenções de trabalho

- Idioma do código: **inglês** para nomes de classe/arquivo do padrão (`AppApi`,
  `BlocSubState`) e **português** para domínio (`AtendimentoModel`, `getGastosPath`),
  seguindo o que o padrão já faz. Texto de UI: sempre ARB, sempre pt-BR.
- Commits em português, como o histórico do repositório.
- Não invente contrato de API: se falta endpoint, ele entra em
  `.specs/endpoints-backend.md` antes de existir código que o chame.
