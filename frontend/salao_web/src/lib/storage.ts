import type { Salao, Sessao, Usuario } from "./types";

/**
 * Persistência da sessão — fachada única sobre o `localStorage`.
 *
 * Espelha o `AppStorage` do Flutter (decisão A4): chaves centralizadas aqui,
 * nenhuma tela ou hook escreve `localStorage` direto. Serve para sessão e cache
 * leve; **não há offline-first** — escrita sem rede falha e a UI mostra erro.
 *
 * Todo acesso é protegido: a rota renderiza no servidor (SSR do TanStack Start),
 * onde `window` não existe, e o navegador pode recusar o storage em janela
 * privada. Nos dois casos a leitura devolve `null` e o app cai no login, em vez
 * de quebrar na hidratação.
 */
const CHAVES = {
  bearerToken: "@thamires:token",
  refreshToken: "@thamires:refresh-token",
  usuario: "@thamires:usuario",
  salao: "@thamires:salao",
} as const;

function disponivel(): Storage | null {
  if (typeof window === "undefined") return null;
  try {
    return window.localStorage;
  } catch {
    return null;
  }
}

function ler(chave: string): string | null {
  try {
    return disponivel()?.getItem(chave) ?? null;
  } catch {
    return null;
  }
}

function escrever(chave: string, valor: string): void {
  try {
    disponivel()?.setItem(chave, valor);
  } catch {
    /* janela privada ou storage cheio: a sessão vira apenas de memória */
  }
}

function remover(chave: string): void {
  try {
    disponivel()?.removeItem(chave);
  } catch {
    /* nada a fazer */
  }
}

function lerJson<T>(chave: string): T | null {
  const bruto = ler(chave);
  if (!bruto) return null;
  try {
    return JSON.parse(bruto) as T;
  } catch {
    remover(chave);
    return null;
  }
}

export const AppStorage = {
  get token(): string | null {
    return ler(CHAVES.bearerToken);
  },

  get refreshToken(): string | null {
    return ler(CHAVES.refreshToken);
  },

  get usuario(): Usuario | null {
    return lerJson<Usuario>(CHAVES.usuario);
  },

  get salao(): Salao | null {
    return lerJson<Salao>(CHAVES.salao);
  },

  /** `true` quando há token guardado — o guard de rota lê só isto. */
  get autenticado(): boolean {
    return (ler(CHAVES.bearerToken) ?? "").length > 0;
  },

  /** Grava a sessão inteira: o que o login e o refresh devolvem. */
  salvarSessao(sessao: Sessao): void {
    escrever(CHAVES.bearerToken, sessao.token);
    escrever(CHAVES.refreshToken, sessao.refresh_token);
    escrever(CHAVES.usuario, JSON.stringify(sessao.usuario));
    escrever(CHAVES.salao, JSON.stringify(sessao.salao));
  },

  /** Só os tokens: o refresh renova credencial, não muda quem está logado. */
  salvarTokens(token: string, refreshToken: string): void {
    escrever(CHAVES.bearerToken, token);
    escrever(CHAVES.refreshToken, refreshToken);
  },

  limpar(): void {
    Object.values(CHAVES).forEach(remover);
  },
} as const;
