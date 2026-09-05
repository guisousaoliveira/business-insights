import { ApiError, AppErrorCodes } from "../error-codes";
import type { Envelope, Query } from "../http";
import { DemoDatabase, demoDatabase } from "./demo-database";
import { hoje, parseData } from "./datas";

/**
 * O roteador do modo demo — método + rota entram, envelope sai.
 *
 * É o análogo do FastAPI: só traduz HTTP em chamada de método e devolve o
 * envelope cru. Nenhuma regra de negócio mora aqui; ela está toda no
 * `DemoDatabase`, para que o backend real possa ser conferido contra um arquivo
 * só.
 *
 * O `http.ts` desvia para cá **antes** do `fetch`, não em vez do repositório: a
 * resposta sobe pelo mesmo caminho de produção, com o mesmo parse e o mesmo
 * `ApiError`. Se o formato do envelope mudar, os dois modos quebram juntos — que
 * é exatamente o que a demo precisa provar.
 */

const db = demoDatabase;

/** O corpo que o app manda, já como mapa. */
type Body = Record<string, unknown>;

function corpo(body: unknown): Body {
  return typeof body === "object" && body !== null ? (body as Body) : {};
}

function inteiro(query: Query | undefined, chave: string, padrao: number): number {
  const valor = query?.[chave];
  const numero = typeof valor === "number" ? valor : Number(valor);
  return Number.isFinite(numero) ? numero : padrao;
}

function naoEncontrado(metodo: string, path: string): never {
  throw new ApiError(
    404,
    AppErrorCodes.notFound,
    `Rota não implementada no modo demo: ${metodo} ${path}`,
  );
}

export async function demoRequest<T>(
  metodo: string,
  path: string,
  query?: Query,
  body?: unknown,
): Promise<Envelope<T>> {
  // Latência artificial: sem ela o `loading` pisca e ninguém vê o estado de
  // carregamento que cada tela tem.
  await new Promise((resolve) => setTimeout(resolve, DemoDatabase.latencia));
  return rotear(metodo, path, query, corpo(body)) as Envelope<T>;
}

function rotear(
  metodo: string,
  path: string,
  query: Query | undefined,
  body: Body,
): Envelope<unknown> {
  const partes = path.split("/").filter(Boolean);
  const recurso = partes[0] ?? "";
  const id = partes[1] ?? "";
  const acao = partes[2] ?? "";
  const chave = `${metodo} /${recurso}`;

  switch (recurso) {
    case "auth":
      return auth(metodo, id, body, path);

    case "atendimentos":
      return atendimentos(metodo, id, acao, query, body, path);

    case "gastos":
      if (metodo === "GET" && !id) {
        const agora = new Date();
        return db.getGastos(
          inteiro(query, "ano", agora.getFullYear()),
          inteiro(query, "mes", agora.getMonth() + 1),
        );
      }
      if (metodo === "POST" && !id) return db.createGasto(body);
      if (metodo === "PATCH" && acao === "pagar") return db.pagarGasto(id);
      if (metodo === "PATCH") return db.editGasto(id, body);
      if (metodo === "DELETE") return db.deleteGasto(id);
      return naoEncontrado(metodo, path);

    case "resumo":
      if (metodo === "GET" && id === "mensal") {
        const agora = new Date();
        return db.getResumoMensal(
          inteiro(query, "ano", agora.getFullYear()),
          inteiro(query, "mes", agora.getMonth() + 1),
        );
      }
      return naoEncontrado(metodo, path);

    case "precificacao":
      if (metodo === "POST" && id === "calcular") {
        const precoAtual = query?.["preco_atual"];
        return db.calcularPreco(
          body,
          precoAtual === undefined || precoAtual === null || precoAtual === ""
            ? null
            : Number(precoAtual),
        );
      }
      return naoEncontrado(metodo, path);

    case "estoque":
      return estoque(metodo, partes, query, body, path);

    case "kits":
      if (metodo === "GET" && !id) return db.getKits();
      if (metodo === "POST" && !id) return db.createKit(body);
      if (metodo === "POST" && acao === "montar") return db.montarKit(id, body);
      if (metodo === "POST" && acao === "vender") return db.venderKit(id, body);
      if (metodo === "PATCH") return db.editKit(id, body);
      if (metodo === "DELETE") return db.deleteKit(id);
      return naoEncontrado(metodo, path);

    case "perfil":
      return perfil(metodo, partes, query, body, path);

    case "servicos":
      if (metodo === "GET" && !id) return db.getServicos();
      if (metodo === "POST" && !id) return db.createServico(body);
      if (metodo === "PATCH") return db.editServico(id, body);
      if (metodo === "DELETE") return db.deleteServico(id);
      return naoEncontrado(metodo, path);

    case "alertas":
      if (metodo === "GET" && id === "preferencias") return db.getPreferencias();
      if (metodo === "PUT" && id === "preferencias") return db.setPreferencias(body);
      if (metodo === "GET" && !id) return db.getAlertas(query?.["apenas_nao_lidos"] === true);
      if (metodo === "PATCH" && id === "lidos") return db.marcarTodosLidos();
      if (metodo === "PATCH" && acao === "lido") return db.marcarLido(id);
      return naoEncontrado(metodo, path);

    // Push não existe na web e o backend não guarda nada por token aqui — o
    // registro do dispositivo é aceito e descartado, para o fluxo de login e
    // logout do app rodar igual nos dois modos.
    case "dispositivos":
      if (metodo === "POST" || metodo === "DELETE") {
        return { total: 0, mensagem: "ok", codigo: null, result: null };
      }
      return naoEncontrado(metodo, path);

    default:
      return naoEncontrado(metodo, chave);
  }
}

function auth(metodo: string, acao: string, body: Body, path: string): Envelope<unknown> {
  if (metodo === "POST" && acao === "login") {
    return db.login(String(body["email"] ?? ""), String(body["senha"] ?? ""));
  }
  if (metodo === "POST" && acao === "refresh") {
    // Na demo o token nunca expira, mas a rota existe: é o caminho que o
    // interceptor 401 percorre, e ele precisa ser exercitável.
    return {
      total: 0,
      mensagem: "ok",
      codigo: null,
      result: { token: "demo-token", refresh_token: "demo-refresh-token", expira_em: 3600 },
    };
  }
  if (metodo === "POST" && acao === "logout") {
    return { total: 0, mensagem: "ok", codigo: null, result: null };
  }
  if (metodo === "GET" && acao === "eu") return db.eu();
  return naoEncontrado(metodo, path);
}

function atendimentos(
  metodo: string,
  id: string,
  acao: string,
  query: Query | undefined,
  body: Body,
  path: string,
): Envelope<unknown> {
  if (metodo === "GET" && !id) {
    const base = hoje();
    const inicioQuery = query?.["inicio"];
    const fimQuery = query?.["fim"];
    const inicio =
      typeof inicioQuery === "string" && inicioQuery
        ? parseData(inicioQuery)
        : new Date(base.getFullYear(), base.getMonth(), 1);
    const fim =
      typeof fimQuery === "string" && fimQuery
        ? parseData(fimQuery)
        : new Date(base.getFullYear(), base.getMonth() + 1, 0);
    const status = String(query?.["status"] ?? "")
      .split(",")
      .filter(Boolean);
    return db.getAtendimentos(inicio, fim, status);
  }

  if (metodo === "GET") return db.getAtendimento(id);
  if (metodo === "POST" && !acao) return db.createAtendimento(body);
  if (metodo === "PATCH" && acao === "finalizar") return db.finalizarAtendimento(id, body);
  if (metodo === "PATCH" && acao === "cancelar") return db.cancelarAtendimento(id);
  if (metodo === "PATCH") return db.editAtendimento(id, body);
  if (metodo === "DELETE") return db.deleteAtendimento(id);
  return naoEncontrado(metodo, path);
}

function estoque(
  metodo: string,
  partes: string[],
  query: Query | undefined,
  body: Body,
  path: string,
): Envelope<unknown> {
  const secao = partes[1] ?? "";
  const id = partes[2] ?? "";
  const acao = partes[3] ?? "";

  if (secao === "movimentacoes" && metodo === "GET") {
    const itemId = query?.["item_id"];
    return db.getMovimentacoes(typeof itemId === "string" && itemId ? itemId : undefined);
  }

  if (secao === "itens") {
    if (metodo === "GET" && !id) {
      const codigoBarras = query?.["codigo_barras"];
      return db.getItens(typeof codigoBarras === "string" && codigoBarras ? codigoBarras : undefined);
    }
    if (metodo === "POST" && !id) return db.createItem(body);
    if (metodo === "GET" && acao === "movimentacoes") return db.getMovimentacoes(id);
    if (metodo === "POST" && acao === "movimentacoes") return db.createMovimentacao(id, body);
    if (metodo === "PATCH") return db.editItem(id, body);
    if (metodo === "DELETE") return db.deleteItem(id);
  }

  return naoEncontrado(metodo, path);
}

function perfil(
  metodo: string,
  partes: string[],
  query: Query | undefined,
  body: Body,
  path: string,
): Envelope<unknown> {
  const secao = partes[1] ?? "";
  const id = partes[2] ?? "";
  const acao = partes[3] ?? "";

  if (!secao) {
    if (metodo === "GET") return db.getPerfil();
    if (metodo === "PUT" || metodo === "PATCH") return db.updatePerfil(body);
  }

  if (secao === "custos-fixos") {
    if (metodo === "GET" && !id) {
      const competencia = query?.["competencia"];
      return db.getCustosFixos(typeof competencia === "string" ? competencia : undefined);
    }
    if (metodo === "POST" && !id) return db.createCustoFixo(body);
    if (metodo === "PATCH" && acao === "pagar") return db.pagarCustoFixo(id, body);
    if (metodo === "PATCH") return db.editCustoFixo(id, body);
    if (metodo === "DELETE") return db.deleteCustoFixo(id);
  }

  return naoEncontrado(metodo, path);
}
