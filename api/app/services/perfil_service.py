"""Serviço de perfil e custos fixos (endpoints-backend.md §7)."""

from datetime import date, datetime, timezone
import re
from fastapi import HTTPException
from supabase import Client

from app.core.supabase_client import row, rows
from app.schemas.perfil import (
    PerfilOut,
    SalaoDados,
    PerfilUpdateIn,
    CustoFixoIn,
    CustoFixoPatchIn,
    CustoFixoPagarIn,
    CustoFixoOut,
    CustosFixosListaOut,
)


def _buscar_perfil_salao(supabase: Client, user_id: str) -> dict:
    resp = (
        supabase.table("perfil_salao")
        .select("*")
        .eq("user_id", user_id)
        .execute()
    )
    linhas = rows(resp.data)
    if not linhas:
        # Se não existir perfil para o user_id, cria um perfil padrão
        insert_resp = (
            supabase.table("perfil_salao")
            .insert({
                "user_id": user_id,
                "nome_salao": "Meu Salão",
                "nome_proprietaria": "",
                "telefone": "",
                "meta_faturamento_mensal": 9000.0,
            })
            .execute()
        )
        return row(insert_resp.data)
    return linhas[0]


def obter_perfil(supabase: Client, user_id: str) -> PerfilOut:
    linha = _buscar_perfil_salao(supabase, user_id)
    return PerfilOut(
        salao=SalaoDados(
            id=linha.get("id", user_id),
            nome=linha.get("nome_salao", "Meu Salão"),
            proprietaria=linha.get("nome_proprietaria", ""),
            foto_url=linha.get("foto_url"),
            telefone_whatsapp=linha.get("telefone", ""),
            meta_faturamento_mensal=float(linha.get("meta_faturamento_mensal", 9000.0)),
        )
    )


def atualizar_perfil(supabase: Client, user_id: str, dados: PerfilUpdateIn) -> PerfilOut:
    _buscar_perfil_salao(supabase, user_id)
    campos = {
        "nome_salao": dados.nome,
        "nome_proprietaria": dados.proprietaria,
        "foto_url": dados.foto_url,
        "telefone": dados.telefone_whatsapp,
        "meta_faturamento_mensal": dados.meta_faturamento_mensal,
    }
    supabase.table("perfil_salao").update(campos).eq("user_id", user_id).execute()
    return obter_perfil(supabase, user_id)


def _competencia_para_date(competencia_str: str) -> str:
    # AAAA-MM -> AAAA-MM-01
    return f"{competencia_str}-01"


def listar_custos_fixos(
    supabase: Client,
    user_id: str,
    competencia: str | None = None,
) -> CustosFixosListaOut:
    hoje = date.today()
    comp = competencia or hoje.strftime("%Y-%m")
    if not re.match(r"^\d{4}-(0[1-9]|1[0-2])$", comp):
        raise HTTPException(
            status_code=422,
            detail={"codigo": "VALIDACAO_INVALIDA", "mensagem": "Competência inválida (esperado AAAA-MM)"},
        )

    data_comp = _competencia_para_date(comp)

    # 1. Busca todos os custos fixos cadastrados
    resp_custos = (
        supabase.table("custos_fixos")
        .select("id, descricao, valor, dia_vencimento")
        .eq("user_id", user_id)
        .order("dia_vencimento")
        .execute()
    )
    custos_linhas = rows(resp_custos.data)

    # 2. Busca pagamentos registrados para a competência alvo
    resp_pagamentos = (
        supabase.table("custos_fixos_pagamentos")
        .select("custo_fixo_id, pago_em")
        .eq("user_id", user_id)
        .eq("competencia", data_comp)
        .execute()
    )
    pagamentos_map = {str(p["custo_fixo_id"]): p.get("pago_em") for p in rows(resp_pagamentos.data)}

    custos_out: list[CustoFixoOut] = []
    total_mensal = 0.0
    total_pago = 0.0

    for c in custos_linhas:
        cid = str(c["id"])
        valor = float(c["valor"])
        total_mensal += valor

        pago_em = pagamentos_map.get(cid)
        pago = cid in pagamentos_map
        if pago:
            total_pago += valor

        pago_em_dt = None
        if pago_em:
            try:
                pago_em_dt = datetime.fromisoformat(str(pago_em))
            except Exception:
                pago_em_dt = None

        custos_out.append(
            CustoFixoOut(
                id=cid,
                descricao=str(c["descricao"]),
                valor=valor,
                dia_vencimento=int(c.get("dia_vencimento") or 1),
                competencia=comp,
                pago=pago,
                pago_em=pago_em_dt,
            )
        )

    total_pendente = total_mensal - total_pago

    return CustosFixosListaOut(
        total_mensal=round(total_mensal, 2),
        total_pago=round(total_pago, 2),
        total_pendente=round(total_pendente, 2),
        custos=custos_out,
    )


def _buscar_custo_fixo(supabase: Client, user_id: str, custo_id: str) -> dict:
    resp = (
        supabase.table("custos_fixos")
        .select("*")
        .eq("user_id", user_id)
        .eq("id", custo_id)
        .execute()
    )
    linhas = rows(resp.data)
    if not linhas:
        raise HTTPException(
            status_code=404,
            detail={"codigo": "RECURSO_NAO_ENCONTRADO", "mensagem": "Custo fixo não encontrado"},
        )
    return linhas[0]


def criar_custo_fixo(supabase: Client, user_id: str, dados: CustoFixoIn) -> CustoFixoOut:
    hoje = date.today()
    comp = hoje.strftime("%Y-%m")
    insert_resp = (
        supabase.table("custos_fixos")
        .insert({
            "user_id": user_id,
            "descricao": dados.descricao,
            "valor": dados.valor,
            "dia_vencimento": dados.dia_vencimento,
        })
        .execute()
    )
    linha = row(insert_resp.data)
    return CustoFixoOut(
        id=str(linha["id"]),
        descricao=str(linha["descricao"]),
        valor=float(linha["valor"]),
        dia_vencimento=int(linha.get("dia_vencimento", dados.dia_vencimento)),
        competencia=comp,
        pago=False,
        pago_em=None,
    )


def editar_custo_fixo(
    supabase: Client, user_id: str, custo_id: str, dados: CustoFixoPatchIn
) -> CustoFixoOut:
    _buscar_custo_fixo(supabase, user_id, custo_id)
    campos = {}
    if dados.descricao is not None:
        campos["descricao"] = dados.descricao
    if dados.valor is not None:
        campos["valor"] = dados.valor
    if dados.dia_vencimento is not None:
        campos["dia_vencimento"] = dados.dia_vencimento

    if campos:
        supabase.table("custos_fixos").update(campos).eq("id", custo_id).execute()

    linha = _buscar_custo_fixo(supabase, user_id, custo_id)
    hoje = date.today()
    comp = hoje.strftime("%Y-%m")
    data_comp = _competencia_para_date(comp)

    # Checa status de pagamento no mês atual
    resp_pag = (
        supabase.table("custos_fixos_pagamentos")
        .select("pago_em")
        .eq("custo_fixo_id", custo_id)
        .eq("competencia", data_comp)
        .execute()
    )
    pag_linhas = rows(resp_pag.data)
    pago = bool(pag_linhas)
    pago_em_dt = None
    if pago and pag_linhas[0].get("pago_em"):
        try:
            pago_em_dt = datetime.fromisoformat(str(pag_linhas[0]["pago_em"]))
        except Exception:
            pago_em_dt = None

    return CustoFixoOut(
        id=str(linha["id"]),
        descricao=str(linha["descricao"]),
        valor=float(linha["valor"]),
        dia_vencimento=int(linha.get("dia_vencimento") or 1),
        competencia=comp,
        pago=pago,
        pago_em=pago_em_dt,
    )


def pagar_custo_fixo(
    supabase: Client, user_id: str, custo_id: str, dados: CustoFixoPagarIn
) -> CustoFixoOut:
    linha = _buscar_custo_fixo(supabase, user_id, custo_id)
    comp = dados.competencia
    data_comp = _competencia_para_date(comp)

    if dados.pago:
        agora_iso = datetime.now(timezone.utc).isoformat()
        supabase.table("custos_fixos_pagamentos").upsert(
            {
                "custo_fixo_id": custo_id,
                "user_id": user_id,
                "competencia": data_comp,
                "pago_em": agora_iso,
            },
            on_conflict="custo_fixo_id,competencia",
        ).execute()
        pago_em_dt = datetime.fromisoformat(agora_iso)
        pago = True
    else:
        supabase.table("custos_fixos_pagamentos").delete().eq(
            "custo_fixo_id", custo_id
        ).eq("competencia", data_comp).execute()
        pago_em_dt = None
        pago = False

    return CustoFixoOut(
        id=linha["id"],
        descricao=linha["descricao"],
        valor=float(linha["valor"]),
        dia_vencimento=int(linha.get("dia_vencimento") or 1),
        competencia=comp,
        pago=pago,
        pago_em=pago_em_dt,
    )


def excluir_custo_fixo(supabase: Client, user_id: str, custo_id: str) -> None:
    _buscar_custo_fixo(supabase, user_id, custo_id)
    supabase.table("custos_fixos").delete().eq("id", custo_id).execute()
