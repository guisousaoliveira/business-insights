# Mapa de endpoints — FastAPI

Especificação do backend que o app Flutter consome. Consequência da **decisão A1**
([CLAUDE.md](../CLAUDE.md)): o FastAPI é o **único** backend que o app enxerga. O
Supabase é detalhe de implementação dele — o Flutter não fala PostgREST, não fala RPC,
não carrega `anon key`.

**Status de cada endpoint:**
`EXISTE` já implementado · `ALTERAR` existe mas muda · `NOVO` a implementar.

---

## 0. Contrato geral

### Base URL

Injetada por `--dart-define=API_BASE_URL=...`, nunca fixa no código.
Sugestão: `https://api.thamiresbeauty.com.br/v1`.

### Cabeçalhos

| Header | Quando | Valor |
|---|---|---|
| `Authorization` | toda requisição autenticada | `Bearer <token>` |
| `Accept-Language` | sempre | `pt-BR` |
| `Content-Type` | POST/PUT/PATCH | `application/json` |

### Envelope de resposta — obrigatório e uniforme

O padrão de projeto codifica o envelope **uma vez** em `ResponseModel`. Toda resposta,
sucesso ou erro, tem a mesma forma:

```json
{
  "total": 12,
  "mensagem": "ok",
  "codigo": null,
  "result": { }
}
```

| Campo | Tipo | Significado |
|---|---|---|
| `total` | `int` | quantidade de itens em `result` quando for lista; `1` para objeto; `0` em erro |
| `mensagem` | `string` | texto humano. Em erro, mensagem de fallback (o app prefere a tradução por código) |
| `codigo` | `string?` | **código de erro de negócio**. `null` em sucesso. Ver §9 |
| `result` | `object \| array \| null` | a carga útil |

Erro sai com o HTTP status apropriado **e** o mesmo envelope:

```json
{
  "total": 0,
  "mensagem": "Não há saldo em estoque para dar baixa neste item.",
  "codigo": "ESTOQUE_INSUFICIENTE",
  "result": null
}
```

> **Por que código e não texto:** o app identifica erro de negócio por `codigo`, nunca
> pela mensagem. Mensagem muda quando alguém corrige uma vírgula; código não. Todo
> código novo entra em §9 **e** ganha uma chave no ARB do app.

### Autorização

O servidor **deriva a usuária do token** e devolve só o que é dela. Nenhum endpoint
aceita `user_id` no corpo ou na query — se aceitar e confiar, é falha de servidor.

> ⚠️ **Dívida crítica de segurança.** `api/app/routers/relatorio.py::_extrair_user_id`
> decodifica o JWT em base64 **sem verificar a assinatura** e usa o `sub`. Enquanto o
> Flutter falava direto com o Supabase (RLS na anon key) isso era só feio; com A1 o
> FastAPI passa a ser a única barreira, e qualquer pessoa forja um token com o `sub` da
> usuária. Validar com `SUPABASE_JWT_SECRET` (python-jose) é pré-requisito de produção.

### Convenções

- Datas: ISO-8601. `date` puro (`2026-06-03`) para prazo; `datetime` com timezone para
  registro (`2026-06-03T14:30:00-03:00`).
- Dinheiro: `number` em reais com 2 casas (`180.00`). Nunca string, nunca centavos int.
- Identificadores: `uuid` string.
- Enums: **string**, nunca int (reordenar enum não pode ser quebra silenciosa).
- Paginação: `?pagina=1&tamanho=50` onde indicado; `total` no envelope é o total geral,
  não o da página.

---

## 1. `auth` — 4 operações

### `POST /auth/login` — `NOVO`

```json
// request
{ "email": "thamires@exemplo.com", "senha": "..." }
```
```json
// result
{
  "token": "eyJ...",
  "refresh_token": "eyJ...",
  "expira_em": 3600,
  "usuario": { "id": "uuid", "nome": "Thamires Borges", "email": "thamires@exemplo.com" },
  "salao": { "id": "uuid", "nome": "Thamires Borges Beauty", "foto_url": null }
}
```

Erros: `401` + `AUTH_CREDENCIAIS_INVALIDAS`.

### `POST /auth/refresh` — `NOVO`

`{ "refresh_token": "..." }` → mesmo `result` do login (token + refresh novos).
Erros: `401` + `AUTH_REFRESH_INVALIDO` (o app faz logout).

O interceptor do Dio chama este endpoint **antes** de deslogar, em `QueuedInterceptor`
para não disparar N refreshes simultâneos.

### `POST /auth/logout` — `NOVO`

Sem corpo. Invalida o refresh token. `result: null`.

### `GET /auth/eu` — `NOVO`

Dados da sessão corrente (`usuario` + `salao`). Usado no boot para revalidar token e
repopular o cabeçalho sem esperar as telas.

---

## 2. `atendimentos` — 7 operações

Status: `agendado` · `finalizado` · `cancelado`.
Cancelado **não** entra em nenhum cálculo financeiro.

### `GET /atendimentos` — `NOVO`

Query: `inicio` (date), `fim` (date), `status` (opcional, csv), `pagina`, `tamanho`.

> O `status` **é consumido pelo app** desde o filtro da tela de atendimentos: ele não é
> opcional na prática. Filtrar no servidor e não na lista já baixada é o que faz
> `saldo_liquido` e `quantidade` baterem com os cartões na tela.

```json
// result — o agregado vem junto porque o cabeçalho verde da tela precisa dele
{
  "saldo_liquido": 430.00,
  "quantidade": 3,
  "atendimentos": [
    {
      "id": "uuid",
      "cliente_nome": "Maria",
      "cliente_telefone": "+5511999887766",
      "data": "2026-08-31T10:00:00-03:00",
      "status": "finalizado",
      "servicos": [
        { "servico_id": "uuid", "nome": "Extensão de cílios", "preco": 180.00 }
      ],
      "materiais": [
        { "item_estoque_id": "uuid", "nome": "Fio mink 0.07", "quantidade": 1, "preco": 35.00 }
      ],
      "total_servicos": 180.00,
      "total_materiais": 35.00,
      "saldo": 145.00
    }
  ]
}
```

> `total_servicos`, `total_materiais` e `saldo` vêm **calculados do servidor**. Hoje o
> app calcula com getters no model; passa a só exibir. Motivo: a mesma conta alimenta o
> resumo, o alerta e o n8n — três lugares onde não pode divergir.

### `POST /atendimentos` — `NOVO`

Cria **agendado**. Materiais não entram aqui (só na finalização).

```json
{
  "cliente_nome": "Fernanda",
  "cliente_telefone": "+5511988887777",
  "data": "2026-09-03T14:00:00-03:00",
  "servicos": [{ "servico_id": "uuid" }]
}
```

O preço vem da tabela de serviços do salão e é **congelado como snapshot** no
atendimento — mudar o preço no perfil não pode reescrever o histórico. Serviço avulso
(sem cadastro) é aceito como `{ "nome": "...", "preco": 90.00 }`.

### `GET /atendimentos/{id}` — `NOVO`
### `PATCH /atendimentos/{id}` — `NOVO`

Edita cliente, data e serviços. Aceita **agendado e finalizado**; cancelado recusa com
`409` + `ATENDIMENTO_STATUS_INVALIDO`.

```json
{
  "cliente_nome": "Fernanda",
  "cliente_telefone": "+5511988887777",
  "data": "2026-09-03T14:00:00-03:00",
  "servicos": [{ "servico_id": "uuid" }]
}
```

> **Por que finalizado também edita.** Corrigir o nome do cliente ou o serviço lançado
> num atendimento que já aconteceu é o caso comum — errar o nome só aparece depois. O
> que continua fechado é **cancelado**: registro fora das contas do mês não se
> reescreve. Materiais **não** entram neste corpo: quem mexe em material é
> `/finalizar`, a operação que dá baixa no estoque — editar nunca move saldo de item.
> O preço do catálogo é congelado de novo, igual ao `POST`.

### `PATCH /atendimentos/{id}/finalizar` — `NOVO`

```json
{
  "materiais": [
    { "item_estoque_id": "uuid", "quantidade": 1 },
    { "nome": "Fita micropore", "quantidade": 2, "preco": 8.00 }
  ],
  "confirmar_estoque_insuficiente": false
}
```

**Regra de negócio que mora aqui, no servidor:** finalizar dá **baixa no estoque** de
cada material com `item_estoque_id`, gerando uma `movimentacao` do tipo `saida` com
`atendimento_id` preenchido, e recalcula os alertas de estoque. O preço do material é o
`custo_medio` do item no momento da baixa (snapshot — ver §5).

**De onde vem essa lista:** o app abre a finalização com um modal de confirmação de
consumo já preenchido pelos `produtos_padrao` dos serviços do atendimento (§8) —
somando as quantidades quando dois serviços pedem o mesmo item. A usuária ajusta o que
saiu a mais ou a menos, remove o que não usou e acrescenta o que usou fora do padrão.
O corpo é sempre o **estado final** dessa conferência, nunca a diferença em relação ao
padrão: o servidor não deduz consumo, ele grava o que foi confirmado.

#### Estoque insuficiente: avisar e perguntar — `DECIDIDO`

Duas passadas, **no mesmo endpoint**, controladas por `confirmar_estoque_insuficiente`:

**1ª passada** — o app sempre manda `false`. Se falta saldo de qualquer material, o
servidor **não grava nada** (nem o status, nem as movimentações) e devolve `409`:

```json
{
  "total": 0,
  "mensagem": "Alguns materiais estão sem saldo em estoque.",
  "codigo": "ESTOQUE_INSUFICIENTE",
  "result": {
    "faltantes": [
      {
        "item_estoque_id": "uuid",
        "nome": "Cola adesiva para cílios",
        "unidade": "un",
        "quantidade_solicitada": 2,
        "quantidade_disponivel": 0,
        "deficit": 2
      }
    ]
  }
}
```

**2ª passada** — o app mostra o aviso com essa lista e o botão *Finalizar mesmo assim*.
Se ela confirmar, repete a chamada idêntica com `confirmar_estoque_insuficiente: true`:
o servidor finaliza, grava as movimentações normalmente, **deixa o saldo negativo** e
gera um alerta `estoque_negativo` por item afetado.

> **Por que não bloquear.** Ela repõe depois de atender, não antes. Bloquear travaria o
> registro do atendimento — o dado que sustenta todo o resumo financeiro — por causa de
> um controle de estoque desatualizado. Saldo negativo é feio e visível, que é
> exatamente o efeito desejado: aparece em vermelho na tela de Estoque e vira alerta até
> ela repor.

`confirmar_estoque_insuficiente: true` libera **só a checagem de saldo**. Status inválido,
material inexistente e corpo malformado continuam recusando.

Erros: `409` + `ESTOQUE_INSUFICIENTE` (1ª passada) · `409` +
`ATENDIMENTO_STATUS_INVALIDO` · `404` + `RECURSO_NAO_ENCONTRADO`.

### `PATCH /atendimentos/{id}/cancelar` — `NOVO`

Se já estava finalizado, **estorna** as movimentações de estoque. `result` com o
atendimento atualizado.

### `DELETE /atendimentos/{id}` — `NOVO`

Só para agendado. Finalizado se cancela, não se apaga (histórico financeiro).

---

## 3. `gastos` — 5 operações

**Contrato vencedor** (o `schema.sql` se ajusta a ele, não o contrário):

| Campo | Valores |
|---|---|
| `forma_pagamento` | `a_vista` · `credito` · `debito` · `pix` |
| `categoria` | `fixo` · `material` · `outros` |

O campo `prioridade` (`alta`/`média`/`baixa`) do `schema.sql` **sai** — não aparece no
protótipo e não alimenta nenhum cálculo. Urgência é derivada do prazo.

### `GET /gastos` — `NOVO`

Query: `mes`, `ano`, `pago` (bool, opcional), `categoria`, `pagina`, `tamanho`.

```json
{
  "total_pendente": 246.80,
  "total_pago_mes": 210.00,
  "gastos": [
    {
      "id": "uuid",
      "nome": "Conta de luz",
      "valor": 120.00,
      "prazo_pagamento": "2026-09-03",
      "forma_pagamento": "pix",
      "categoria": "fixo",
      "pago": false,
      "pago_em": null,
      "vence_em_dias": 1,
      "itens": [{ "nome": "...", "preco": 0.00 }]
    }
  ]
}
```

`vence_em_dias` vem do servidor (negativo = vencido). O app não recalcula prazo — é a
mesma regra que gera o alerta.

### `POST /gastos` — `NOVO`
### `PATCH /gastos/{id}` — `NOVO`
### `PATCH /gastos/{id}/pagar` — `NOVO`

Corpo opcional `{ "pago_em": "2026-09-02" }`; ausente = hoje.
Idempotente: gasto já pago devolve `200` com o estado atual, **não** erro.

### `DELETE /gastos/{id}` — `NOVO`

---

## 4. `resumo` — 2 operações

### `GET /resumo/mensal?ano&mes` — `ALTERAR`

Existe como `GET /relatorio/mensal`. Muda de nome (alinha com o módulo do app) e
**ganha os insights do protótipo**, que hoje não existem em lugar nenhum:

```json
{
  "ano": 2026, "mes": 8,
  "saldo_final": 1240.00,
  "entrou": 2985.00,
  "saiu": 1745.00,
  "meta_faturamento_mensal": 9000.00,
  "historico_seis_meses": [
    { "ano": 2026, "mes": 3, "receitas": 2100.00, "despesas": 1700.00 },
    { "ano": 2026, "mes": 8, "receitas": 2985.00, "despesas": 1745.00 }
  ],
  "receita": {
    "total_servicos": 2985.00,
    "total_insumos": 397.00,
    "liquido_atendimentos": 2588.00,
    "quantidade_atendimentos": 18,
    "total_kits": 135.00,
    "quantidade_kits_vendidos": 3,
    "custo_kits_vendidos": 64.50,
    "servicos_mais_realizados": [
      { "nome": "Extensão de cílios", "quantidade": 2, "total_receita": 360.00, "lucro": 290.00 }
    ]
  },
  "gastos": {
    "total_custos_fixos": 1348.00,
    "total_gastos_variaveis": 397.00,
    "total_saiu": 1745.00
  },
  "insights": {
    "ticket_medio": 165.00,
    "margem_lucro_percentual": 41.5,
    "variacao_percentual_mes_anterior": 18.0,
    "saldo_mes_anterior": 1050.00,
    "servico_mais_lucrativo": { "nome": "Extensão de cílios", "lucro": 290.00 }
  },
  "alerta_zero_a_zero": false
}
```

Campos novos em relação ao que a API devolve hoje: `saldo_final` no topo, `entrou`,
`saiu`, `meta_faturamento_mensal`, `historico_seis_meses`, o bloco `insights` inteiro,
`lucro` em cada item de `servicos_mais_realizados` e os três campos de kit dentro de
`receita`. O histórico sempre contém seis posições em ordem cronológica, inclusive
meses sem movimento (valores zero), para o gráfico não deslocar os rótulos.

`servicos_mais_realizados[].lucro = total_receita - soma(custo_insumos_snapshot)`.
Ao finalizar o atendimento, o servidor calcula e congela
`atendimento_servicos.custo_insumos_snapshot` usando a composição padrão e o
`custo_medio` vigente. Alterar preço, composição ou custo depois não reescreve meses
fechados.

**Onde a venda de kit entra na conta** (§6): `entrou = total_servicos + total_kits`. O
custo do kit **não** entra em `saiu` — ele já saiu quando o insumo foi comprado, e contar
de novo na venda seria contar duas vezes. `custo_kits_vendidos` está no payload só para a
margem: é informativo, não entra em nenhuma soma do saldo.

`ticket_medio` continua sendo `total_servicos ÷ quantidade_atendimentos` — kit não é
atendimento e diluiria o número que ela usa para decidir preço.

> O model Flutter atual (`RelatorioMensal`, plano) **não** bate com este payload
> aninhado. Vence este; o model é reescrito na F3.

### `POST /precificacao/calcular` — `EXISTE`

Mantido como está. É cálculo puro, não toca no banco.
Migra de `/precificacao/calcular` para dentro do módulo `resumo` no app, sem mudar o
path no servidor.

---

## 5. `estoque` — 6 operações

Módulo dividido de `kits` porque juntos passariam de 8 operações.

**Nada disso existe hoje** — nem tabela no `schema.sql`, nem endpoint. É a maior lacuna
do backend: o estoque só vive no mock do Flutter.

Tabelas a criar: `estoque_itens`, `estoque_movimentacoes`, `kits`, `kit_itens`.

### `GET /estoque/itens` — `NOVO`

Query: `status` (`ok`/`alerta`/`critico`/`negativo`), `categoria`, `ativo`.

```json
{
  "total_alertas": 3,
  "valor_total": 428.50,
  "itens": [
    {
      "id": "uuid",
      "nome": "Cola adesiva para cílios",
      "unidade": "un",
      "categoria": "cilios",
      "quantidade_atual": 0,
      "quantidade_minima": 2,
      "custo_medio": 28.00,
      "custo_ultima_compra": 30.00,
      "status": "critico",
      "deficit": 2,
      "ativo": true
    }
  ]
}
```

`status` e `deficit` vêm do **servidor** (S7 da adaptação): `negativo` quando
`quantidade_atual < 0`, `critico` quando `== 0`, `alerta` quando
`<= quantidade_minima`, senão `ok`. O app não recalcula — a mesma regra alimenta o push
e o n8n.

`negativo` existe por causa da decisão de finalizar atendimento sem saldo (§2): o estado
tem que ser visível e distinto de "acabou", senão ela não sabe que deve **mais** do que
zero ao repor.

`unidade` ∈ `un` · `ml` · `g` · `cx`.
`categoria` ∈ `cilios` · `sobrancelha` · `limpeza_pele` · `descartavel` · `outro`.

### `POST /estoque/itens` — `NOVO`
### `PATCH /estoque/itens/{id}` — `NOVO`
### `DELETE /estoque/itens/{id}` — `NOVO`

Soft delete (`ativo = false`) quando o item já tem movimentação — apagar quebraria o
histórico de custo dos atendimentos.

### `POST /estoque/itens/{id}/movimentacoes` — `NOVO`

```json
{ "tipo": "entrada", "quantidade": 10, "motivo": "Compra — fornecedor",
  "custo_unitario": 28.00 }
```

`tipo` ∈ `entrada` · `saida` · `ajuste`. Devolve o item com a quantidade e o custo já
atualizados.

#### Custo do item: média ponderada móvel — `DECIDIDO`

Toda `entrada` que traz `custo_unitario` recalcula o custo do item:

```
custo_medio_novo = (saldo_atual × custo_medio_atual + qtd_entrada × custo_unitario)
                   ÷ (saldo_atual + qtd_entrada)
```

Se `saldo_atual <= 0`, não há o que ponderar: `custo_medio_novo = custo_unitario`.
`saida` e `ajuste` **nunca** mexem no custo — só no saldo.

O item guarda os dois valores:

| Campo | Para que serve |
|---|---|
| `custo_medio` | margem do kit, custo do atendimento, valor total do estoque |
| `custo_ultima_compra` | informativo — quanto ela pagou na última vez |

> **Por que média e não último preço.** Com "último preço", uma única compra cara ou
> promocional reescreve o custo de todo o saldo parado, e a margem do mês salta sem que
> nada de real tenha mudado. A média move o custo na proporção do que entrou: comprar
> 2 unidades caras sobre 20 baratas quase não mexe no número, que é o comportamento
> correto. É também o critério contábil usual no Brasil (custo médio ponderado móvel).

Saída manual que deixaria o saldo negativo: `409` + `ESTOQUE_INSUFICIENTE`, com o mesmo
`result.faltantes` da finalização. A movimentação avulsa **não** tem confirmação em duas
passadas: negativo só entra pelo caminho do atendimento, onde há um fato real por trás.

### `GET /estoque/movimentacoes` — `NOVO`

Query: `item_id`, `inicio`, `fim`, `tipo`, `pagina`, `tamanho`.
Alimenta o histórico (ícone de relógio na app bar de Estoque).

```json
{ "movimentacoes": [
  { "id": "uuid", "item_id": "uuid", "item_nome": "Cola adesiva para cílios",
    "tipo": "saida", "quantidade": 1, "motivo": "Atendimento — Maria",
    "atendimento_id": "uuid", "criado_em": "2026-08-31T10:40:00-03:00" }
] }
```

---

## 6. `kits` — 6 operações

Kit de revenda: um produto **montado a partir do estoque que ela já tem** e vendido
avulso, fora do atendimento.

`GET /kits` é o cadastro (a *receita* do kit). Montar e vender são dois fatos separados,
porque acontecem em momentos diferentes: ela monta cinco kits numa tarde e vende ao longo
das semanas seguintes. Por isso o kit tem saldo próprio — `quantidade_montada`.

```
estoque de insumos  ──montar──▶  kits montados  ──vender──▶  receita
```

### `GET /kits` — `NOVO`

```json
{ "kits": [
  { "id": "uuid", "nome": "Kit cuidado pós-cílios", "preco_venda": 45.00,
    "custo_total": 21.50, "margem": 23.50,
    "quantidade_montada": 3,
    "quantidade_montavel": 7,
    "disponivel": true,
    "itens": [
      { "item_estoque_id": "uuid", "nome": "Removedor", "quantidade": 1, "unidade": "un" },
      { "item_estoque_id": "uuid", "nome": "Fita micropore", "quantidade": 2, "unidade": "cx" }
    ] }
] }
```

Tudo que é derivado é do servidor:

| Campo | Cálculo |
|---|---|
| `custo_total` | Σ (`quantidade` do item × `custo_medio` do item) |
| `margem` | `preco_venda − custo_total` |
| `quantidade_montada` | saldo de kits prontos, na prateleira |
| `quantidade_montavel` | `min(saldo_item ÷ quantidade_item)` sobre os itens — quantos ainda dá para montar |
| `disponivel` | `quantidade_montada > 0 || quantidade_montavel > 0` |

### `POST /kits` — `NOVO`
### `PATCH /kits/{id}` — `NOVO`
### `DELETE /kits/{id}` — `NOVO`

Soft delete (`ativo = false`) se o kit já tem venda ou montagem — apagar quebraria o
histórico de receita.

### `POST /kits/{id}/montar` — `NOVO`

```json
{ "quantidade": 2, "confirmar_estoque_insuficiente": false }
```

Baixa `quantidade × quantidade_item` de **cada** item da composição, gerando uma
`movimentacao` de `saida` por item com `kit_id` preenchido e motivo `Montagem de kit`, e
soma `quantidade` em `quantidade_montada`. Operação **atômica**: ou baixa todos os itens,
ou nenhum.

Mesma mecânica de duas passadas da finalização (§2): sem saldo, `409` +
`ESTOQUE_INSUFICIENTE` com `result.faltantes`; se ela confirmar, monta e deixa o saldo
negativo.

`result`: o kit atualizado.

### `POST /kits/{id}/vender` — `NOVO`

```json
{ "quantidade": 1, "preco_unitario": 45.00, "forma_pagamento": "pix",
  "data": "2026-09-02T15:20:00-03:00" }
```

Decrementa `quantidade_montada` e grava a venda com **snapshot** de `preco_unitario` e
`custo_total` (o kit pode mudar de preço depois; a venda de ontem não muda). `data` é
opcional — ausente vale `now()`.

`preco_unitario` também é opcional: ausente, vale o `preco_venda` do cadastro. Existe
para o desconto de balcão, que acontece.

Vender mais do que está montado: `409` + `KIT_NAO_MONTADO`, com
`result: { "quantidade_montada": 1, "quantidade_solicitada": 3 }`. **Aqui não há
confirmação em duas passadas** — não existe "vender um kit que não existe"; ela monta e
vende. É diferente do estoque de insumo, onde o negativo representa um consumo real que
já aconteceu.

`forma_pagamento` usa a mesma lista de `gastos`: `a_vista` · `credito` · `debito` · `pix`.

> **Impacto no resumo (§4):** a venda de kit é receita e precisa aparecer no mês. Ver o
> bloco `receita.kits` acrescentado lá.

---

## 7. `perfil` — 10 operações

### `GET /perfil` — `NOVO`
### `PUT /perfil` — `NOVO`

```json
{ "salao": { "id": "uuid", "nome": "Thamires Borges Beauty",
             "proprietaria": "Thamires Borges", "foto_url": null,
             "telefone_whatsapp": "+5511999999999",
             "meta_faturamento_mensal": 9000.00 } }
```

`PUT /perfil` aceita `meta_faturamento_mensal`; o Resumo usa essa meta para calcular
o percentual alcançado. O `telefone_whatsapp` e o `limite_gasto_alerta` que hoje vivem no mock do ApiService
migram: o telefone fica aqui, o limite vai para as **preferências de alerta** (§8).

### `GET /perfil/custos-fixos` — `NOVO`

Aceita `?competencia=2026-09`; sem ela, vale o **mês corrente**.

```json
{ "total_mensal": 1348.00,
  "total_pago": 1200.00,
  "total_pendente": 148.00,
  "custos": [{ "id": "uuid", "descricao": "Aluguel", "valor": 1200.00,
               "dia_vencimento": 5, "competencia": "2026-09",
               "pago": true, "pago_em": "2026-09-03T10:12:00Z" }] }
```

`pago` **não é campo do cadastro**: é o estado daquele custo *naquela
competência*, resolvido pelo servidor a partir de `custos_fixos_pagamentos`. O
mesmo aluguel volta com `pago: true` em setembro e `pago: false` em outubro sem
que ninguém desmarque nada — é o que faz o custo fixo se comportar como
compromisso recorrente, e não como lançamento.

Os dois totais vêm somados do servidor: o app não soma lista.

### `POST /perfil/custos-fixos` — `NOVO`
### `PATCH /perfil/custos-fixos/{id}` — `NOVO`

Mesmo corpo nos dois; o `PATCH` substitui os três campos.

```json
{ "descricao": "Aluguel", "valor": 1200.00, "dia_vencimento": 5 }
```

`dia_vencimento` é **inteiro de 1 a 31 e obrigatório** — fora da faixa,
`422 VALIDACAO_INVALIDA`. Guarda-se o dia literal que a usuária escolheu, não uma
data: "todo dia 31" continua sendo dia 31 em fevereiro, e quem agenda o aviso é que
resolve o mês curto (último dia do mês). Sem ele um custo fixo é só uma parcela do
total — não dá para avisar que vence amanhã nem para ordenar o mês.

Custo fixo cadastrado antes deste campo existir volta com `dia_vencimento: 1`, que é
o default da coluna.

### `DELETE /perfil/custos-fixos/{id}` — `NOVO`

Apaga junto o histórico de pagamento do custo (`on delete cascade`).

### `PATCH /perfil/custos-fixos/{id}/pagar` — `NOVO`

```json
{ "competencia": "2026-09", "pago": true }
```

Marca (ou desmarca) o pagamento de **uma competência**. É idempotente: pagar
duas vezes o mesmo mês não duplica nada — `unique (custo_fixo_id, competencia)`.

- `competencia` fora do formato `AAAA-MM` → `422 VALIDACAO_INVALIDA`.
- `pago: false` remove a marcação e devolve o custo para pendente. Desmarcar é
  tão necessário quanto marcar: um toque errado no celular não pode calar o
  alerta do aluguel pelo mês inteiro.
- **Pagar não lança gasto.** Custo fixo já entra no resultado do mês pelo
  perfil; criar um `gasto` aqui contaria o aluguel duas vezes.

### `GET /perfil/horario-funcionamento` — `NOVO`
### `PUT /perfil/horario-funcionamento` — `NOVO`

Base do cálculo de horário livre do agendamento público (§10). Decisão do dono do
projeto: **cada dia da semana tem seu próprio horário**, não um expediente único
repetido — é o que permite "funciono seg-sex mas sábado só de manhã, domingo fechado".

```json
{
  "horarios": [
    { "dia_semana": 0, "ativo": false, "hora_inicio": null, "hora_fim": null },
    { "dia_semana": 1, "ativo": true,  "hora_inicio": "09:00", "hora_fim": "19:00" },
    { "dia_semana": 2, "ativo": true,  "hora_inicio": "09:00", "hora_fim": "19:00" },
    { "dia_semana": 3, "ativo": true,  "hora_inicio": "09:00", "hora_fim": "19:00" },
    { "dia_semana": 4, "ativo": true,  "hora_inicio": "09:00", "hora_fim": "19:00" },
    { "dia_semana": 5, "ativo": true,  "hora_inicio": "09:00", "hora_fim": "19:00" },
    { "dia_semana": 6, "ativo": true,  "hora_inicio": "09:00", "hora_fim": "14:00" }
  ]
}
```

`dia_semana`: `0` domingo … `6` sábado. O `PUT` **substitui os 7 dias de uma vez** —
mesma filosofia do `PATCH /servicos/{id}` com `produtos_padrao`: o cliente manda o
estado final da tela (um toggle + dois campos de hora por dia), o servidor não faz
diff. Dia com `ativo: false` não abre horário nenhum, mesmo que `hora_inicio`/
`hora_fim` venham preenchidos — o servidor ignora as horas quando o dia está inativo.

`hora_inicio`/`hora_fim` obrigatórios e `hora_inicio < hora_fim` quando `ativo: true`,
senão `422 VALIDACAO_INVALIDA`. **Não há exceção por data** (feriado, folga pontual)
nesta versão — é dia da semana fixo. Se isso virar necessário, entra depois como uma
tabela de bloqueios pontuais; não faz parte do escopo atual.

### `GET /perfil/link-agendamento` — `NOVO`

```json
{ "slug": "thamires-beauty", "url": "https://agendar.thamiresbeauty.com.br/thamires-beauty" }
```

Decisão do dono do projeto: **o link é fixo por salão**, não por cliente/convite — a
profissional compartilha essa mesma URL sempre (bio do Instagram, WhatsApp etc.), sem
expiração e sem precisar gerar um link por pessoa. `slug` é derivado do nome do salão
no cadastro (normalizado, sem acento/espaço) com sufixo numérico em caso de colisão
(`thamires-beauty-2`); não há endpoint de regenerar nesta versão — mudar de slug muda a
URL que ela já divulgou, então fica manual/suporte enquanto não houver pedido pra isso.

---

## 8. `servicos` — 4 operações

Tabela de preços do salão. Módulo próprio para não estourar o `perfil`.

### `GET /servicos` — `NOVO`

```json
{ "servicos": [
  { "id": "uuid", "nome": "Extensão de cílios", "preco": 180.00,
    "duracao_minutos": 90,
    "produtos_padrao": [
      { "item_estoque_id": "uuid", "nome": "Fio mink 0.07",
        "quantidade": 1, "unidade": "un" }
    ] }
] }
```

`duracao_minutos` existe por causa do **agendamento público** (§10): é o que o
servidor soma para calcular quanto tempo um horário escolhido pelo cliente bloqueia na
agenda. Obrigatório e `> 0` — sem duração não dá para calcular horário livre.

`produtos_padrao` é o vínculo do serviço com o estoque: **todo serviço realizado
consome, por padrão, os itens listados aqui**. É o que a tela de finalizar atendimento
usa para já abrir a baixa preenchida — a usuária confere e ajusta o que saiu a mais ou
a menos, em vez de lembrar do zero. Tabela `servico_produtos_padrao` a criar.

`nome` e `unidade` vêm **resolvidos do item**, não do que o cliente mandou: sem isso a
tela teria que cruzar duas listas só para escrever "2 cx".

### `POST /servicos` — `NOVO`
### `PATCH /servicos/{id}` — `NOVO`

Mesmo corpo nos dois. O `PATCH` **substitui** a lista inteira de produtos padrão — o
app manda o estado final da tela, não um diff:

```json
{ "nome": "Extensão de cílios", "preco": 180.00, "duracao_minutos": 90,
  "produtos_padrao": [
    { "item_estoque_id": "uuid", "quantidade": 1 }
  ] }
```

- `produtos_padrao` é opcional; ausente ou `[]` significa serviço que não consome
  material.
- `item_estoque_id` inexistente ou inativo é **404**, e nada é gravado: material
  fantasma vira uma baixa de estoque que nunca fecha.
- `item_estoque_id` repetido no mesmo corpo é **422** — duas linhas do mesmo item viram
  duas baixas que ninguém confere na hora de finalizar.
- `quantidade` > 0.

### `DELETE /servicos/{id}` — `NOVO`

Serviço já usado em atendimento: soft delete. O snapshot no atendimento preserva nome e
preço históricos.

---

## 9. `alertas` — 7 operações

**O cálculo do alerta é do servidor** (S7). O app não varre listas procurando
`quantidade <= minima`: ele busca alertas prontos. Motivo: a mesma regra tem que valer
para o push e para o n8n, que não passam pelo app.

Tipos de alerta na V1:

| `tipo` | Dispara quando | `severidade` |
|---|---|---|
| `estoque_negativo` | `quantidade_atual < 0` (atendimento/montagem confirmados sem saldo) | `critico` |
| `estoque_critico` | `quantidade_atual == 0` | `critico` |
| `estoque_baixo` | `quantidade_atual <= quantidade_minima` | `alerta` |
| `gasto_a_vencer` | pendente vencendo em ≤7 dias | `alerta` |
| `gasto_vencido` | pendente com prazo passado | `critico` |
| `custo_fixo_a_vencer` | custo fixo da competência corrente **em aberto**, vencendo em ≤7 dias | `alerta` |
| `custo_fixo_vencido` | custo fixo da competência corrente **em aberto** com o dia já passado | `critico` |
| `saldo_negativo` | saldo do mês < 0 no fechamento parcial | `critico` |
| `zero_a_zero` | saldo do mês < limite configurado | `alerta` |
| `agendamento_publico_novo` | cliente marcou um atendimento pelo link (§10) | `info` |

### `GET /alertas` — `NOVO`

Query: `apenas_nao_lidos` (bool), `tipo`, `severidade`.

```json
{
  "total_nao_lidos": 4,
  "resumo": { "critico": 2, "alerta": 2, "info": 0 },
  "alertas": [
    {
      "id": "uuid",
      "tipo": "estoque_critico",
      "severidade": "critico",
      "titulo": "Cola adesiva para cílios acabou",
      "mensagem": "Você está com 0 un. e o mínimo é 2 un.",
      "referencia_tipo": "estoque_item",
      "referencia_id": "uuid",
      "criado_em": "2026-09-01T08:00:00-03:00",
      "lido_em": null
    }
  ]
}
```

`resumo.critico + resumo.alerta` é o número do **badge** no ícone de Estoque, hoje
calculado no cliente (`EstoqueProvider.totalAlertas`).

`referencia_tipo` + `referencia_id` é o que permite tocar no alerta e cair na tela
certa. O app mapeia tipo → rota; o servidor não conhece rotas de UI.

### `PATCH /alertas/{id}/lido` — `NOVO`
### `PATCH /alertas/lidos` — `NOVO`

Marca todos como lidos. Corpo opcional `{ "tipo": "estoque_baixo" }` para marcar só um
recorte.

### `GET /alertas/preferencias` — `NOVO`
### `PUT /alertas/preferencias` — `NOVO`

```json
{
  "limite_saldo_alerta": 150.00,
  "dias_antecedencia_vencimento": 7,
  "canais": {
    "in_app":   { "ativo": true },
    "push":     { "ativo": true },
    "whatsapp": { "ativo": false },
    "email":    { "ativo": false }
  },
  "tipos_silenciados": ["zero_a_zero"]
}
```

`dias_antecedencia_vencimento` vale para **gasto pendente e custo fixo** — é uma
janela só, e uma semana é o padrão: é o prazo que ainda dá tempo de fazer alguma
coisa. (Chamava-se `dias_antecedencia_gasto`, com 3 dias; mudou junto com o custo fixo
ganhar dia de vencimento, e nenhum backend consumia o nome antigo.)

Custo fixo tem par "vencido" porque o servidor **sabe** se ela pagou: o `PATCH
/perfil/custos-fixos/{id}/pagar` (§7) grava a competência. Enquanto o mês corrente
estiver em aberto, o vencimento que conta é o **deste mês**, e ele fica para trás —
isso é `custo_fixo_vencido`. Marcada como paga, a competência para de gerar alerta e o
próximo alvo é o mês seguinte. Mês curto encurta o dia: com `dia_vencimento` 31,
fevereiro avisa no dia 28; o 31 continua guardado.

A **competência entra na chave de dedupe** dos dois tipos: o aluguel de setembro e o de
outubro são dois avisos, e marcar um como lido não pode calar o outro.

`referencia_tipo` é `custo_fixo`, e o app leva para o **Perfil** — é lá que ela marca
como pago ou conserta o valor e o dia, não em Gastos.

Os canais `whatsapp` e `email` já aparecem no contrato, desligados — ver §10.

### `POST /dispositivos` — `NOVO`

```json
{ "token": "fcm-token...", "plataforma": "android", "modelo": "Moto G84" }
```

`plataforma` ∈ `android` · `ios` · `web`. Idempotente por token.

### `DELETE /dispositivos/{token}` — `NOVO`

Chamado no logout — senão a próxima usuária do aparelho recebe alertas alheios.

---

## 10. `agendamento_publico` — 3 operações

**O único módulo sem `Authorization`.** É a tela que o cliente abre pelo link fixo do
salão (§7) para marcar um horário sozinho, sem login — decisões do dono do projeto:

- Link fixo por salão (não por cliente/convite, não expira).
- Cliente pode escolher **múltiplos serviços** no mesmo agendamento, igual ao fluxo
  interno (§2) — a duração do horário bloqueado é a **soma** de `duracao_minutos` de
  cada serviço escolhido.
- **Confirmação automática**: ao escolher um horário livre, o agendamento já entra como
  `agendado` — não existe estado "pendente de aprovação". Isso só é seguro porque
  `horarios-disponiveis` (abaixo) nunca oferece um horário que já colide com outro
  atendimento.

Autenticação: **nenhuma**. O `slug` na URL identifica o salão — não é secreto (a ideia
é ser compartilhável), então nenhum dado sensível do salão pode vazar aqui além do que
já é público num cartão de visita (nome, foto, serviços e preços).

### `GET /agendamento-publico/{slug}` — `NOVO`

```json
{
  "salao": { "nome": "Thamires Borges Beauty", "foto_url": "https://..." },
  "servicos": [
    { "id": "uuid", "nome": "Extensão de cílios", "preco": 180.00, "duracao_minutos": 90 }
  ]
}
```

`slug` inexistente ou salão inativo → `404 RECURSO_NAO_ENCONTRADO`. Não devolve
`telefone_whatsapp`, custo fixo, estoque ou qualquer outro dado do módulo `perfil` —
só o necessário pra montar a tela de agendar.

### `GET /agendamento-publico/{slug}/horarios-disponiveis` — `NOVO`

Query: `data` (date, obrigatório), `servico_ids` (csv de uuid, obrigatório).

```json
{
  "duracao_total_minutos": 150,
  "horarios": ["09:00", "09:30", "10:00", "13:30", "14:00"]
}
```

Cálculo, todo no servidor: pega o expediente do dia da semana de `data` em
`horario_funcionamento` (§7) — dia `ativo: false` devolve `horarios: []` — gera os
slots possíveis a cada 30 min dentro do expediente, e remove os que colidem com
qualquer `atendimento` `agendado`/`finalizado` daquele dia (considerando a duração de
cada um) ou que não caibam antes do fim do expediente com a `duracao_total_minutos`
pedida. `data` no passado → `horarios: []` (não é erro, só não há o que oferecer).

### `POST /agendamento-publico/{slug}/agendar` — `NOVO`

```json
{
  "cliente_nome": "Fernanda",
  "cliente_telefone": "+5511988887777",
  "data": "2026-09-10T14:00:00-03:00",
  "servicos": [{ "servico_id": "uuid" }]
}
```

Cria o `atendimento` direto como `agendado` — mesma regra de preço/serviço congelado
do `POST /atendimentos` (§2), com `origem: "publico"` (ver §14). **O servidor
revalida a disponibilidade na hora de gravar** (não confia no que o `GET
horarios-disponiveis` devolveu segundos atrás — dois clientes podem estar olhando o
mesmo horário ao mesmo tempo): se o horário deixou de estar livre,
`409 HORARIO_INDISPONIVEL` e nada é gravado; o app reconsulta os horários e pede pra
escolher outro. Sem segunda passada tipo A5 — não existe "agendar mesmo assim" contra
a própria agenda.

Ao gravar com sucesso, gera o alerta in-app "novo agendamento pelo link" (módulo
`alertas`, tipo a acrescentar em §9) para a profissional ver na próxima abertura do
app — reaproveita o mesmo canal, não precisa do n8n para isso.

---

## 11. Canais futuros (WhatsApp e e-mail) — mapeados, não implementados

Decisão A3: entram no contrato agora, ligam depois. O n8n já tem os fluxos
(`n8n/fluxo_1_alerta_saldo_mensal.json`, `fluxo_2_resumo_semanal.json`).

| Endpoint | Quem chama | Status |
|---|---|---|
| `GET /interno/alertas-pendentes` | n8n (cron) | `NOVO`, futuro |
| `POST /interno/alertas/{id}/entregue` | n8n, após enviar | `NOVO`, futuro |
| `GET /relatorio/semanal` | n8n (cron semanal) | `EXISTE` |
| `POST /webhooks/confirmacao` | n8n | `EXISTE` |
| `POST /webhooks/acionar-resumo-semanal` | n8n | `EXISTE` |

Autenticação dos `/interno/*` e `/webhooks/*`: secret compartilhado em `X-N8N-Secret`,
como já é feito hoje. **Hoje o secret só é exigido em produção**
(`_validar_n8n` em `api/app/routers/webhooks.py`) — endpoints internos que devolvem dado
da usuária devem exigi-lo em todo ambiente.

---

## 12. Códigos de erro (`AppErrorCodes`)

Todo código aqui tem uma chave correspondente no ARB do app. Código novo no backend sem
entrada aqui = mensagem genérica na tela.

| Código | HTTP | Significado |
|---|---|---|
| `AUTH_CREDENCIAIS_INVALIDAS` | 401 | e-mail ou senha incorretos |
| `AUTH_REFRESH_INVALIDO` | 401 | refresh expirado/revogado → logout |
| `AUTH_TOKEN_AUSENTE` | 401 | requisição sem `Authorization` |
| `VALIDACAO_INVALIDA` | 422 | corpo malformado; `result` traz os campos |
| `RECURSO_NAO_ENCONTRADO` | 404 | id inexistente |
| `ATENDIMENTO_STATUS_INVALIDO` | 409 | operação incompatível com o status atual |
| `ESTOQUE_INSUFICIENTE` | 409 | baixa maior que o saldo; `result.faltantes` lista o que falta. Reenviar com `confirmar_estoque_insuficiente: true` passa por cima (§2 e §6) |
| `KIT_NAO_MONTADO` | 409 | venda maior que `quantidade_montada`; sem confirmação por cima |
| `ITEM_EM_USO` | 409 | exclusão de item/serviço com histórico → use soft delete |
| `GASTO_JA_PAGO` | 409 | reservado; hoje `/pagar` é idempotente e devolve 200 |
| `LIMITE_EXCEDIDO` | 429 | rate limit |
| `HORARIO_INDISPONIVEL` | 409 | agendamento público: horário deixou de estar livre entre a consulta e a gravação (§10) |

Faixas sem código de negócio caem no tratamento genérico do `ErrorModel`: 401/403 →
sessão expirada, 404 → não encontrado, 4xx → erro de requisição, 5xx → erro de servidor,
sem resposta → erro de conexão.

---

## 13. Resumo por módulo

| Módulo | Operações | `EXISTE` | `ALTERAR` | `NOVO` |
|---|---|---|---|---|
| `auth` | 4 | — | — | 4 |
| `atendimentos` | 7 | — | — | 7 |
| `gastos` | 5 | — | — | 5 |
| `resumo` | 2 | 1 | 1 | — |
| `estoque` | 6 | — | — | 6 |
| `kits` | 6 | — | — | 6 |
| `perfil` | 10 | — | — | 10 |
| `servicos` | 4 | — | — | 4 |
| `alertas` | 7 | — | — | 7 |
| `agendamento_publico` | 3 | — | — | 3 |
| n8n / interno | 5 | 3 | — | 2 |
| **Total** | **59** | **4** | **1** | **54** |

## 14. Mudanças necessárias no banco

**O SQL pronto está em [`database/migrations/001_v1_completo.sql`](../database/migrations/001_v1_completo.sql)** — idempotente, executável direto no SQL Editor do Supabase. Esta seção é só o resumo do que ele faz. O agendamento público (§10) ainda **não** tem migration escrita — entra numa `002_agendamento_publico.sql` própria (ver `.specs/pedidos-backend.md`, lote L8).

**Tabelas novas (11):** `perfil_salao` · `estoque_itens` · `estoque_movimentacoes` ·
`kits` · `kit_itens` · `kit_vendas` · `servico_produtos_padrao` · `alertas` ·
`alerta_preferencias` · `dispositivos` · `refresh_tokens`.

**Tabelas novas para o agendamento público (a escrever, lote L8):**

| Tabela/coluna | Para quê |
|---|---|
| `servicos.duracao_minutos` | calcular quanto tempo um agendamento bloqueia na agenda (§8) |
| `horario_funcionamento` (`salao_id`, `dia_semana`, `ativo`, `hora_inicio`, `hora_fim`) | expediente por dia da semana (§7) |
| `salao.slug_agendamento` | URL fixa do link público (§7), único, gerado no cadastro |
| `atendimentos.origem` (`interno` \| `publico`) | diferenciar na lista/alerta quem veio pelo link (§10) |

**Alterações:**

| Tabela | Mudança | Por quê |
|---|---|---|
| `gastos` | `descricao` → `nome` | alinha com o app e com o protótipo |
| `gastos` | `forma_pagamento` passa a `a_vista`/`credito`/`debito`/`pix` | o check atual só aceita `à vista`/`cartão`, com acento e espaço |
| `gastos` | `prioridade` → `categoria` (`fixo`/`material`/`outros`) | o protótipo agrupa por categoria, não por prioridade |
| `gastos` | `+ pago_em timestamptz` | saber *quando* pagou, não só que pagou |
| `atendimentos` | `+ status` (`agendado`/`finalizado`/`cancelado`) | o app já usa; o banco não tem |
| `atendimentos` | `+ finalizado_em`, `+ cancelado_em` | auditoria do que entra no resumo |
| `atendimento_insumos` | `+ item_estoque_id` (fk nulável), `+ quantidade` | ligar o insumo ao estoque; nulável porque insumo avulso continua válido |
| `servicos` | `+ ativo boolean` | soft delete: serviço com histórico não some |

**Sem migração de dados destrutiva.** `forma_pagamento` e `categoria` são convertidos por
`update` a partir dos valores antigos (`'à vista'` → `a_vista`, `'cartão'` → `credito`,
prioridade `alta` → categoria `fixo`), então o que já existe no banco sobrevive.

**RLS** continua ligada como segunda barreira, mas o FastAPI passa a acessar com a
service role e **filtra por usuário derivado do token** — o que só é seguro depois de
corrigir a validação do JWT (§0).
