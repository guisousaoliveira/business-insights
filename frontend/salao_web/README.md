# GlowApp Web — React

O front-end web do GlowApp. É onde a profissional senta para fechar as contas;
o dia a dia acontece no app Flutter (`../salao_app`), que atende Android e iOS.

Contexto do produto, contrato da API e as decisões A1–A10 estão no
[CLAUDE.md](../../CLAUDE.md) da raiz. O padrão deste projeto está em
[`.specs/padrao-react-salao.md`](../../.specs/padrao-react-salao.md).

## Rodar

```sh
npm install
npm run dev:demo     # modo demo: servidor falso em memória, nada é gravado
npm run dev          # contra o FastAPI de .env (padrão: http://localhost:8000/v1)
```

Copie `.env.example` para `.env` para apontar a outro backend.

## Portões

```sh
npm run typecheck    # tsc --noEmit
npm run lint         # eslint
npm run build
```

## Estrutura

```
src/
├── routes/          # roteamento por arquivo (TanStack Start) — ver routes/README.md
├── components/      # AppShell (casca), ui/ (shadcn), ui-kit.tsx (os blocos do protótipo)
├── hooks/
└── lib/
    ├── http.ts      # única saída de rede: envelope, token, refresh, ApiError
    ├── api/         # um módulo por domínio + paths.ts (nenhuma URL fora dele)
    ├── queries.ts   # os hooks que as telas usam, e o que invalidar após cada escrita
    ├── types.ts     # os tipos do contrato, em snake_case
    ├── storage.ts   # fachada do localStorage (sessão)
    ├── env.ts       # o único lugar que lê import.meta.env
    └── demo/        # o servidor falso do modo demo
```

Nenhum componente chama a API direto: a tela usa um hook de `queries.ts`, o hook usa
um módulo de `api/`, e só o `http.ts` fala com a rede.

## Lovable

Este projeto veio do [Lovable](https://lovable.dev) e continua conectado a ele —
commits enviados voltam a aparecer no editor. **Não reescreva histórico publicado**
(sem force-push, rebase, amend ou squash de commit já enviado).

## Stack

TanStack Start · React 19 · TypeScript · Tailwind 4 · shadcn/ui · TanStack Query ·
recharts · sonner
