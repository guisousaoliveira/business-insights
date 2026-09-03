import { createFileRoute } from "@tanstack/react-router";
import {
  ArrowDownToLine,
  ArrowUpFromLine,
  Boxes,
  Package,
  PackagePlus,
  Plus,
  ShoppingBag,
  TriangleAlert,
} from "lucide-react";
import { useMemo, useState } from "react";
import { toast } from "sonner";
import { AppShell } from "@/components/AppShell";
import { EstoqueInsuficienteDialog, faltantesDoErro } from "@/components/EstoqueInsuficienteDialog";
import {
  Card,
  EmptyState,
  ListSkeleton,
  Money,
  Pill,
  SectionTitle,
  StatCard,
  type BadgeTone,
} from "@/components/ui-kit";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { formatBRL, formatDateTime } from "@/lib/format";
import {
  textoDoErro,
  useCriarItem,
  useCriarKit,
  useCriarMovimentacao,
  useEstoque,
  useKits,
  useMontarKit,
  useMovimentacoes,
  useVenderKit,
} from "@/lib/queries";
import type {
  CategoriaEstoque,
  FaltanteEstoque,
  FormaPagamento,
  ItemEstoque,
  Kit,
  StatusEstoque,
  TipoMovimentacao,
  UnidadeEstoque,
} from "@/lib/types";

export const Route = createFileRoute("/estoque")({
  head: () => ({
    meta: [
      { title: "Estoque e kits — GlowApp" },
      {
        name: "description",
        content:
          "Acompanhe saldo, custo médio ponderado e monte kits para revenda usando os insumos do salão.",
      },
      { property: "og:title", content: "Estoque e kits — GlowApp" },
      {
        property: "og:description",
        content: "Saldo de produtos, entradas, saídas e kits prontos para vender.",
      },
    ],
  }),
  component: EstoquePage,
});

/** `negativo` é distinto de `critico`: "devo mais do que tenho" ≠ "acabou" (A5). */
const tomStatus: Record<StatusEstoque, BadgeTone> = {
  ok: "positive",
  alerta: "warning",
  critico: "negative",
  negativo: "negative",
};

const rotuloStatus: Record<StatusEstoque, string> = {
  ok: "Saldo ok",
  alerta: "Estoque baixo",
  critico: "Sem saldo",
  negativo: "Saldo negativo",
};

const UNIDADES: { valor: UnidadeEstoque; label: string }[] = [
  { valor: "un", label: "Unidade" },
  { valor: "ml", label: "Mililitro" },
  { valor: "g", label: "Grama" },
  { valor: "cx", label: "Caixa" },
];

const CATEGORIAS: { valor: CategoriaEstoque; label: string }[] = [
  { valor: "cilios", label: "Cílios" },
  { valor: "sobrancelha", label: "Sobrancelhas" },
  { valor: "limpeza_pele", label: "Limpeza de pele" },
  { valor: "descartavel", label: "Descartáveis" },
  { valor: "outro", label: "Outros" },
];

const FORMAS: { valor: FormaPagamento; label: string }[] = [
  { valor: "a_vista", label: "À vista" },
  { valor: "pix", label: "Pix" },
  { valor: "debito", label: "Débito" },
  { valor: "credito", label: "Crédito" },
];

const rotuloCategoria = new Map(CATEGORIAS.map((c) => [c.valor, c.label]));

function EstoquePage() {
  const { data: estoque, isPending, isError, error } = useEstoque();
  const { data: listaKits } = useKits();
  const { data: historico } = useMovimentacoes();

  const movimentacao = useCriarMovimentacao();
  const criarItem = useCriarItem();
  const criarKit = useCriarKit();
  const montar = useMontarKit();
  const vender = useVenderKit();

  const [entradaItem, setEntradaItem] = useState<ItemEstoque | null>(null);
  const [saidaItem, setSaidaItem] = useState<ItemEstoque | null>(null);
  const [tipoSaida, setTipoSaida] = useState<Exclude<TipoMovimentacao, "entrada">>("saida");
  const [qtd, setQtd] = useState("1");
  const [custo, setCusto] = useState("");
  const [motivo, setMotivo] = useState("");

  const [kitParaMontar, setKitParaMontar] = useState<Kit | null>(null);
  const [unidades, setUnidades] = useState("1");
  const [faltantes, setFaltantes] = useState<FaltanteEstoque[] | null>(null);

  const [kitParaVender, setKitParaVender] = useState<Kit | null>(null);
  const [qtdVenda, setQtdVenda] = useState("1");
  const [precoVenda, setPrecoVenda] = useState("");
  const [formaVenda, setFormaVenda] = useState<FormaPagamento>("pix");

  const [itemAberto, setItemAberto] = useState(false);
  const [formItem, setFormItem] = useState({
    nome: "",
    categoria: "cilios" as CategoriaEstoque,
    unidade: "un" as UnidadeEstoque,
    quantidade: "0",
    minimo: "1",
    custo: "",
  });

  const [kitAberto, setKitAberto] = useState(false);
  const [formKit, setFormKit] = useState<{
    nome: string;
    precoVenda: string;
    itens: { item_estoque_id: string; quantidade: number }[];
  }>({ nome: "", precoVenda: "", itens: [] });

  const itens = useMemo(() => estoque?.itens ?? [], [estoque]);
  const kits = listaKits?.kits ?? [];

  // Quem está mais perto de acabar primeiro. `status` é do servidor; a ordem, da tela.
  const ordenados = useMemo(
    () =>
      itens
        .slice()
        .sort(
          (a, b) =>
            a.quantidade_atual / (a.quantidade_minima || 1) -
            b.quantidade_atual / (b.quantidade_minima || 1),
        ),
    [itens],
  );

  const kitsProntos = kits.reduce((t, k) => t + k.quantidade_montada, 0);

  const abrirEntrada = (p: ItemEstoque) => {
    setEntradaItem(p);
    setQtd("1");
    setCusto(String(p.custo_ultima_compra));
    setMotivo("Compra");
  };

  const abrirSaida = (p: ItemEstoque) => {
    setSaidaItem(p);
    setTipoSaida("saida");
    setQtd("1");
    setMotivo("");
  };

  const confirmarEntrada = () => {
    if (!entradaItem) return;
    const quantidade = Number(qtd.replace(",", "."));
    const custoUnitario = Number(custo.replace(",", "."));
    if (!(quantidade > 0) || !(custoUnitario >= 0)) {
      toast.error("Informe quantidade e custo válidos.");
      return;
    }
    movimentacao.mutate(
      {
        itemId: entradaItem.id,
        body: {
          tipo: "entrada",
          quantidade,
          motivo: motivo.trim() || "Compra",
          // É este custo que recalcula a média ponderada móvel (A6) — no servidor.
          custo_unitario: custoUnitario,
        },
      },
      {
        onSuccess: () => {
          toast.success(`Entrada registrada em ${entradaItem.nome}.`);
          setEntradaItem(null);
        },
        onError: (erro) => toast.error(textoDoErro(erro)),
      },
    );
  };

  const confirmarSaida = () => {
    if (!saidaItem) return;
    const quantidade = Number(qtd.replace(",", "."));
    if (!(quantidade > 0)) {
      toast.error("Informe uma quantidade válida.");
      return;
    }
    movimentacao.mutate(
      {
        itemId: saidaItem.id,
        body: {
          tipo: tipoSaida,
          quantidade,
          motivo: motivo.trim() || (tipoSaida === "saida" ? "Saída manual" : "Contagem"),
        },
      },
      {
        onSuccess: () => {
          toast.success(
            tipoSaida === "saida" ? "Saída registrada." : "Saldo ajustado pela contagem.",
          );
          setSaidaItem(null);
        },
        onError: (erro) => toast.error(textoDoErro(erro)),
      },
    );
  };

  const cadastrarItem = () => {
    const quantidade = Number(formItem.quantidade.replace(",", "."));
    const minimo = Number(formItem.minimo.replace(",", "."));
    const custoUnitario = Number(formItem.custo.replace(",", "."));
    if (!formItem.nome.trim() || !(custoUnitario >= 0) || !Number.isFinite(quantidade)) {
      toast.error("Informe nome, quantidade e custo do produto.");
      return;
    }
    criarItem.mutate(
      {
        nome: formItem.nome.trim(),
        categoria: formItem.categoria,
        unidade: formItem.unidade,
        quantidade_atual: quantidade,
        quantidade_minima: Number.isFinite(minimo) ? minimo : 1,
        custo_unitario: custoUnitario,
      },
      {
        onSuccess: () => {
          setItemAberto(false);
          setFormItem({
            nome: "",
            categoria: "cilios",
            unidade: "un",
            quantidade: "0",
            minimo: "1",
            custo: "",
          });
          toast.success("Produto cadastrado no estoque.");
        },
        onError: (erro) => toast.error(textoDoErro(erro)),
      },
    );
  };

  const alternarItemKit = (itemId: string) => {
    const existe = formKit.itens.some((i) => i.item_estoque_id === itemId);
    setFormKit({
      ...formKit,
      itens: existe
        ? formKit.itens.filter((i) => i.item_estoque_id !== itemId)
        : [...formKit.itens, { item_estoque_id: itemId, quantidade: 1 }],
    });
  };

  const custoFormKit = formKit.itens.reduce((t, i) => {
    const p = itens.find((x) => x.id === i.item_estoque_id);
    return t + (p ? p.custo_medio * i.quantidade : 0);
  }, 0);

  const cadastrarKit = () => {
    const preco = Number(formKit.precoVenda.replace(",", "."));
    if (!formKit.nome.trim() || !(preco > 0) || formKit.itens.length === 0) {
      toast.error("Informe nome, preço de venda e ao menos um insumo.");
      return;
    }
    criarKit.mutate(
      { nome: formKit.nome.trim(), preco_venda: preco, itens: formKit.itens },
      {
        onSuccess: () => {
          setKitAberto(false);
          setFormKit({ nome: "", precoVenda: "", itens: [] });
          toast.success("Kit criado. Monte as unidades para começar a vender.");
        },
        onError: (erro) => toast.error(textoDoErro(erro)),
      },
    );
  };

  function confirmarMontagem(confirmarEstoqueInsuficiente: boolean) {
    if (!kitParaMontar) return;
    const quantidade = Number(unidades);
    if (!(quantidade > 0)) {
      toast.error("Informe quantas unidades deseja montar.");
      return;
    }
    montar.mutate(
      { id: kitParaMontar.id, quantidade, confirmar: confirmarEstoqueInsuficiente },
      {
        onSuccess: () => {
          toast.success(`${quantidade} unidade(s) de ${kitParaMontar.nome} montada(s).`);
          setFaltantes(null);
          setKitParaMontar(null);
        },
        onError: (erro) => {
          // Montar consome insumo: passa pelo mesmo aviso de A5 da finalização.
          const faltando = faltantesDoErro(erro);
          if (faltando && !confirmarEstoqueInsuficiente) setFaltantes(faltando);
          else {
            setFaltantes(null);
            toast.error(textoDoErro(erro));
          }
        },
      },
    );
  }

  function confirmarVenda() {
    if (!kitParaVender) return;
    const quantidade = Number(qtdVenda);
    const preco = Number(precoVenda.replace(",", "."));
    if (!(quantidade > 0)) {
      toast.error("Informe quantas unidades foram vendidas.");
      return;
    }
    vender.mutate(
      {
        id: kitParaVender.id,
        quantidade,
        formaPagamento: formaVenda,
        // Ausente vale o preço de cadastro; serve para o desconto de balcão.
        ...(preco > 0 && preco !== kitParaVender.preco_venda ? { precoUnitario: preco } : {}),
      },
      {
        onSuccess: () => {
          toast.success(`Venda registrada: ${kitParaVender.nome}.`);
          setKitParaVender(null);
        },
        // Sem segunda passada: `KIT_NAO_MONTADO` é definitivo (A7).
        onError: (erro) => toast.error(textoDoErro(erro)),
      },
    );
  }

  return (
    <AppShell
      titulo="Estoque"
      subtitulo="Saldo, custo médio e kits para revenda"
      acaoLabel="Novo produto"
      onAcao={() => setItemAberto(true)}
    >
      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <StatCard
          label="Valor em estoque"
          value={formatBRL(estoque?.valor_total ?? 0)}
          tone="brand"
          destaque
        />
        <StatCard label="Produtos" value={String(itens.length)} />
        <StatCard
          label="Para repor"
          value={String(estoque?.total_alertas ?? 0)}
          tone={estoque && estoque.total_alertas > 0 ? "warning" : "positive"}
          hint="abaixo do mínimo"
        />
        <StatCard label="Kits prontos" value={String(kitsProntos)} />
      </div>

      <Tabs defaultValue="produtos" className="mt-5">
        <TabsList className="h-11 rounded-xl">
          <TabsTrigger value="produtos">Produtos</TabsTrigger>
          <TabsTrigger value="kits">Kits para revenda</TabsTrigger>
          <TabsTrigger value="movimentacoes">Movimentações</TabsTrigger>
        </TabsList>

        <TabsContent value="produtos" className="mt-4">
          {isPending ? (
            <ListSkeleton />
          ) : isError ? (
            <EmptyState
              icon={<TriangleAlert className="size-5" />}
              titulo="Não deu para carregar o estoque"
              descricao={textoDoErro(error)}
            />
          ) : ordenados.length ? (
            <ul className="space-y-3">
              {ordenados.map((p) => (
                <li key={p.id}>
                  <Card className="p-4">
                    <div className="grid grid-cols-[minmax(0,1fr)_auto] items-start gap-3">
                      <div className="min-w-0">
                        <p className="truncate font-semibold">{p.nome}</p>
                        <p className="mt-0.5 text-xs text-muted-foreground">
                          {rotuloCategoria.get(p.categoria) ?? p.categoria} • mínimo{" "}
                          {p.quantidade_minima} {p.unidade}
                        </p>
                        <div className="mt-2 flex flex-wrap items-center gap-1.5">
                          <Pill tone={tomStatus[p.status]}>{rotuloStatus[p.status]}</Pill>
                          <Pill>Custo médio {formatBRL(p.custo_medio)}</Pill>
                          {p.deficit > 0 ? <Pill tone="warning">Faltam {p.deficit}</Pill> : null}
                        </div>
                      </div>
                      <div className="shrink-0 text-right">
                        <p
                          className={
                            "font-display text-2xl font-semibold tabular-nums " +
                            (p.status === "negativo" || p.status === "critico"
                              ? "text-negative"
                              : p.status === "alerta"
                                ? "text-warning"
                                : "text-foreground")
                          }
                        >
                          {p.quantidade_atual}
                        </p>
                        <p className="text-[11px] text-muted-foreground">{p.unidade}</p>
                        <div className="mt-2 flex justify-end gap-1">
                          <Button
                            size="icon"
                            variant="ghost"
                            aria-label="Registrar entrada"
                            onClick={() => abrirEntrada(p)}
                          >
                            <ArrowDownToLine className="size-4 text-positive" />
                          </Button>
                          <Button
                            size="icon"
                            variant="ghost"
                            aria-label="Registrar saída"
                            onClick={() => abrirSaida(p)}
                          >
                            <ArrowUpFromLine className="size-4 text-primary" />
                          </Button>
                        </div>
                      </div>
                    </div>
                  </Card>
                </li>
              ))}
            </ul>
          ) : (
            <EmptyState
              icon={<Package className="size-5" />}
              titulo="Estoque vazio"
              descricao="Cadastre seus produtos para acompanhar saldo, custo e reposição."
              acao={<Button onClick={() => setItemAberto(true)}>Novo produto</Button>}
            />
          )}
        </TabsContent>

        <TabsContent value="kits" className="mt-4">
          <SectionTitle
            hint="Montar consome insumo; vender baixa o kit montado"
            action={
              <Button size="sm" onClick={() => setKitAberto(true)}>
                <Plus className="size-4" />
                Criar kit
              </Button>
            }
          >
            Kits para revenda
          </SectionTitle>
          {kits.length ? (
            <ul className="space-y-3">
              {kits.map((k) => (
                <li key={k.id}>
                  <Card className="p-4">
                    <div className="grid grid-cols-[minmax(0,1fr)_auto] items-start gap-3">
                      <div className="min-w-0">
                        <p className="truncate font-semibold">{k.nome}</p>
                        <p className="mt-0.5 text-xs text-muted-foreground">
                          {k.itens.map((i) => `${i.quantidade}x ${i.nome}`).join(" • ")}
                        </p>
                        <div className="mt-2 flex flex-wrap items-center gap-1.5">
                          <Pill tone="brand">Venda {formatBRL(k.preco_venda)}</Pill>
                          <Pill>Custo {formatBRL(k.custo_total)}</Pill>
                          <Pill tone={k.margem >= 0 ? "positive" : "negative"}>
                            Lucro {formatBRL(k.margem)}
                          </Pill>
                          <Pill>Dá para montar {k.quantidade_montavel}</Pill>
                        </div>
                      </div>
                      <div className="shrink-0 text-right">
                        <p className="font-display text-2xl font-semibold tabular-nums">
                          {k.quantidade_montada}
                        </p>
                        <p className="text-[11px] text-muted-foreground">montados</p>
                        <div className="mt-2 flex flex-col gap-1.5">
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => {
                              setKitParaMontar(k);
                              setUnidades("1");
                            }}
                          >
                            <Boxes className="size-4" />
                            Montar
                          </Button>
                          <Button
                            size="sm"
                            disabled={k.quantidade_montada <= 0}
                            onClick={() => {
                              setKitParaVender(k);
                              setQtdVenda("1");
                              setPrecoVenda(String(k.preco_venda));
                              setFormaVenda("pix");
                            }}
                          >
                            <ShoppingBag className="size-4" />
                            Vender
                          </Button>
                        </div>
                      </div>
                    </div>
                  </Card>
                </li>
              ))}
            </ul>
          ) : (
            <EmptyState
              icon={<Boxes className="size-5" />}
              titulo="Nenhum kit cadastrado"
              descricao="Monte kits com o que você já tem no estoque e acompanhe a margem de cada um."
              acao={<Button onClick={() => setKitAberto(true)}>Criar kit</Button>}
            />
          )}
        </TabsContent>

        <TabsContent value="movimentacoes" className="mt-4">
          <SectionTitle hint="Entradas, saídas e ajustes mais recentes">Movimentações</SectionTitle>
          {historico?.movimentacoes.length ? (
            <Card className="p-2">
              <ul className="divide-y divide-border">
                {historico.movimentacoes.slice(0, 20).map((m) => (
                  <li key={m.id} className="flex items-center justify-between gap-3 px-2 py-3">
                    <div className="min-w-0">
                      <p className="truncate text-sm font-medium">{m.item_nome}</p>
                      <p className="text-xs text-muted-foreground">
                        {formatDateTime(m.criado_em)} • {m.motivo}
                      </p>
                    </div>
                    <Pill
                      tone={
                        m.tipo === "entrada" ? "positive" : m.tipo === "saida" ? "neutral" : "brand"
                      }
                    >
                      {m.tipo === "entrada" ? "+" : m.tipo === "saida" ? "−" : "="}
                      {m.quantidade}
                    </Pill>
                  </li>
                ))}
              </ul>
            </Card>
          ) : (
            <EmptyState
              icon={<Package className="size-5" />}
              titulo="Sem movimentações"
              descricao="Registre entradas de compras e saídas de uso para acompanhar o custo real."
            />
          )}
        </TabsContent>
      </Tabs>

      {/* Entrada */}
      <Dialog open={entradaItem !== null} onOpenChange={(o) => !o && setEntradaItem(null)}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Entrada de estoque</DialogTitle>
            <DialogDescription>
              {entradaItem?.nome} — o custo médio ponderado é recalculado automaticamente.
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-3 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label htmlFor="qtd-entrada">Quantidade</Label>
              <Input
                id="qtd-entrada"
                inputMode="decimal"
                value={qtd}
                onChange={(e) => setQtd(e.target.value)}
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="custo-entrada">Custo unitário (R$)</Label>
              <Input
                id="custo-entrada"
                inputMode="decimal"
                value={custo}
                onChange={(e) => setCusto(e.target.value)}
              />
            </div>
            <div className="space-y-1.5 sm:col-span-2">
              <Label htmlFor="motivo-entrada">Motivo</Label>
              <Input
                id="motivo-entrada"
                value={motivo}
                onChange={(e) => setMotivo(e.target.value)}
                placeholder="Ex.: compra na Bella Lash"
              />
            </div>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setEntradaItem(null)}
              disabled={movimentacao.isPending}
            >
              Cancelar
            </Button>
            <Button onClick={confirmarEntrada} disabled={movimentacao.isPending}>
              Registrar entrada
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Saída ou ajuste */}
      <Dialog open={saidaItem !== null} onOpenChange={(o) => !o && setSaidaItem(null)}>
        <DialogContent className="sm:max-w-sm">
          <DialogHeader>
            <DialogTitle>Movimentar estoque</DialogTitle>
            <DialogDescription>
              {saidaItem?.nome} — saldo atual {saidaItem?.quantidade_atual} {saidaItem?.unidade}.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-3">
            <div className="space-y-1.5">
              <Label>Tipo</Label>
              <Select value={tipoSaida} onValueChange={(v) => setTipoSaida(v as typeof tipoSaida)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="saida">Saída (uso ou perda)</SelectItem>
                  <SelectItem value="ajuste">Ajuste (contagem)</SelectItem>
                </SelectContent>
              </Select>
              <p className="text-xs text-muted-foreground">
                {tipoSaida === "saida"
                  ? "Subtrai do saldo. Saldo não se edita: corrigir é lançar um ajuste."
                  : "Define o saldo como o valor contado."}
              </p>
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="qtd-saida">Quantidade</Label>
              <Input
                id="qtd-saida"
                inputMode="decimal"
                value={qtd}
                onChange={(e) => setQtd(e.target.value)}
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="motivo-saida">Motivo</Label>
              <Input
                id="motivo-saida"
                value={motivo}
                onChange={(e) => setMotivo(e.target.value)}
                placeholder={
                  tipoSaida === "saida" ? "Ex.: produto vencido" : "Ex.: contagem do mês"
                }
              />
            </div>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setSaidaItem(null)}
              disabled={movimentacao.isPending}
            >
              Cancelar
            </Button>
            <Button onClick={confirmarSaida} disabled={movimentacao.isPending}>
              Registrar
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Montar kit */}
      <Dialog open={kitParaMontar !== null} onOpenChange={(o) => !o && setKitParaMontar(null)}>
        <DialogContent className="sm:max-w-sm">
          <DialogHeader>
            <DialogTitle>Montar kit</DialogTitle>
            <DialogDescription>
              {kitParaMontar?.nome} — os insumos serão baixados do estoque. Dá para montar{" "}
              {kitParaMontar?.quantidade_montavel} com o saldo de hoje.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-1.5">
            <Label htmlFor="unidades">Unidades</Label>
            <Input
              id="unidades"
              inputMode="numeric"
              value={unidades}
              onChange={(e) => setUnidades(e.target.value)}
            />
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setKitParaMontar(null)}
              disabled={montar.isPending}
            >
              Cancelar
            </Button>
            <Button onClick={() => confirmarMontagem(false)} disabled={montar.isPending}>
              Montar
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <EstoqueInsuficienteDialog
        faltantes={faltantes}
        acao={`montar ${unidades} kit(s)`}
        confirmando={montar.isPending}
        onCancelar={() => setFaltantes(null)}
        onConfirmar={() => confirmarMontagem(true)}
      />

      {/* Vender kit */}
      <Dialog open={kitParaVender !== null} onOpenChange={(o) => !o && setKitParaVender(null)}>
        <DialogContent className="sm:max-w-sm">
          <DialogHeader>
            <DialogTitle>Vender kit</DialogTitle>
            <DialogDescription>
              {kitParaVender?.nome} — {kitParaVender?.quantidade_montada} montado(s) na prateleira.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-3">
            <div className="grid gap-3 sm:grid-cols-2">
              <div className="space-y-1.5">
                <Label htmlFor="qtd-venda">Unidades</Label>
                <Input
                  id="qtd-venda"
                  inputMode="numeric"
                  value={qtdVenda}
                  onChange={(e) => setQtdVenda(e.target.value)}
                />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="preco-venda">Preço unitário (R$)</Label>
                <Input
                  id="preco-venda"
                  inputMode="decimal"
                  value={precoVenda}
                  onChange={(e) => setPrecoVenda(e.target.value)}
                />
              </div>
            </div>
            <div className="space-y-1.5">
              <Label>Forma de pagamento</Label>
              <Select value={formaVenda} onValueChange={(v) => setFormaVenda(v as FormaPagamento)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {FORMAS.map((f) => (
                    <SelectItem key={f.valor} value={f.valor}>
                      {f.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setKitParaVender(null)}
              disabled={vender.isPending}
            >
              Cancelar
            </Button>
            <Button onClick={confirmarVenda} disabled={vender.isPending}>
              Registrar venda
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Novo produto */}
      <Dialog open={itemAberto} onOpenChange={setItemAberto}>
        <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Novo produto</DialogTitle>
            <DialogDescription>
              Cadastre o insumo com nome, unidade de medida, saldo inicial e custo.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-3">
            <div className="space-y-1.5">
              <Label htmlFor="nome-produto">Nome do produto</Label>
              <Input
                id="nome-produto"
                value={formItem.nome}
                onChange={(e) => setFormItem({ ...formItem, nome: e.target.value })}
                placeholder="Ex.: cola para extensão de cílios"
              />
            </div>
            <div className="grid gap-3 sm:grid-cols-2">
              <div className="space-y-1.5">
                <Label>Categoria</Label>
                <Select
                  value={formItem.categoria}
                  onValueChange={(v) =>
                    setFormItem({ ...formItem, categoria: v as CategoriaEstoque })
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {CATEGORIAS.map((c) => (
                      <SelectItem key={c.valor} value={c.valor}>
                        {c.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1.5">
                <Label>Unidade de medida</Label>
                <Select
                  value={formItem.unidade}
                  onValueChange={(v) => setFormItem({ ...formItem, unidade: v as UnidadeEstoque })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {UNIDADES.map((u) => (
                      <SelectItem key={u.valor} value={u.valor}>
                        {u.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="qtd-inicial">Saldo inicial</Label>
                <Input
                  id="qtd-inicial"
                  inputMode="decimal"
                  value={formItem.quantidade}
                  onChange={(e) => setFormItem({ ...formItem, quantidade: e.target.value })}
                />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="minimo">Estoque mínimo</Label>
                <Input
                  id="minimo"
                  inputMode="decimal"
                  value={formItem.minimo}
                  onChange={(e) => setFormItem({ ...formItem, minimo: e.target.value })}
                />
              </div>
              <div className="space-y-1.5 sm:col-span-2">
                <Label htmlFor="custo-produto">Custo unitário (R$)</Label>
                <Input
                  id="custo-produto"
                  inputMode="decimal"
                  value={formItem.custo}
                  onChange={(e) => setFormItem({ ...formItem, custo: e.target.value })}
                  placeholder="0,00"
                />
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setItemAberto(false)}
              disabled={criarItem.isPending}
            >
              Cancelar
            </Button>
            <Button onClick={cadastrarItem} disabled={criarItem.isPending}>
              <PackagePlus className="size-4" />
              Cadastrar produto
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Criar kit */}
      <Dialog open={kitAberto} onOpenChange={setKitAberto}>
        <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Criar kit para revenda</DialogTitle>
            <DialogDescription>
              Escolha os produtos que compõem o kit e o preço de venda.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-3">
            <div className="space-y-1.5">
              <Label htmlFor="nome-kit">Nome do kit</Label>
              <Input
                id="nome-kit"
                value={formKit.nome}
                onChange={(e) => setFormKit({ ...formKit, nome: e.target.value })}
                placeholder="Ex.: kit cuidados com cílios"
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="preco-kit">Preço de venda (R$)</Label>
              <Input
                id="preco-kit"
                inputMode="decimal"
                value={formKit.precoVenda}
                onChange={(e) => setFormKit({ ...formKit, precoVenda: e.target.value })}
                placeholder="0,00"
              />
            </div>
            <div className="space-y-2">
              <Label>Produtos do kit</Label>
              <div className="max-h-52 space-y-1.5 overflow-y-auto rounded-xl border border-border p-2">
                {itens.map((p) => {
                  const item = formKit.itens.find((i) => i.item_estoque_id === p.id);
                  return (
                    <div key={p.id} className="flex items-center gap-2 rounded-lg px-2 py-1.5">
                      <Switch
                        checked={item !== undefined}
                        onCheckedChange={() => alternarItemKit(p.id)}
                        aria-label={p.nome}
                      />
                      <span className="min-w-0 flex-1 truncate text-sm">{p.nome}</span>
                      {item ? (
                        <Input
                          className="h-9 w-16"
                          inputMode="numeric"
                          value={String(item.quantidade)}
                          onChange={(e) =>
                            setFormKit({
                              ...formKit,
                              itens: formKit.itens.map((i) =>
                                i.item_estoque_id === p.id
                                  ? { ...i, quantidade: Number(e.target.value) || 1 }
                                  : i,
                              ),
                            })
                          }
                        />
                      ) : (
                        <span className="text-[11px] text-muted-foreground">{p.unidade}</span>
                      )}
                    </div>
                  );
                })}
              </div>
              <p className="text-xs text-muted-foreground">
                Custo dos insumos: <Money value={custoFormKit} /> • Lucro por kit:{" "}
                <Money
                  value={(Number(formKit.precoVenda.replace(",", ".")) || 0) - custoFormKit}
                  colorir
                />
              </p>
            </div>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setKitAberto(false)}
              disabled={criarKit.isPending}
            >
              Cancelar
            </Button>
            <Button onClick={cadastrarKit} disabled={criarKit.isPending}>
              <Boxes className="size-4" />
              Criar kit
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </AppShell>
  );
}
