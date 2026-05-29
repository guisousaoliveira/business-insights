"""
Router: /webhooks

Endpoints que o n8n chama de volta no FastAPI.
Isso é o canal inverso: n8n → FastAPI (ao contrário do fluxo normal).

Casos de uso:
  - n8n terminou de processar algo e quer confirmar
  - n8n quer acionar um recálculo agendado
  - futuramente: receber confirmação de leitura de mensagem WhatsApp

Autenticação: secret compartilhado no header X-N8N-Secret.
Simples e suficiente para comunicação interna entre serviços.
"""

from fastapi import APIRouter, Header, HTTPException, Depends
from supabase import Client
from pydantic import BaseModel

from app.core.supabase_client import get_supabase
from app.core.config import get_settings

router = APIRouter(prefix="/webhooks", tags=["Webhooks n8n"])


def _validar_n8n(x_n8n_secret: str | None = Header(default=None)) -> None:
    """
    Valida que a requisição veio do n8n usando um secret compartilhado.
    Configure N8N_WEBHOOK_SECRET no .env e no n8n (Header node).
    """
    cfg = get_settings()
    # Se não tiver secret configurado, só bloqueia em produção
    secret_esperado = getattr(cfg, "n8n_webhook_secret", None)
    if cfg.is_production and secret_esperado and x_n8n_secret != secret_esperado:
        raise HTTPException(status_code=403, detail="Secret inválido")


class ConfirmacaoN8N(BaseModel):
    user_id: str
    evento: str
    mensagem: str | None = None


@router.post(
    "/confirmacao",
    summary="Recebe confirmação de processamento do n8n",
    description="O n8n chama este endpoint após processar um alerta ou resumo com sucesso.",
    dependencies=[Depends(_validar_n8n)],
)
async def receber_confirmacao(payload: ConfirmacaoN8N):
    """
    Ponto de entrada para o n8n confirmar que processou uma notificação.
    Hoje apenas loga — futuramente pode marcar no banco que o usuário recebeu.
    """
    import logging
    logging.getLogger(__name__).info(
        "Confirmação n8n recebida: user=%s evento=%s msg=%s",
        payload.user_id,
        payload.evento,
        payload.mensagem,
    )
    return {"status": "recebido"}


@router.post(
    "/acionar-resumo-semanal",
    summary="n8n aciona o recálculo do resumo semanal",
    description=(
        "O n8n usa este endpoint em seu cron job semanal. "
        "FastAPI recalcula e devolve os dados para o n8n formatar e enviar."
    ),
    dependencies=[Depends(_validar_n8n)],
)
async def acionar_resumo_semanal(
    user_id: str,
    supabase: Client = Depends(get_supabase),
):
    """
    Delegado ao router de relatório para evitar duplicação de lógica.
    O n8n chama aqui; este endpoint chama o service de relatório.
    """
    from datetime import date, timedelta

    hoje = date.today()
    inicio = hoje - timedelta(days=hoje.weekday())
    fim = inicio + timedelta(days=6)

    resp_atend = (
        supabase.table("atendimentos")
        .select("id")
        .eq("user_id", user_id)
        .gte("data", inicio.isoformat())
        .lte("data", fim.isoformat())
        .execute()
    )
    ids_atend = [a["id"] for a in (resp_atend.data or [])]

    receita_bruta = 0.0
    if ids_atend:
        resp_serv = (
            supabase.table("atendimento_servicos")
            .select("preco_snapshot")
            .in_("atendimento_id", ids_atend)
            .execute()
        )
        receita_bruta = sum(float(s["preco_snapshot"]) for s in (resp_serv.data or []))

    resp_gastos = (
        supabase.table("gastos")
        .select("valor")
        .eq("user_id", user_id)
        .eq("pago", False)
        .gte("prazo", inicio.isoformat())
        .lte("prazo", fim.isoformat())
        .execute()
    )
    gastos_pendentes = sum(float(g["valor"]) for g in (resp_gastos.data or []))

    return {
        "user_id": user_id,
        "semana_inicio": inicio.isoformat(),
        "semana_fim": fim.isoformat(),
        "atendimentos": len(ids_atend),
        "receita_bruta": round(receita_bruta, 2),
        "gastos_pendentes": round(gastos_pendentes, 2),
        "saldo_semana": round(receita_bruta - gastos_pendentes, 2),
    }
