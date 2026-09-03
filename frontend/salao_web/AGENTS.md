<!-- LOVABLE:BEGIN -->
> [!IMPORTANT]
> This project is connected to [Lovable](https://lovable.dev). Avoid rewriting
> published git history — force pushing, or rebasing/amending/squashing commits
> that are already pushed — as it rewrites history on Lovable's side and the
> user will likely lose their project history.
>
> Commits you push to the connected branch sync back to Lovable and show up in
> the editor, so keep the branch in a working state.
<!-- LOVABLE:END -->

# Salão Web — regras do projeto

Front-end web da Thamires Borges Beauty (salão de beleza, usuária única). O app de
celular é o Flutter em `../salao_app`; os dois falam com o **mesmo** FastAPI.

Leia antes de mexer: [`../../CLAUDE.md`](../../CLAUDE.md) (contexto e decisões A1–A10)
e [`../../.specs/padrao-react-salao.md`](../../.specs/padrao-react-salao.md) (o padrão
deste projeto, com a checklist de conformidade).

O que não se negocia aqui:

- **A camada de dados tem dono.** Rota → hook de `lib/queries.ts` → módulo de
  `lib/api/` → `lib/http.ts`. Nenhum `fetch` fora do `http.ts`, nenhuma URL fora de
  `lib/api/paths.ts`, nenhum `localStorage` fora de `lib/storage.ts`, nenhum
  `import.meta.env` fora de `lib/env.ts`.
- **O cliente nunca fala com o Supabase** (A1) — só com o FastAPI.
- **Erro é identificado por código**, nunca por mensagem (`AppErrorCodes`).
- **Quem calcula é o servidor**: `status`, `saldo`, `margem`, `deficit`,
  `vence_em_dias`, totais. A tela não recalcula; o que ela soma é rotulado como prévia.
- **Tipos em `snake_case`**, iguais ao JSON do contrato — sem camada de conversão.
- **Estoque insuficiente avisa, não bloqueia** (A5): primeira chamada com
  `confirmar_estoque_insuficiente: false`, e no `409 ESTOQUE_INSUFICIENTE` o
  `EstoqueInsuficienteDialog` pergunta antes de repetir com `true`. Vender kit **não**
  tem segunda passada (A7).
- **Se falta endpoint, ele entra em `../../.specs/endpoints-backend.md` antes** de
  existir código que o chame. E toda mudança de contrato mexe também no
  `settings/app_api.dart` do Flutter.
- Texto de UI em **pt-BR**. Paleta roxa; verde e vermelho são reservados a
  positivo/negativo.

Antes de fechar: `npm run typecheck`, `npm run lint`, `npm run build`.
