"""Regras de `estoque` (endpoints-backend.md §5, A6)."""

from fastapi import HTTPException
from supabase import Client

from app.schemas.estoque import ItemIn, ItemPatchIn, MovimentacaoIn

_CAMPOS_ITEM = "id, nome, unidade, categoria, quantidade_atual, quantidade_minima, custo_medio, custo_ultima_compra, status, deficit, ativo, codigo_barras"


def _validar_codigo_barras_livre(
    supabase: Client, user_id: str, codigo_barras: str, ignorar_item_id: str | None = None
) -> None:
    query = (
        supabase.table("estoque_itens")
        .select("id")
        .eq("user_id", user_id)
        .eq("codigo_barras", codigo_barras)
    )
    if ignorar_item_id:
        query = query.neq("id", ignorar_item_id)
    if query.execute().data:
        raise HTTPException(
            status_code=409,
            detail={
                "codigo": "CODIGO_BARRAS_JA_CADASTRADO",
                "mensagem": "Esse código de barras já está em uso por outro item.",
            },
        )




def _buscar_item(supabase: Client, user_id: str, item_id: str) -> dict:
    resp = (
        supabase.table("estoque_itens")
        .select(_CAMPOS_ITEM)
        .eq("user_id", user_id)
        .eq("id", item_id)
        .execute()
    )
    linhas = resp.data or []
    if not linhas:
        raise HTTPException(
            status_code=404,
            detail={"codigo": "RECURSO_NAO_ENCONTRADO", "mensagem": "Item de estoque não encontrado"},
        )
    return linhas[0]


def listar(
    supabase: Client,
    user_id: str,
    status: str | None,
    categoria: str | None,
    ativo: bool | None,
    codigo_barras: str | None = None,
) -> dict:
    query = supabase.table("estoque_itens").select(_CAMPOS_ITEM).eq("user_id", user_id)
    if status:
        query = query.eq("status", status)
    if categoria:
        query = query.eq("categoria", categoria)
    if codigo_barras:
        query = query.eq("codigo_barras", codigo_barras)
    if ativo is not None:
        query = query.eq("ativo", ativo)
    else:
        query = query.eq("ativo", True)
    itens = query.order("nome").execute().data or []

    total_alertas = sum(1 for i in itens if i["status"] in ("alerta", "critico", "negativo"))
    valor_total = sum(i["quantidade_atual"] * i["custo_medio"] for i in itens if i["quantidade_atual"] > 0)
    return {"total_alertas": total_alertas, "valor_total": valor_total, "itens": itens}


def criar(supabase: Client, user_id: str, body: ItemIn) -> dict:
    if body.codigo_barras:
        _validar_codigo_barras_livre(supabase, user_id, body.codigo_barras)
    resp = (
        supabase.table("estoque_itens")
        .insert({
            "user_id": user_id,
            "nome": body.nome,
            "unidade": body.unidade,
            "categoria": body.categoria,
            "quantidade_atual": body.quantidade_atual,
            "quantidade_minima": body.quantidade_minima,
            "custo_medio": body.custo_unitario,
            "custo_ultima_compra": body.custo_unitario,
            "codigo_barras": body.codigo_barras,
            "ativo": True,
        })
        .execute()
    )
    return _buscar_item(supabase, user_id, resp.data[0]["id"])


def editar(supabase: Client, user_id: str, item_id: str, body: ItemPatchIn) -> dict:
    _buscar_item(supabase, user_id, item_id)
    campos = {}
    if body.nome is not None:
        campos["nome"] = body.nome
    if body.unidade is not None:
        campos["unidade"] = body.unidade
    if body.categoria is not None:
        campos["categoria"] = body.categoria
    if body.quantidade_minima is not None:
        campos["quantidade_minima"] = body.quantidade_minima
    if body.codigo_barras is not None:
        _validar_codigo_barras_livre(supabase, user_id, body.codigo_barras, ignorar_item_id=item_id)
        campos["codigo_barras"] = body.codigo_barras
    if campos:
        supabase.table("estoque_itens").update(campos).eq("id", item_id).execute()
    return _buscar_item(supabase, user_id, item_id)


def excluir(supabase: Client, user_id: str, item_id: str) -> None:
    _buscar_item(supabase, user_id, item_id)
    resp = (
        supabase.table("estoque_movimentacoes")
        .select("id")
        .eq("item_id", item_id)
        .limit(1)
        .execute()
    )
    if resp.data:
        supabase.table("estoque_itens").update({"ativo": False}).eq("id", item_id).execute()
    else:
        supabase.table("estoque_itens").delete().eq("id", item_id).execute()


def criar_movimentacao(supabase: Client, user_id: str, item_id: str, body: MovimentacaoIn) -> dict:
    item = _buscar_item(supabase, user_id, item_id)

    if body.tipo == "saida" and item["quantidade_atual"] < body.quantidade:
        raise HTTPException(
            status_code=409,
            detail={
                "codigo": "ESTOQUE_INSUFICIENTE",
                "mensagem": "Saldo insuficiente para essa saída.",
                "result": {
                    "faltantes": [{
                        "item_estoque_id": item["id"],
                        "nome": item["nome"],
                        "unidade": item["unidade"],
                        "quantidade_solicitada": body.quantidade,
                        "quantidade_disponivel": item["quantidade_atual"],
                        "deficit": body.quantidade - item["quantidade_atual"],
                    }]
                },
            },
        )

    novo_saldo = item["quantidade_atual"]
    novo_custo_medio = item["custo_medio"]
    novo_custo_ultima_compra = item["custo_ultima_compra"]

    if body.tipo == "entrada":
        novo_saldo = item["quantidade_atual"] + body.quantidade
        if body.custo_unitario is not None:
            if item["quantidade_atual"] <= 0:
                novo_custo_medio = body.custo_unitario
            else:
                novo_custo_medio = (
                    item["quantidade_atual"] * item["custo_medio"] + body.quantidade * body.custo_unitario
                ) / novo_saldo
            novo_custo_ultima_compra = body.custo_unitario
    elif body.tipo == "saida":
        novo_saldo = item["quantidade_atual"] - body.quantidade
    else:  # ajuste
        novo_saldo = item["quantidade_atual"] + body.quantidade

    supabase.table("estoque_movimentacoes").insert({
        "user_id": user_id,
        "item_id": item_id,
        "tipo": body.tipo,
        "quantidade": body.quantidade,
        "motivo": body.motivo,
        "custo_unitario": body.custo_unitario,
        "forcada": False,
    }).execute()

    supabase.table("estoque_itens").update({
        "quantidade_atual": novo_saldo,
        "custo_medio": novo_custo_medio,
        "custo_ultima_compra": novo_custo_ultima_compra,
    }).eq("id", item_id).execute()

    return _buscar_item(supabase, user_id, item_id)


def listar_movimentacoes(
    supabase: Client,
    user_id: str,
    item_id: str | None,
    inicio: str | None,
    fim: str | None,
    tipo: str | None,
) -> dict:
    query = supabase.table("estoque_movimentacoes").select(
        "id, item_id, tipo, quantidade, motivo, atendimento_id, criado_em"
    ).eq("user_id", user_id)
    if item_id:
        query = query.eq("item_id", item_id)
    if tipo:
        query = query.eq("tipo", tipo)
    if inicio:
        query = query.gte("criado_em", f"{inicio}T00:00:00-03:00")
    if fim:
        query = query.lte("criado_em", f"{fim}T23:59:59-03:00")
    linhas = query.order("criado_em", desc=True).execute().data or []

    ids_item = list({m["item_id"] for m in linhas})
    nomes: dict[str, str] = {}
    if ids_item:
        resp_itens = supabase.table("estoque_itens").select("id, nome").in_("id", ids_item).execute()
        nomes = {i["id"]: i["nome"] for i in (resp_itens.data or [])}

    return {
        "movimentacoes": [
            {
                "id": m["id"],
                "item_id": m["item_id"],
                "item_nome": nomes.get(m["item_id"], ""),
                "tipo": m["tipo"],
                "quantidade": m["quantidade"],
                "motivo": m["motivo"],
                "atendimento_id": m.get("atendimento_id"),
                "criado_em": m["criado_em"],
            }
            for m in linhas
        ]
    }
