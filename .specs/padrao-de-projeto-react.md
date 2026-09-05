# Padrão de projeto React (business-insights)

Fecha a trilha **R0** do [`CLAUDE.md`](../CLAUDE.md). É a convenção única para
`frontend/salao_web/`, escrita **antes** do primeiro módulo — mesmo espírito do que
existia para o Flutter congelado ([`padrao-de-projeto-flutter/`](padrao-de-projeto-flutter/README.md),
[`padrao-flutter-salao.md`](padrao-flutter-salao.md)): não inventar estrutura tela por
tela, decidir uma vez e seguir.

A stack já está fixada pelas dependências instaladas em `frontend/salao_web/`: React +
TypeScript + Vite, TanStack Router/Start, TanStack Query, React Hook Form + Zod,
Tailwind CSS v4 + Radix UI, lucide-react, date-fns + react-day-picker. Este documento
decide **como usá-las juntas**, não troca nenhuma.

> Herda do Flutter tudo que não é framework: uma `baseUrl` só (A1), erro como dado,
> nenhuma autorização decidida no cliente, cores de sinal semânticas, alertas calculados
> no servidor. O que muda é só a casca de implementação.

## R1 — Estrutura de pastas

Por **módulo de domínio**, não por tipo de arquivo — mesmo corte do Flutter
(`auth`, `atendimentos`, `gastos`, `resumo`, `estoque`, `kits`, `perfil`, `servicos`,
`alertas`), para o nome do módulo continuar sendo a unidade de dado nas duas stacks.

```
src/
├── routes/                        # roteamento por arquivo (TanStack Router/Start)
│   ├── __root.tsx                 # shell: provider do QueryClient, layout base
│   ├── login.tsx
│   └── _authenticated/            # layout route com guard (R3) — troca de aba não recarrega a casca
│       ├── route.tsx              # AppShell: sidebar desktop / bottom nav mobile
│       ├── resumo.tsx             # rota inicial pós-login (A9)
│       ├── atendimentos.tsx
│       ├── gastos.tsx
│       ├── estoque.tsx
│       ├── perfil.tsx
│       └── alertas.tsx
├── modules/
│   └── atendimentos/
│       ├── api.ts                 # funções que chamam api-client.ts — um endpoint por função
│       ├── queries.ts             # hooks useQuery/useMutation + query-key factory (R2)
│       ├── schemas.ts             # Zod: valida resposta da API e forms (R5)
│       ├── types.ts               # tipos derivados dos schemas (z.infer)
│       └── components/            # componentes só desse módulo (cartão, dialog, calendário)
├── components/                    # design system compartilhado (equivalente a ui/components)
│   └── ui/                        # primitives Radix + Tailwind (Button, Dialog, Table, Badge…)
├── lib/
│   ├── api-client.ts              # fetch wrapper único — a única baseURL do app (R2)
│   ├── api-envelope.ts            # parse do envelope {total, mensagem, codigo, result} (R6)
│   ├── auth.ts                    # sessão: leitura/escrita do token, hook useAuth (R3)
│   └── query-client.ts            # instância única do QueryClient
└── styles/
    └── tokens.css                 # variáveis da paleta (R7)
```

Cada módulo espelha o que o Flutter fazia com `cubits/`, `repositories/`, `models/`:
`api.ts` é o repository, `queries.ts` é o cubit (mas como hooks), `schemas.ts`/`types.ts`
são o model.

**Nomenclatura de arquivo:** kebab-case (`novo-atendimento-dialog.tsx`), como o
ecossistema React/shadcn já usa. Componente exportado em PascalCase, hook em camelCase
com prefixo `use`. Domínio em português (`Atendimento`, `getGastosPath`), infraestrutura
em inglês (`ApiClient`, `QueryClient`) — mesma convenção do Flutter.

## R2 — Camada de dados: fetch client único + TanStack Query por módulo

Uma **única `baseUrl`**, lida de variável de ambiente (`VITE_API_BASE_URL`), nunca
hardcoded em nenhum arquivo — a regra é a mesma do `AppApi` no Flutter (A1). Vive só em
`lib/api-client.ts`:

```ts
// lib/api-client.ts
export async function apiFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const token = getToken(); // lib/auth.ts
  const res = await fetch(`${API_BASE_URL}${path}`, {
    ...init,
    headers: { ...init?.headers, ...(token && { Authorization: `Bearer ${token}` }) },
  });
  if (res.status === 401) { clearToken(); router.navigate({ to: '/login' }); }
  return parseEnvelope<T>(await res.json()); // lança ApiError se codigo vier preenchido
}
```

Nenhum `fetch` solto em componente ou em `modules/*/api.ts` — todos passam por
`apiFetch`. Isso é o interceptor 401 do Flutter (A2), só que como um wrapper em vez de
um interceptor do Dio.

Cada módulo expõe funções puras de chamada em `api.ts`:

```ts
// modules/atendimentos/api.ts
export const getAtendimentos = (filtros: AtendimentosFiltro) =>
  apiFetch<GetAtendimentosResponse>(`/atendimentos?${toQueryString(filtros)}`);
```

E os hooks de dados em `queries.ts`, com uma **query-key factory** por módulo (evita
string mágica espalhada, equivalente ao que os `getXPath` centralizados faziam):

```ts
// modules/atendimentos/queries.ts
export const atendimentosKeys = {
  all: ['atendimentos'] as const,
  list: (filtros: AtendimentosFiltro) => [...atendimentosKeys.all, 'list', filtros] as const,
};

export const useAtendimentos = (filtros: AtendimentosFiltro) =>
  useQuery({ queryKey: atendimentosKeys.list(filtros), queryFn: () => getAtendimentos(filtros) });

export const useFinalizarAtendimento = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: finalizarAtendimento,
    onSuccess: () => qc.invalidateQueries({ queryKey: atendimentosKeys.all }),
  });
};
```

Componente de tela só consome `useAtendimentos`/`useFinalizarAtendimento` — nunca
`apiFetch` direto, nunca `fetch` global. Essa fronteira é intransponível, igual à do
repository no Flutter.

## R3 — Sessão: `localStorage`, guard de rota, sem offline-first

Sem Hive, sem drift, sem equivalente disso em React — só `localStorage`, uma chave só
(`salao:auth:token`), lida/escrita através de `lib/auth.ts`. Nenhum outro arquivo chama
`localStorage` direto — mesma disciplina de chave centralizada que o `AppStorage` exigia
(A4, agora sem `SharedPreferences` por trás).

**Guard de rota**: a rota `_authenticated` (TanStack Router, `beforeLoad`) redireciona
para `/login` se não houver token — não existe tela protegida fora dela. Rota pública
sem guard (ex.: futura tela de agendamento por link) fica **fora** de `_authenticated`.

**Sem offline-first**: escrita sem rede falha, a mutation cai em erro, a tela mostra a
mensagem do envelope (R6). Igual à decisão A4 original — só muda o armazenamento por
trás.

## R4 — Roteamento: TanStack Router/Start, file-based

Rotas em `src/routes/`, arquivo = rota. `_authenticated/route.tsx` é o `AppShell`
(equivalente ao `AppScaffold`): decide sidebar (desktop) vs. bottom nav (mobile) por
media query, e envolve todas as rotas autenticadas sem recarregar a casca ao trocar de
aba — mesmo motivo do Flutter (transição só no conteúdo, não na casca).

Rota inicial pós-login: `/resumo` (A9). 404 cai numa rota `catch-all` que redireciona
pra `/resumo` (autenticado) ou `/login` — mesmo comportamento de fallback do
`onGenerateRoute` do Flutter.

## R5 — Formulários: React Hook Form + Zod

Schema Zod por módulo em `schemas.ts`, usado nos dois lados: valida o formulário
(`zodResolver`) **e** tipa a resposta da API (`schema.parse(json)` dentro de
`api.ts`/`api-envelope.ts`). Um schema, duas validações — não duplicar tipo à mão.

```ts
// modules/atendimentos/schemas.ts
export const criarAtendimentoSchema = z.object({
  clienteNome: z.string().min(1),
  clienteTelefone: z.string().min(8),
  data: z.string().datetime(),
  servicos: z.array(z.object({ servicoId: z.string() })).min(1),
});
export type CriarAtendimentoInput = z.infer<typeof criarAtendimentoSchema>;
```

## R6 — Erro é dado, não estado solto

Mesma filosofia do Flutter (`BlocDataState` sem estado de erro próprio — erro é
`data is ErrorModel`), adaptada ao que o TanStack Query já oferece nativamente:
`useQuery`/`useMutation` devolvem `{ data, error, isError }` — **não** criar uma
máquina de estados paralela por cima disso.

`lib/api-envelope.ts` traduz o envelope do FastAPI (`{ total, mensagem, codigo,
result }`) em:

```ts
export class ApiError extends Error {
  constructor(public codigo: string, mensagem: string) { super(mensagem); }
}

export function parseEnvelope<T>(json: ApiEnvelopeShape): T {
  if (json.codigo) throw new ApiError(json.codigo, json.mensagem);
  return json.result as T;
}
```

Erro de negócio se identifica por **`codigo`** (`ESTOQUE_INSUFICIENTE`,
`ATENDIMENTO_STATUS_INVALIDO` etc.), nunca por texto de `mensagem` — mesma regra do
`AppErrorCodes` do Flutter. Telas leem `error instanceof ApiError && error.codigo === …`
para casos especiais (ex.: o fluxo de duas passadas de A5); genérico cai num toast com
`error.message`.

## R7 — Design system: tokens Tailwind + cores semânticas

A paleta (roxa, com verde/vermelho/âmbar reservados a significado) vira variáveis CSS
em `styles/tokens.css` e entra no `tailwind.config` como cores nomeadas — os valores não
mudam em relação ao que está em `CLAUDE.md`:

```css
:root {
  --color-primary: #BD6DF2; --color-primary-dark: #896393; --color-primary-accent: #BD4EBF;
  --color-success: #3B6D11; --color-success-light: #EAF3DE;
  --color-danger: #A32D2D; --color-danger-light: #FCEBEB;
  --color-amber: #854F0B; --color-amber-light: #FAEEDA;
  --color-text-1: #1A1A1A; --color-text-2: #6B6B6B; --color-text-3: #9E9E9E;
  --color-surface: #FFFFFF; --color-border: #EAE6E5; --color-scaffold: #FFFFFF;
}
```

Regra que não muda (mesma da S6 do Flutter): `success`/`danger`/`amber` só por
significado (saldo, pago/pendente, estoque), nunca decorativo; `primary` só por
identidade/ação, nunca pra indicar resultado. Um número financeiro nunca é roxo.

Componentes base (`components/ui/`) vêm de Radix UI estilizado com Tailwind (padrão
shadcn) — nenhuma tela usa uma cor Tailwind padrão (`bg-purple-500` etc.) direto, só os
tokens acima.

**Ícones**: `lucide-react`. Ao portar uma tela do protótipo (Tabler Icons), mapear pelo
nome visualmente mais próximo — sem uma camada de indireção tipo `AppAssets`, já que
não há mais o problema de SVG ausente que motivou aquilo no Flutter.

## R8 — Casca responsiva

Mesmo conceito do Flutter (`AppScaffold`), sem o nome:

| | mobile/tablet | desktop |
|---|---|---|
| Navegação | bottom nav, 5 itens | sidebar lateral |
| Ação primária | FAB | botão no cabeçalho |
| Listas | cartões empilhados | tabela / grid 2 colunas |

Implementado como media query Tailwind (`lg:`) dentro do `AppShell` (R4) — sem
biblioteca de detecção de dispositivo, `matchMedia`/CSS já resolve.

## R9 — i18n: não tem, e é proposital

**Divergência deliberada em relação ao Flutter**, que exigia ARB por causa do padrão
base do framework. Aqui: um idioma só (pt-BR), um produto só, sem plano de
internacionalizar. Strings de UI ficam direto no componente, em português. Se um dia
existir uma segunda língua, aí sim entra `i18next` — não antes, é complexidade sem uso.

## Checklist de conformidade

- [ ] Nenhum `fetch` fora de `lib/api-client.ts`
- [ ] Nenhuma `baseUrl`/URL literal fora de `lib/api-client.ts` e `modules/*/api.ts`
- [ ] Nenhum `localStorage` fora de `lib/auth.ts`
- [ ] Todo dado de servidor passa por `useQuery`/`useMutation` — nenhum `useEffect` +
      `fetch` manual
- [ ] Todo formulário usa `zodResolver` com schema de `modules/*/schemas.ts`
- [ ] Erro de negócio checado por `error.codigo` (`ApiError`), nunca por texto de
      mensagem
- [ ] Cor de sinal (verde/vermelho/âmbar) usada por significado, não por estética
- [ ] Nenhuma cor/ícone fora dos tokens (`tailwind.config`) e do `lucide-react`
- [ ] Nenhuma autorização decidida no cliente — o servidor deriva tudo do token
- [ ] Tela verificada nas duas cascas (bottom nav e sidebar)
