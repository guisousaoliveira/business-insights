# Padrão React — `frontend/salao_web`

O que vale para o front-end web. É o par do `.specs/padrao-flutter-salao.md`: o
Flutter continua sendo o app de celular, e esta spec descreve como o React
chega no **mesmo backend, com o mesmo contrato e as mesmas decisões**.

Decisão que o originou: **A10** — a web é React, o Flutter é só Android/iOS.

## De onde veio o código

`frontend/salao_web` é o MVP gerado pelo Lovable (TanStack Start + React 19 +
Tailwind 4 + shadcn/ui), com a camada de dados **reescrita** contra
`.specs/endpoints-backend.md`. As telas ficaram como estavam — nenhum redesenho.
O que o MVP tinha de mock em memória foi jogado fora inteiro.

O repositório está conectado ao Lovable: **não reescreva histórico publicado**
(sem force-push, rebase, amend ou squash de commit já enviado), senão o histórico
do projeto se perde do lado de lá.

## A camada de dados

Uma pilha só, do componente até a rede:

> Rota (`src/routes/*.tsx`) → hook de `lib/queries.ts` → módulo de `lib/api/*.ts`
> → `lib/http.ts` → FastAPI

Cada degrau tem um dono, e o de baixo nunca conhece o de cima:

| Arquivo | Equivalente no Flutter | Regra |
|---|---|---|
| `lib/http.ts` | `settings/app_api.dart` | única saída para a rede; monta URL, header, envelope e erro. Ninguém mais chama `fetch`. |
| `lib/api/paths.ts` | `AppApi.*Path` | **nenhuma string de URL fora daqui**. |
| `lib/api/*.ts` | `repositories/` | um módulo por domínio; não trata exceção, não decide autorização, devolve o tipo do contrato. |
| `lib/queries.ts` | `cubits/` | os hooks que a tela usa; é aqui que mora **o que invalidar depois de cada escrita**. |
| `lib/types.ts` | `models/` | os tipos do contrato, em `snake_case`, iguais ao JSON. |
| `lib/storage.ts` | `settings/app_storage.dart` | fachada única do `localStorage`, chaves centralizadas. |
| `lib/env.ts` | `settings/app_environment.dart` | o único lugar que lê `import.meta.env`. |

### Envelope e erro

Toda resposta é `{ total, mensagem, codigo, result }` (§0 do contrato). O
transporte desembrulha o `result` e, no caminho de erro, lança `ApiError` com o
**código** — nunca com a mensagem. Tela e hook comparam código
(`AppErrorCodes.insufficientStock`), porque texto de erro muda e código não.

### `snake_case` de propósito

Os tipos de `lib/types.ts` usam exatamente os nomes do JSON. Não há camada de
conversão para `camelCase`: cada renomeação seria um lugar a mais para o
contrato divergir em silêncio, e o ganho estético não paga a auditoria.

### Quem calcula é o servidor

`status`, `deficit`, `saldo`, `margem`, `vence_em_dias`, `quantidade_montavel`,
`custo_total` e os totais **chegam prontos**. A tela não recalcula nenhum deles;
onde ela soma alguma coisa (a prévia de custo do atendimento, por exemplo), o
número é rotulado como prévia e o valor que vale é o que volta do POST.

## Sessão

`lib/storage.ts` guarda token, refresh token, usuário e salão. O transporte
tenta o refresh uma vez no 401; se ele falhar, limpa o storage e chama o
callback registrado por `__root.tsx`, que zera o cache do react-query e manda
para `/login`. Nenhuma rota lê `localStorage` direto.

Todo acesso ao storage é defensivo: a rota também renderiza no servidor (SSR do
TanStack Start), onde `window` não existe.

## Modo demo

`npm run dev:demo` (`vite --mode demo`, `.env.demo`). Um servidor falso em
memória (`lib/demo/`) responde **por trás do mesmo transporte**, devolvendo o
envelope cru e lançando os mesmos códigos de erro. É o espelho do modo demo do
Flutter e roda as mesmas regras: as duas passadas de A5, a média ponderada de
A6, o `KIT_NAO_MONTADO` de A7.

O estado vive na aba e some quando ela fecha. Não é cache e não é offline-first.

## Rotas

TanStack Start, roteamento por arquivo em `src/routes/` — ver
`src/routes/README.md`. `routeTree.gen.ts` é gerado; não edite.

Cinco destinos, os mesmos do app: `/` (Resumo), `/atendimentos`, `/gastos`,
`/estoque`, `/perfil`, mais `/alertas` e `/login`. A casca (`AppShell.tsx`) tem
as duas formas do protótipo: menu lateral de 172px a partir de `lg`, barra
inferior e FAB abaixo disso. O guard de sessão vive nela — sem sessão, redireciona
para `/login`.

## Checklist de conformidade (web)

- [ ] Nenhum `fetch` fora de `lib/http.ts`
- [ ] Nenhuma string de URL fora de `lib/api/paths.ts`; nenhuma `baseUrl` fixa
- [ ] Nenhum acesso a `localStorage` fora de `lib/storage.ts`
- [ ] Nenhum `import.meta.env` fora de `lib/env.ts`
- [ ] Nenhum componente chama `*Api` direto — sempre um hook de `queries.ts`
- [ ] Erro identificado por **código**, nunca por mensagem
- [ ] Nada que o servidor calcula é recalculado na tela
- [ ] Toda escrita invalida as chaves dos módulos que ela move
- [ ] Vocabulário fechado (`unidade`, `categoria`, `forma_pagamento`, `status`)
      vem do contrato, não de texto livre
- [ ] `npm run typecheck` e `npm run lint` limpos, `npm run build` concluindo
