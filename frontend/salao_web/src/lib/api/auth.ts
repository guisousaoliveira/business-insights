import { AppApi } from "../http";
import { AppStorage } from "../storage";
import type { Salao, Sessao, Usuario } from "../types";
import { Paths } from "./paths";

/**
 * `auth` — 4 operações (§1 do contrato).
 *
 * É o único módulo que escreve no `AppStorage`: quem guarda e apaga a sessão é
 * daqui, não a tela de login. O refresh automático vive no transporte.
 */
export const AuthApi = {
  /** Login não leva bearer: a credencial é o próprio corpo. */
  async login(email: string, senha: string): Promise<Sessao> {
    const { result } = await AppApi.postSemToken<Sessao>(Paths.login, { email, senha });
    AppStorage.salvarSessao(result);
    return result;
  },

  /**
   * Avisa o servidor e limpa a sessão local.
   *
   * A falha da chamada não impede a saída: se ela clicou em "sair", sair é o
   * que tem que acontecer — token inválido no servidor é problema do servidor.
   */
  async logout(): Promise<void> {
    try {
      await AppApi.post(Paths.logout);
    } finally {
      AppStorage.limpar();
    }
  },

  /** Revalida a sessão guardada contra o servidor no boot do app. */
  async eu(): Promise<{ usuario: Usuario; salao: Salao }> {
    const { result } = await AppApi.get<{ usuario: Usuario; salao: Salao }>(Paths.eu);
    return result;
  },
} as const;
