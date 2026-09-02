# Pedidos ao backend — o que falta para integrar

Este documento é a **ordem de serviço**. Ele não repete o contrato: o payload de cada
endpoint está em [`endpoints-backend.md`](endpoints-backend.md) e o SQL em
[`001_v1_completo.sql`](001_v1_completo.sql).
Aqui está o que implementar, em que ordem, e como saber que terminou.

O índice de tudo — quais arquivos entregar e as regras que o app já assume — está em
[`00-ENTREGA-BACKEND.md`](00-ENTREGA-BACKEND.md).

**Situação hoje:** o app Flutter está pronto e compila (web e mobile), mas fala com um
backend que existe em 4 dos 53 endpoints. Ele não tem tela mockada nem modo demo — sem
API, abre no login e para ali.

| Frente | Estado |
|---|---|
| App Flutter | ✅ pronto — web, Android e iOS, 46 testes, `analyze` limpo |
| Contrato de API | ✅ especificado — 53 operações |
| Schema do banco | ✅ escrito — falta **executar** |
| FastAPI | ⛔ 4 de 53 endpoints |
| Push (FCM) | ⛔ depende de projeto Firebase |

### O que o app já implementa e espera encontrar

Não são pedidos de UI — já estão escritos e testados. São a razão de alguns endpoints
terem um formato específico:

- **Duas passadas no estoque insuficiente** (A5). `POST /atendimentos/{id}/finalizar` e
  `POST /kits/{id}/montar` recebem `confirmar_estoque_insuficiente`. Com `false` e sem
  saldo: **não grave nada**, devolva `409` + `ESTOQUE_INSUFICIENTE` +
  `result.faltantes`. O app abre o aviso, e se ela confirmar repete a mesma chamada com
  `true`. Sem o `result.faltantes` o aviso aparece sem dizer o que falta.
- **`custo_medio` e `custo_ultima_compra`** (A6), não `custo_unitario`. O app lê os dois
  nomes novos; o antigo não existe mais em lugar nenhum.
- **`quantidade_montada` e `quantidade_montavel`** em `GET /kits` (A7). O botão "Vender"
  fica desabilitado quando `quantidade_montada` é 0 — sem esses campos ele nunca liga.
- **`status: "negativo"`** em `GET /estoque/itens` quando `quantidade_atual < 0`. O app
  já decodifica; se vier `critico`, "acabou" e "devo mais do que tenho" viram a mesma
  coisa na tela.
- **`receita.total_kits` / `quantidade_kits_vendidos` / `custo_kits_vendidos`** no
  resumo. Ausentes, viram 0 e a linha de kits simplesmente não aparece — não quebra, mas
  a venda de kit some do mês.

---

## Como ler um pedido

Cada lote tem: **o que entregar**, **regras que não podem ser esquecidas** e **como
testar**. Um lote só está pronto quando a tela correspondente do app funciona de ponta a
ponta contra o servidor real — não quando o endpoint responde 200 no Swagger.

Os lotes estão em ordem de dependência. L0 destrava tudo; L1 e L2 destravam o uso diário;
L6 é o único que depende de coisa fora do nosso controle (Firebase).

---

## L0 — Fundação `bloqueia todo o resto`

### L0.1 · Executar a migration

```bash
# Supabase Dashboard > SQL Editor
# 1) 001_v1_completo.sql
# 2) 002_seed_teste.sql  (só em dev/homolog)
```

O script é idempotente. Depois de rodar, confira que estas 12 tabelas existem:
`perfil_salao` · `estoque_itens` · `estoque_movimentacoes` · `kits` · `kit_itens` ·
`kit_vendas` · `servico_produtos_padrao` · `custos_fixos_pagamentos` · `alertas` ·
`alerta_preferencias` · `dispositivos` · `refresh_tokens`.

### L0.2 · Validar o JWT de verdade `🔴 segurança`

`api/app/routers/relatorio.py::_extrair_user_id` decodifica o token em base64 e confia no
`sub`, **sem verificar a assinatura**. Enquanto o Flutter falava direto com o Supabase, a
RLS segurava; agora o FastAPI é a única barreira, e qualquer pessoa monta um token com o
`sub` da usuária e lê a receita dela inteira.

Trocar por validação real:

```python
from jose import jwt, JWTError

payload = jwt.decode(
    token,
    settings.supabase_jwt_secret,     # nova env var: SUPABASE_JWT_SECRET
    algorithms=["HS256"],
    audience="authenticated",
)
user_id = payload["sub"]
```

Vira uma dependency (`Depends(usuario_atual)`) usada por **todo** endpoint autenticado.
Nenhum endpoint aceita `user_id` no corpo ou na query — se aceitar e confiar, o resto da
segurança não importa.

**Aceite:** requisição sem token → `401 AUTH_TOKEN_AUSENTE`; token com assinatura
adulterada → `401`; token válido de outra usuária → só vê os dados dela.

### L0.3 · Envelope e erros

Toda resposta, sucesso ou falha, sai no mesmo formato (§0 do mapa):

```json
{ "total": 12, "mensagem": "ok", "codigo": null, "result": { } }
```

Um `exception_handler` global cobre `HTTPException`, `RequestValidationError` e
`Exception`. O app lê `codigo` para escolher a mensagem traduzida; **texto de mensagem
nunca é usado para identificar erro**.

Códigos obrigatórios: os 11 da §11 do mapa. Código novo no servidor sem entrada lá =
mensagem genérica na tela da usuária.

**Aceite:** forçar um 500 e conferir que a resposta ainda tem as 4 chaves do envelope.

### L0.4 · Auth `POST /auth/login` · `/refresh` · `/logout` · `GET /auth/eu`

Login autentica no Supabase Auth (`sign_in_with_password`) e devolve token + refresh +
`usuario` + `salao`. O refresh vai para `refresh_tokens` **hasheado** — nunca em claro.
`logout` marca `revogado_em`.

`GET /auth/eu` é chamado no boot para revalidar a sessão. Sem ele, um token expirado só
aparece quando a primeira tela falha.

**Aceite:** o app abre, loga com `teste@salao.app`, cai no Resumo e o nome do salão
aparece no cabeçalho.

---

## L1 — Cadastros `destrava Perfil e o formulário de atendimento`

### L1.1 · `servicos` (4)

`GET · POST · PATCH · DELETE /servicos`

- `GET` traz `produtos_padrao` de cada serviço (join com `servico_produtos_padrao`) — é
  o que a finalização de atendimento pré-preenche.
- `POST` e `PATCH` recebem `produtos_padrao` como lista de
  `{item_estoque_id, quantidade}` e o `PATCH` **substitui a lista inteira**: o app manda
  o estado final da tela, não um diff. Grave `delete` + `insert` na tabela de vínculo,
  na mesma transação.
- Devolva `nome` e `unidade` **resolvidos do item**, nunca ecoando o corpo — a tela
  escreve "2 cx" sem cruzar duas listas.
- `item_estoque_id` inexistente ou inativo é `404` e não grava nada: material fantasma
  vira baixa de estoque que nunca fecha. Item repetido no mesmo corpo é
  `422 VALIDACAO_INVALIDA` — duas linhas do mesmo material viram duas baixas que
  ninguém confere na hora de finalizar.
- `DELETE` de serviço já usado em atendimento é **soft delete** (`ativo = false`), senão
  o histórico perde o vínculo. Se não tem uso, pode apagar de verdade.

### L1.2 · `perfil` (7)

`GET · PUT /perfil` + CRUD de `/perfil/custos-fixos` + `PATCH
/perfil/custos-fixos/{id}/pagar`.

`GET /perfil/custos-fixos` devolve `total_mensal`, `total_pago` e `total_pendente` já
somados — o app não soma lista.

Cada custo carrega `dia_vencimento`, inteiro de 1 a 31, **obrigatório** no `POST` e no
`PATCH` (fora da faixa: `422 VALIDACAO_INVALIDA`). O `PATCH` deixou de ser opcional: a
tela de Perfil abre a linha e edita descrição, valor e dia. Guarde o dia literal, não
uma data — quem resolve fevereiro é o agendador do aviso, na hora de avisar. A coluna
entra em `custos_fixos` com `default 1`, que é o que os registros antigos passam a
devolver.

**Pagamento é por competência, não por cadastro.** Custo fixo não se paga uma vez: ele
volta todo mês. `PATCH /perfil/custos-fixos/{id}/pagar` recebe
`{ "competencia": "2026-09", "pago": true }` e grava em `custos_fixos_pagamentos`
(`unique (custo_fixo_id, competencia)`, idempotente). O `GET` resolve `pago`/`pago_em`
para a competência pedida (`?competencia=`, default: mês corrente) — por isso o aluguel
pago em setembro nasce em aberto em outubro sem ninguém desmarcar nada.

- `pago: false` **remove** a marcação. Desmarcar é tão necessário quanto marcar: um
  toque errado no celular não pode calar o alerta do aluguel pelo mês inteiro.
- Competência fora de `AAAA-MM`: `422 VALIDACAO_INVALIDA`.
- **Pagar não lança `gasto`.** Custo fixo já entra no resultado do mês pelo perfil;
  criar um gasto aqui contaria o aluguel duas vezes.
- `DELETE` do custo apaga o histórico junto (`on delete cascade`).

**Aceite do lote:** tela de Perfil lista, cria, edita e apaga serviço e custo fixo; o
total mensal bate; o dia de vencimento sobrevive a um `PATCH` que só muda o valor;
vincular dois materiais a um serviço e reabrir a edição traz os dois, com nome e
unidade do estoque; marcar um custo fixo como pago zera o `total_pendente` na proporção
certa e, virado o mês, o mesmo custo volta em aberto.

---

## L2 — Operação diária `a razão de o app existir`

### L2.1 · `atendimentos` (7)

`GET · POST · GET/{id} · PATCH/{id} · PATCH/{id}/finalizar · PATCH/{id}/cancelar ·
DELETE/{id}`

Regras que moram no servidor:

1. **Snapshot de preço.** `atendimento_servicos.preco_snapshot` copia o preço do serviço
   no momento do agendamento. Mudar o preço na tabela depois não pode reescrever o
   passado.
2. **Status.** `PATCH` comum aceita `agendado` **e `finalizado`** — corrigir o nome do
   cliente ou o serviço lançado depois do atendimento é o caso comum. Só `cancelado`
   recusa, com `409 ATENDIMENTO_STATUS_INVALIDO`: registro fora das contas do mês não
   se reescreve. O corpo nunca traz materiais (isso é `/finalizar`), e o preço do
   catálogo é congelado de novo, igual ao `POST`.
3. **Filtro de status no `GET`.** O `status` csv da query deixou de ser opcional na
   prática: é o filtro da tela de atendimentos. `saldo_liquido` e `quantidade` têm que
   refletir o filtro, não o mês inteiro.
4. **Finalizar dá baixa no estoque** — ver L3.3, é o ponto mais delicado do sistema. A
   lista de materiais que chega no corpo é o **estado final** da confirmação de consumo:
   o app abre o modal pré-preenchido pelos `produtos_padrao` dos serviços do atendimento
   (somando quando dois serviços pedem o mesmo item) e ela ajusta para mais, para menos,
   remove ou acrescenta. O servidor não deduz consumo a partir do serviço — ele grava o
   que foi confirmado.
5. **Cancelar um finalizado estorna** as movimentações (movimentação de `entrada`
   compensatória, não `delete` — histórico não se apaga).
6. `DELETE` só de agendado. Finalizado se cancela.

### L2.2 · `gastos` (5)

`GET · POST · PATCH/{id} · PATCH/{id}/pagar · DELETE/{id}`

- `GET` devolve `total_pendente`, `total_pago` e `total_geral` calculados no servidor.
- `/pagar` é **idempotente**: pagar duas vezes devolve 200, não 409. A usuária toca duas
  vezes por engano e não pode ver erro por isso.
- `pago = true` grava `pago_em = now()`.

**Aceite do lote:** agendar, editar, cancelar e listar atendimentos; lançar gasto,
marcar pago, ver os totais mudarem.

---

## L3 — Estoque `a maior lacuna: não existe nada hoje`

### L3.1 · `GET /estoque/itens` e o CRUD (4)

`status` e `deficit` **não são calculados no Python**: são colunas geradas na tabela
(§2 do SQL). Isso garante que app, push e n8n leem o mesmo número.

`GET` devolve também `total_alertas` (itens em `alerta`, `critico` ou `negativo`) e
`valor_total` (Σ `quantidade_atual × custo_medio`, ignorando negativos).

`DELETE` com movimentação = soft delete.

### L3.2 · `POST /estoque/itens/{id}/movimentacoes` e `GET /estoque/movimentacoes` (2)

**Média ponderada móvel** a cada `entrada` com `custo_unitario`:

```
custo_medio = (saldo × custo_medio + qtd × custo_unitario) ÷ (saldo + qtd)
```

Com `saldo <= 0`, o custo novo é o `custo_unitario` da entrada. `saida` e `ajuste` não
tocam no custo. `custo_ultima_compra` sempre recebe o `custo_unitario` da entrada.

Toda movimentação é **transacional junto com o update do saldo**. Um `insert` sem o
`update` (ou o contrário) deixa o estoque mentindo, e estoque que mente é pior que
estoque que não existe.

### L3.3 · Finalizar atendimento com baixa `⚠️ o ponto crítico`

Fluxo de duas passadas, decidido com a usuária:

```
app → PATCH /atendimentos/{id}/finalizar  { materiais, confirmar_estoque_insuficiente: false }
                                │
                 falta saldo?   ├── não → finaliza, baixa estoque, 200
                                │
                                └── sim → 409 ESTOQUE_INSUFICIENTE
                                          result.faltantes: [{ nome, solicitada, disponivel, deficit }]
                                          NADA foi gravado
                                                │
                         app mostra "Finalizar mesmo assim?"
                                                │
app → PATCH /atendimentos/{id}/finalizar  { materiais, confirmar_estoque_insuficiente: true }
                                                │
                                    finaliza, saldo fica negativo,
                                    movimentacao.forcada = true,
                                    gera alerta estoque_negativo
```

Não bloqueia porque ela repõe **depois** de atender. Travar o registro do atendimento —
o dado que sustenta o resumo financeiro inteiro — por causa de um controle de estoque
desatualizado seria trocar o problema grande pelo pequeno.

Três coisas que não podem escapar:

- A 1ª passada **não grava nada**, nem parcialmente. Tudo numa transação.
- `confirmar_estoque_insuficiente: true` libera **só** a checagem de saldo. Status
  inválido e material inexistente continuam recusando.
- `movimentacao.forcada = true` marca as baixas forçadas, para depois dar para auditar
  por que um item ficou negativo.

**Aceite:** finalizar um atendimento usando "Cola adesiva" (saldo 0 no seed) devolve 409
com a lista; confirmando, finaliza e a Cola aparece em vermelho com −1 na tela de Estoque
e um alerta na central.

---

## L4 — Kits `montar é operação real`

### L4.1 · `GET /kits` e CRUD (4)

Derivados calculados no servidor: `custo_total`, `margem`, `quantidade_montavel`
(`min(saldo_item ÷ quantidade_item)`) e `disponivel`.

### L4.2 · `POST /kits/{id}/montar`

Baixa `quantidade × quantidade_item` de cada item da composição, **atomicamente**, e soma
em `kits.quantidade_montada`. Movimentação com `kit_id` e motivo `Montagem de kit`.

Mesma mecânica de duas passadas do L3.3.

### L4.3 · `POST /kits/{id}/vender`

Decrementa `quantidade_montada`, grava em `kit_vendas` com snapshot de nome, preço e
custo. `preco_unitario` opcional (ausente = preço do cadastro) para o desconto de balcão.

Vender mais do que está montado: `409 KIT_NAO_MONTADO`. **Sem** confirmação por cima —
não existe vender um kit que não foi montado, ao contrário do insumo, onde o negativo
representa um consumo que de fato aconteceu.

**Aceite:** montar 2 kits derruba o saldo dos insumos; vender 1 sobe a receita do mês.

---

## L5 — Resumo `os números que ela olha primeiro`

### `GET /resumo/mensal?ano&mes` — renomear e estender

Além dos totais já descritos, entregar seis meses de receitas/despesas em ordem
cronológica, a meta mensal do perfil e o lucro por serviço calculado a partir do
snapshot de custo do atendimento. Esses campos alimentam diretamente o novo painel;
não devem ser recalculados no Flutter.

Existe como `GET /relatorio/mensal`. Muda de nome e ganha `saldo_final`, `entrou`, `saiu`,
o bloco `insights` inteiro e os três campos de kit.

Contas que precisam bater:

| Campo | Fórmula |
|---|---|
| `entrou` | `total_servicos + total_kits` |
| `saiu` | `total_custos_fixos + total_gastos_variaveis` |
| `saldo_final` | `entrou − saiu` |
| `ticket_medio` | `total_servicos ÷ quantidade_atendimentos` — kit **não** entra |
| `margem_lucro_percentual` | `saldo_final ÷ entrou × 100` |
| `variacao_percentual_mes_anterior` | contra o `saldo_final` do mês anterior |

**Custo de kit não entra em `saiu`** — ele já saiu quando o insumo foi comprado. Contar de
novo na venda seria contar duas vezes. `custo_kits_vendidos` vai no payload só para a
margem.

Atendimento `cancelado` não entra em nada.

`POST /precificacao/calcular` fica como está — é cálculo puro.

**Aceite:** o saldo da tela de Resumo bate com a soma manual dos atendimentos e gastos
do seed.

---

## L6 — Alertas `a funcionalidade nova`

### L6.1 · Geração `job`

Um job (cron a cada hora, ou trigger + recálculo) mantém a tabela `alertas` viva:

| `tipo` | Dispara quando |
|---|---|
| `estoque_negativo` | `quantidade_atual < 0` |
| `estoque_critico` | `quantidade_atual == 0` |
| `estoque_baixo` | `quantidade_atual <= quantidade_minima` |
| `gasto_a_vencer` | pendente vencendo em ≤ `dias_antecedencia_vencimento` (7) |
| `gasto_vencido` | pendente com prazo passado |
| `custo_fixo_a_vencer` | competência corrente **em aberto**, vencendo em ≤ `dias_antecedencia_vencimento` |
| `custo_fixo_vencido` | competência corrente **em aberto** com o `dia_vencimento` já passado |
| `saldo_negativo` | saldo do mês < 0 |
| `zero_a_zero` | saldo do mês < `limite_saldo_alerta` |

Os dois tipos de custo fixo são a razão de ele ter `dia_vencimento` (L1.2). O par
"vencido" existe porque o servidor **sabe** se ela pagou: `custos_fixos_pagamentos`
responde isso. Enquanto a competência corrente estiver em aberto, o vencimento que
conta é o **deste mês**, e ele fica para trás — isso é `custo_fixo_vencido`. Marcada
como paga, a competência para de gerar alerta (resolva os que já existem) e o próximo
alvo é o mês seguinte; em mês curto, o dia 31 avisa no dia 28. A `chave_dedupe` tem que
incluir a competência (`custo_fixo:{id}:{ano}-{mes}`), senão o aviso do mês que vem
morre deduplicado contra o deste mês.

**Deduplicação é obrigatória.** O índice único `idx_alertas_dedupe` já força um alerta
vivo por `chave_dedupe`. Sem isso, um cron horário gera 24 avisos por dia do mesmo vidro
de cola e a central vira ruído que ela aprende a ignorar — o que mata a funcionalidade
inteira.

Quando a condição deixa de valer, marque `resolvido_em` em vez de apagar.

Respeite `tipos_silenciados` e os canais das preferências.

### L6.2 · Endpoints (7)

`GET /alertas` · `PATCH /alertas/{id}/lido` · `PATCH /alertas/lidos` ·
`GET · PUT /alertas/preferencias` · `POST /dispositivos` · `DELETE /dispositivos/{token}`

`GET /alertas` devolve `total_nao_lidos` e `resumo: { critico, alerta, info }` —
`critico + alerta` é o número do badge. O app não conta lista.

`POST /dispositivos` é idempotente por token. `DELETE` no logout, senão a próxima pessoa
que usar o aparelho recebe alertas alheios.

### L6.3 · Push `depende do Firebase`

Bloqueado até existir projeto Firebase com FCM (só o dono da conta cria). Quando existir:
`google-services.json` / `GoogleService-Info.plist` no app e envio via FCM no servidor,
para os tokens ativos de `dispositivos`, respeitando `canal_push`.

**Aceite do lote:** deixar um item negativo faz o badge subir e o alerta aparecer na
central; marcar lido zera o badge.

---

## L7 — n8n `pode esperar`

| Endpoint | Estado |
|---|---|
| `GET /relatorio/semanal` | existe |
| `POST /webhooks/confirmacao` | existe |
| `POST /webhooks/acionar-resumo-semanal` | existe |
| `GET /interno/alertas-pendentes` | novo |
| `POST /interno/alertas/{id}/entregue` | novo |

Os canais WhatsApp e e-mail já estão no contrato de preferências, desligados.

Hoje `_validar_n8n` (`api/app/routers/webhooks.py`) só exige o secret **em produção**.
Endpoint interno que devolve dado da usuária precisa exigir em todo ambiente — em
homolog o dado é real também.

---

## Rastreamento: tela ↔ endpoint

Serve para saber o que uma tela precisa antes de testá-la.

| Tela | Endpoints |
|---|---|
| Login | `POST /auth/login`, `GET /auth/eu` |
| Resumo | `GET /resumo/mensal`, `GET /alertas` |
| Atendimentos | `GET/POST/PATCH/DELETE /atendimentos`, `/finalizar`, `/cancelar`, `GET /servicos`, `GET /estoque/itens` |
| Gastos | `GET/POST/PATCH/DELETE /gastos`, `/pagar` |
| Estoque | `GET/POST/PATCH/DELETE /estoque/itens`, `/movimentacoes`, `GET /kits`, `/montar`, `/vender` |
| Perfil | `GET/PUT /perfil`, CRUD `/perfil/custos-fixos`, CRUD `/servicos`, `GET/PUT /alertas/preferencias` |
| Central de alertas | `GET /alertas`, `PATCH /alertas/{id}/lido`, `PATCH /alertas/lidos` |

---

## Pronto quando

Vale para todo endpoint, e é o que o app assume:

- [ ] Responde no envelope de 4 chaves, inclusive em erro
- [ ] Deriva a usuária do **JWT validado**; ignora qualquer `user_id` que venha do cliente
- [ ] Devolve valores **já calculados** (totais, status, margem, badge) — o app não soma
      lista nem recalcula regra de negócio
- [ ] Erro de negócio tem `codigo` da §11 do mapa
- [ ] Datas em ISO-8601 com timezone; dinheiro em `number` com 2 casas; enums em string
- [ ] Operação que mexe em saldo é transacional
- [ ] `404` em id de outra usuária (não `403` — não confirma que o registro existe)

---

## Configuração de ambiente

Novas variáveis no `api/.env`:

```bash
SUPABASE_JWT_SECRET=...     # Dashboard > Settings > API > JWT Secret
N8N_SECRET=...              # já usado, passa a ser exigido em todo ambiente
FCM_SERVER_KEY=...          # só no L6.3
```

O app aponta para o backend por `--dart-define-from-file`:

```bash
flutter run -d chrome --dart-define-from-file=env/dev.json
```

`env/dev.json` já está em `http://localhost:8000/v1` — o FastAPI precisa servir sob o
prefixo `/v1` e liberar CORS para a origem do Flutter web.
