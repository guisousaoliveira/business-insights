/**
 * Ponto de entrada do acesso a dados.
 *
 * As telas importam daqui (`@/lib/api`), nunca de `http.ts` nem de `paths.ts`:
 * é o que mantém a fronteira com a rede em um lugar só.
 */
export { Paths } from "./paths";
export { AuthApi } from "./auth";
export { AtendimentosApi } from "./atendimentos";
export { GastosApi } from "./gastos";
export { ResumoApi } from "./resumo";
export { EstoqueApi } from "./estoque";
export { KitsApi } from "./kits";
export { PerfilApi } from "./perfil";
export { ServicosApi } from "./servicos";
export { AlertasApi } from "./alertas";

export type {
  AtendimentoBody,
  FinalizarBody,
  MaterialEntrada,
  ServicoEntrada,
} from "./atendimentos";
export type { GastoBody } from "./gastos";
export type { Precificacao, PrecificacaoBody } from "./resumo";
export type { ItemBody, MovimentacaoBody } from "./estoque";
export type { KitBody } from "./kits";
export type { CustoFixoBody, PerfilBody } from "./perfil";
export type { ServicoBody } from "./servicos";
