import { AppEnvironment } from "./env";
import { ApiError, AppErrorCodes, erroDeConexao } from "./error-codes";
import { AppStorage } from "./storage";

/**
 * Transporte — a **única** saída do app para a rede.
 *
 * Equivale ao `AppApi` do Flutter: nenhuma outra camada monta URL, header ou
 * trata status HTTP. Os módulos de `lib/api/` chamam os verbos daqui; as telas
 * nem sabem que ele existe.
 *
 * O app fala **só com o FastAPI** (decisão A1). Não há Supabase aqui — nem
 * PostgREST, nem RPC, nem `anon key`.
 */

/** Envelope de §0 do contrato: igual para sucesso e para erro. */
export interface Envelope<T> {
  total: number;
  mensagem: string;
  codigo: string | null;
  result: T;
}

type Metodo = "GET" | "POST" | "PUT" | "PATCH" | "DELETE";

export type Query = Record<string, string | number | boolean | undefined | null>;

interface Opcoes {
  query?: Query | undefined;
  body?: unknown;
  /** O refresh usa o refresh token, não o bearer da sessão. */
  semToken?: boolean | undefined;
}

/**
 * Chamado quando o refresh falha e a sessão cai.
 *
 * Fica como callback para o transporte não importar o router: quem sabe
 * navegar é o `__root`, que registra isto no boot.
 */
let aoExpirarSessao: (() => void) | null = null;

export function registrarExpiracaoDeSessao(callback: () => void): void {
  aoExpirarSessao = callback;
}

function derrubarSessao(): void {
  AppStorage.limpar();
  aoExpirarSessao?.();
}

function montarUrl(path: string, query?: Query): string {
  const url = new URL(`${AppEnvironment.apiBaseUrl}${path}`);
  Object.entries(query ?? {}).forEach(([chave, valor]) => {
    if (valor === undefined || valor === null || valor === "") return;
    url.searchParams.set(chave, String(valor));
  });
  return url.toString();
}

/**
 * Refresh serializado.
 *
 * Uma promise só para N chamadas que levaram 401 ao mesmo tempo — sem isso, N
 * refreshes disparam em paralelo e os N−1 últimos falham com o token já
 * rotacionado (é o `QueuedInterceptor` do Dio, no Flutter).
 */
let refreshEmVoo: Promise<boolean> | null = null;

async function renovarToken(): Promise<boolean> {
  const refreshToken = AppStorage.refreshToken;
  if (!refreshToken) return false;

  refreshEmVoo ??= (async () => {
    try {
      const envelope = await executar<{ token: string; refresh_token: string }>(
        "POST",
        "/auth/refresh",
        { body: { refresh_token: refreshToken }, semToken: true },
      );
      AppStorage.salvarTokens(envelope.result.token, envelope.result.refresh_token);
      return true;
    } catch {
      return false;
    } finally {
      refreshEmVoo = null;
    }
  })();

  return refreshEmVoo;
}

/** Uma ida à rede, sem a lógica de renovação. */
async function executar<T>(metodo: Metodo, path: string, opcoes: Opcoes): Promise<Envelope<T>> {
  if (AppEnvironment.isDemo) {
    // Import dinâmico: em produção o chunk da demo existe no disco mas nunca é
    // baixado, porque esta linha não roda. É o equivalente ao tree shaking que
    // apaga a pasta `demo/` do bundle Flutter.
    const { demoRequest } = await import("./demo/demo-transport");
    return demoRequest<T>(metodo, path, opcoes.query, opcoes.body);
  }

  const headers: Record<string, string> = { "Accept-Language": "pt-BR" };
  if (opcoes.body !== undefined) headers["Content-Type"] = "application/json";
  if (!opcoes.semToken) {
    const token = AppStorage.token;
    if (token) headers["Authorization"] = `Bearer ${token}`;
  }

  let resposta: Response;
  try {
    // `body` entra só quando existe: `fetch` recusa a chave presente com valor
    // `undefined` num GET.
    const init: RequestInit = { method: metodo, headers };
    if (opcoes.body !== undefined) init.body = JSON.stringify(opcoes.body);
    resposta = await fetch(montarUrl(path, opcoes.query), init);
  } catch {
    throw erroDeConexao();
  }

  // 204 e corpo vazio são resposta legítima de DELETE: viram envelope vazio em
  // vez de estourar no `JSON.parse`.
  const texto = await resposta.text();
  let envelope: Envelope<T>;
  try {
    envelope = texto
      ? (JSON.parse(texto) as Envelope<T>)
      : { total: 0, mensagem: "", codigo: null, result: null as T };
  } catch {
    throw new ApiError(resposta.status, null, "Resposta do servidor em formato inesperado.");
  }

  if (!resposta.ok) {
    throw new ApiError(
      resposta.status,
      envelope.codigo ?? null,
      envelope.mensagem ?? "",
      envelope.result ?? null,
    );
  }

  return envelope;
}

/**
 * Verbo genérico com renovação de sessão.
 *
 * Sessão expirada é tratada em **um lugar só**: nenhum hook e nenhuma tela
 * checa 401. Tenta o refresh antes de derrubar.
 */
async function request<T>(metodo: Metodo, path: string, opcoes: Opcoes = {}): Promise<Envelope<T>> {
  try {
    return await executar<T>(metodo, path, opcoes);
  } catch (erro) {
    const expirou = erro instanceof ApiError && erro.status === 401 && !opcoes.semToken;
    if (!expirou) throw erro;

    // Credencial errada no login não é sessão expirada: renovar não ajuda e
    // limparia o storage de quem nem chegou a entrar.
    if ((erro as ApiError).is(AppErrorCodes.invalidCredentials)) throw erro;

    if (!(await renovarToken())) {
      derrubarSessao();
      throw erro;
    }
    return executar<T>(metodo, path, opcoes);
  }
}

export const AppApi = {
  get: <T>(path: string, query?: Query) => request<T>("GET", path, { query }),
  post: <T>(path: string, body?: unknown, query?: Query) =>
    request<T>("POST", path, { body, query }),
  put: <T>(path: string, body?: unknown) => request<T>("PUT", path, { body }),
  patch: <T>(path: string, body?: unknown) => request<T>("PATCH", path, { body }),
  delete: <T>(path: string, body?: unknown) => request<T>("DELETE", path, { body }),
  /** Fluxo que precisa de credencial diferente da sessão (o login e o refresh). */
  postSemToken: <T>(path: string, body?: unknown) =>
    request<T>("POST", path, { body, semToken: true }),
  derrubarSessao,
} as const;
