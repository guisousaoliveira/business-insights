# Salon API — FastAPI

Backend de cálculos e relatórios do app de gestão para salão de beleza.

## Princípio central

> **Este serviço é deliberadamente enxuto.**
> CRUD puro (atendimento, gasto, perfil, serviço) fica no Supabase REST API — o Flutter chama diretamente.
> O FastAPI entra apenas quando há lógica que o Supabase não resolve: agregações multi-tabela, cálculos de precificação e disparo de webhooks para o n8n.

---

## Estrutura

```
salon_api/
├── app/
│   ├── main.py                     # FastAPI app + CORS + routers
│   ├── core/
│   │   ├── config.py               # Settings via pydantic-settings + .env
│   │   ├── supabase_client.py      # Cliente singleton (service key)
│   │   └── n8n_client.py           # Disparo de webhooks ao n8n
│   ├── schemas/
│   │   ├── relatorio.py            # Pydantic models entrada/saída
│   │   └── webhook.py              # Payloads enviados ao n8n
│   ├── services/
│   │   ├── relatorio_service.py    # Consolida resumo mensal do Supabase
│   │   ├── precificacao_service.py # Cálculo de preço mínimo (puro)
│   │   └── webhook_service.py      # Orquestra alertas ao n8n
│   └── routers/
│       ├── relatorio.py            # GET /relatorio/mensal, /relatorio/semanal
│       ├── precificacao.py         # POST /precificacao/calcular
│       ├── webhooks.py             # POST /webhooks/* (n8n → FastAPI)
│       └── health.py               # GET /health
├── supabase/
│   └── schema.sql                  # SQL completo com RLS e índices
├── tests/
│   ├── test_precificacao.py        # Testes unitários de cálculo (sem banco)
│   └── test_relatorio_service.py   # Testes com mock do Supabase
├── .env.example                    # Variáveis de ambiente necessárias
├── Dockerfile
└── requirements.txt
```

---

## Setup local

```bash
# 1. Clone e entre na pasta
cd salon_api

# 2. Ambiente virtual
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate

# 3. Dependências
pip install -r requirements.txt

# 4. Variáveis de ambiente
cp .env.example .env
# Edite .env com suas credenciais do Supabase

# 5. Rode
uvicorn app.main:app --reload --port 8000
```

Acesse: http://localhost:8000/docs

---

## Endpoints

### `GET /relatorio/mensal?ano=2025&mes=5`
Consolida atendimentos, insumos, gastos e custos fixos do mês.
Chamado pela tela de Resumo do Flutter.
Dispara webhook ao n8n se saldo < R$100.

**Header obrigatório:** `Authorization: Bearer <supabase_jwt>`

**Resposta:**
```json
{
  "ano": 2025,
  "mes": 5,
  "receita": {
    "total_servicos": 450.0,
    "total_insumos": 35.0,
    "liquido_atendimentos": 415.0,
    "quantidade_atendimentos": 3,
    "servicos_mais_realizados": [
      {"nome": "Extensão de cílios", "quantidade": 2, "total_receita": 360.0}
    ]
  },
  "gastos": {
    "total_custos_fixos": 1348.0,
    "total_gastos_variaveis": 635.0,
    "total_saiu": 1983.0
  },
  "saldo_final": -1568.0,
  "alerta_zero_a_zero": true
}
```

---

### `POST /precificacao/calcular?preco_atual=180`
Calcula o preço mínimo de um serviço e diagnostica se está no prejuízo.

**Body:**
```json
{
  "custo_material": 32.0,
  "tempo_minutos": 120,
  "meta_hora": 50.0,
  "percentual_overhead": 0.30,
  "percentual_lucro": 0.20
}
```

**Resposta:**
```json
{
  "custo_material": 32.0,
  "custo_tempo": 100.0,
  "custo_overhead": 39.60,
  "custo_total": 171.60,
  "preco_minimo": 205.92,
  "preco_sugerido": 210.0,
  "cobrindo_custos": false,
  "preco_atual": 180.0,
  "diferenca": -25.92
}
```

---

### `GET /relatorio/semanal`
Chamado pelo n8n via cron. Retorna resumo da semana e dispara notificação.

### `GET /health`
Verifica conectividade com o Supabase. Usado pelo orquestrador de deploy.

### `POST /webhooks/confirmacao`
O n8n confirma que processou uma notificação com sucesso.

### `POST /webhooks/acionar-resumo-semanal`
O n8n aciona o recálculo semanal via cron job.

---

## Banco de dados (Supabase)

Execute `supabase/schema.sql` no SQL Editor do Supabase Dashboard.

O SQL cria:
- 6 tabelas com constraints e checks
- RLS habilitado em todas (usuária só vê seus dados)
- Políticas por `auth.uid()`
- Índices nas colunas mais consultadas pelo FastAPI

---

## Testes

```bash
pytest tests/ -v
```

Os testes de precificação rodam sem dependências externas.
Os testes de relatório usam mock do Supabase — também sem banco.

---

## Deploy

```bash
# Docker
docker build -t salon-api .
docker run -p 8000:8000 --env-file .env salon-api
```

**Railway / Render:** aponte para o repositório, configure as variáveis do `.env.example` no painel e o Dockerfile é detectado automaticamente.

---

## Fluxo de dados completo

```
Flutter
  │
  ├─── CRUD (atendimento, gasto, perfil) ──→ Supabase REST API
  │                                               │
  │                                          PostgreSQL + RLS
  │
  └─── Relatório / Precificação ───────────→ FastAPI
                                                 │
                                    ┌────────────┴──────────────┐
                               Supabase SDK               n8n webhook
                            (lê dados p/ cálculo)    (alerta zero a zero)
                                                              │
                                                    WhatsApp / Email
```
