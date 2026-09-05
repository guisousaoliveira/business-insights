"""Serviço de gastos (endpoints-backend.md §3)."""

from datetime import date, datetime, timezone
import calendar
from fastapi import HTTPException
from supabase import Client

from typing import cast
from app.core.supabase_client import row, rows
from app.schemas.gastos import (
    GastoIn,
    GastoPatchIn,
    GastoPagarIn,
    GastoOut,
    FormaPagamento,
    CategoriaGasto,
)


def _converter_linha_para_gasto_out(linha: dict) -> GastoOut:
    prazo_str = linha.get("prazo")
    if isinstance(prazo_str, str):
        prazo_data = date.fromisoformat(prazo_str)
    elif isinstance(prazo_str, date):
        prazo_data = prazo_str
    else:
        prazo_data = date.today()

    hoje = date.today()
    vence_em_dias = (prazo_data - hoje).days

    pago_em_val = linha.get("pago_em")
    if isinstance(pago_em_val, str):
        try:
            pago_em_dt = datetime.fromisoformat(pago_em_val)
        except Exception:
            pago_em_dt = None
    elif isinstance(pago_em_val, datetime):
        pago_em_dt = pago_em_val
    else:
        pago_em_dt = None

    forma_pg = linha.get("forma_pagamento") or "a_vista"
    cat = linha.get("categoria") or "outros"

    return GastoOut(
        id=str(linha["id"]),
        nome=str(linha.get("nome") or linha.get("descricao", "")),
        valor=float(linha["valor"]),
        prazo_pagamento=prazo_data,
        forma_pagamento=cast(FormaPagamento, forma_pg),
        categoria=cast(CategoriaGasto, cat),
        pago=bool(linha.get("pago", False)),
        pago_em=pago_em_dt,
        vence_em_dias=vence_em_dias,
        itens=linha.get("itens") or [],
    )


def _buscar_gasto(supabase: Client, user_id: str, gasto_id: str) -> dict:
    resp = (
        supabase.table("gastos")
        .select("*")
        .eq("user_id", user_id)
        .eq("id", gasto_id)
        .execute()
    )
    linhas = rows(resp.data)
    if not linhas:
        raise HTTPException(
            status_code=404,
            detail={"codigo": "RECURSO_NAO_ENCONTRADO", "mensagem": "Gasto não encontrado"},
        )
    return linhas[0]


def listar_gastos(
    supabase: Client,
    user_id: str,
    mes: int | None = None,
    ano: int | None = None,
    pago: bool | None = None,
    categoria: str | None = None,
    pagina: int = 1,
    tamanho: int = 50,
) -> dict:
    hoje = date.today()
    alvo_ano = ano or hoje.year
    alvo_mes = mes or hoje.month
    ultimo_dia = calendar.monthrange(alvo_ano, alvo_mes)[1]
    data_inicio_mes = f"{alvo_ano:04d}-{alvo_mes:02d}-01"
    data_fim_mes = f"{alvo_ano:04d}-{alvo_mes:02d}-{ultimo_dia:02d}"

    # Query principal filtrada
    query = supabase.table("gastos").select("*").eq("user_id", user_id)

    if mes and ano:
        query = query.gte("prazo", data_inicio_mes).lte("prazo", data_fim_mes)
    elif ano:
        query = query.gte("prazo", f"{ano:04d}-01-01").lte("prazo", f"{ano:04d}-12-31")

    if pago is not None:
        query = query.eq("pago", pago)
    if categoria:
        query = query.eq("categoria", categoria)

    offset = (pagina - 1) * tamanho
    resp_linhas = (
        query.order("pago")
        .order("prazo")
        .range(offset, offset + tamanho - 1)
        .execute()
    )
    linhas = rows(resp_linhas.data)

    # Totais agregados:
    # 1. Total pendente geral (gastos não pagos)
    resp_pendentes = (
        supabase.table("gastos")
        .select("valor")
        .eq("user_id", user_id)
        .eq("pago", False)
        .execute()
    )
    total_pendente = sum(float(g["valor"]) for g in rows(resp_pendentes.data))

    # 2. Total pago no mês
    resp_pagos_mes = (
        supabase.table("gastos")
        .select("valor")
        .eq("user_id", user_id)
        .eq("pago", True)
        .gte("prazo", data_inicio_mes)
        .lte("prazo", data_fim_mes)
        .execute()
    )
    total_pago_mes = sum(float(g["valor"]) for g in rows(resp_pagos_mes.data))

    gastos_out = [_converter_linha_para_gasto_out(linha) for linha in linhas]

    return {
        "total_pendente": round(total_pendente, 2),
        "total_pago_mes": round(total_pago_mes, 2),
        "gastos": gastos_out,
    }


def criar_gasto(supabase: Client, user_id: str, body: GastoIn) -> GastoOut:
    dados_insert = {
        "user_id": user_id,
        "nome": body.nome,
        "valor": body.valor,
        "prazo": body.prazo_pagamento.isoformat(),
        "forma_pagamento": body.forma_pagamento,
        "categoria": body.categoria,
        "pago": body.pago,
        "pago_em": body.pago_em.isoformat() if body.pago_em else (datetime.now(timezone.utc).isoformat() if body.pago else None),
    }
    resp = supabase.table("gastos").insert(dados_insert).execute()
    linha_criada = row(resp.data)
    return _converter_linha_para_gasto_out(linha_criada)


def editar_gasto(supabase: Client, user_id: str, gasto_id: str, body: GastoPatchIn) -> GastoOut:
    _buscar_gasto(supabase, user_id, gasto_id)
    campos = {}
    if body.nome is not None:
        campos["nome"] = body.nome
    if body.valor is not None:
        campos["valor"] = body.valor
    if body.prazo_pagamento is not None:
        campos["prazo"] = body.prazo_pagamento.isoformat()
    if body.forma_pagamento is not None:
        campos["forma_pagamento"] = body.forma_pagamento
    if body.categoria is not None:
        campos["categoria"] = body.categoria
    if body.pago is not None:
        campos["pago"] = body.pago
        if body.pago and body.pago_em is None:
            campos["pago_em"] = datetime.now(timezone.utc).isoformat()
        elif not body.pago:
            campos["pago_em"] = None
    if body.pago_em is not None:
        campos["pago_em"] = body.pago_em.isoformat()

    if campos:
        supabase.table("gastos").update(campos).eq("id", gasto_id).execute()

    linha_atualizada = _buscar_gasto(supabase, user_id, gasto_id)
    return _converter_linha_para_gasto_out(linha_atualizada)


def pagar_gasto(supabase: Client, user_id: str, gasto_id: str, body: GastoPagarIn) -> GastoOut:
    gasto = _buscar_gasto(supabase, user_id, gasto_id)
    # Idempotência: se já estiver pago, devolve 200 com o estado atual sem erro
    if gasto.get("pago"):
        return _converter_linha_para_gasto_out(gasto)

    if body.pago_em is not None:
        pago_em_str = body.pago_em.isoformat() if isinstance(body.pago_em, (date, datetime)) else str(body.pago_em)
    else:
        pago_em_str = datetime.now(timezone.utc).isoformat()

    supabase.table("gastos").update({
        "pago": True,
        "pago_em": pago_em_str,
    }).eq("id", gasto_id).execute()

    linha_atualizada = _buscar_gasto(supabase, user_id, gasto_id)
    return _converter_linha_para_gasto_out(linha_atualizada)


def excluir_gasto(supabase: Client, user_id: str, gasto_id: str) -> None:
    _buscar_gasto(supabase, user_id, gasto_id)
    supabase.table("gastos").delete().eq("id", gasto_id).execute()
