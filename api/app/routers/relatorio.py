"""
Router: /relatorio

Endpoints de consolidação e relatório — a única coisa que mora aqui
é lógica que o Supabase não consegue fazer sozinho: agregações
com múltiplas tabelas, regras de negócio e disparo de alertas.

CRUD puro (criar/editar/apagar atendimento, gasto, etc.) fica
no Supabase REST API — o Flutter chama diretamente.
"""

from fastapi import APIRouter, Depends, Query
from supabase import Client

from app.core.supabase_client import get_supabase, rows
from app.core.security import usuario_atual
from app.schemas.relatorio import ResumoMensal
from app.services.relatorio_service import calcular_resumo_mensal
from app.services.webhook_service import notificar_alerta_saldo

router = APIRouter(prefix="/relatorio", tags=["Relatório"])

# A extração de user_id agora é feita por `usuario_atual` (app/core/security.py),
# que VALIDA a assinatura do JWT com SUPABASE_JWT_SECRET antes de confiar no `sub`.
# O decode manual em base64 que existia aqui não checava assinatura nenhuma:
# qualquer pessoa montava um token com o `sub` de outra usuária e lia a receita
# dela inteira. Esse era o item 🔴 do L0.


# ── GET /relatorio/mensal ──────────────────────────────────────────

@router.get(
    "/mensal",
    response_model=ResumoMensal,
    summary="Resumo financeiro consolidado do mês",
    description=(
        "Agrega atendimentos, insumos, gastos e custos fixos do mês "
        "em um único payload. Chamado pela tela de Resumo do Flutter. "
        "Dispara alerta ao n8n se o saldo ficar no zero a zero."
    ),
)
async def resumo_mensal(
    ano: int = Query(..., ge=2020, le=2100, description="Ano ex: 2025"),
    mes: int = Query(..., ge=1, le=12, description="Mês ex: 5"),
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resumo = await calcular_resumo_mensal(supabase, user_id, ano, mes)

    # Dispara alerta ao n8n em background — não bloqueia a resposta
    await notificar_alerta_saldo(user_id, resumo)

    return resumo


# ── GET /relatorio/semanal ─────────────────────────────────────────

@router.get(
    "/semanal",
    summary="Resumo rápido da semana atual",
    description=(
        "Chamado pelo n8n via cron toda semana. "
        "Retorna atendimentos, receita bruta e gastos pendentes da semana corrente. "
        "O n8n recebe esses dados e envia a notificação para a proprietária."
    ),
)
async def resumo_semanal(
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    from datetime import date, timedelta
    from app.services.webhook_service import notificar_resumo_semanal

    hoje = date.today()
    inicio = hoje - timedelta(days=hoje.weekday())
    fim = inicio + timedelta(days=6)

    # Atendimentos da semana
    resp_atend = (
        supabase.table("atendimentos")
        .select("id")
        .eq("user_id", user_id)
        .gte("data", inicio.isoformat())
        .lte("data", fim.isoformat())
        .execute()
    )
    ids_atend = [str(a["id"]) for a in rows(resp_atend.data)]

    receita_bruta = 0.0
    if ids_atend:
        resp_serv = (
            supabase.table("atendimento_servicos")
            .select("preco_snapshot")
            .in_("atendimento_id", ids_atend)
            .execute()
        )
        receita_bruta = sum(float(s["preco_snapshot"]) for s in rows(resp_serv.data))

    # Gastos pendentes da semana
    resp_gastos = (
        supabase.table("gastos")
        .select("valor")
        .eq("user_id", user_id)
        .eq("pago", False)
        .gte("prazo", inicio.isoformat())
        .lte("prazo", fim.isoformat())
        .execute()
    )
    gastos_pendentes = sum(float(g["valor"]) for g in rows(resp_gastos.data))

    await notificar_resumo_semanal(
        user_id=user_id,
        atendimentos=len(ids_atend),
        receita_bruta=receita_bruta,
        gastos_pendentes=gastos_pendentes,
    )

    return {
        "semana_inicio": inicio.isoformat(),
        "semana_fim": fim.isoformat(),
        "atendimentos": len(ids_atend),
        "receita_bruta": round(receita_bruta, 2),
        "gastos_pendentes": round(gastos_pendentes, 2),
        "saldo_semana": round(receita_bruta - gastos_pendentes, 2),
    }
