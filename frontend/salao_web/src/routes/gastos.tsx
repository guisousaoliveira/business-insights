import { createFileRoute } from "@tanstack/react-router";
import { CheckCircle2, Pencil, Receipt, Trash2, TriangleAlert } from "lucide-react";
import { useMemo, useState } from "react";
import { toast } from "sonner";
import { AppShell } from "@/components/AppShell";
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
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import type { GastoBody } from "@/lib/api";
import { formatBRL, formatDate, MESES, nomeMes } from "@/lib/format";
import {
  textoDoErro,
  useCriarGasto,
  useEditarGasto,
  useExcluirGasto,
  useGastos,
  usePagarGasto,
} from "@/lib/queries";
import type { CategoriaGasto, FormaPagamento, Gasto } from "@/lib/types";

export const Route = createFileRoute("/gastos")({
  head: () => ({
    meta: [
      { title: "Gastos e contas — GlowApp" },
      {
        name: "description",
        content:
          "Controle materiais, custos fixos e outras contas do salão por categoria, status e vencimento.",
      },
      { property: "og:title", content: "Gastos e contas — GlowApp" },
      {
        property: "og:description",
        content: "Veja o que já foi pago, o que está pendente e o que venceu no seu salão.",
      },
    ],
  }),
  component: GastosPage,
});

const CATEGORIAS: { valor: CategoriaGasto; label: string }[] = [
  { valor: "material", label: "Material" },
  { valor: "fixo", label: "Custo fixo" },
  { valor: "outros", label: "Outros" },
];

const FORMAS: { valor: FormaPagamento; label: string }[] = [
  { valor: "a_vista", label: "À vista" },
  { valor: "pix", label: "Pix" },
  { valor: "debito", label: "Débito" },
  { valor: "credito", label: "Crédito" },
];

const rotuloCategoria: Record<CategoriaGasto, string> = {
  material: "Material",
  fixo: "Custo fixo",
  outros: "Outros",
};

const rotuloForma: Record<FormaPagamento, string> = {
  a_vista: "À vista",
  pix: "Pix",
  debito: "Débito",
  credito: "Crédito",
};

/**
 * Situação = `pago` + `vence_em_dias`, os dois vindos do servidor. Não existe
 * campo "status" no contrato: vencido é pendente que passou do prazo, e quem
 * conta os dias é quem tem o relógio confiável.
 */
type Situacao = "pago" | "pendente" | "vencido";

function situacaoDo(g: Gasto): Situacao {
  if (g.pago) return "pago";
  return g.vence_em_dias < 0 ? "vencido" : "pendente";
}

const tomSituacao: Record<Situacao, BadgeTone> = {
  pago: "positive",
  pendente: "warning",
  vencido: "negative",
};

const rotuloSituacao: Record<Situacao, string> = {
  pago: "Pago",
  pendente: "Pendente",
  vencido: "Vencido",
};

const hoje = new Date();
const anoAtual = hoje.getFullYear();
const mesAtual = hoje.getMonth() + 1;

interface Form {
  id?: string;
  nome: string;
  categoria: CategoriaGasto;
  valor: string;
  prazo: string;
  forma: FormaPagamento;
}

function formVazio(): Form {
  return {
    nome: "",
    categoria: "material",
    valor: "",
    prazo: new Date().toISOString().slice(0, 10),
    forma: "pix",
  };
}

function GastosPage() {
  const [mes, setMes] = useState(mesAtual);
  const [ano, setAno] = useState(anoAtual);
  const [filtro, setFiltro] = useState<"todos" | Situacao>("todos");
  const [categoria, setCategoria] = useState<"todas" | CategoriaGasto>("todas");
  const [aberto, setAberto] = useState(false);
  const [form, setForm] = useState<Form>(formVazio);

  const { data, isPending, isError, error } = useGastos(ano, mes);
  const criar = useCriarGasto();
  const editar = useEditarGasto();
  const pagar = usePagarGasto();
  const excluir = useExcluirGasto();

  const gastos = useMemo(() => data?.gastos ?? [], [data]);

  const lista = useMemo(
    () =>
      gastos
        .filter((g) => (filtro === "todos" ? true : situacaoDo(g) === filtro))
        .filter((g) => (categoria === "todas" ? true : g.categoria === categoria))
        .slice()
        .sort((a, b) => b.prazo_pagamento.localeCompare(a.prazo_pagamento)),
    [gastos, filtro, categoria],
  );

  const total = gastos.reduce((t, g) => t + g.valor, 0);
  const vencidos = gastos
    .filter((g) => situacaoDo(g) === "vencido")
    .reduce((t, g) => t + g.valor, 0);

  const salvando = criar.isPending || editar.isPending;

  const abrirNovo = () => {
    setForm(formVazio());
    setAberto(true);
  };

  const abrirEdicao = (g: Gasto) => {
    setForm({
      id: g.id,
      nome: g.nome,
      categoria: g.categoria,
      valor: String(g.valor),
      prazo: g.prazo_pagamento.slice(0, 10),
      forma: g.forma_pagamento,
    });
    setAberto(true);
  };

  const salvar = () => {
    const valor = Number(form.valor.replace(",", "."));
    if (!form.nome.trim() || !Number.isFinite(valor) || valor <= 0) {
      toast.error("Informe uma descrição e um valor válido.");
      return;
    }
    const body: GastoBody = {
      nome: form.nome.trim(),
      valor,
      prazo_pagamento: form.prazo,
      forma_pagamento: form.forma,
      categoria: form.categoria,
    };
    const opcoes = {
      onSuccess: () => {
        setAberto(false);
        toast.success(form.id ? "Gasto atualizado." : "Gasto registrado.");
      },
      onError: (erro: unknown) => toast.error(textoDoErro(erro)),
    };
    if (form.id) editar.mutate({ id: form.id, body }, opcoes);
    else criar.mutate(body, opcoes);
  };

  return (
    <AppShell
      titulo="Gastos"
      subtitulo={`Materiais, custos fixos e outras contas de ${nomeMes(mes)}`}
      acaoLabel="Novo gasto"
      onAcao={abrirNovo}
    >
      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <StatCard label="Total no período" value={formatBRL(total)} />
        <StatCard label="Já pago" value={formatBRL(data?.total_pago_mes ?? 0)} tone="positive" />
        <StatCard label="Pendente" value={formatBRL(data?.total_pendente ?? 0)} tone="warning" />
        <StatCard label="Vencido" value={formatBRL(vencidos)} tone="negative" />
      </div>

      <div className="mt-5 flex flex-wrap items-center gap-2">
        <Tabs value={filtro} onValueChange={(v) => setFiltro(v as typeof filtro)}>
          <TabsList className="h-11 rounded-xl">
            <TabsTrigger value="todos">Todos</TabsTrigger>
            <TabsTrigger value="pendente">Pendentes</TabsTrigger>
            <TabsTrigger value="pago">Pagos</TabsTrigger>
            <TabsTrigger value="vencido">Vencidos</TabsTrigger>
          </TabsList>
        </Tabs>
        <Select value={categoria} onValueChange={(v) => setCategoria(v as typeof categoria)}>
          <SelectTrigger className="h-11 w-[160px] rounded-xl bg-surface">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="todas">Todas as categorias</SelectItem>
            {CATEGORIAS.map((c) => (
              <SelectItem key={c.valor} value={c.valor}>
                {c.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={String(mes)} onValueChange={(v) => setMes(Number(v))}>
          <SelectTrigger className="h-11 w-[150px] rounded-xl bg-surface">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {MESES.map((m, i) => (
              <SelectItem key={m} value={String(i + 1)}>
                {m}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={String(ano)} onValueChange={(v) => setAno(Number(v))}>
          <SelectTrigger className="h-11 w-[110px] rounded-xl bg-surface">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {[anoAtual - 1, anoAtual].map((a) => (
              <SelectItem key={a} value={String(a)}>
                {a}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="mt-4">
        <SectionTitle hint={`${lista.length} lançamentos`}>Lançamentos</SectionTitle>
        {isPending ? (
          <ListSkeleton />
        ) : isError ? (
          <EmptyState
            icon={<TriangleAlert className="size-5" />}
            titulo="Não deu para carregar os gastos"
            descricao={textoDoErro(error)}
          />
        ) : lista.length ? (
          <ul className="space-y-3">
            {lista.map((g) => {
              const situacao = situacaoDo(g);
              return (
                <li key={g.id}>
                  <Card className="p-4">
                    <div className="grid grid-cols-[minmax(0,1fr)_auto] items-start gap-3">
                      <div className="min-w-0">
                        <p className="truncate font-semibold">{g.nome}</p>
                        <p className="mt-0.5 text-xs text-muted-foreground">
                          Vence em {formatDate(g.prazo_pagamento)} •{" "}
                          {rotuloForma[g.forma_pagamento]}
                        </p>
                        <div className="mt-2 flex flex-wrap items-center gap-1.5">
                          <Pill tone="brand">{rotuloCategoria[g.categoria]}</Pill>
                          <Pill tone={tomSituacao[situacao]}>{rotuloSituacao[situacao]}</Pill>
                        </div>
                      </div>
                      <div className="shrink-0 text-right">
                        <Money value={g.valor} className="text-base" />
                        <div className="mt-2 flex justify-end gap-1">
                          {!g.pago ? (
                            <Button
                              size="icon"
                              variant="ghost"
                              aria-label="Marcar como pago"
                              disabled={pagar.isPending}
                              onClick={() =>
                                pagar.mutate(g.id, {
                                  onSuccess: () => toast.success("Gasto marcado como pago."),
                                  onError: (erro) => toast.error(textoDoErro(erro)),
                                })
                              }
                            >
                              <CheckCircle2 className="size-4 text-positive" />
                            </Button>
                          ) : null}
                          <Button
                            size="icon"
                            variant="ghost"
                            aria-label="Editar gasto"
                            onClick={() => abrirEdicao(g)}
                          >
                            <Pencil className="size-4" />
                          </Button>
                          <Button
                            size="icon"
                            variant="ghost"
                            aria-label="Excluir gasto"
                            disabled={excluir.isPending}
                            onClick={() =>
                              excluir.mutate(g.id, {
                                onSuccess: () => toast.success("Gasto excluído."),
                                onError: (erro) => toast.error(textoDoErro(erro)),
                              })
                            }
                          >
                            <Trash2 className="size-4 text-negative" />
                          </Button>
                        </div>
                      </div>
                    </div>
                  </Card>
                </li>
              );
            })}
          </ul>
        ) : (
          <EmptyState
            icon={<Receipt className="size-5" />}
            titulo="Nenhum gasto por aqui"
            descricao="Registre suas contas e compras de material para saber o lucro real."
            acao={<Button onClick={abrirNovo}>Novo gasto</Button>}
          />
        )}
      </div>

      <Dialog open={aberto} onOpenChange={setAberto}>
        <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-md">
          <DialogHeader>
            <DialogTitle>{form.id ? "Editar gasto" : "Novo gasto"}</DialogTitle>
            <DialogDescription>
              Informe o valor, o vencimento e a categoria para o cálculo do lucro.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-3">
            <div className="space-y-1.5">
              <Label htmlFor="descricao">Descrição</Label>
              <Input
                id="descricao"
                value={form.nome}
                onChange={(e) => setForm({ ...form, nome: e.target.value })}
                placeholder="Ex.: compra de cílios"
              />
            </div>
            <div className="grid gap-3 sm:grid-cols-2">
              <div className="space-y-1.5">
                <Label htmlFor="valor">Valor (R$)</Label>
                <Input
                  id="valor"
                  inputMode="decimal"
                  value={form.valor}
                  onChange={(e) => setForm({ ...form, valor: e.target.value })}
                  placeholder="0,00"
                />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="vencimento">Vencimento</Label>
                <Input
                  id="vencimento"
                  type="date"
                  value={form.prazo}
                  onChange={(e) => setForm({ ...form, prazo: e.target.value })}
                />
              </div>
            </div>
            <div className="grid gap-3 sm:grid-cols-2">
              <div className="space-y-1.5">
                <Label>Categoria</Label>
                <Select
                  value={form.categoria}
                  onValueChange={(v) => setForm({ ...form, categoria: v as CategoriaGasto })}
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
                <Label>Forma de pagamento</Label>
                <Select
                  value={form.forma}
                  onValueChange={(v) => setForm({ ...form, forma: v as FormaPagamento })}
                >
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
            {/*
              Não existe campo "situação" aqui: o gasto nasce pendente e a baixa
              é um ato separado (o botão ✓ da lista, `PATCH /gastos/{id}/pagar`).
            */}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setAberto(false)} disabled={salvando}>
              Cancelar
            </Button>
            <Button onClick={salvar} disabled={salvando}>
              Salvar
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </AppShell>
  );
}
