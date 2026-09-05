import {
  useMutation,
  useQuery,
  useQueryClient,
  type QueryClient,
  type UseMutationResult,
} from "@tanstack/react-query";

import {
  AgendamentoPublicoApi,
  AlertasApi,
  AtendimentosApi,
  AuthApi,
  EstoqueApi,
  GastosApi,
  KitsApi,
  PerfilApi,
  ResumoApi,
  ServicosApi,
  type AgendarBody,
  type AtendimentoBody,
  type CustoFixoBody,
  type FinalizarBody,
  type GastoBody,
  type ItemBody,
  type KitBody,
  type MovimentacaoBody,
  type PerfilBody,
  type Precificacao,
  type PrecificacaoBody,
  type ServicoBody,
} from "./api";
import { ApiError } from "./error-codes";
import { AppStorage } from "./storage";
import type { FormaPagamento, HorarioDia, Salao, StatusAtendimento, Usuario } from "./types";

/**
 * A camada de dados vista pela tela.
 *
 * Nenhum componente chama `*Api` direto: as telas usam estes hooks, e é aqui
 * que mora a decisão de **o que precisa ser recarregado depois de cada
 * escrita**. Finalizar um atendimento mexe em estoque, resumo e alertas ao
 * mesmo tempo — se cada tela lembrasse disso sozinha, uma delas ia esquecer, e
 * o número errado ficaria na frente da usuária.
 *
 * É o análogo do Cubit do app Flutter: o `queryKey` faz o papel do sub-estado, e
 * a invalidação, o do `emit`.
 */

// ── Chaves ───────────────────────────────────────────────────────────────────

/**
 * O primeiro segmento é o **grupo**: `invalidateQueries` casa por prefixo, e é
 * o que permite invalidar "todos os meses de gastos" sem saber qual mês está na
 * tela.
 */
export const chaves = {
  sessao: () => ["sessao"] as const,
  resumo: (ano: number, mes: number) => ["resumo", ano, mes] as const,
  atendimentos: (inicio: string, fim: string, status: StatusAtendimento[]) =>
    ["atendimentos", inicio, fim, status.join(",")] as const,
  atendimento: (id: string) => ["atendimentos", "item", id] as const,
  gastos: (ano: number, mes: number) => ["gastos", ano, mes] as const,
  estoque: () => ["estoque"] as const,
  movimentacoes: (itemId?: string) => ["movimentacoes", itemId ?? "todas"] as const,
  kits: () => ["kits"] as const,
  perfil: () => ["perfil"] as const,
  custosFixos: (competencia?: string) => ["custos-fixos", competencia ?? "corrente"] as const,
  servicos: () => ["servicos"] as const,
  alertas: (apenasNaoLidos: boolean) => ["alertas", apenasNaoLidos] as const,
  preferenciasAlerta: () => ["preferencias-alerta"] as const,
  horarioFuncionamento: () => ["horario-funcionamento"] as const,
  linkAgendamento: () => ["link-agendamento"] as const,
  agendamentoPublico: (slug: string) => ["agendamento-publico", slug] as const,
  horariosDisponiveisPublico: (slug: string, data: string, servicoIds: string[]) =>
    ["horarios-disponiveis-publico", slug, data, servicoIds.join(",")] as const,
} as const;

type Grupo =
  | "resumo"
  | "atendimentos"
  | "gastos"
  | "estoque"
  | "movimentacoes"
  | "kits"
  | "perfil"
  | "custos-fixos"
  | "servicos"
  | "alertas"
  | "horario-funcionamento"
  | "link-agendamento";

function invalidar(cliente: QueryClient, grupos: Grupo[]): void {
  grupos.forEach((grupo) => void cliente.invalidateQueries({ queryKey: [grupo] }));
}

/**
 * Quase toda escrita mexe no resumo e pode criar ou apagar alerta — o saldo do
 * mês e o sino são derivados de tudo. Por isso os dois entram na conta de
 * praticamente qualquer mutação.
 */
const SEMPRE: Grupo[] = ["resumo", "alertas"];

/** Texto pronto para a tela, sem ela precisar conhecer `ApiError`. */
export function textoDoErro(erro: unknown): string {
  if (erro instanceof ApiError) return erro.texto;
  return "Não foi possível concluir. Tente de novo.";
}

// ── Sessão ───────────────────────────────────────────────────────────────────

export interface Sessao {
  usuario: Usuario | null;
  salao: Salao | null;
}

/**
 * Quem está logado, segundo o `AppStorage`.
 *
 * Fica no cache do react-query em vez de num `useState` para que login e logout
 * atualizem o app inteiro de uma vez — o cabeçalho e o guard leem a mesma
 * chave.
 *
 * `data` é `undefined` na primeira renderização (inclusive no SSR, onde não há
 * `localStorage`): o guard espera esse ciclo antes de decidir, senão jogaria
 * para o login quem já está autenticado.
 */
export function useSessao() {
  return useQuery({
    queryKey: chaves.sessao(),
    queryFn: (): Sessao | null =>
      AppStorage.autenticado ? { usuario: AppStorage.usuario, salao: AppStorage.salao } : null,
    staleTime: Infinity,
    retry: false,
  });
}

export function useLogin(): UseMutationResult<Sessao, unknown, { email: string; senha: string }> {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: async ({ email, senha }: { email: string; senha: string }) => {
      const sessao = await AuthApi.login(email, senha);
      return { usuario: sessao.usuario, salao: sessao.salao };
    },
    onSuccess: (sessao) => {
      cliente.setQueryData(chaves.sessao(), sessao);
      // Dados de outra usuária não podem sobrar no cache depois da troca.
      void cliente.invalidateQueries();
    },
  });
}

export function useLogout(): UseMutationResult<void, unknown, void> {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: () => AuthApi.logout(),
    // `onSettled`: a sessão local é limpa mesmo se o servidor recusar — quem
    // clicou em "sair" tem que sair.
    onSettled: () => {
      cliente.setQueryData(chaves.sessao(), null);
      cliente.clear();
    },
  });
}

// ── resumo ───────────────────────────────────────────────────────────────────

export function useResumo(ano: number, mes: number) {
  return useQuery({
    queryKey: chaves.resumo(ano, mes),
    queryFn: () => ResumoApi.mensal({ ano, mes }),
  });
}

/** Cálculo puro: não invalida nada, porque não muda nada no servidor. */
export function usePrecificacao(): UseMutationResult<
  Precificacao,
  unknown,
  { body: PrecificacaoBody; precoAtual?: number }
> {
  return useMutation({
    mutationFn: ({ body, precoAtual }: { body: PrecificacaoBody; precoAtual?: number }) =>
      precoAtual === undefined
        ? ResumoApi.calcularPreco(body)
        : ResumoApi.calcularPreco(body, precoAtual),
  });
}

// ── atendimentos ─────────────────────────────────────────────────────────────

export function useAtendimentos(inicio: string, fim: string, status: StatusAtendimento[] = []) {
  return useQuery({
    queryKey: chaves.atendimentos(inicio, fim, status),
    queryFn: () =>
      status.length > 0
        ? AtendimentosApi.listar({ inicio, fim, status })
        : AtendimentosApi.listar({ inicio, fim }),
  });
}

export function useCriarAtendimento() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: (body: AtendimentoBody) => AtendimentosApi.criar(body),
    onSuccess: () => invalidar(cliente, ["atendimentos", ...SEMPRE]),
  });
}

export function useEditarAtendimento() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: ({ id, body }: { id: string; body: AtendimentoBody }) =>
      AtendimentosApi.editar(id, body),
    onSuccess: () => invalidar(cliente, ["atendimentos", ...SEMPRE]),
  });
}

/**
 * As duas passadas de A5 moram na tela, não aqui: a primeira chamada vem com
 * `confirmar_estoque_insuficiente: false` e, se o servidor responder
 * `409 ESTOQUE_INSUFICIENTE`, a tela abre o diálogo e chama de novo com `true`.
 *
 * O hook não engole esse erro nem confirma sozinho — confirmar é decisão dela.
 */
export function useFinalizarAtendimento() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: ({ id, body }: { id: string; body: FinalizarBody }) =>
      AtendimentosApi.finalizar(id, body),
    // Finalizar dá baixa no estoque: sem invalidar `estoque` e `movimentacoes`,
    // a tela de estoque continuaria mostrando o saldo de antes.
    onSuccess: () =>
      invalidar(cliente, ["atendimentos", "estoque", "movimentacoes", "kits", ...SEMPRE]),
  });
}

export function useCancelarAtendimento() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => AtendimentosApi.cancelar(id),
    // Cancelar um finalizado estorna a baixa — mexe no estoque também.
    onSuccess: () =>
      invalidar(cliente, ["atendimentos", "estoque", "movimentacoes", "kits", ...SEMPRE]),
  });
}

export function useExcluirAtendimento() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => AtendimentosApi.excluir(id),
    onSuccess: () => invalidar(cliente, ["atendimentos", ...SEMPRE]),
  });
}

// ── gastos ───────────────────────────────────────────────────────────────────

export function useGastos(ano: number, mes: number) {
  return useQuery({
    queryKey: chaves.gastos(ano, mes),
    queryFn: () => GastosApi.listar({ ano, mes }),
  });
}

export function useCriarGasto() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: (body: GastoBody) => GastosApi.criar(body),
    onSuccess: () => invalidar(cliente, ["gastos", ...SEMPRE]),
  });
}

export function useEditarGasto() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: ({ id, body }: { id: string; body: Partial<GastoBody> }) =>
      GastosApi.editar(id, body),
    onSuccess: () => invalidar(cliente, ["gastos", ...SEMPRE]),
  });
}

export function usePagarGasto() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => GastosApi.pagar(id),
    onSuccess: () => invalidar(cliente, ["gastos", ...SEMPRE]),
  });
}

export function useExcluirGasto() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => GastosApi.excluir(id),
    onSuccess: () => invalidar(cliente, ["gastos", ...SEMPRE]),
  });
}

// ── estoque ──────────────────────────────────────────────────────────────────

export function useEstoque() {
  return useQuery({
    queryKey: chaves.estoque(),
    queryFn: () => EstoqueApi.listarItens(),
  });
}

export function useMovimentacoes(itemId?: string) {
  return useQuery({
    queryKey: chaves.movimentacoes(itemId),
    queryFn: () =>
      itemId === undefined
        ? EstoqueApi.listarMovimentacoes()
        : EstoqueApi.listarMovimentacoes({ item_id: itemId }),
  });
}

export function useCriarItem() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: (body: ItemBody) => EstoqueApi.criarItem(body),
    onSuccess: () => invalidar(cliente, ["estoque", "movimentacoes", "kits", ...SEMPRE]),
  });
}

export function useEditarItem() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: ({ id, body }: { id: string; body: Partial<ItemBody> }) =>
      EstoqueApi.editarItem(id, body),
    onSuccess: () => invalidar(cliente, ["estoque", "kits", "servicos", ...SEMPRE]),
  });
}

export function useExcluirItem() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => EstoqueApi.excluirItem(id),
    onSuccess: () => invalidar(cliente, ["estoque", "movimentacoes", "kits", ...SEMPRE]),
  });
}

/** Entrada, saída ou ajuste — é o que move o saldo e a média ponderada (A6). */
export function useCriarMovimentacao() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: ({ itemId, body }: { itemId: string; body: MovimentacaoBody }) =>
      EstoqueApi.criarMovimentacao(itemId, body),
    // O custo médio muda: a margem de todo kit que usa o item muda junto.
    onSuccess: () => invalidar(cliente, ["estoque", "movimentacoes", "kits", ...SEMPRE]),
  });
}

// ── kits ─────────────────────────────────────────────────────────────────────

export function useKits() {
  return useQuery({
    queryKey: chaves.kits(),
    queryFn: () => KitsApi.listar(),
  });
}

export function useCriarKit() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: (body: KitBody) => KitsApi.criar(body),
    onSuccess: () => invalidar(cliente, ["kits", ...SEMPRE]),
  });
}

export function useEditarKit() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: ({ id, body }: { id: string; body: Partial<KitBody> }) => KitsApi.editar(id, body),
    onSuccess: () => invalidar(cliente, ["kits", ...SEMPRE]),
  });
}

export function useExcluirKit() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => KitsApi.excluir(id),
    onSuccess: () => invalidar(cliente, ["kits", ...SEMPRE]),
  });
}

/** Consome insumo: passa pelo aviso de A5, igual à finalização. */
export function useMontarKit() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: ({
      id,
      quantidade,
      confirmar = false,
    }: {
      id: string;
      quantidade: number;
      confirmar?: boolean;
    }) => KitsApi.montar(id, quantidade, confirmar),
    onSuccess: () => invalidar(cliente, ["kits", "estoque", "movimentacoes", ...SEMPRE]),
  });
}

/** Sem segunda passada: `KIT_NAO_MONTADO` é definitivo (A7). */
export function useVenderKit() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: ({
      id,
      quantidade,
      formaPagamento,
      precoUnitario,
    }: {
      id: string;
      quantidade: number;
      formaPagamento: FormaPagamento;
      precoUnitario?: number;
    }) =>
      KitsApi.vender(
        id,
        precoUnitario === undefined
          ? { quantidade, forma_pagamento: formaPagamento }
          : { quantidade, forma_pagamento: formaPagamento, preco_unitario: precoUnitario },
      ),
    // Venda é receita: entra no resumo do mês.
    onSuccess: () => invalidar(cliente, ["kits", ...SEMPRE]),
  });
}

// ── perfil, custos fixos e serviços ──────────────────────────────────────────

export function usePerfil() {
  return useQuery({
    queryKey: chaves.perfil(),
    queryFn: () => PerfilApi.obter(),
  });
}

export function useSalvarPerfil() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: (body: PerfilBody) => PerfilApi.atualizar(body),
    // A meta de faturamento vive no perfil e aparece no resumo.
    onSuccess: () => invalidar(cliente, ["perfil", ...SEMPRE]),
  });
}

/** `competencia` no formato `AAAA-MM`; ausente vale o mês corrente. */
export function useCustosFixos(competencia?: string) {
  return useQuery({
    queryKey: chaves.custosFixos(competencia),
    queryFn: () => PerfilApi.listarCustosFixos(competencia),
  });
}

export function useCriarCustoFixo() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: (body: CustoFixoBody) => PerfilApi.criarCustoFixo(body),
    onSuccess: () => invalidar(cliente, ["custos-fixos", ...SEMPRE]),
  });
}

export function useEditarCustoFixo() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: ({ id, body }: { id: string; body: Partial<CustoFixoBody> }) =>
      PerfilApi.editarCustoFixo(id, body),
    onSuccess: () => invalidar(cliente, ["custos-fixos", ...SEMPRE]),
  });
}

export function useExcluirCustoFixo() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => PerfilApi.excluirCustoFixo(id),
    onSuccess: () => invalidar(cliente, ["custos-fixos", ...SEMPRE]),
  });
}

/** `pago: false` desmarca — errar o clique numa conta não paga é comum. */
export function usePagarCustoFixo() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: ({ id, competencia, pago }: { id: string; competencia: string; pago: boolean }) =>
      PerfilApi.pagarCustoFixo(id, competencia, pago),
    onSuccess: () => invalidar(cliente, ["custos-fixos", ...SEMPRE]),
  });
}

export function useServicos() {
  return useQuery({
    queryKey: chaves.servicos(),
    queryFn: () => ServicosApi.listar(),
  });
}

export function useCriarServico() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: (body: ServicoBody) => ServicosApi.criar(body),
    onSuccess: () => invalidar(cliente, ["servicos", ...SEMPRE]),
  });
}

export function useEditarServico() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: ({ id, body }: { id: string; body: Partial<ServicoBody> }) =>
      ServicosApi.editar(id, body),
    // Mudar o preço não reescreve atendimento passado: lá ele está congelado.
    onSuccess: () => invalidar(cliente, ["servicos", ...SEMPRE]),
  });
}

export function useExcluirServico() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => ServicosApi.excluir(id),
    onSuccess: () => invalidar(cliente, ["servicos", ...SEMPRE]),
  });
}

export function useHorarioFuncionamento() {
  return useQuery({
    queryKey: chaves.horarioFuncionamento(),
    queryFn: () => PerfilApi.obterHorarioFuncionamento(),
  });
}

export function useSalvarHorarioFuncionamento() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: (horarios: HorarioDia[]) => PerfilApi.salvarHorarioFuncionamento(horarios),
    onSuccess: () => invalidar(cliente, ["horario-funcionamento"]),
  });
}

export function useLinkAgendamento() {
  return useQuery({
    queryKey: chaves.linkAgendamento(),
    queryFn: () => PerfilApi.obterLinkAgendamento(),
  });
}

// ── agendamento público (sem sessão) ─────────────────────────────────────────

export function useAgendamentoPublico(slug: string) {
  return useQuery({
    queryKey: chaves.agendamentoPublico(slug),
    queryFn: () => AgendamentoPublicoApi.obterPagina(slug),
    retry: false,
  });
}

/** Só busca quando há data e ao menos um serviço escolhido. */
export function useHorariosDisponiveisPublico(slug: string, data: string, servicoIds: string[]) {
  return useQuery({
    queryKey: chaves.horariosDisponiveisPublico(slug, data, servicoIds),
    queryFn: () => AgendamentoPublicoApi.obterHorariosDisponiveis(slug, data, servicoIds),
    enabled: Boolean(data) && servicoIds.length > 0,
  });
}

export function useAgendarPublico(slug: string) {
  return useMutation({
    mutationFn: (body: AgendarBody) => AgendamentoPublicoApi.agendar(slug, body),
  });
}

// ── alertas ──────────────────────────────────────────────────────────────────

export function useAlertas(apenasNaoLidos = false) {
  return useQuery({
    queryKey: chaves.alertas(apenasNaoLidos),
    queryFn: () => AlertasApi.listar(apenasNaoLidos),
  });
}

export function useMarcarAlertaLido() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => AlertasApi.marcarLido(id),
    onSuccess: () => invalidar(cliente, ["alertas"]),
  });
}

export function useMarcarTodosAlertasLidos() {
  const cliente = useQueryClient();
  return useMutation({
    mutationFn: () => AlertasApi.marcarTodosLidos(),
    onSuccess: () => invalidar(cliente, ["alertas"]),
  });
}
