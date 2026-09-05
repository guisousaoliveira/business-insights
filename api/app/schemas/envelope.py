"""
Envelope de resposta — obrigatório e uniforme em toda a API (endpoints-backend.md §0).

Toda resposta, sucesso ou erro, sai neste formato:

    { "total": 12, "mensagem": "ok", "codigo": null, "result": {} }

`total`    quantidade de itens em `result` (lista), 1 (objeto) ou 0 (erro)
`mensagem` texto humano — o app prefere traduzir pelo `codigo`, isto é fallback
`codigo`   código de erro de negócio (§9/§11 do contrato); `null` em sucesso
`result`   a carga útil, ou `null` em erro

Erros de negócio (409 estoque insuficiente, 401 credenciais inválidas, etc.) devem
ser levantados como `HTTPException(status_code=..., detail={"codigo": ..., "mensagem": ...,
"result": ...})` — o exception_handler abaixo lê esse formato. Se o detail vier como
string simples (código legado ou erro do próprio FastAPI), cai no fallback genérico.
"""

from typing import Any, Generic, TypeVar

from fastapi import FastAPI, Request, HTTPException
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import BaseModel

T = TypeVar("T")


class ResponseModel(BaseModel, Generic[T]):
    total: int
    mensagem: str
    codigo: str | None = None
    result: T | None = None


def sucesso(result: Any, mensagem: str = "ok", total: int | None = None) -> dict:
    """
    Monta o envelope de sucesso. Se `total` não for informado, é inferido:
    len(result) para lista, 1 para objeto/None-não-nulo, 0 para result None.
    """
    if total is None:
        if isinstance(result, list):
            total = len(result)
        elif result is None:
            total = 0
        else:
            total = 1
    return {"total": total, "mensagem": mensagem, "codigo": None, "result": result}


def _erro(status_code: int, codigo: str | None, mensagem: str, result: Any = None) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={"total": 0, "mensagem": mensagem, "codigo": codigo, "result": result},
    )


def registrar_exception_handlers(app: FastAPI) -> None:
    """
    Cobre HTTPException, RequestValidationError e Exception genérica — as três
    fontes de erro da API — para que TODA resposta de erro, sem exceção, saia
    com as quatro chaves do envelope. Forçar um 500 e conferir isso é o teste
    de aceite descrito em 00-ENTREGA-BACKEND.md §4.
    """

    @app.exception_handler(HTTPException)
    async def handler_http_exception(request: Request, exc: HTTPException) -> JSONResponse:
        detail = exc.detail
        if isinstance(detail, dict):
            codigo = detail.get("codigo")
            mensagem = detail.get("mensagem", "Erro na requisição")
            result = detail.get("result")
        else:
            # detail veio como string simples — não tem código de negócio associado
            codigo = None
            mensagem = str(detail) if detail else "Erro na requisição"
            result = None
        return _erro(exc.status_code, codigo, mensagem, result)

    @app.exception_handler(RequestValidationError)
    async def handler_validation_error(request: Request, exc: RequestValidationError) -> JSONResponse:
        # exc.errors() traz 'ctx': {'error': ValueError(...)} quando o erro vem
        # de um @model_validator — um ValueError cru não é serializável em JSON,
        # o que quebrava o JSONResponse e mascarava tudo como 500. Removemos
        # 'ctx' (ou convertemos para string) antes de montar o envelope.
        campos = []
        for erro in exc.errors():
            erro = dict(erro)
            ctx = erro.get("ctx")
            if isinstance(ctx, dict):
                erro["ctx"] = {k: str(v) for k, v in ctx.items()}
            campos.append(erro)
        return _erro(
            422,
            "VALIDACAO_INVALIDA",
            "Corpo da requisição inválido",
            result={"campos": campos},
        )

    @app.exception_handler(Exception)
    async def handler_generic_exception(request: Request, exc: Exception) -> JSONResponse:
        import logging
        logging.getLogger(__name__).exception("Erro não tratado")
        return _erro(500, None, "Erro interno do servidor")
