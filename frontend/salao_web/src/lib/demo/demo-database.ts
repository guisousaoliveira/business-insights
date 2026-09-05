import { ApiError, AppErrorCodes } from "../error-codes";
import type { Envelope } from "../http";
import type {
  Alerta,
  AlertasPagina,
  Atendimento,
  AtendimentoMaterial,
  AtendimentoServico,
  AtendimentosPagina,
  CategoriaEstoque,
  CategoriaGasto,
  CustoFixo,
  CustosFixosPagina,
  EstoquePagina,
  FaltanteEstoque,
  FormaPagamento,
  Gasto,
  GastosPagina,
  ItemEstoque,
  Kit,
  Movimentacao,
  Perfil,
  PontoHistorico,
  PreferenciasAlerta,
  ProdutoPadrao,
  ResumoMensal,
  Servico,
  ServicoRealizado,
  SeveridadeAlerta,
  StatusAtendimento,
  StatusEstoque,
  TipoAlerta,
  TipoMovimentacao,
  UnidadeEstoque,
} from "../types";
import {
  agoraIso,
  competenciaDe,
  diferencaEmDias,
  emDias,
  hoje,
  noMes,
  paraDataApi,
  paraIso,
  parseData,
  ultimoDiaDoMes,
  vencimentoNoMes,
} from "./datas";

/**
 * Servidor falso do modo demo — o backend inteiro, em memória.
 *
 * Porte fiel de `frontend/salao_app/lib/repositories/demo/demo_database.dart`.
 * Os dois precisam concordar: são a mesma especificação executável do FastAPI
 * que ainda não existe, e é contra eles que o backend vai ser conferido.
 *
 * Três regras que ele segue de propósito, porque são as que o app assume:
 *
 * 1. **Devolve envelope, não modelo.** Todo retorno passa pelo mesmo
 *    `{ total, mensagem, codigo, result }` e desce pelo mesmo caminho de
 *    produção. O que está aqui é, literalmente, um exemplo executável do
 *    payload que o backend precisa produzir.
 * 2. **Erro de negócio é `ApiError` com `codigo`.** Inclusive o
 *    `result.faltantes` das duas passadas de estoque (regra A5).
 * 3. **O servidor entrega número pronto** (S7): status, déficit, margem,
 *    totais e alertas são calculados aqui, nunca na tela.
 *
 * **Não é cache e não é offline-first** (A4): o estado vive na aba e some no
 * reload.
 */

// ── Linhas das "tabelas" ─────────────────────────────────────────────────────

interface ItemRow {
  id: string;
  nome: string;
  unidade: UnidadeEstoque;
  categoria: CategoriaEstoque;
  quantidade_atual: number;
  quantidade_minima: number;
  custo_medio: number;
  custo_ultima_compra: number;
  ativo: boolean;
}

interface ServicoRow {
  id: string;
  nome: string;
  preco: number;
  produtos_padrao: ProdutoPadrao[];
}

interface KitRow {
  id: string;
  nome: string;
  preco_venda: number;
  quantidade_montada: number;
  itens: { item_estoque_id: string; quantidade: number }[];
}

interface KitVendaRow {
  kit_id: string;
  nome: string;
  quantidade: number;
  preco_unitario: number;
  custo_unitario: number;
  forma_pagamento: FormaPagamento;
  data: string;
}

interface AtendimentoRow {
  id: string;
  cliente_nome: string;
  cliente_telefone: string | null;
  data: string;
  status: StatusAtendimento;
  servicos: AtendimentoServico[];
  materiais: AtendimentoMaterial[];
}

interface GastoRow {
  id: string;
  nome: string;
  valor: number;
  prazo_pagamento: string;
  forma_pagamento: FormaPagamento;
  categoria: CategoriaGasto;
  pago: boolean;
  pago_em: string | null;
  itens: { nome: string; preco: number }[];
}

interface CustoFixoRow {
  id: string;
  descricao: string;
  valor: number;
  dia_vencimento: number;
}

/** Corpos aceitos — o que o app manda, ainda sem validar. */
type Body = Record<string, unknown>;

function texto(body: Body, chave: string): string {
  return String(body[chave] ?? "");
}

function numero(body: Body, chave: string, padrao = 0): number {
  const valor = body[chave];
  return typeof valor === "number" ? valor : Number(valor ?? padrao) || padrao;
}

function lista(body: Body, chave: string): Body[] {
  const valor = body[chave];
  return Array.isArray(valor) ? (valor as Body[]) : [];
}

export class DemoDatabase {
  /**
   * Latência artificial. Sem ela os `loading` piscam e ninguém vê o estado de
   * carregamento que o app tem em cada operação.
   */
  static readonly latencia = 320;

  /**
   * Uma semana de antecedência para tudo que vence: gasto pendente e custo
   * fixo. É o prazo que dá tempo de fazer alguma coisa — avisar no dia é só
   * informar que já era tarde. Vira o padrão das preferências de alerta.
   */
  static readonly diasAntecedenciaVencimento = 7;

  private seq = 0;

  private readonly itens: ItemRow[] = [];
  private readonly movimentacoes: Movimentacao[] = [];
  private readonly servicos: ServicoRow[] = [];
  private readonly kits: KitRow[] = [];
  private readonly kitVendas: KitVendaRow[] = [];
  private readonly atendimentos: AtendimentoRow[] = [];
  private readonly gastos: GastoRow[] = [];
  private readonly custosFixos: CustoFixoRow[] = [];

  /**
   * `custo fixo → { competência: data em que foi pago }`.
   *
   * Tabela à parte de propósito: custo fixo não se paga uma vez, ele volta todo
   * mês. Guardar `pago` dentro do cadastro faria o aluguel pago em setembro
   * nascer pago em outubro.
   */
  private readonly custosFixosPagos = new Map<string, Map<string, string>>();

  private readonly alertasLidos = new Set<string>();

  private perfil: Perfil = {
    id: "demo-salao",
    nome: "",
    proprietaria: "",
    foto_url: null,
    telefone_whatsapp: null,
    meta_faturamento_mensal: 0,
  };

  private preferencias: PreferenciasAlerta = {
    limite_saldo_alerta: 200,
    dias_antecedencia_vencimento: DemoDatabase.diasAntecedenciaVencimento,
    canais: {
      in_app: { ativo: true },
      push: { ativo: true },
      whatsapp: { ativo: false },
      email: { ativo: false },
    },
    tipos_silenciados: [],
  };

  constructor() {
    this.semear();
  }

  private novoId(prefixo: string): string {
    this.seq += 1;
    return `${prefixo}-${this.seq}`;
  }

  // ── Envelope e erro ────────────────────────────────────────────────────────

  /** O envelope do §0 do contrato, igual para sucesso e falha. */
  private envelope<T>(result: T, total = 0, mensagem = "ok"): Envelope<T> {
    return { total, mensagem, codigo: null, result };
  }

  private vazio(): Envelope<null> {
    return this.envelope(null);
  }

  private erro(codigo: string, status: number, mensagem: string, result: unknown = null): never {
    throw new ApiError(status, codigo, mensagem, result);
  }

  private naoEncontrado(oQue: string): never {
    return this.erro(AppErrorCodes.notFound, 404, `${oQue} não encontrado.`);
  }

  // ── Estoque: cálculo ───────────────────────────────────────────────────────

  private itemPorId(id: string): ItemRow {
    const item = this.itens.find((e) => e.id === id);
    if (!item) this.naoEncontrado("Item");
    return item;
  }

  /**
   * `negativo` é status próprio: "devo mais do que tenho" não é a mesma coisa
   * que "acabou" (A5).
   */
  private static statusDoItem(atual: number, minima: number): StatusEstoque {
    if (atual < 0) return "negativo";
    if (atual === 0) return "critico";
    if (atual <= minima) return "alerta";
    return "ok";
  }

  private itemToApi(row: ItemRow): ItemEstoque {
    return {
      id: row.id,
      nome: row.nome,
      unidade: row.unidade,
      categoria: row.categoria,
      quantidade_atual: row.quantidade_atual,
      quantidade_minima: row.quantidade_minima,
      custo_medio: row.custo_medio,
      custo_ultima_compra: row.custo_ultima_compra,
      status: DemoDatabase.statusDoItem(row.quantidade_atual, row.quantidade_minima),
      deficit: Math.max(0, row.quantidade_minima - row.quantidade_atual),
      ativo: row.ativo,
    };
  }

  private movimentar(
    item: ItemRow,
    tipo: TipoMovimentacao,
    quantidade: number,
    motivo: string,
    atendimentoId: string | null = null,
  ): void {
    this.movimentacoes.unshift({
      id: this.novoId("mov"),
      item_id: item.id,
      item_nome: item.nome,
      tipo,
      quantidade,
      motivo,
      atendimento_id: atendimentoId,
      criado_em: agoraIso(),
    });
  }

  /**
   * A primeira passada de A5: devolve o que falta **sem gravar nada**.
   *
   * `pedidos` é `{ item_estoque_id: quantidade }`. Lista vazia = tem saldo para
   * tudo.
   */
  private faltantes(pedidos: Map<string, number>): FaltanteEstoque[] {
    const faltando: FaltanteEstoque[] = [];
    pedidos.forEach((quantidade, itemId) => {
      const item = this.itemPorId(itemId);
      if (item.quantidade_atual >= quantidade) return;
      faltando.push({
        item_estoque_id: item.id,
        nome: item.nome,
        unidade: item.unidade,
        quantidade_solicitada: quantidade,
        quantidade_disponivel: item.quantidade_atual,
        deficit: quantidade - item.quantidade_atual,
      });
    });
    return faltando;
  }

  private estoqueInsuficiente(faltantes: FaltanteEstoque[]): never {
    return this.erro(AppErrorCodes.insufficientStock, 409, "Estoque insuficiente para concluir.", {
      faltantes,
    });
  }

  // ── Kits: cálculo ──────────────────────────────────────────────────────────

  private kitPorId(id: string): KitRow {
    const kit = this.kits.find((e) => e.id === id);
    if (!kit) this.naoEncontrado("Kit");
    return kit;
  }

  private custoDoKit(kit: KitRow): number {
    return kit.itens.reduce(
      (custo, linha) =>
        custo + linha.quantidade * this.itemPorId(linha.item_estoque_id).custo_medio,
      0,
    );
  }

  /**
   * Quantos kits o estoque de hoje ainda cobre — `min(saldo ÷ composição)`.
   * Separado de `quantidade_montada`, que é o que já está pronto na prateleira
   * (A7).
   */
  private montavel(kit: KitRow): number {
    if (kit.itens.length === 0) return 0;
    let minimo = Number.POSITIVE_INFINITY;
    for (const linha of kit.itens) {
      if (linha.quantidade <= 0) continue;
      const item = this.itemPorId(linha.item_estoque_id);
      minimo = Math.min(minimo, item.quantidade_atual / linha.quantidade);
    }
    if (!Number.isFinite(minimo)) return 0;
    return Math.max(0, Math.floor(minimo));
  }

  private kitToApi(kit: KitRow): Kit {
    const custo = this.custoDoKit(kit);
    const montavel = this.montavel(kit);
    return {
      id: kit.id,
      nome: kit.nome,
      preco_venda: kit.preco_venda,
      custo_total: custo,
      margem: kit.preco_venda - custo,
      quantidade_montada: kit.quantidade_montada,
      quantidade_montavel: montavel,
      disponivel: kit.quantidade_montada > 0 || montavel > 0,
      itens: kit.itens.map((linha) => {
        const item = this.itemPorId(linha.item_estoque_id);
        return {
          item_estoque_id: item.id,
          nome: item.nome,
          quantidade: linha.quantidade,
          unidade: item.unidade,
        };
      }),
    };
  }

  // ── Atendimentos e gastos: cálculo ─────────────────────────────────────────

  private atendimentoToApi(row: AtendimentoRow): Atendimento {
    const totalServicos = row.servicos.reduce((soma, e) => soma + e.preco, 0);
    const totalMateriais = row.materiais.reduce((soma, e) => soma + e.preco, 0);
    return {
      id: row.id,
      cliente_nome: row.cliente_nome,
      cliente_telefone: row.cliente_telefone,
      data: row.data,
      status: row.status,
      servicos: row.servicos,
      materiais: row.materiais,
      total_servicos: totalServicos,
      total_materiais: totalMateriais,
      saldo: totalServicos - totalMateriais,
    };
  }

  private gastoToApi(row: GastoRow): Gasto {
    return {
      id: row.id,
      nome: row.nome,
      valor: row.valor,
      prazo_pagamento: row.prazo_pagamento,
      forma_pagamento: row.forma_pagamento,
      categoria: row.categoria,
      pago: row.pago,
      pago_em: row.pago_em,
      // Negativo = vencido. Quem calcula prazo é o servidor: é a mesma regra
      // que gera o alerta de gasto a vencer.
      vence_em_dias: diferencaEmDias(parseData(row.prazo_pagamento), hoje()),
      itens: row.itens,
    };
  }

  // ── auth ───────────────────────────────────────────────────────────────────

  /**
   * Aceita qualquer e-mail e qualquer senha — **menos a senha `errada`**, que
   * devolve `AUTH_CREDENCIAIS_INVALIDAS`. É a única forma de ver o caminho de
   * erro do login sem backend; convenção do modo demo, não contrato de API.
   */
  login(email: string, senha: string): Envelope<unknown> {
    if (senha === "errada") {
      this.erro(AppErrorCodes.invalidCredentials, 401, "E-mail ou senha incorretos.");
    }
    return this.envelope({
      token: "demo-token",
      refresh_token: "demo-refresh-token",
      expira_em: 3600,
      usuario: { id: "demo-usuario", nome: this.perfil.proprietaria, email },
      salao: { id: this.perfil.id, nome: this.perfil.nome, foto_url: this.perfil.foto_url },
    });
  }

  eu(): Envelope<unknown> {
    return this.envelope({
      usuario: {
        id: "demo-usuario",
        nome: this.perfil.proprietaria,
        email: "demo@thamiresbeauty.com.br",
      },
      salao: { id: this.perfil.id, nome: this.perfil.nome, foto_url: this.perfil.foto_url },
    });
  }

  // ── atendimentos ───────────────────────────────────────────────────────────

  /**
   * [status] é a query csv opcional de `GET /atendimentos`. Vazia significa
   * "todos" — o filtro da tela manda a lista, não o app inteiro.
   */
  getAtendimentos(inicio: Date, fim: Date, status: string[] = []): Envelope<AtendimentosPagina> {
    const limite = new Date(fim.getFullYear(), fim.getMonth(), fim.getDate(), 23, 59, 59);
    const atendimentos = this.atendimentos
      .filter((e) => {
        const data = parseData(e.data);
        if (data < inicio || data > limite) return false;
        return status.length === 0 || status.includes(e.status);
      })
      .map((e) => this.atendimentoToApi(e))
      .sort((a, b) => b.data.localeCompare(a.data));

    const saldo = atendimentos
      .filter((e) => e.status === "finalizado")
      .reduce((soma, e) => soma + e.saldo, 0);

    return this.envelope(
      { saldo_liquido: saldo, quantidade: atendimentos.length, atendimentos },
      atendimentos.length,
    );
  }

  getAtendimento(id: string): Envelope<Atendimento> {
    const row = this.atendimentos.find((e) => e.id === id);
    if (!row) this.naoEncontrado("Atendimento");
    return this.envelope(this.atendimentoToApi(row));
  }

  /**
   * Preço do catálogo é congelado aqui, no servidor: mudar a tabela de preços
   * depois não pode reescrever o histórico financeiro. Serviço avulso chega com
   * nome e preço e passa direto.
   */
  private congelarServicos(servicos: Body[]): AtendimentoServico[] {
    return servicos.map((linha) => {
      const id = linha["servico_id"];
      if (typeof id !== "string") {
        return { servico_id: null, nome: texto(linha, "nome"), preco: numero(linha, "preco") };
      }
      const servico = this.servicos.find((s) => s.id === id);
      if (!servico) this.naoEncontrado("Serviço");
      return { servico_id: servico.id, nome: servico.nome, preco: servico.preco };
    });
  }

  createAtendimento(body: Body): Envelope<null> {
    this.atendimentos.push({
      id: this.novoId("atendimento"),
      cliente_nome: texto(body, "cliente_nome"),
      cliente_telefone: (body["cliente_telefone"] as string | null) ?? null,
      data: texto(body, "data"),
      status: "agendado",
      servicos: this.congelarServicos(lista(body, "servicos")),
      materiais: [],
    });
    return this.vazio();
  }

  /**
   * `PATCH /atendimentos/{id}`: cliente, data e serviços. Cancelado recusa —
   * registro fora das contas não se reescreve. Finalizado aceita, e o preço do
   * catálogo é congelado de novo, igual à criação.
   */
  editAtendimento(id: string, body: Body): Envelope<null> {
    const atendimento = this.atendimentos.find((e) => e.id === id);
    if (!atendimento) this.naoEncontrado("Atendimento");
    if (atendimento.status === "cancelado") {
      this.erro(
        AppErrorCodes.appointmentInvalidStatus,
        409,
        "Um atendimento cancelado não pode ser editado.",
      );
    }

    atendimento.cliente_nome = texto(body, "cliente_nome");
    atendimento.cliente_telefone = (body["cliente_telefone"] as string | null) ?? null;
    atendimento.data = texto(body, "data");
    atendimento.servicos = this.congelarServicos(lista(body, "servicos"));
    return this.vazio();
  }

  /**
   * As duas passadas de A5. Com saldo faltando e `confirmar` em `false`, sai
   * `409 ESTOQUE_INSUFICIENTE` e **nada** é gravado — nem parcialmente.
   */
  finalizarAtendimento(id: string, body: Body): Envelope<null> {
    const atendimento = this.atendimentos.find((e) => e.id === id);
    if (!atendimento) this.naoEncontrado("Atendimento");
    if (atendimento.status !== "agendado") {
      this.erro(AppErrorCodes.appointmentInvalidStatus, 409, "Este atendimento não está agendado.");
    }

    const materiais = lista(body, "materiais");
    const pedidos = new Map<string, number>();
    for (const material of materiais) {
      const itemId = material["item_estoque_id"];
      if (typeof itemId !== "string") continue;
      pedidos.set(itemId, (pedidos.get(itemId) ?? 0) + numero(material, "quantidade"));
    }

    const faltando = this.faltantes(pedidos);
    const confirmou = body["confirmar_estoque_insuficiente"] === true;
    // O confirmar libera **só** a checagem de saldo. Status inválido e material
    // inexistente continuam recusando — os dois já barraram acima.
    if (faltando.length > 0 && !confirmou) this.estoqueInsuficiente(faltando);

    const gravados: AtendimentoMaterial[] = [];
    for (const material of materiais) {
      const itemId = material["item_estoque_id"];
      const quantidade = numero(material, "quantidade");
      if (typeof itemId !== "string") {
        gravados.push({
          item_estoque_id: null,
          nome: texto(material, "nome"),
          quantidade,
          preco: numero(material, "preco"),
        });
        continue;
      }
      const item = this.itemPorId(itemId);
      item.quantidade_atual -= quantidade;
      this.movimentar(item, "saida", quantidade, "Atendimento", id);
      gravados.push({
        item_estoque_id: item.id,
        nome: item.nome,
        quantidade,
        // O custo do material é o custo médio de hoje (A6), congelado na linha.
        preco: quantidade * item.custo_medio,
      });
    }

    atendimento.materiais = gravados;
    atendimento.status = "finalizado";
    return this.vazio();
  }

  cancelarAtendimento(id: string): Envelope<null> {
    const atendimento = this.atendimentos.find((e) => e.id === id);
    if (!atendimento) this.naoEncontrado("Atendimento");
    if (atendimento.status === "cancelado") {
      this.erro(AppErrorCodes.appointmentInvalidStatus, 409, "Este atendimento já está cancelado.");
    }

    // Cancelar um atendimento já finalizado estorna a baixa que a finalização
    // deu — senão o estoque fica devendo material que nunca foi usado.
    if (atendimento.status === "finalizado") {
      for (const material of atendimento.materiais) {
        if (!material.item_estoque_id) continue;
        const item = this.itemPorId(material.item_estoque_id);
        item.quantidade_atual += material.quantidade;
        this.movimentar(
          item,
          "entrada",
          material.quantidade,
          "Estorno — atendimento cancelado",
          id,
        );
      }
      atendimento.materiais = [];
    }

    atendimento.status = "cancelado";
    return this.vazio();
  }

  deleteAtendimento(id: string): Envelope<null> {
    const index = this.atendimentos.findIndex((e) => e.id === id);
    if (index >= 0) this.atendimentos.splice(index, 1);
    return this.vazio();
  }

  // ── gastos ─────────────────────────────────────────────────────────────────

  getGastos(ano: number, mes: number): Envelope<GastosPagina> {
    const gastos = this.gastos
      .filter((e) => noMes(parseData(e.prazo_pagamento), ano, mes))
      .map((e) => this.gastoToApi(e))
      .sort((a, b) => a.prazo_pagamento.localeCompare(b.prazo_pagamento));

    return this.envelope(
      {
        total_pendente: gastos.filter((e) => !e.pago).reduce((soma, e) => soma + e.valor, 0),
        total_pago_mes: gastos.filter((e) => e.pago).reduce((soma, e) => soma + e.valor, 0),
        gastos,
      },
      gastos.length,
    );
  }

  createGasto(body: Body): Envelope<null> {
    this.gastos.push({
      id: this.novoId("gasto"),
      nome: texto(body, "nome"),
      valor: numero(body, "valor"),
      prazo_pagamento: texto(body, "prazo_pagamento"),
      forma_pagamento: (body["forma_pagamento"] as FormaPagamento) ?? "a_vista",
      categoria: (body["categoria"] as CategoriaGasto) ?? "outros",
      pago: false,
      pago_em: null,
      itens: (body["itens"] as GastoRow["itens"]) ?? [],
    });
    return this.vazio();
  }

  editGasto(id: string, body: Body): Envelope<null> {
    const gasto = this.gastos.find((e) => e.id === id);
    if (!gasto) this.naoEncontrado("Gasto");

    if ("nome" in body) gasto.nome = texto(body, "nome");
    if ("valor" in body) gasto.valor = numero(body, "valor");
    if ("prazo_pagamento" in body) gasto.prazo_pagamento = texto(body, "prazo_pagamento");
    if ("forma_pagamento" in body)
      gasto.forma_pagamento = body["forma_pagamento"] as FormaPagamento;
    if ("categoria" in body) gasto.categoria = body["categoria"] as CategoriaGasto;
    if ("itens" in body) gasto.itens = (body["itens"] as GastoRow["itens"]) ?? [];
    return this.vazio();
  }

  pagarGasto(id: string): Envelope<null> {
    const gasto = this.gastos.find((e) => e.id === id);
    if (!gasto) this.naoEncontrado("Gasto");
    if (gasto.pago) {
      this.erro(AppErrorCodes.expenseAlreadyPaid, 409, "Este gasto já está pago.");
    }
    gasto.pago = true;
    gasto.pago_em = agoraIso();
    return this.vazio();
  }

  deleteGasto(id: string): Envelope<null> {
    const index = this.gastos.findIndex((e) => e.id === id);
    if (index >= 0) this.gastos.splice(index, 1);
    return this.vazio();
  }

  // ── estoque ────────────────────────────────────────────────────────────────

  getItens(): Envelope<EstoquePagina> {
    const itens = this.itens
      .filter((e) => e.ativo)
      .map((e) => this.itemToApi(e))
      .sort((a, b) => a.nome.localeCompare(b.nome, "pt-BR"));

    return this.envelope(
      {
        total_alertas: itens.filter((e) => e.status !== "ok").length,
        valor_total: itens.reduce((soma, e) => soma + e.quantidade_atual * e.custo_medio, 0),
        itens,
      },
      itens.length,
    );
  }

  createItem(body: Body): Envelope<null> {
    const quantidade = numero(body, "quantidade_atual");
    const custo = numero(body, "custo_unitario");
    const item: ItemRow = {
      id: this.novoId("item"),
      nome: texto(body, "nome"),
      unidade: (body["unidade"] as UnidadeEstoque) ?? "un",
      categoria: (body["categoria"] as CategoriaEstoque) ?? "outro",
      quantidade_atual: quantidade,
      quantidade_minima: numero(body, "quantidade_minima"),
      custo_medio: custo,
      custo_ultima_compra: custo,
      ativo: true,
    };
    this.itens.push(item);
    if (quantidade > 0) this.movimentar(item, "entrada", quantidade, "Cadastro do item");
    return this.vazio();
  }

  editItem(id: string, body: Body): Envelope<null> {
    const item = this.itemPorId(id);
    if ("nome" in body) item.nome = texto(body, "nome");
    if ("unidade" in body) item.unidade = body["unidade"] as UnidadeEstoque;
    if ("categoria" in body) item.categoria = body["categoria"] as CategoriaEstoque;
    if ("quantidade_minima" in body) item.quantidade_minima = numero(body, "quantidade_minima");
    // Saldo não se edita: ele é o acumulado das movimentações. Corrigir
    // contagem é lançar um `ajuste` — é por isso que existe histórico.
    return this.vazio();
  }

  deleteItem(id: string): Envelope<null> {
    const item = this.itemPorId(id);

    // Item que compõe kit não sai: apagar deixaria o kit sem custo e sem
    // composição.
    const emKit = this.kits.some((kit) => kit.itens.some((linha) => linha.item_estoque_id === id));
    if (emKit) {
      this.erro(AppErrorCodes.itemInUse, 409, "Este item faz parte de um kit.");
    }

    // Com movimentação, é soft delete — apagar quebraria o histórico de custo
    // dos atendimentos que já usaram o item.
    if (this.movimentacoes.some((e) => e.item_id === id)) {
      item.ativo = false;
    } else {
      this.itens.splice(this.itens.indexOf(item), 1);
    }
    return this.vazio();
  }

  /**
   * Média ponderada móvel (A6): uma compra cara ou promocional move o custo na
   * proporção do que entrou, em vez de reescrever o saldo parado.
   */
  createMovimentacao(itemId: string, body: Body): Envelope<null> {
    const item = this.itemPorId(itemId);
    const tipo = (body["tipo"] as TipoMovimentacao) ?? "entrada";
    const quantidade = numero(body, "quantidade");
    const custoUnitario =
      typeof body["custo_unitario"] === "number" ? (body["custo_unitario"] as number) : null;
    const saldo = item.quantidade_atual;

    if (tipo === "entrada") {
      if (custoUnitario !== null) {
        item.custo_medio =
          saldo <= 0
            ? custoUnitario
            : (saldo * item.custo_medio + quantidade * custoUnitario) / (saldo + quantidade);
        item.custo_ultima_compra = custoUnitario;
      }
      item.quantidade_atual = saldo + quantidade;
    } else if (tipo === "saida") {
      item.quantidade_atual = saldo - quantidade;
    } else {
      // `ajuste` é contagem: define o saldo.
      item.quantidade_atual = quantidade;
    }

    this.movimentar(item, tipo, quantidade, texto(body, "motivo"));
    return this.vazio();
  }

  getMovimentacoes(itemId?: string): Envelope<{ movimentacoes: Movimentacao[] }> {
    const movimentacoes = this.movimentacoes.filter((e) => !itemId || e.item_id === itemId);
    return this.envelope({ movimentacoes }, movimentacoes.length);
  }

  // ── kits ───────────────────────────────────────────────────────────────────

  getKits(): Envelope<{ kits: Kit[] }> {
    const kits = this.kits.map((e) => this.kitToApi(e));
    return this.envelope({ kits }, kits.length);
  }

  createKit(body: Body): Envelope<null> {
    this.kits.push({
      id: this.novoId("kit"),
      nome: texto(body, "nome"),
      preco_venda: numero(body, "preco_venda"),
      quantidade_montada: 0,
      itens: lista(body, "itens").map((linha) => ({
        item_estoque_id: texto(linha, "item_estoque_id"),
        quantidade: numero(linha, "quantidade"),
      })),
    });
    return this.vazio();
  }

  editKit(id: string, body: Body): Envelope<null> {
    const kit = this.kitPorId(id);
    if ("nome" in body) kit.nome = texto(body, "nome");
    if ("preco_venda" in body) kit.preco_venda = numero(body, "preco_venda");
    if ("itens" in body) {
      kit.itens = lista(body, "itens").map((linha) => ({
        item_estoque_id: texto(linha, "item_estoque_id"),
        quantidade: numero(linha, "quantidade"),
      }));
    }
    return this.vazio();
  }

  deleteKit(id: string): Envelope<null> {
    const index = this.kits.findIndex((e) => e.id === id);
    if (index >= 0) this.kits.splice(index, 1);
    return this.vazio();
  }

  /** Montar consome insumo e passa pelo aviso de A5, igual à finalização. */
  montarKit(id: string, body: Body): Envelope<null> {
    const kit = this.kitPorId(id);
    const quantidade = numero(body, "quantidade");
    const confirmou = body["confirmar_estoque_insuficiente"] === true;

    const pedidos = new Map<string, number>();
    for (const linha of kit.itens) {
      pedidos.set(
        linha.item_estoque_id,
        (pedidos.get(linha.item_estoque_id) ?? 0) + linha.quantidade * quantidade,
      );
    }

    const faltando = this.faltantes(pedidos);
    if (faltando.length > 0 && !confirmou) this.estoqueInsuficiente(faltando);

    pedidos.forEach((total, itemId) => {
      const item = this.itemPorId(itemId);
      item.quantidade_atual -= total;
      this.movimentar(item, "saida", total, "Montagem de kit");
    });

    kit.quantidade_montada += quantidade;
    return this.vazio();
  }

  /**
   * Vender **não** tem segunda passada (A7): um kit que não foi montado não
   * existe para vender.
   */
  venderKit(id: string, body: Body): Envelope<null> {
    const kit = this.kitPorId(id);
    const quantidade = numero(body, "quantidade");

    if (quantidade > kit.quantidade_montada) {
      this.erro(
        AppErrorCodes.kitNotAssembled,
        409,
        "Você tem menos kits montados do que está vendendo.",
        { quantidade_montada: kit.quantidade_montada, quantidade_solicitada: quantidade },
      );
    }

    kit.quantidade_montada -= quantidade;
    this.kitVendas.push({
      kit_id: kit.id,
      nome: kit.nome,
      quantidade,
      preco_unitario:
        typeof body["preco_unitario"] === "number"
          ? (body["preco_unitario"] as number)
          : kit.preco_venda,
      custo_unitario: this.custoDoKit(kit),
      forma_pagamento: (body["forma_pagamento"] as FormaPagamento) ?? "a_vista",
      data: typeof body["data"] === "string" ? (body["data"] as string) : agoraIso(),
    });
    return this.vazio();
  }

  // ── perfil e serviços ──────────────────────────────────────────────────────

  getPerfil(): Envelope<{ salao: Perfil }> {
    return this.envelope({ salao: this.perfil });
  }

  updatePerfil(body: Body): Envelope<null> {
    this.perfil = { ...this.perfil, ...(body as Partial<Perfil>) };
    return this.vazio();
  }

  /**
   * O `pago` não sai do cadastro, sai da tabela de pagamentos — por isso o mês
   * que vira zera todo mundo sem ninguém precisar desmarcar nada.
   *
   * Sem `competencia`, vale o mês corrente: é o mês que ela está fechando.
   */
  getCustosFixos(competencia?: string): Envelope<CustosFixosPagina> {
    const alvo =
      competencia && /^\d{4}-(0[1-9]|1[0-2])$/.test(competencia)
        ? competencia
        : competenciaDe(hoje());

    let pago = 0;
    let pendente = 0;
    const custos: CustoFixo[] = this.custosFixos.map((custo) => {
      const pagoEm = this.custosFixosPagos.get(custo.id)?.get(alvo) ?? null;
      if (pagoEm === null) pendente += custo.valor;
      else pago += custo.valor;

      return { ...custo, competencia: alvo, pago: pagoEm !== null, pago_em: pagoEm };
    });

    return this.envelope(
      {
        total_mensal: pago + pendente,
        total_pago: pago,
        total_pendente: pendente,
        custos,
      },
      custos.length,
    );
  }

  createCustoFixo(body: Body): Envelope<null> {
    this.custosFixos.push({
      id: this.novoId("custo"),
      descricao: texto(body, "descricao"),
      valor: numero(body, "valor"),
      dia_vencimento: this.diaVencimento(body),
    });
    return this.vazio();
  }

  editCustoFixo(id: string, body: Body): Envelope<null> {
    const custo = this.custosFixos.find((e) => e.id === id);
    if (!custo) this.naoEncontrado("Custo fixo");

    custo.descricao = texto(body, "descricao");
    custo.valor = numero(body, "valor");
    custo.dia_vencimento = this.diaVencimento(body);
    return this.vazio();
  }

  /**
   * O dia é obrigatório no contrato, mas quem manda fora da faixa 1..31 leva
   * 422 — deixar passar um "dia 40" é criar uma data que nunca chega.
   */
  private diaVencimento(body: Body): number {
    const dia = Number(body["dia_vencimento"]);
    if (!Number.isFinite(dia) || dia < 1 || dia > 31) {
      this.erro(AppErrorCodes.invalidValidation, 422, "Dia de vencimento deve estar entre 1 e 31.");
    }
    return Math.trunc(dia);
  }

  deleteCustoFixo(id: string): Envelope<null> {
    const index = this.custosFixos.findIndex((e) => e.id === id);
    if (index >= 0) this.custosFixos.splice(index, 1);
    this.custosFixosPagos.delete(id);
    return this.vazio();
  }

  /**
   * Marca ou desmarca o pagamento de uma competência.
   *
   * Desmarcar é tão necessário quanto marcar: um toque errado no celular não
   * pode calar o alerta do aluguel pelo mês inteiro.
   */
  pagarCustoFixo(id: string, body: Body): Envelope<null> {
    if (!this.custosFixos.some((e) => e.id === id)) this.naoEncontrado("Custo fixo");

    const competencia = texto(body, "competencia");
    if (!/^\d{4}-(0[1-9]|1[0-2])$/.test(competencia)) {
      this.erro(AppErrorCodes.invalidValidation, 422, "Competência deve estar no formato AAAA-MM.");
    }

    let pagamentos = this.custosFixosPagos.get(id);
    if (!pagamentos) {
      pagamentos = new Map<string, string>();
      this.custosFixosPagos.set(id, pagamentos);
    }

    if (body["pago"] === false) pagamentos.delete(competencia);
    else pagamentos.set(competencia, agoraIso());
    return this.vazio();
  }

  getServicos(): Envelope<{ servicos: Servico[] }> {
    return this.envelope({ servicos: this.servicos }, this.servicos.length);
  }

  createServico(body: Body): Envelope<null> {
    this.servicos.push({
      id: this.novoId("servico"),
      nome: texto(body, "nome"),
      preco: numero(body, "preco"),
      produtos_padrao: this.produtosPadrao(body),
    });
    return this.vazio();
  }

  editServico(id: string, body: Body): Envelope<null> {
    const servico = this.servicos.find((e) => e.id === id);
    if (!servico) this.naoEncontrado("Serviço");

    servico.nome = texto(body, "nome");
    servico.preco = numero(body, "preco");
    servico.produtos_padrao = this.produtosPadrao(body);
    return this.vazio();
  }

  /**
   * O corpo manda só `item_estoque_id` + `quantidade`; nome e unidade são do
   * item, e o servidor devolve resolvidos — senão a tela de finalizar
   * atendimento teria que cruzar duas listas para escrever "2 cx".
   *
   * Id inexistente é 404 aqui mesmo: vincular material fantasma criaria uma
   * baixa de estoque que nunca fecha.
   */
  private produtosPadrao(body: Body): ProdutoPadrao[] {
    const linhas = lista(body, "produtos_padrao").map((linha) => {
      const item = this.itemPorId(texto(linha, "item_estoque_id"));
      return {
        item_estoque_id: item.id,
        nome: item.nome,
        quantidade: numero(linha, "quantidade"),
        unidade: item.unidade,
      };
    });

    // Item repetido é erro, não soma: duas linhas do mesmo material viram duas
    // baixas, e ninguém confere isso na hora de finalizar.
    const ids = new Set(linhas.map((e) => e.item_estoque_id));
    if (ids.size !== linhas.length) {
      this.erro(AppErrorCodes.invalidValidation, 422, "Material repetido na lista do serviço.");
    }
    return linhas;
  }

  deleteServico(id: string): Envelope<null> {
    const index = this.servicos.findIndex((e) => e.id === id);
    if (index >= 0) this.servicos.splice(index, 1);
    return this.vazio();
  }

  // ── resumo ─────────────────────────────────────────────────────────────────

  getResumoMensal(ano: number, mes: number): Envelope<ResumoMensal> {
    return this.envelope(this.resumo(ano, mes, true));
  }

  private saldoDoMes(ano: number, mes: number): number {
    return this.resumo(ano, mes, false).saldo_final;
  }

  /** Toda a conta do mês em um lugar. O app não soma nada disso (S7). */
  private resumo(ano: number, mes: number, comparar: boolean): ResumoMensal {
    const finalizados = this.atendimentos
      .filter((e) => e.status === "finalizado" && noMes(parseData(e.data), ano, mes))
      .map((e) => this.atendimentoToApi(e));

    const totalServicos = finalizados.reduce((soma, e) => soma + e.total_servicos, 0);
    const totalInsumos = finalizados.reduce((soma, e) => soma + e.total_materiais, 0);

    // Ranking por nome do serviço, não por id: serviço avulso também conta.
    const ranking = new Map<string, ServicoRealizado>();
    for (const atendimento of finalizados) {
      for (const servico of atendimento.servicos) {
        const linha = ranking.get(servico.nome) ?? {
          nome: servico.nome,
          quantidade: 0,
          total_receita: 0,
          lucro: 0,
        };
        linha.quantidade += 1;
        linha.total_receita += servico.preco;
        ranking.set(servico.nome, linha);
      }
    }
    const maisRealizados = [...ranking.values()].sort((a, b) => b.total_receita - a.total_receita);
    for (const servico of maisRealizados) {
      const custoRateado =
        totalServicos === 0 ? 0 : totalInsumos * (servico.total_receita / totalServicos);
      servico.lucro = servico.total_receita - custoRateado;
    }

    const vendas = this.kitVendas.filter((e) => noMes(parseData(e.data), ano, mes));
    const totalKits = vendas.reduce((soma, e) => soma + e.quantidade * e.preco_unitario, 0);
    const quantidadeKits = vendas.reduce((soma, e) => soma + e.quantidade, 0);
    const custoKits = vendas.reduce((soma, e) => soma + e.quantidade * e.custo_unitario, 0);

    // Custo fixo é o compromisso recorrente do perfil. O gasto de categoria
    // `fixo` é a materialização dele no mês — contar os dois somaria o mesmo
    // aluguel duas vezes.
    const totalCustosFixos = this.custosFixos.reduce((soma, e) => soma + e.valor, 0);
    const totalVariaveis = this.gastos
      .filter((e) => e.categoria !== "fixo" && noMes(parseData(e.prazo_pagamento), ano, mes))
      .reduce((soma, e) => soma + e.valor, 0);

    // Venda de kit é receita e entra no `entrou`. O custo do kit **não** entra
    // no `saiu`: já saiu quando o insumo foi comprado.
    const entrou = totalServicos + totalKits;
    const saiu = totalCustosFixos + totalVariaveis;
    const saldoFinal = entrou - saiu;

    const anterior = comparar
      ? this.saldoDoMes(mes === 1 ? ano - 1 : ano, mes === 1 ? 12 : mes - 1)
      : 0;

    const historico: PontoHistorico[] = comparar
      ? Array.from({ length: 6 }, (_, index) => {
          const periodo = new Date(ano, mes - 1 - (5 - index), 1);
          const parcial = this.resumo(periodo.getFullYear(), periodo.getMonth() + 1, false);
          return {
            ano: periodo.getFullYear(),
            mes: periodo.getMonth() + 1,
            receitas: parcial.entrou,
            despesas: parcial.saiu,
          };
        })
      : [];

    const primeiro = maisRealizados[0];

    return {
      ano,
      mes,
      saldo_final: saldoFinal,
      entrou,
      saiu,
      meta_faturamento_mensal: this.perfil.meta_faturamento_mensal,
      historico_seis_meses: historico,
      receita: {
        total_servicos: totalServicos,
        total_insumos: totalInsumos,
        liquido_atendimentos: totalServicos - totalInsumos,
        quantidade_atendimentos: finalizados.length,
        total_kits: totalKits,
        quantidade_kits_vendidos: Math.trunc(quantidadeKits),
        custo_kits_vendidos: custoKits,
        servicos_mais_realizados: maisRealizados.slice(0, 5),
      },
      gastos: {
        total_custos_fixos: totalCustosFixos,
        total_gastos_variaveis: totalVariaveis,
        total_saiu: saiu,
      },
      insights: {
        // Kit não é atendimento e diluiria o ticket que ela usa para precificar.
        ticket_medio: finalizados.length === 0 ? 0 : totalServicos / finalizados.length,
        margem_lucro_percentual: entrou === 0 ? 0 : (saldoFinal / entrou) * 100,
        variacao_percentual_mes_anterior:
          anterior === 0 ? 0 : ((saldoFinal - anterior) / Math.abs(anterior)) * 100,
        saldo_mes_anterior: anterior,
        servico_mais_lucrativo: primeiro
          ? { nome: primeiro.nome, lucro: primeiro.total_receita }
          : null,
      },
      // Trabalhou o mês e sobrou quase nada: o "zero a zero" do protótipo.
      alerta_zero_a_zero:
        entrou > 0 && saldoFinal >= 0 && saldoFinal < this.preferencias.limite_saldo_alerta,
    };
  }

  /** Cálculo puro de `POST /precificacao/calcular` — não toca em nada. */
  calcularPreco(body: Body, precoAtual: number | null): Envelope<unknown> {
    const custoMaterial = numero(body, "custo_material");
    const tempoMinutos = numero(body, "tempo_minutos", 1);
    const metaHora = numero(body, "meta_hora");
    const overhead = numero(body, "percentual_overhead", 0.15);
    const lucro = numero(body, "percentual_lucro", 0.2);

    const custoTempo = metaHora * (tempoMinutos / 60);
    const custoOverhead = (custoMaterial + custoTempo) * overhead;
    const custoTotal = custoMaterial + custoTempo + custoOverhead;
    const precoMinimo = custoTotal * (1 + lucro);

    return this.envelope({
      custo_material: custoMaterial,
      custo_tempo: custoTempo,
      custo_overhead: custoOverhead,
      custo_total: custoTotal,
      preco_minimo: precoMinimo,
      preco_sugerido: Math.ceil(precoMinimo / 5) * 5,
      cobrindo_custos: precoAtual === null ? null : precoAtual >= custoTotal,
      diferenca: precoAtual === null ? null : precoAtual - precoMinimo,
    });
  }

  // ── alertas ────────────────────────────────────────────────────────────────

  /**
   * Dias até o vencimento em aberto — negativo quando o dia deste mês já passou
   * e ninguém marcou como pago.
   *
   * Custo fixo não tem data, tem dia. Enquanto a competência corrente estiver
   * em aberto, o vencimento que interessa é o **deste mês**, e ele fica para
   * trás: é o que torna o `custo_fixo_vencido` possível. Pago o mês, o alvo
   * passa a ser o mês que vem.
   *
   * Mês curto encurta o dia: "todo dia 31" vira 28 em fevereiro. O dia 31
   * continua guardado; quem resolve o mês é este cálculo, na hora de avisar.
   */
  static diasAteVencer(
    diaVencimento: number,
    opcoes: { referencia?: Date; pagoNoMes?: boolean } = {},
  ): number {
    const referencia = opcoes.referencia ?? hoje();
    const desteMes = vencimentoNoMes(
      diaVencimento,
      referencia.getFullYear(),
      referencia.getMonth() + 1,
    );

    const proximo = new Date(referencia.getFullYear(), referencia.getMonth() + 1, 1);
    const alvo =
      desteMes < referencia && opcoes.pagoNoMes === true
        ? vencimentoNoMes(diaVencimento, proximo.getFullYear(), proximo.getMonth() + 1)
        : desteMes;
    return diferencaEmDias(alvo, referencia);
  }

  /**
   * Em produção quem gera é o job do backend. Aqui os alertas são derivados do
   * estado a cada leitura — por isso o id é estável (`tipo:referencia`): é o
   * que faz "marcar como lido" continuar valendo quando a lista é refeita.
   */
  private gerarAlertas(): Alerta[] {
    const agora = agoraIso();
    const lista: Alerta[] = [];

    const adicionar = (dados: {
      tipo: TipoAlerta;
      severidade: SeveridadeAlerta;
      titulo: string;
      mensagem: string;
      referenciaTipo?: Alerta["referencia_tipo"];
      referenciaId?: string;
      competencia?: string;
    }) => {
      const id =
        `${dados.tipo}:${dados.referenciaId ?? "geral"}` +
        `${dados.competencia === undefined ? "" : `:${dados.competencia}`}`;
      if (this.preferencias.tipos_silenciados.includes(dados.tipo)) return;
      lista.push({
        id,
        tipo: dados.tipo,
        severidade: dados.severidade,
        titulo: dados.titulo,
        mensagem: dados.mensagem,
        referencia_tipo: dados.referenciaTipo ?? null,
        referencia_id: dados.referenciaId ?? null,
        criado_em: agora,
        lido_em: this.alertasLidos.has(id) ? agora : null,
      });
    };

    for (const item of this.itens.filter((e) => e.ativo)) {
      const status = DemoDatabase.statusDoItem(item.quantidade_atual, item.quantidade_minima);
      if (status === "ok") continue;

      const tipo: TipoAlerta =
        status === "negativo"
          ? "estoque_negativo"
          : status === "critico"
            ? "estoque_critico"
            : "estoque_baixo";
      const titulo =
        status === "negativo"
          ? `${item.nome} está com saldo negativo`
          : status === "critico"
            ? `${item.nome} acabou`
            : `${item.nome} está no mínimo`;

      adicionar({
        tipo,
        severidade: status === "alerta" ? "alerta" : "critico",
        titulo,
        mensagem: `Saldo ${item.quantidade_atual} ${item.unidade}, mínimo ${item.quantidade_minima} ${item.unidade}.`,
        referenciaTipo: "estoque_item",
        referenciaId: item.id,
      });
    }

    const antecedencia = this.preferencias.dias_antecedencia_vencimento;

    for (const gasto of this.gastos.filter((e) => !e.pago)) {
      const dias = diferencaEmDias(parseData(gasto.prazo_pagamento), hoje());
      if (dias > antecedencia) continue;
      adicionar({
        tipo: dias < 0 ? "gasto_vencido" : "gasto_a_vencer",
        severidade: dias < 0 ? "critico" : "alerta",
        titulo: dias < 0 ? `${gasto.nome} venceu` : `${gasto.nome} vence em ${dias} dia(s)`,
        mensagem: `Valor de ${gasto.valor}.`,
        referenciaTipo: "gasto",
        referenciaId: gasto.id,
      });
    }

    const competenciaAtual = competenciaDe(hoje());
    for (const custo of this.custosFixos) {
      // Pago o mês, não há o que avisar. E o alerta some sozinho quando ela
      // marca — é o que dá sentido ao check na tela de perfil.
      if (this.custosFixosPagos.get(custo.id)?.has(competenciaAtual)) continue;

      const dias = DemoDatabase.diasAteVencer(custo.dia_vencimento);
      if (dias > antecedencia) continue;
      adicionar({
        tipo: dias < 0 ? "custo_fixo_vencido" : "custo_fixo_a_vencer",
        severidade: dias < 0 ? "critico" : "alerta",
        titulo:
          dias < 0
            ? `${custo.descricao} venceu`
            : dias === 0
              ? `${custo.descricao} vence hoje`
              : `${custo.descricao} vence em ${dias} dia(s)`,
        mensagem: `Valor de ${custo.valor}.`,
        referenciaTipo: "custo_fixo",
        referenciaId: custo.id,
        // A competência entra na chave de dedupe: o aluguel de setembro e o de
        // outubro são dois avisos, e marcar um como lido não cala o outro.
        competencia: competenciaAtual,
      });
    }

    const agoraData = new Date();
    const saldo = this.saldoDoMes(agoraData.getFullYear(), agoraData.getMonth() + 1);
    if (saldo < 0) {
      adicionar({
        tipo: "saldo_negativo",
        severidade: "critico",
        titulo: "O mês está negativo",
        mensagem: "Saiu mais do que entrou até agora.",
      });
    }

    return lista;
  }

  getAlertas(apenasNaoLidos?: boolean): Envelope<AlertasPagina> {
    const todos = this.gerarAlertas();
    const naoLidos = todos.filter((e) => e.lido_em === null);
    const alertas = apenasNaoLidos === true ? naoLidos : todos;

    return this.envelope(
      {
        total_nao_lidos: naoLidos.length,
        resumo: {
          critico: naoLidos.filter((e) => e.severidade === "critico").length,
          alerta: naoLidos.filter((e) => e.severidade === "alerta").length,
          info: naoLidos.filter((e) => e.severidade === "info").length,
        },
        alertas,
      },
      alertas.length,
    );
  }

  marcarLido(id: string): Envelope<null> {
    this.alertasLidos.add(id);
    return this.vazio();
  }

  marcarTodosLidos(): Envelope<null> {
    this.gerarAlertas().forEach((e) => this.alertasLidos.add(e.id));
    return this.vazio();
  }

  getPreferencias(): Envelope<PreferenciasAlerta> {
    return this.envelope(this.preferencias);
  }

  setPreferencias(body: Body): Envelope<null> {
    this.preferencias = { ...this.preferencias, ...(body as Partial<PreferenciasAlerta>) };
    return this.vazio();
  }

  // ── seed ───────────────────────────────────────────────────────────────────

  /**
   * Mantém a data dentro do mês corrente. As telas filtram por mês, e um seed
   * relativo ("3 dias atrás") cairia no mês anterior nos primeiros dias — o app
   * abriria vazio justamente quando alguém foi ver a demo.
   */
  private static nesteMes(dias: number): Date {
    const base = hoje();
    const alvo = emDias(dias);
    if (alvo.getMonth() === base.getMonth() && alvo.getFullYear() === base.getFullYear()) {
      return alvo;
    }

    // Nos primeiros dias do mês quase todo o seed cairia no mês anterior.
    // Espalhar pelos dias que já existem é melhor do que empilhar tudo em hoje.
    const ultimo = ultimoDiaDoMes(base.getFullYear(), base.getMonth() + 1);
    const dia =
      dias < 0
        ? Math.max(1, base.getDate() - (Math.abs(dias) % base.getDate()))
        : Math.min(ultimo, base.getDate() + 1);
    return new Date(base.getFullYear(), base.getMonth(), dia);
  }

  /**
   * Espelho de `database/migrations/002_seed_teste.sql`: um item em cada estado
   * de estoque, um gasto vencido, um a vencer e um pago, atendimentos
   * finalizados e um agendado. É o que faz cada cor da tela aparecer.
   */
  private semear(): void {
    this.perfil = {
      id: "demo-salao",
      nome: "Thamires Borges Beauty",
      proprietaria: "Thamires Borges",
      foto_url: null,
      telefone_whatsapp: "5511999990000",
      meta_faturamento_mensal: 9000,
    };

    const item = (
      nome: string,
      unidade: UnidadeEstoque,
      categoria: CategoriaEstoque,
      atual: number,
      minima: number,
      medio: number,
      ultima: number,
    ): ItemRow => {
      const row: ItemRow = {
        id: this.novoId("item"),
        nome,
        unidade,
        categoria,
        quantidade_atual: atual,
        quantidade_minima: minima,
        custo_medio: medio,
        custo_ultima_compra: ultima,
        ativo: true,
      };
      this.itens.push(row);
      return row;
    };

    const fio = item("Fio mink 0.07", "cx", "cilios", 8, 3, 42, 45);
    const removedor = item("Removedor de cola", "ml", "cilios", 120, 50, 0.35, 0.4);
    const micropore = item("Fita micropore", "cx", "descartavel", 2, 2, 6.5, 6.5);
    const cola = item("Cola adesiva para cílios", "un", "cilios", 0, 2, 28, 30);
    const pinca = item("Pinça curva", "un", "sobrancelha", -1, 1, 35, 35);

    this.movimentar(fio, "entrada", 10, "Compra — fornecedor");
    this.movimentar(removedor, "entrada", 150, "Compra — fornecedor");
    this.movimentar(pinca, "saida", 1, "Atendimento — saldo confirmado");

    const produto = (row: ItemRow, quantidade: number): ProdutoPadrao => ({
      item_estoque_id: row.id,
      nome: row.nome,
      quantidade,
      unidade: row.unidade,
    });

    this.servicos.push(
      {
        id: this.novoId("servico"),
        nome: "Extensão de cílios",
        preco: 180,
        produtos_padrao: [produto(fio, 1), produto(cola, 1), produto(micropore, 2)],
      },
      {
        id: this.novoId("servico"),
        nome: "Manutenção de cílios",
        preco: 100,
        produtos_padrao: [],
      },
      {
        id: this.novoId("servico"),
        nome: "Sobrancelha fio a fio",
        preco: 120,
        produtos_padrao: [],
      },
    );

    this.custosFixos.push(
      { id: this.novoId("custo"), descricao: "Aluguel", valor: 1200, dia_vencimento: 5 },
      { id: this.novoId("custo"), descricao: "Internet", valor: 99, dia_vencimento: 12 },
      {
        id: this.novoId("custo"),
        descricao: "App de agendamento",
        valor: 49,
        dia_vencimento: 20,
      },
    );

    const kit: KitRow = {
      id: this.novoId("kit"),
      nome: "Kit cuidado pós-cílios",
      preco_venda: 45,
      quantidade_montada: 3,
      itens: [
        { item_estoque_id: removedor.id, quantidade: 30 },
        { item_estoque_id: micropore.id, quantidade: 1 },
      ],
    };
    this.kits.push(kit);

    this.kitVendas.push(
      {
        kit_id: kit.id,
        nome: kit.nome,
        quantidade: 1,
        preco_unitario: 45,
        custo_unitario: 17,
        forma_pagamento: "pix",
        data: paraIso(DemoDatabase.nesteMes(-4)),
      },
      {
        kit_id: kit.id,
        nome: kit.nome,
        quantidade: 2,
        preco_unitario: 45,
        custo_unitario: 17,
        forma_pagamento: "a_vista",
        data: paraIso(DemoDatabase.nesteMes(-9)),
      },
    );

    // Um mês inteiro de trabalho, para o resumo ter o que consolidar: sem
    // histórico, a tela mais importante do app abre vazia.
    //
    // Só a Ana Paula consome material do estoque — o saldo dos itens acima já
    // está líquido dela, como no seed do banco. Os outros usam material avulso
    // (`item_estoque_id` nulo), que entra no custo do atendimento sem mexer no
    // estoque.
    const avulso: AtendimentoMaterial[] = [
      { item_estoque_id: null, nome: "Insumos da aplicação", quantidade: 1, preco: 35 },
    ];

    const atendimento = (
      cliente: string,
      telefone: string,
      dias: number,
      status: StatusAtendimento,
      indices: number[],
      materiais: AtendimentoMaterial[] = [],
    ) => {
      this.atendimentos.push({
        id: this.novoId("atendimento"),
        cliente_nome: cliente,
        cliente_telefone: telefone,
        data: paraIso(DemoDatabase.nesteMes(dias)),
        status,
        servicos: indices.flatMap((i) => {
          const servico = this.servicos[i];
          return servico
            ? [{ servico_id: servico.id, nome: servico.nome, preco: servico.preco }]
            : [];
        }),
        materiais,
      });
    };

    atendimento(
      "Ana Paula",
      "(11) 99999-0001",
      -2,
      "finalizado",
      [0, 2],
      [
        { item_estoque_id: fio.id, nome: fio.nome, quantidade: 1, preco: 42 },
        { item_estoque_id: micropore.id, nome: micropore.nome, quantidade: 2, preco: 13 },
        { item_estoque_id: null, nome: "Máscara de argila", quantidade: 1, preco: 9 },
      ],
    );
    atendimento("Bruna Lima", "(11) 99999-0003", -3, "finalizado", [0], avulso);
    atendimento("Juliana Reis", "(11) 99999-0004", -5, "finalizado", [1, 2]);
    atendimento("Marina Costa", "(11) 99999-0005", -7, "finalizado", [0], avulso);
    atendimento("Patrícia Alves", "(11) 99999-0006", -9, "finalizado", [2]);
    atendimento("Renata Dias", "(11) 99999-0007", -11, "finalizado", [0], avulso);
    atendimento("Sofia Martins", "(11) 99999-0008", -13, "finalizado", [1]);
    atendimento("Tatiane Rocha", "(11) 99999-0009", -15, "finalizado", [0, 2]);
    atendimento("Vanessa Luz", "(11) 99999-0010", -18, "finalizado", [0], avulso);
    atendimento("Yara Nunes", "(11) 99999-0011", -21, "finalizado", [1, 2]);
    atendimento("Beatriz Faria", "(11) 99999-0012", -24, "finalizado", [0]);
    atendimento("Carla Mendes", "(11) 98888-0002", 1, "agendado", [1]);

    this.gastos.push(
      {
        id: this.novoId("gasto"),
        nome: "Fios e colas (extensão)",
        valor: 340,
        prazo_pagamento: paraDataApi(DemoDatabase.nesteMes(-3)),
        forma_pagamento: "credito",
        categoria: "material",
        pago: false,
        pago_em: null,
        itens: [],
      },
      {
        id: this.novoId("gasto"),
        nome: "Aluguel sala",
        valor: 1200,
        prazo_pagamento: paraDataApi(DemoDatabase.nesteMes(2)),
        forma_pagamento: "pix",
        categoria: "fixo",
        pago: false,
        pago_em: null,
        itens: [],
      },
      {
        id: this.novoId("gasto"),
        nome: "Pinças e acessórios",
        valor: 85,
        prazo_pagamento: paraDataApi(DemoDatabase.nesteMes(-10)),
        forma_pagamento: "a_vista",
        categoria: "material",
        pago: true,
        pago_em: paraIso(DemoDatabase.nesteMes(-10)),
        itens: [],
      },
    );
  }
}

/** Instância única da aba. Some no reload — é demo, não banco. */
export const demoDatabase = new DemoDatabase();
