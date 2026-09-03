# Thamires Borges Beauty — business-insights

App de gestão financeira para um salão de beleza de uma profissional autônoma.
Responde a uma pergunta só, de várias formas: **"eu estou ganhando ou perdendo
dinheiro?"** — por atendimento, por mês, por serviço.

São três peças, e cada uma roda sozinha:

| Pasta | O que é | Quando você mexe |
|---|---|---|
| `api/` | FastAPI — o **único** backend que os front-ends enxergam (A1) | backend, contrato |
| `frontend/salao_app/` | Flutter — só **Android/iOS** (A10) | o app do dia a dia |
| `frontend/salao_web/` | React (TanStack Start) — a **web** (A10) | fechar as contas no navegador |

Contexto, decisões de arquitetura (A1–A10) e estado da migração: [CLAUDE.md](CLAUDE.md).
Contrato da API: [`.specs/endpoints-backend.md`](.specs/endpoints-backend.md).

---

## Dois jeitos de rodar os front-ends

Os dois front-ends têm **modo demo**: um servidor falso em memória por trás do mesmo
transporte. O app fica navegável de ponta a ponta **sem o FastAPI no ar**, e nada é
gravado — cada front-end tem seu próprio banco em memória, independente do outro.

Use a demo para mexer em tela; use a API real para mexer em contrato.

> **Hoje só a demo cobre o app inteiro.** Apenas 4 dos 53 endpoints existem (fase F4,
> ver [`.specs/pedidos-backend.md`](.specs/pedidos-backend.md)), então contra a API real
> a maioria das telas ainda não tem com quem falar.

### 🎭 Com mock (modo demo)

```bash
npm --prefix frontend/salao_web run dev:demo
```

```bash
cd frontend/salao_app && flutter run --dart-define-from-file=env/demo.json
```

Login: **qualquer** e-mail e senha entram. A senha `errada` devolve
`AUTH_CREDENCIAIS_INVALIDAS`, para testar o caminho de erro. A tela de login mostra um
aviso âmbar enquanto o modo está ligado.

### 🔌 Puxando a API direto

Primeiro suba o backend (seção abaixo). Depois:

```bash
npm --prefix frontend/salao_web run dev
```

```bash
cd frontend/salao_app && flutter run --dart-define-from-file=env/dev.json
```

Na web, `npm run dev` lê o `.env` — copie o exemplo uma vez:

```bash
cp frontend/salao_web/.env.example frontend/salao_web/.env
```

No Flutter, o arquivo de `env/` é que escolhe o backend:

| Arquivo | `API_BASE_URL` |
|---|---|
| `env/demo.json` | ignorado — `DEMO_MODE: true` |
| `env/dev.json` | `http://localhost:8000/v1` |
| `env/hml.json` | `https://api.hml.thamiresbeauty.com.br/v1` |
| `env/prod.json` | `https://api.thamiresbeauty.com.br/v1` |

> **Emulador Android não enxerga `localhost`** — ele é o próprio emulador. Para bater no
> FastAPI da sua máquina, rode com o IP de host do emulador:
> `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/v1`
> (no iOS Simulator e em device físico na mesma rede, use `localhost` ou o IP da máquina).

---

## Backend (FastAPI)

```bash
cd api
python -m venv venv
venv\Scripts\activate          # Linux/macOS: source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env            # preencha as credenciais do Supabase
uvicorn app.main:app --reload --port 8000
```

Sobe em `http://localhost:8000` — que é a `API_BASE_URL` que os dois front-ends esperam
em dev. Docs interativas em `http://localhost:8000/docs`.

O `.env` precisa listar em `CORS_ORIGINS` a origem que o `vite dev` imprimir no terminal,
senão a web apanha do navegador antes de chegar na API.

O SQL do banco está em `database/migrations/` e **ainda não foi executado** no Supabase.

---

## Portões antes de fechar qualquer mudança

Rode os do lado que você tocou.

```bash
cd frontend/salao_app && flutter analyze && dart format --set-exit-if-changed . && flutter test
```

```bash
npm --prefix frontend/salao_web run typecheck && npm --prefix frontend/salao_web run lint && npm --prefix frontend/salao_web run build
```

```bash
cd api && pytest
```

---

## Uma mudança de contrato mexe nos dois front-ends

`frontend/salao_web/src/lib/api/paths.ts` e
`frontend/salao_app/lib/settings/app_api.dart` são espelhos. Deixar um para depois é
como o contrato diverge. E se falta endpoint, ele entra em
[`.specs/endpoints-backend.md`](.specs/endpoints-backend.md) **antes** de existir código
que o chame.

`frontend/salao_web` está conectado ao Lovable: nunca reescreva histórico já publicado
(sem force-push, rebase, amend ou squash de commit enviado).
