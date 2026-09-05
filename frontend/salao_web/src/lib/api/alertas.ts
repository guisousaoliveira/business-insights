import { AppApi } from "../http";
import type { AlertasPagina, PreferenciasAlerta } from "../types";
import { Paths } from "./paths";

/**
 * `alertas` — 7 operações (§9 do contrato).
 *
 * Quem decide o que é alerta é o servidor: estoque baixo, gasto a vencer, custo
 * fixo vencido, saldo negativo, zero a zero. A tela só lista e marca como lido
 * — a mesma regra alimenta o badge, o push e o n8n.
 *
 * `/dispositivos` mora aqui porque só existe para o push: registrar no login,
 * remover no logout, senão a próxima usuária do aparelho recebe alerta alheio.
 */
export const AlertasApi = {
  listar(apenasNaoLidos?: boolean): Promise<AlertasPagina> {
    return AppApi.get<AlertasPagina>(Paths.alertas, {
      apenas_nao_lidos: apenasNaoLidos,
    }).then((r) => r.result);
  },

  marcarLido(id: string): Promise<void> {
    return AppApi.patch(Paths.lerAlerta(id)).then(() => undefined);
  },

  marcarTodosLidos(): Promise<void> {
    return AppApi.patch(Paths.lerTodosAlertas).then(() => undefined);
  },

  preferencias(): Promise<PreferenciasAlerta> {
    return AppApi.get<PreferenciasAlerta>(Paths.preferenciasAlerta).then((r) => r.result);
  },

  salvarPreferencias(body: PreferenciasAlerta): Promise<void> {
    return AppApi.put(Paths.preferenciasAlerta, body).then(() => undefined);
  },

  /** Idempotente por token. */
  registrarDispositivo(body: {
    token: string;
    plataforma: "android" | "ios" | "web";
    modelo?: string;
  }): Promise<void> {
    return AppApi.post(Paths.dispositivos, body).then(() => undefined);
  },

  removerDispositivo(token: string): Promise<void> {
    return AppApi.delete(Paths.dispositivo(token)).then(() => undefined);
  },
} as const;
