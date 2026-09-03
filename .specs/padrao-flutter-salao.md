# Padrão de projeto Flutter — adaptação Salão (business-insights)

**Base:** [`padrao-de-projeto-flutter/`](padrao-de-projeto-flutter/README.md) — leia
primeiro. Este documento não o substitui; registra só onde este projeto diverge e por
quê. O padrão base vale para tudo **exceto** nos pontos abaixo.

O que **não** muda, e é a maior parte: cubit por módulo, `BlocSubState` por operação,
erro como tipo de dado, repository como interface + impl injetada, `copyWith` com
`?? this.x`, `buildWhen` sempre presente, componentes `App*`, tokens em
`AppColors`/`AppFonts`, nada de Material solto na tela, nada de string fora do ARB.

> Este app é **só Android/iOS** (decisão A10 — a web é o React em
> `frontend/salao_web`), com um usuário só e sem operação offline. É a diferença que
> gera quase todas as divergências abaixo — a adaptação FrotaOP (mobile puro, offline,
> multiusuário) se aplica quase inteira, e o padrão base, que é web, não.

## S1 — Camada de dados: REST via Dio contra o FastAPI, e só ele

Vale como está no padrão. Uma única `baseUrl`, apontando para o FastAPI
(decisão A1 do [CLAUDE.md](../CLAUDE.md)).

**O Flutter não conhece o Supabase.** Não há SDK do Supabase no `pubspec.yaml`, não há
`anon key` no binário, não há chamada a PostgREST nem a RPC. Se encontrar qualquer uma
dessas coisas, é resíduo do desenho anterior — apague. O Supabase é detalhe de
implementação do FastAPI.

**A regra que sobrevive a qualquer troca futura de backend:** a fronteira do repository
é intransponível. Nenhum tipo do Dio cruza para dentro do cubit ou do model. Erro de
negócio se identifica por **código** (`AppErrorCodes`), nunca por texto de mensagem.

## S2 — Storage: só `SharedPreferences`

Nem Hive (padrão base), nem drift (adaptação FrotaOP).

`AppStorage` mantém a mesma superfície pública do padrão
(`read`/`write`/`delete`/`clear` + chaves centralizadas), implementada sobre
`SharedPreferences`. Sem code-gen e sem banco local.

Serve para o que o padrão sempre disse: **sessão e cache leve**. Mapas e listas são
gravados como JSON string (`jsonEncode`/`jsonDecode`) — a fachada esconde isso; quem
chama continua vendo `read<Map>` / `write`.

**Não há offline-first.** Escrita sem rede falha, o cubit emite `ErrorModel` e a UI
mostra o erro. Se um dia isso mudar, a camada `sync/` da adaptação FrotaOP é o caminho
— e aí este parágrafo some.

## S3 — A casca é só mobile

O padrão base é web; a adaptação FrotaOP é mobile. **Aqui vale a do FrotaOP**: o
`AppScaffold` tem uma forma só — app bar, `AppBottomNav` de 5 itens e FAB no canto
inferior direito para a ação primária. Listas são sempre cartões empilhados, padding
de 12px, e o `AppDialog` é sempre bottom sheet.

Isso mudou em 03/09/2026 com a decisão A10. Até ali havia um ramo `>1024` com menu
lateral, `AppTable` e grid de duas colunas; ele foi removido junto com a pasta `web/`
do projeto Flutter. **`AppTable` e `AppPagination` não existem mais** — se uma tabela
voltar a ser necessária, ela nasce no React.

`AppCurrentRoute` continua sendo a fonte única do item ativo. `deviceType(context)`
sobreviveu com três valores (`mobile`, `tablet`, `tabletLandscape`) e serve para
densidade, não para trocar de casca — não existe mais `isWideLayout`.

**Alvo de toque mínimo de 44dp**, garantido pelo `AppTappable`. Não é o mesmo cenário
do FrotaOP (cabine, sol, mão suja) — aqui é uso de mão em ambiente interno — mas
continua sendo toque, não mouse.

## S4 — Um usuário, e mesmo assim nenhuma autorização no cliente

O app é de usuária única. Isso **não** autoriza filtrar no cliente.

O app manda o token em toda requisição e consome o que a API devolver. O servidor deriva
o usuário do token e devolve apenas o que é dele. **Endpoint que aceita `user_id` no
corpo e confia nele é falha de servidor** — e hoje `api/app/routers/relatorio.py`
decodifica o JWT sem verificar assinatura, o que é exatamente isso. A F4 corrige.

Do login, o app guarda token, refresh token, id e nome. **Não há papéis** (`admin`,
`motorista` etc.) — não existe hierarquia neste produto. Se aparecer um campo de papel,
é resíduo.

## S5 — Sem `print`, com logger

`settings/app_logger.dart`, com níveis, chamado nos dois lugares onde erro nasce: o
`catch` do cubit e o `ErrorModel.fromDioException`. Em release, só `warning` e `error`.
`avoid_print: true` no `analysis_options.yaml`.

## S6 — Cores de sinal são semânticas, não decorativas

A paleta é roxa, mas **verde e vermelho não são temas — são significado**: saldo
positivo/negativo, pago/pendente, estoque ok/alerta. Isso está registrado no próprio
protótipo e vale como regra de design system:

- `AppColors.success*` só para valor que entra, gasto quitado, estoque saudável.
- `AppColors.danger*` só para valor que sai, pendência, estoque crítico.
- `AppColors.amber*` para o meio-termo: agendado, estoque em alerta, vencimento próximo.
- `AppColors.primary*` para identidade e ação — **nunca** para indicar resultado.

Um número financeiro nunca é roxo. Um botão nunca é verde.

## S7 — Módulo `alertas` é transversal, e o cálculo é do servidor

O app **não** decide o que é alerta. Ele não varre a lista de estoque procurando
`quantidade <= minima`, nem a de gastos procurando vencimento — isso é regra de negócio
e mora no FastAPI, que devolve alertas prontos com severidade.

Motivo: a mesma regra precisa valer para o push e para o n8n, que não passam pelo app.
Duplicar o cálculo no cliente garante que um dia as duas versões discordem.

O que o app faz: busca `GET /alertas`, mostra badge, banner e central, e marca como
lido. O `AlertaModel` traz `severidade`, `titulo`, `mensagem` e a rota de destino.

## Checklist de conformidade

Além dos portões do padrão base, antes de marcar qualquer task como concluída:

- [ ] Nenhum widget Material direto na tela — só `App*`
- [ ] Nenhuma cor ou `TextStyle` literal fora de `AppColors` / `AppFonts`
- [ ] Nenhuma string visível ao usuário fora do ARB
- [ ] Nenhum enum fora de `app_enums.dart`
- [ ] Nenhuma string de URL fora de `AppApi`; nenhuma `baseUrl` fixa no código
- [ ] Nenhuma menção a Supabase no código Flutter
- [ ] Nenhum tipo do Dio (`Response`, `DioException`) cruzando o repository
- [ ] Nenhuma chave de storage fora de `AppStorage`
- [ ] `copyWith` com `?? this.x` em **todos** os campos
- [ ] `buildWhen` / `listenWhen` presentes, comparando o sub-estado específico
- [ ] Cubit trata sucesso, `DioException` e genérico — sempre terminando em `completed`
- [ ] Repository não trata exceção, e nenhuma autorização é decidida no cliente
- [ ] Cor de sinal (verde/vermelho/âmbar) usada por significado, não por estética
- [ ] Nenhum ramo de layout por largura de tela: a casca é uma só (A10)
