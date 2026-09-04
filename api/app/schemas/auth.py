from pydantic import BaseModel, EmailStr


class LoginRequest(BaseModel):
    email: EmailStr
    senha: str


class RefreshRequest(BaseModel):
    refresh_token: str


class UsuarioOut(BaseModel):
    id: str
    nome: str
    email: str


class SalaoOut(BaseModel):
    id: str
    nome: str
    foto_url: str | None = None


class SessaoOut(BaseModel):
    token: str
    refresh_token: str
    expira_em: int
    usuario: UsuarioOut
    salao: SalaoOut


class EuOut(BaseModel):
    usuario: UsuarioOut
    salao: SalaoOut
