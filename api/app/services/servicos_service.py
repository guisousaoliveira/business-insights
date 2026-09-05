"""Regras de `servicos` (endpoints-backend.md §8)."""

from fastapi import HTTPException
from supabase import Client

from app.schemas.servicos import ProdutoPadraoIn, ServicoIn, ServicoPatchIn


def _montar_produtos_padrao(supabase: Client, servico_ids: list[str]) -> dict[str, list[dict]]:
    if not servico_ids:
        return {}
    resp = (
        supabase.table("servico_produtos_padrao")
        .select("servico_id, item_estoque_id, quantidade")
        .in_("servico_id", servico_ids)
        .execute()
    )
    linhas = resp.data or []
    itens: dict[str, dict] = {}
    ids_item = list({linha["item_estoque_id"] for linha in linhas})
    if ids_item:
        resp_itens = (
            supabase.table("estoque_itens").select("id, nome, unidade").in_("id", ids_item).execute()
        )
        itens = {i["id"]: i for i in (resp_itens.data or [])}

    por_servico: dict[str, list[dict]] = {sid: [] for sid in servico_ids}
    for linha in linhas:
        item = itens.get(linha["item_estoque_id"], {})
        por_servico.setdefault(linha["servico_id"], []).append({
            "item_estoque_id": linha["item_estoque_id"],
            "nome": item.get("nome", ""),
            "quantidade": linha["quantidade"],
            "unidade": item.get("unidade", "un"),
        })
    return por_servico


def _validar_itens_estoque(supabase: Client, user_id: str, produtos: list[ProdutoPadraoIn]) -> None:
    if not produtos:
        return
    ids = [p.item_estoque_id for p in produtos]
    resp = (
        supabase.table("estoque_itens")
        .select("id, ativo")
        .eq("user_id", user_id)
        .in_("id", ids)
        .execute()
    )
    encontrados = {i["id"]: i for i in (resp.data or [])}
    invalidos = [i for i in ids if i not in encontrados or not encontrados[i]["ativo"]]
    if invalidos:
        raise HTTPException(
            status_code=404,
            detail={
                "codigo": "RECURSO_NAO_ENCONTRADO",
                "mensagem": "Item de estoque inválido ou inativo",
                "result": {"item_estoque_ids": invalidos},
            },
        )


def _buscar_servico(supabase: Client, user_id: str, servico_id: str) -> dict:
    resp = (
        supabase.table("servicos")
        .select("id, nome, preco, duracao_minutos, ativo")
        .eq("user_id", user_id)
        .eq("id", servico_id)
        .execute()
    )
    linhas = resp.data or []
    if not linhas:
        raise HTTPException(
            status_code=404,
            detail={"codigo": "RECURSO_NAO_ENCONTRADO", "mensagem": "Serviço não encontrado"},
        )
    return linhas[0]


def _montar_saida(supabase: Client, servico: dict) -> dict:
    produtos = _montar_produtos_padrao(supabase, [servico["id"]]).get(servico["id"], [])
    return {
        "id": servico["id"],
        "nome": servico["nome"],
        "preco": servico["preco"],
        "duracao_minutos": servico.get("duracao_minutos"),
        "ativo": servico["ativo"],
        "produtos_padrao": produtos,
    }


def listar(supabase: Client, user_id: str) -> dict:
    resp = (
        supabase.table("servicos")
        .select("id, nome, preco, duracao_minutos, ativo")
        .eq("user_id", user_id)
        .eq("ativo", True)
        .order("nome")
        .execute()
    )
    servicos = resp.data or []
    por_servico = _montar_produtos_padrao(supabase, [s["id"] for s in servicos])
    return {
        "servicos": [
            {
                "id": s["id"],
                "nome": s["nome"],
                "preco": s["preco"],
                "duracao_minutos": s.get("duracao_minutos"),
                "ativo": s["ativo"],
                "produtos_padrao": por_servico.get(s["id"], []),
            }
            for s in servicos
        ]
    }


def criar(supabase: Client, user_id: str, body: ServicoIn) -> dict:
    _validar_itens_estoque(supabase, user_id, body.produtos_padrao)
    resp = (
        supabase.table("servicos")
        .insert({
            "user_id": user_id,
            "nome": body.nome,
            "preco": body.preco,
            "duracao_minutos": body.duracao_minutos,
            "ativo": True,
        })
        .execute()
    )
    servico = resp.data[0]
    if body.produtos_padrao:
        supabase.table("servico_produtos_padrao").insert([
            {"servico_id": servico["id"], "item_estoque_id": p.item_estoque_id, "quantidade": p.quantidade}
            for p in body.produtos_padrao
        ]).execute()
    return _montar_saida(supabase, servico)


def editar(supabase: Client, user_id: str, servico_id: str, body: ServicoPatchIn) -> dict:
    servico = _buscar_servico(supabase, user_id, servico_id)

    campos = {}
    if body.nome is not None:
        campos["nome"] = body.nome
    if body.preco is not None:
        campos["preco"] = body.preco
    if body.duracao_minutos is not None:
        campos["duracao_minutos"] = body.duracao_minutos
    if campos:
        supabase.table("servicos").update(campos).eq("id", servico_id).execute()
        servico = {**servico, **campos}

    if body.produtos_padrao is not None:
        _validar_itens_estoque(supabase, user_id, body.produtos_padrao)
        supabase.table("servico_produtos_padrao").delete().eq("servico_id", servico_id).execute()
        if body.produtos_padrao:
            supabase.table("servico_produtos_padrao").insert([
                {"servico_id": servico_id, "item_estoque_id": p.item_estoque_id, "quantidade": p.quantidade}
                for p in body.produtos_padrao
            ]).execute()

    return _montar_saida(supabase, servico)


def excluir(supabase: Client, user_id: str, servico_id: str) -> None:
    _buscar_servico(supabase, user_id, servico_id)
    supabase.table("servicos").update({"ativo": False}).eq("id", servico_id).execute()
