"""
Ponto de entrada da API do salão.

Responsabilidade desta camada:
  - Montar o app FastAPI com CORS, routers e metadata
  - Não conter nenhuma lógica de negócio

Divisão de trabalho (ver CONTEXTO_IA.md):
  - CRUD puro → Supabase REST API (Flutter chama diretamente)
  - Cálculos e relatórios → FastAPI (este serviço)
  - Automações e notificações → n8n (chama esta API via webhooks)
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.routers import relatorio, precificacao, webhooks, health

cfg = get_settings()

app = FastAPI(
    title="Salon API",
    description=(
        "Backend de cálculos e relatórios do app de gestão de salão. "
        "CRUD básico fica no Supabase — este serviço contém apenas "
        "lógica que o Supabase não resolve sozinho."
    ),
    version="1.0.0",
    # Docs desativadas em produção para não expor schema
    docs_url=None if cfg.is_production else "/docs",
    redoc_url=None if cfg.is_production else "/redoc",
)

# ── CORS ───────────────────────────────────────────────────────────
# Flutter (PWA) roda em origem diferente da API
app.add_middleware(
    CORSMiddleware,
    allow_origins=cfg.cors_origins_list,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH", "DELETE"],
    allow_headers=["*"],
)

# ── Routers ────────────────────────────────────────────────────────
app.include_router(health.router)
app.include_router(relatorio.router)
app.include_router(precificacao.router)
app.include_router(webhooks.router)


@app.get("/", include_in_schema=False)
def root():
    return {"servico": "Salon API", "docs": "/docs", "health": "/health"}
