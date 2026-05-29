# Fluxos n8n — App de Gestão do Salão

Três fluxos que cobrem toda a camada de automação e notificação do projeto.
Nenhum membro do time precisa escrever código para ajustá-los.

---

## Arquivos

```
salon_n8n/
├── fluxo_1_alerta_saldo_mensal.json   # FastAPI → n8n → proprietária
├── fluxo_2_resumo_semanal.json        # Cron domingo 19h → proprietária
├── fluxo_3_error_handler.json         # Qualquer falha → time de dev
├── n8n_variaveis.env.example          # Todas as variáveis necessárias
├── supabase_perfil_salao.sql          # Tabela extra necessária para os fluxos
└── README.md                          # Este arquivo
```

---

## Visão geral dos fluxos

```
┌─────────────────────────────────────────────────────────────────┐
│ FLUXO 1 — Alerta de saldo mensal                                │
│                                                                 │
│  FastAPI                                                        │
│  (resumo mensal calculado, saldo < R$100)                       │
│      │                                                          │
│      └─→ POST /webhook/alerta-saldo-mensal                      │
│              │                                                  │
│              ├─ Valida secret                                   │
│              ├─ Busca telefone/email no Supabase                │
│              ├─ Formata mensagem (PT-BR, formatação R$)         │
│              ├─ Envia WhatsApp (Evolution) OU Email (SMTP)      │
│              └─ Confirma ao FastAPI (POST /webhooks/confirmacao)│
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ FLUXO 2 — Resumo semanal (cron)                                 │
│                                                                 │
│  Todo domingo às 19h                                            │
│      │                                                          │
│      ├─ Busca todas as proprietárias com notificacoes_ativas    │
│      └─ Para cada uma:                                          │
│          ├─ POST /webhooks/acionar-resumo-semanal               │
│          ├─ Formata mensagem com atendimentos + receita + saldo  │
│          ├─ Envia WhatsApp OU Email                             │
│          └─ Aguarda 3s antes da próxima (rate limit)            │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ FLUXO 3 — Error handler global                                  │
│                                                                 │
│  Qualquer fluxo falha                                           │
│      │                                                          │
│      └─→ Avisa o time de dev (WhatsApp ou email)               │
│          com: fluxo, nó, mensagem de erro, ID da execução       │
└─────────────────────────────────────────────────────────────────┘
```

---

## Pré-requisitos

Antes de importar os fluxos, conclua:

1. **n8n rodando** — self-hosted ou n8n Cloud
2. **FastAPI no ar** — Railway, Render ou Fly.io
3. **Supabase configurado** — schema.sql + supabase_perfil_salao.sql executados
4. **Canal escolhido** — Evolution API (WhatsApp) ou SMTP (e-mail)

---

## Passo a passo de configuração

### 1. Executar o SQL extra no Supabase

```sql
-- Cole o conteúdo de supabase_perfil_salao.sql no SQL Editor do Supabase
-- Isso cria a tabela perfil_salao e o trigger de criação automática de perfil
```

### 2. Configurar variáveis no n8n

Acesse **Settings → Variables** e cadastre todas as variáveis do arquivo
`n8n_variaveis.env.example`. As obrigatórias para qualquer canal:

| Variável | Descrição |
|---|---|
| `CANAL_NOTIFICACAO` | `whatsapp` ou `email` |
| `SUPABASE_URL` | URL do seu projeto Supabase |
| `SUPABASE_ANON_KEY` | Chave anon (para leitura com RLS) |
| `SUPABASE_SERVICE_KEY` | Chave service (para o cron iterar todos os usuários) |
| `FASTAPI_URL` | URL base da sua API, ex: `https://salon-api.railway.app` |
| `N8N_WEBHOOK_SECRET` | String aleatória — mesma do `.env` do FastAPI |

Se **WhatsApp**:

| Variável | Descrição |
|---|---|
| `EVOLUTION_API_URL` | URL da sua Evolution API |
| `EVOLUTION_INSTANCE` | Nome da instância configurada |
| `EVOLUTION_API_KEY` | Chave de autenticação |
| `TELEFONE_DEV` | Número do dev para alertas de erro (formato: `5511999990000`) |

Se **Email**:

| Variável | Descrição |
|---|---|
| `SMTP_FROM` | Remetente, ex: `noreply@seudominio.com` |
| `EMAIL_PROPRIETARIA` | E-mail da proprietária |
| `EMAIL_DEV` | E-mail do time para alertas de erro |

### 3. Configurar credencial SMTP (se usar email)

1. **Settings → Credentials → Add Credential**
2. Tipo: **SMTP**
3. Preencha host, porta, usuário e senha do seu provedor
4. Dê o nome `SMTP Salão` (é o nome referenciado nos fluxos)

Provedores recomendados:
- **Resend** (resend.com) — 3.000 e-mails/mês gratuitos, setup simples
- **Brevo** (brevo.com) — 300 e-mails/dia gratuitos
- **Gmail** — funciona, mas exige app password e tem limite diário

### 4. Importar os fluxos

Para cada arquivo `.json`:

1. **Workflows → Add Workflow → Import from file**
2. Selecione o arquivo `.json`
3. O fluxo abre no editor — revise as posições dos nós
4. **Ative o fluxo** (toggle no canto superior direito)

Ordem recomendada de importação:
1. `fluxo_3_error_handler.json` — ative primeiro
2. `fluxo_1_alerta_saldo_mensal.json`
3. `fluxo_2_resumo_semanal.json`

### 5. Configurar o error handler nos outros fluxos

Após importar todos:

1. Abra o **Fluxo 1**
2. **Settings** (engrenagem no topo) → **Error Workflow**
3. Selecione **"Salão — Tratamento de Erros Global"**
4. Repita para o **Fluxo 2**

### 6. Atualizar o .env do FastAPI

Adicione as variáveis que o FastAPI precisa para chamar o n8n:

```env
# URL do webhook do n8n (copie da URL do nó "Receber alerta do FastAPI")
N8N_BASE_URL=https://seu-n8n.com
N8N_WEBHOOK_ALERTA_SALDO=webhook/alerta-saldo-mensal
N8N_WEBHOOK_RESUMO_SEMANAL=webhook/resumo-semanal

# Secret compartilhado (mesmo valor de N8N_WEBHOOK_SECRET no n8n)
N8N_WEBHOOK_SECRET=troque-por-uma-string-aleatoria-longa
```

> **Atenção:** adicione `N8N_WEBHOOK_SECRET` também ao `Settings` da classe `Settings` em `app/core/config.py`:
> ```python
> n8n_webhook_secret: str = Field(default="", env="N8N_WEBHOOK_SECRET")
> ```

### 7. Testar manualmente

**Fluxo 1 — Alerta de saldo:**
```bash
curl -X POST https://SEU-N8N.com/webhook/alerta-saldo-mensal \
  -H "Content-Type: application/json" \
  -H "X-N8N-Secret: seu-secret-aqui" \
  -d '{
    "user_id": "uuid-de-teste",
    "mes": 5,
    "ano": 2025,
    "saldo_final": 50.00,
    "total_entrou": 1200.00,
    "total_saiu": 1150.00,
    "mensagem": "Teste de alerta"
  }'
```

**Fluxo 2 — Resumo semanal:**
Clique em **"Test workflow"** no editor do n8n — ele executa o cron manualmente.

**Fluxo 3 — Error handler:**
Force um erro desativando o Supabase temporariamente e rodando o Fluxo 1.

---

## Ajuste de fuso horário

O cron do Fluxo 2 usa o fuso do servidor n8n. Para garantir que dispare às 19h de Brasília:

- **n8n self-hosted:** defina `GENERIC_TIMEZONE=America/Sao_Paulo` no `.env` do n8n
- **n8n Cloud:** configure em **Settings → Instance → Timezone**

---

## Estrutura da mensagem gerada

### WhatsApp (Fluxo 1 — Alerta mensal)
```
Oi Ana! 👋 Aqui é o resumo do Studio Bela.

🟡 Resultado de maio/2025

💰 Entrou: R$ 1.200,00
💸 Saiu:   R$ 1.150,00
📊 Saldo:  R$ 50,00

O salão fechou o mês quase no zero a zero.
Que tal avaliar a precificação dos serviços? 💡

_Mensagem automática do app de gestão_
```

### WhatsApp (Fluxo 2 — Resumo semanal)
```
Oi Ana! 👋 Aqui está o resumo da semana do Studio Bela.

📅 Semana 12/05 a 18/05

🪑 Atendimentos realizados: 4
💰 Receita bruta:           R$ 720,00
💸 Gastos pendentes:        R$ 340,00
🟢 Saldo da semana:         R$ 380,00

Semana organizada! Continue assim. 💪

_Mensagem automática — App de Gestão do Salão_
```

---

## Troubleshooting rápido

| Problema | Causa provável | Solução |
|---|---|---|
| Webhook retorna 403 | Secret errado | Verifique `N8N_WEBHOOK_SECRET` no n8n e no FastAPI |
| WhatsApp não envia | Instância desconectada | Reconecte a instância no painel da Evolution API |
| Cron não dispara | Fuso horário errado | Defina `GENERIC_TIMEZONE=America/Sao_Paulo` |
| Telefone vazio | Perfil não preenchido | A proprietária precisa salvar o telefone na tela de Perfil |
| Erro no merge de dados | FastAPI retornou 4xx | Verifique se `N8N_WEBHOOK_SECRET` está correto no FastAPI |
| Email vai para spam | Domínio sem SPF/DKIM | Configure SPF e DKIM no DNS do seu domínio |
