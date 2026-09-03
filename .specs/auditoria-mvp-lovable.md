# Auditoria — MVP Lovable × contrato da API

Registro do que o MVP web trazia fora do contrato e como cada ponto foi
resolvido ao integrá-lo (03/09/2026). Serve para duas coisas: explicar por que
uma tela mudou sem redesenho e avisar o backend do que ele **precisa** devolver.

Fonte da verdade em cada linha: `.specs/endpoints-backend.md` e as decisões
A1–A10 do `CLAUDE.md`. Quando o MVP e o contrato discordaram, venceu o contrato.

## 1. Camada de dados

| O que o MVP tinha | O que ficou |
|---|---|
| Store em memória (`lib/store.ts`) com dados de exemplo | apagada; `lib/api/` + `lib/queries.ts` contra o FastAPI |
| `fetch` espalhado / nenhum transporte | `lib/http.ts`, única saída de rede, com o envelope `{total, mensagem, codigo, result}` |
| Sem sessão | `lib/storage.ts`, refresh no 401, guard na casca, expiração levando ao `/login` |
| Campos em `camelCase` inventados | `lib/types.ts` em `snake_case`, iguais ao JSON do contrato |
| Nenhum modo demo | `lib/demo/`, espelho do `demo_database.dart` do Flutter |

## 2. Vocabulários que eram texto livre

O MVP deixava a usuária digitar o que quisesse; o contrato tem lista fechada.
Todos viraram `select`:

- **Unidade de estoque**: `un`, `ml`, `g`, `cx`.
- **Categoria de item**: `cilios`, `sobrancelha`, `limpeza_pele`, `descartavel`,
  `outro`.
- **Forma de pagamento**: `a_vista`, `pix`, `debito`, `credito`.
- **Categoria de gasto**: `material`, `fixo`, `outros`.
- **Status de estoque**: `ok`, `alerta`, `critico`, `negativo` — o `negativo` é
  de A5 e não existia no MVP.
- **Tipo de alerta**: os nove do §9; a tela só escolhe ícone e cor.

## 3. Campos que o MVP mostrava e o contrato não tem

Removidos das telas, porque um campo que ninguém grava é um campo que mente:

- **Serviço**: `duracaoMin`, `custoEstimado`, `ativo`.
- **Perfil**: `email`, `metaLucro` (a meta vem do resumo, calculada).
- **Gasto**: `status` — situação é `pago` + `vence_em_dias`, e quem conta os
  dias é o servidor.
- **Atendimento**: `observacoes`.

## 4. Regras de negócio que faltavam

- **A5 — estoque insuficiente avisa, não bloqueia.** O MVP simplesmente
  registrava. Agora finalizar atendimento e montar kit fazem a primeira chamada
  com `confirmar_estoque_insuficiente: false`; no `409 ESTOQUE_INSUFICIENTE` o
  `EstoqueInsuficienteDialog` mostra `result.faltantes` e, se ela confirmar,
  repete com `true`. Verificado ponta a ponta no modo demo.
- **A6 — custo é média ponderada.** A entrada de estoque passou a exigir
  `custo_unitario`; quem recalcula o `custo_medio` é o servidor. A tela mostra o
  custo médio, não o último preço pago.
- **A7 — montar ≠ vender.** O MVP tinha só "vender kit". Agora são duas ações:
  montar consome insumo e passa pelo aviso de A5; vender **não** tem segunda
  passada, porque `KIT_NAO_MONTADO` é definitivo.
- **Saída de estoque** virou movimentação com tipo (`saida` ou `ajuste`), como o
  contrato pede.

## 5. Parâmetros que a tela precisou ganhar

Sem redesenhar nada, só o controle mínimo que o endpoint exige:

- **Gastos** — seletor de mês (`competencia`).
- **Custos fixos** — a competência corrente, para marcar pago no mês certo.
- **Atendimentos** — o filtro de período virou `inicio`/`fim`, que é como a
  listagem do contrato aceita.

## 6. Pendências para o backend

- **Resumo**: confirmar que custo fixo vem do perfil e gasto variável vem de
  `gastos` com `categoria != 'fixo'`. É a única regra que a demo decidiu sozinha
  (o mesmo aluguel aparece nas duas tabelas no seed) e que o
  `endpoints-backend.md` não fixa.
- **Alertas**: a web assume os nove tipos do §9 já classificados pelo servidor.
- Tudo o mais depende só da F4 sair: hoje as 53 operações existem no contrato e
  no modo demo, e 4 delas no FastAPI.
