# Entrega ao backend — leia este arquivo primeiro

Ponto único de entrada. Tudo que o time de backend precisa está listado aqui; os
outros arquivos são o detalhe de cada item.

**Situação:** o app Flutter está pronto (web, Android e iOS). O backend responde
**4 das 52 operações** que o app chama — apontado para a API real, o app abre no
login e para ali.

Para ver as telas funcionando antes do backend existir, há um **modo demo**: um
servidor falso em memória por trás das mesmas interfaces de repository.

```bash
flutter run -d chrome --dart-define-from-file=env/demo.json
```

Entra com qualquer e-mail e senha. Ele **não substitui o backend** — serve de
espelho: as regras 1 a 7 da seção 3 estão implementadas nele em Dart
(`lib/repositories/demo/demo_database.dart`) e cobertas por 18 testes, então dá
para ler o comportamento esperado em código executável, e comparar payload por
payload com o que o FastAPI devolver.

---

## 1. O pacote — os 5 arquivos que você entrega

Nesta ordem. Quem recebe lê nesta ordem.

| # | Arquivo | O que é |
|---|---|---|
| 1 | [`.specs/00-ENTREGA-BACKEND.md`](00-ENTREGA-BACKEND.md) | **este arquivo** — índice, lista das 52 rotas, regras que não se negociam |
| 2 | [`.specs/pedidos-backend.md`](pedidos-backend.md) | **ordem de serviço**: o que implementar, em que ordem (L0→L7), e o critério de aceite de cada lote |
| 3 | [`.specs/endpoints-backend.md`](endpoints-backend.md) | **contrato**: request e response de cada uma das 52 operações, envelope, códigos de erro |
| 4 | [`database/migrations/001_v1_completo.sql`](../database/migrations/001_v1_completo.sql) | **schema**: 11 tabelas novas + ajustes. Idempotente, roda direto no SQL Editor do Supabase |
| 5 | [`database/migrations/002_seed_teste.sql`](../database/migrations/002_seed_teste.sql) | dados de teste. **Só dev/homolog** |

Contexto opcional, se a pessoa for mexer no app também:
[`CLAUDE.md`](../CLAUDE.md) — decisões de arquitetura A1–A8.

---

## 2. As 52 operações

Prefixo de todas: **`/v1`**. `EXISTE` = já implementado hoje.

### `auth` — 4 · todas novas · **bloqueia todo o resto**

```
POST   /auth/login
POST   /auth/refresh
POST   /auth/logout
GET    /auth/eu
```

### `atendimentos` — 7 · todas novas

```
GET    /atendimentos
POST   /atendimentos
GET    /atendimentos/{id}
PATCH  /atendimentos/{id}
PATCH  /atendimentos/{id}/finalizar     <- dá baixa no estoque (regra 1)
PATCH  /atendimentos/{id}/cancelar      <- estorna a baixa
DELETE /atendimentos/{id}
```

### `gastos` — 5 · todas novas

```
GET    /gastos                          <- devolve total_pendente / total_pago / total_geral
POST   /gastos
PATCH  /gastos/{id}
PATCH  /gastos/{id}/pagar               <- idempotente: pagar 2x devolve 200
DELETE /gastos/{id}
```

### `resumo` — 2 · 1 alterar, 1 existe

```
GET    /resumo/mensal?ano&mes           <- ALTERAR: hoje é GET /relatorio/mensal
POST   /precificacao/calcular           <- EXISTE, fica como está
```

### `estoque` — 6 · todas novas

```
GET    /estoque/itens                   <- status e deficit vêm do banco, não do Python
POST   /estoque/itens
PATCH  /estoque/itens/{id}
DELETE /estoque/itens/{id}
POST   /estoque/itens/{id}/movimentacoes  <- recalcula custo_medio (regra 2)
GET    /estoque/movimentacoes
```

### `kits` — 6 · todas novas

```
GET    /kits                            <- quantidade_montada e quantidade_montavel
POST   /kits
PATCH  /kits/{id}
DELETE /kits/{id}
POST   /kits/{id}/montar                <- consome insumo, duas passadas (regra 1)
POST   /kits/{id}/vender                <- baixa do montado, sem segunda passada
```

### `perfil` — 6 · todas novas

```
GET    /perfil
PUT    /perfil
GET    /perfil/custos-fixos             <- devolve total_mensal somado
POST   /perfil/custos-fixos
PATCH  /perfil/custos-fixos/{id}
DELETE /perfil/custos-fixos/{id}
```

### `servicos` — 4 · todas novas

```
GET    /servicos                        <- com produtos_padrao de cada serviço
POST   /servicos
PATCH  /servicos/{id}
DELETE /servicos/{id}                   <- soft delete se já foi usado
```

### `alertas` — 7 · todas novas

```
GET    /alertas                         <- devolve total_nao_lidos e resumo (o badge)
PATCH  /alertas/{id}/lido
PATCH  /alertas/lidos
GET    /alertas/preferencias
PUT    /alertas/preferencias
POST   /dispositivos                    <- idempotente por token (push)
DELETE /dispositivos/{token}            <- no logout
```

### n8n / interno — 5 · 3 existem

```
GET    /relatorio/semanal               <- EXISTE
POST   /webhooks/confirmacao            <- EXISTE
POST   /webhooks/acionar-resumo-semanal <- EXISTE
GET    /interno/alertas-pendentes       <- novo, pode esperar
POST   /interno/alertas/{id}/entregue   <- novo, pode esperar
```

---

## 3. As 7 regras que o app já assume

O app está escrito e testado contra estes formatos. Mudar qualquer um deles
quebra tela, não só payload.

**1. Estoque insuficiente avisa, não bloqueia — em duas passadas.**
Vale para `PATCH /atendimentos/{id}/finalizar` e `POST /kits/{id}/montar`.

```
1ª chamada  { ..., "confirmar_estoque_insuficiente": false }
   sem saldo -> 409 ESTOQUE_INSUFICIENTE, NADA gravado (nem parcialmente),
                result.faltantes: [{ nome, solicitada, disponivel, deficit }]

   -> o app mostra "Finalizar mesmo assim?" com essa lista

2ª chamada  { ..., "confirmar_estoque_insuficiente": true }
   -> grava, saldo fica negativo, movimentacao.forcada = true, gera alerta
```

Sem `result.faltantes` o aviso aparece sem dizer o que falta. O `true` libera
**só** a checagem de saldo — status inválido e material inexistente continuam
recusando.

**2. Custo do item é média ponderada móvel.** A cada `entrada` com `custo_unitario`:

```
custo_medio = (saldo × custo_medio + qtd × custo_unitario) ÷ (saldo + qtd)
```

Com `saldo <= 0`, o custo novo é o `custo_unitario` da entrada. `saida` e
`ajuste` não tocam no custo. Os campos são **`custo_medio` e
`custo_ultima_compra`** — `custo_unitario` como campo do item não existe mais.

**3. Kit montado e kit vendido são fatos separados.** `GET /kits` devolve
`quantidade_montada` (pronto para vender) e `quantidade_montavel` (o que o
estoque cobre). O botão "Vender" fica desabilitado quando `quantidade_montada` é
0. Vender mais do que está montado é `409 KIT_NAO_MONTADO`, **sem** segunda
passada — um kit que não foi montado não existe para vender.

**4. `status: "negativo"`** em `GET /estoque/itens` quando `quantidade_atual < 0`.
Se vier `critico`, "acabou" e "devo mais do que tenho" viram a mesma coisa na
tela.

**5. Kit no resumo:** `receita.total_kits`, `quantidade_kits_vendidos` e
`custo_kits_vendidos`. O custo do kit **não** entra em `saiu` — ele já saiu
quando o insumo foi comprado; contar de novo é contar o mesmo dinheiro duas
vezes.

**6. O servidor entrega número pronto.** Totais, status, margem, badge, déficit.
O app não soma lista nem recalcula regra de negócio em lugar nenhum.

**7. Erro de negócio se identifica por `codigo`, nunca por texto.** Os 11 códigos:
`AUTH_CREDENCIAIS_INVALIDAS` · `AUTH_REFRESH_INVALIDO` · `AUTH_TOKEN_AUSENTE` ·
`VALIDACAO_INVALIDA` · `RECURSO_NAO_ENCONTRADO` · `ATENDIMENTO_STATUS_INVALIDO` ·
`ESTOQUE_INSUFICIENTE` · `KIT_NAO_MONTADO` · `ITEM_EM_USO` · `GASTO_JA_PAGO` ·
`LIMITE_EXCEDIDO`. Código novo sem entrada no app = mensagem genérica na tela.

---

## 4. O envelope

Toda resposta, sucesso ou falha, sai assim:

```json
{ "total": 12, "mensagem": "ok", "codigo": null, "result": {} }
```

Um `exception_handler` global cobre `HTTPException`, `RequestValidationError` e
`Exception`. Forçar um 500 e conferir que a resposta ainda tem as 4 chaves é o
teste.

Outras convenções: datas em ISO-8601 com timezone · dinheiro em `number` com 2
casas · enums em string · `404` (não `403`) em id de outra usuária, para não
confirmar que o registro existe.

---

## 5. 🔴 A correção de segurança que vem antes de tudo

`api/app/routers/relatorio.py::_extrair_user_id` decodifica o JWT em base64 e
confia no `sub` **sem verificar a assinatura**. Enquanto o Flutter falava direto
com o Supabase, a RLS segurava. Agora o FastAPI é a única barreira: qualquer
pessoa monta um token com o `sub` da usuária e lê a receita dela inteira.

Trocar por validação real com `SUPABASE_JWT_SECRET`, virar uma
`Depends(usuario_atual)` usada por **todo** endpoint autenticado, e **nunca**
aceitar `user_id` vindo do corpo ou da query.

---

## 6. Ordem de execução

Detalhe e critério de aceite de cada lote em
[`pedidos-backend.md`](pedidos-backend.md).

| Lote | O que é | Destrava |
|---|---|---|
| **L0** | migration · **JWT** 🔴 · envelope · auth | tudo |
| **L1** | `servicos` · `perfil` | Perfil e o formulário de atendimento |
| **L2** | `atendimentos` · `gastos` | o uso diário |
| **L3** | `estoque` + baixa na finalização | a maior lacuna: não existe nada hoje |
| **L4** | `kits` (montar e vender) | revenda |
| **L5** | `resumo/mensal` | os números que ela olha primeiro |
| **L6** | `alertas` + push | badge e central (push depende do Firebase) |
| **L7** | endpoints internos do n8n | pode esperar |

---

## 7. Ambiente

Novas variáveis em `api/.env`:

```bash
SUPABASE_JWT_SECRET=...     # Dashboard > Settings > API > JWT Secret
N8N_SECRET=...              # já existe; passa a ser exigido em TODO ambiente
FCM_SERVER_KEY=...          # só no L6
```

A API precisa servir sob o prefixo **`/v1`** e liberar **CORS** para a origem do
Flutter web. O app aponta para o backend por arquivo de ambiente:

```bash
flutter run -d chrome --dart-define-from-file=env/dev.json
```

`env/dev.json` já está em `http://localhost:8000/v1`.

---

## 8. Usuário de teste

Criar no **Supabase Dashboard > Authentication > Users > Add user**, com "Auto
Confirm User" marcado:

```
e-mail: teste@salao.app
senha:  Salao@2026
```

Copiar o UUID gerado por cima de `COLE-O-UUID-AQUI` em `002_seed_teste.sql`,
rodar `001_v1_completo.sql` e depois `002_seed_teste.sql`.

O login só funciona depois do **L0.4** (`POST /auth/login`).

---

## 9. Pronto quando

Um lote está pronto quando a **tela do app funciona de ponta a ponta** contra o
servidor real — não quando o endpoint responde 200 no Swagger.

| Tela | Precisa de |
|---|---|
| Login | `POST /auth/login`, `GET /auth/eu` |
| Resumo | `GET /resumo/mensal`, `GET /alertas` |
| Atendimentos | CRUD `/atendimentos` + `/finalizar` + `/cancelar`, `GET /servicos`, `GET /estoque/itens` |
| Gastos | CRUD `/gastos` + `/pagar` |
| Estoque | CRUD `/estoque/itens`, `/movimentacoes`, `GET /kits`, `/montar`, `/vender` |
| Perfil | `GET/PUT /perfil`, CRUD `/perfil/custos-fixos`, CRUD `/servicos`, `/alertas/preferencias` |
| Central de alertas | `GET /alertas`, `PATCH /alertas/{id}/lido`, `PATCH /alertas/lidos` |
