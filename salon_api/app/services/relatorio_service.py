"""
Serviço de relatório mensal.

Responsabilidade: buscar dados brutos no Supabase e consolidar
em um ResumoMensal pronto para o Flutter consumir.

Regras de negócio (definidas no CONTEXTO_IA.md):
  - saldo_atendimento = totalServicos - totalInsumos
  - saldo_mes = soma(saldo_atendimento) - (custos_fixos + gastos_mes)
  - alerta_zero_a_zero: True quando saldo_final < 100
"""

import calendar
from collections import defaultdict
from supabase import Client

from app.schemas.relatorio import (
    ResumoMensal,
    ResumoReceita,
    ResumoGastos,
    ServicoRanking,
)


async def calcular_resumo_mensal(
    supabase: Client,
    user_id: str,
    ano: int,
    mes: int,
) -> ResumoMensal:
    """
    Consolida todos os dados do mês em um único objeto ResumoMensal.
    Chamado pelo router de relatório e também internamente antes de
    disparar o webhook de alerta de saldo.
    """
    data_inicio, data_fim = _intervalo_mes(ano, mes)

    # ── 1. Atendimentos do mês ─────────────────────────────────────
    resp_atend = (
        supabase.table("atendimentos")
        .select("id")
        .eq("user_id", user_id)
        .gte("data", data_inicio)
        .lte("data", data_fim)
        .execute()
    )
    atendimentos = resp_atend.data or []
    ids_atend = [a["id"] for a in atendimentos]

    total_servicos = 0.0
    total_insumos = 0.0
    contagem_servicos: dict[str, int] = defaultdict(int)
    receita_servicos: dict[str, float] = defaultdict(float)

    if ids_atend:
        # Serviços realizados (com snapshot de preço)
        resp_serv = (
            supabase.table("atendimento_servicos")
            .select("nome_servico, preco_snapshot")
            .in_("atendimento_id", ids_atend)
            .execute()
        )
        for s in resp_serv.data or []:
            total_servicos += float(s["preco_snapshot"])
            contagem_servicos[s["nome_servico"]] += 1
            receita_servicos[s["nome_servico"]] += float(s["preco_snapshot"])

        # Insumos descartáveis usados
        resp_insumos = (
            supabase.table("atendimento_insumos")
            .select("preco")
            .in_("atendimento_id", ids_atend)
            .execute()
        )
        for i in resp_insumos.data or []:
            total_insumos += float(i["preco"])

    liquido_atendimentos = total_servicos - total_insumos

    # ── 2. Ranking de serviços ─────────────────────────────────────
    ranking = sorted(
        [
            ServicoRanking(
                nome=nome,
                quantidade=qtd,
                total_receita=round(receita_servicos[nome], 2),
            )
            for nome, qtd in contagem_servicos.items()
        ],
        key=lambda x: x.quantidade,
        reverse=True,
    )

    # ── 3. Custos fixos (mensais, do perfil) ───────────────────────
    resp_fixos = (
        supabase.table("custos_fixos")
        .select("valor")
        .eq("user_id", user_id)
        .execute()
    )
    total_fixos = sum(float(c["valor"]) for c in (resp_fixos.data or []))

    # ── 4. Gastos variáveis do mês ─────────────────────────────────
    resp_gastos = (
        supabase.table("gastos")
        .select("valor")
        .eq("user_id", user_id)
        .gte("prazo", data_inicio)
        .lte("prazo", data_fim)
        .execute()
    )
    total_gastos_var = sum(float(g["valor"]) for g in (resp_gastos.data or []))

    total_saiu = total_fixos + total_gastos_var

    # ── 5. Consolidação final ──────────────────────────────────────
    saldo_final = round(liquido_atendimentos - total_saiu, 2)

    return ResumoMensal(
        ano=ano,
        mes=mes,
        receita=ResumoReceita(
            total_servicos=round(total_servicos, 2),
            total_insumos=round(total_insumos, 2),
            liquido_atendimentos=round(liquido_atendimentos, 2),
            quantidade_atendimentos=len(ids_atend),
            servicos_mais_realizados=ranking,
        ),
        gastos=ResumoGastos(
            total_custos_fixos=round(total_fixos, 2),
            total_gastos_variaveis=round(total_gastos_var, 2),
            total_saiu=round(total_saiu, 2),
        ),
        saldo_final=saldo_final,
        alerta_zero_a_zero=abs(saldo_final) < 100,
    )


# ── Helpers ────────────────────────────────────────────────────────

def _intervalo_mes(ano: int, mes: int) -> tuple[str, str]:
    """
    Retorna (primeiro_dia_ISO, ultimo_dia_ISO) do mês.
    Ex: (2025, 5) → ("2025-05-01", "2025-05-31")
    """
    ultimo_dia = calendar.monthrange(ano, mes)[1]
    return (
        f"{ano:04d}-{mes:02d}-01",
        f"{ano:04d}-{mes:02d}-{ultimo_dia:02d}",
    )
