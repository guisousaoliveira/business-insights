/**
 * Códigos de erro de negócio — §11 de `.specs/endpoints-backend.md`.
 *
 * O app identifica erro por **código**, nunca pela mensagem: mensagem muda
 * quando alguém corrige uma vírgula, código não. Espelho de
 * `settings/app_error_codes.dart` no Flutter.
 */
export const AppErrorCodes = {
  invalidCredentials: "AUTH_CREDENCIAIS_INVALIDAS",
  invalidRefresh: "AUTH_REFRESH_INVALIDO",
  missingToken: "AUTH_TOKEN_AUSENTE",
  invalidValidation: "VALIDACAO_INVALIDA",
  notFound: "RECURSO_NAO_ENCONTRADO",
  appointmentInvalidStatus: "ATENDIMENTO_STATUS_INVALIDO",
  insufficientStock: "ESTOQUE_INSUFICIENTE",
  kitNotAssembled: "KIT_NAO_MONTADO",
  itemInUse: "ITEM_EM_USO",
  expenseAlreadyPaid: "GASTO_JA_PAGO",
  rateLimited: "LIMITE_EXCEDIDO",
  barcodeAlreadyUsed: "CODIGO_BARRAS_JA_CADASTRADO",
} as const;

export type AppErrorCode = (typeof AppErrorCodes)[keyof typeof AppErrorCodes];

/** Texto por código. Código sem entrada aqui cai na mensagem do servidor. */
const MENSAGENS: Record<string, string> = {
  [AppErrorCodes.invalidCredentials]: "E-mail ou senha não conferem.",
  [AppErrorCodes.invalidRefresh]: "Sua sessão expirou. Entre novamente.",
  [AppErrorCodes.missingToken]: "Sua sessão expirou. Entre novamente.",
  [AppErrorCodes.invalidValidation]: "Confira os dados informados.",
  [AppErrorCodes.notFound]: "Não encontramos esse registro.",
  [AppErrorCodes.appointmentInvalidStatus]:
    "Essa ação não vale para o status atual do atendimento.",
  [AppErrorCodes.insufficientStock]: "Alguns materiais estão sem saldo em estoque.",
  [AppErrorCodes.kitNotAssembled]: "Você tem menos kits montados do que está vendendo.",
  [AppErrorCodes.itemInUse]: "Esse item tem histórico e não pode ser apagado.",
  [AppErrorCodes.expenseAlreadyPaid]: "Esse gasto já está pago.",
  [AppErrorCodes.rateLimited]: "Muitas tentativas. Espere um pouco.",
  [AppErrorCodes.barcodeAlreadyUsed]: "Esse código de barras já está em uso por outro item.",
};

/**
 * Erro que atravessa a camada de dados.
 *
 * Equivale ao `ErrorModel` do Flutter: o transporte é que constrói, e a tela lê
 * `codigo` para decidir o que fazer (o diálogo de estoque insuficiente lê
 * `result.faltantes`). Nenhuma tela inspeciona status HTTP.
 */
export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly codigo: string | null,
    mensagem: string,
    readonly result: unknown = null,
  ) {
    super(mensagem);
    this.name = "ApiError";
  }

  /** `true` quando o erro é o código de negócio informado. */
  is(codigo: AppErrorCode): boolean {
    return this.codigo === codigo;
  }

  /** Texto para a tela: tradução por código, com a mensagem do servidor de reserva. */
  get texto(): string {
    const traduzida = this.codigo === null ? undefined : MENSAGENS[this.codigo];
    if (traduzida) return traduzida;
    if (this.message) return this.message;
    if (this.status === 0) return "Sem conexão com o servidor.";
    if (this.status >= 500) return "O servidor não respondeu como esperado.";
    return "Não foi possível concluir. Tente de novo.";
  }
}

/** Erro de rede/timeout — status 0, sem código de negócio. */
export function erroDeConexao(): ApiError {
  return new ApiError(0, null, "Sem conexão com o servidor.");
}
