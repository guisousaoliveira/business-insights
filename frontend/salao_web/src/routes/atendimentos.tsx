import { createFileRoute } from "@tanstack/react-router";
import { CalendarHeart, CheckCircle2, Pencil, TriangleAlert, X } from "lucide-react";
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
  type BadgeTone,
} from "@/components/ui-kit";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
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
import type { AtendimentoBody } from "@/lib/api";
import { formatBRL, formatDate, formatHora } from "@/lib/format";
import {
  textoDoErro,
  useAtendimentos,
  useCancelarAtendimento,
  useCriarAtendimento,
  useEditarAtendimento,
  useEstoque,
  useFinalizarAtendimento,
  useServicos,
} from "@/lib/queries";
import type { Atendimento, FaltanteEstoque, StatusAtendimento } from "@/lib/types";

export const Route = createFileRoute("/atendimentos")({
  head: () => ({
    meta: [
      { title: "Atendimentos — GlowApp" },
      {
        name: "description",
        content:
          "Agende, finalize e acompanhe o lucro de cada atendimento do salão, com baixa automática de produtos.",
      },
      { property: "og:title", content: "Atendimentos — GlowApp" },
      {
        property: "og:description",
        content: "Controle de agenda, valores cobrados, custos e lucro por atendimento.",
      },
    ],
  }),
  component: AtendimentosPage,
});

const statusInfo: Record<StatusAtendimento, { label: string; tone: BadgeTone }> = {
  agendado: { label: "Agendado", tone: "brand" },
  finalizado: { label: "Finalizado", tone: "positive" },
  cancelado: { label: "Cancelado", tone: "neutral" },
};

type Periodo = "mes" | "proximos" | "todos";

/** `AAAA-MM-DD` no fuso local — `toISOString` daria o dia errado à noite. */
function diaIso(d: Date): string {
  const mes = String(d.getMonth() + 1).padStart(2, "0");
  const dia = String(d.getDate()).padStart(2, "0");
  return `${d.getFullYear()}-${mes}-${dia}`;
}

/** A listagem do contrato é por intervalo: o filtro da tela vira `inicio`/`fim`. */
function intervalo(periodo: Periodo): { inicio: string; fim: string } {
  const hoje = new Date();
  if (periodo === "mes") {
    return {
      inicio: diaIso(new Date(hoje.getFullYear(), hoje.getMonth(), 1)),
      fim: diaIso(new Date(hoje.getFullYear(), hoje.getMonth() + 1, 0)),
    };
  }
  if (periodo === "proximos") {
    const fim = new Date(hoje);
    fim.setDate(fim.getDate() + 30);
    return { inicio: diaIso(hoje), fim: diaIso(fim) };
  }
  return {
    inicio: `${hoje.getFullYear() - 1}-01-01`,
    fim: `${hoje.getFullYear()}-12-31`,
  };
}

/** ISO-8601 com o offset local, como o contrato pede. */
function paraIso(data: string, hora: string): string {
  const minutos = -new Date(`${data}T${hora}:00`).getTimezoneOffset();
  const sinal = minutos >= 0 ? "+" : "-";
  const hh = String(Math.floor(Math.abs(minutos) / 60)).padStart(2, "0");
  const mm = String(Math.abs(minutos) % 60).padStart(2, "0");
  return `${data}T${hora}:00${sinal}${hh}:${mm}`;
}

function nomesDosServicos(a: Atendimento): string {
  return a.servicos.map((s) => s.nome).join(" + ");
}

function AtendimentosPage() {
  const [filtroStatus, setFiltroStatus] = useState<"todos" | StatusAtendimento>("todos");
  const [periodo, setPeriodo] = useState<Periodo>("mes");
  const [formAberto, setFormAberto] = useState(false);
  const [editando, setEditando] = useState<Atendimento | null>(null);
  const [finalizar, setFinalizar] = useState<Atendimento | null>(null);
  const [cancelar, setCancelar] = useState<Atendimento | null>(null);

  const { inicio, fim } = useMemo(() => intervalo(periodo), [periodo]);
  const status = filtroStatus === "todos" ? [] : [filtroStatus];

  const { data, isPending, isError, error } = useAtendimentos(inicio, fim, status);
  const cancelamento = useCancelarAtendimento();

  const lista = useMemo(
    () => (data?.atendimentos ?? []).slice().sort((a, b) => b.data.localeCompare(a.data)),
    [data],
  );

  function abrirNovo() {
    setEditando(null);
    setFormAberto(true);
  }

  return (
    <AppShell
      titulo="Atendimentos"
      subtitulo={
        data
          ? `${data.quantidade} atendimentos • saldo de ${formatBRL(data.saldo_liquido)}`
          : "Agenda, valores e lucro de cada cliente"
      }
      acaoLabel="Agendar atendimento"
      onAcao={abrirNovo}
    >
      <div className="mb-4 flex flex-wrap gap-2">
        <Select value={periodo} onValueChange={(v) => setPeriodo(v as Periodo)}>
          <SelectTrigger className="h-11 w-[160px] rounded-xl bg-surface">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="mes">Este mês</SelectItem>
            <SelectItem value="proximos">Próximos dias</SelectItem>
            <SelectItem value="todos">Todo o período</SelectItem>
          </SelectContent>
        </Select>
        <Select
          value={filtroStatus}
          onValueChange={(v) => setFiltroStatus(v as typeof filtroStatus)}
        >
          <SelectTrigger className="h-11 w-[150px] rounded-xl bg-surface">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="todos">Todos os status</SelectItem>
            <SelectItem value="agendado">Agendados</SelectItem>
            <SelectItem value="finalizado">Finalizados</SelectItem>
            <SelectItem value="cancelado">Cancelados</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {isPending ? (
        <ListSkeleton linhas={5} />
      ) : isError ? (
        <EmptyState
          icon={<TriangleAlert className="size-5" />}
          titulo="Não deu para carregar a agenda"
          descricao={textoDoErro(error)}
        />
      ) : lista.length === 0 ? (
        <EmptyState
          icon={<CalendarHeart className="size-5" />}
          titulo="Nenhum atendimento por aqui"
          descricao="Agende o primeiro atendimento do período para começar a acompanhar seu lucro."
          acao={<Button onClick={abrirNovo}>Agendar atendimento</Button>}
        />
      ) : (
        <div className="grid gap-3 lg:grid-cols-2">
          {lista.map((a) => (
            <Card key={a.id} className="p-4">
              <div className="grid grid-cols-[minmax(0,1fr)_auto] items-start gap-3">
                <div className="min-w-0">
                  <p className="truncate font-display text-base font-semibold">{a.cliente_nome}</p>
                  <p className="mt-0.5 truncate text-sm text-muted-foreground">
                    {nomesDosServicos(a)}
                  </p>
                  <p className="mt-1 text-xs text-muted-foreground">
                    {formatDate(a.data)} às {formatHora(a.data)}
                    {a.cliente_telefone ? ` • ${a.cliente_telefone}` : ""}
                  </p>
                </div>
                <Pill tone={statusInfo[a.status].tone}>{statusInfo[a.status].label}</Pill>
              </div>

              {/* Os três números vêm prontos do servidor — a tela não subtrai nada. */}
              <div className="mt-3 grid grid-cols-3 gap-2 rounded-xl bg-surface-2 p-3 text-center">
                <div>
                  <p className="text-[10px] font-semibold tracking-wide text-muted-foreground uppercase">
                    Cobrado
                  </p>
                  <Money value={a.total_servicos} className="text-sm" />
                </div>
                <div>
                  <p className="text-[10px] font-semibold tracking-wide text-muted-foreground uppercase">
                    Custo
                  </p>
                  <Money value={a.total_materiais} className="text-sm" />
                </div>
                <div>
                  <p className="text-[10px] font-semibold tracking-wide text-muted-foreground uppercase">
                    Lucro
                  </p>
                  <Money value={a.saldo} colorir className="text-sm" />
                </div>
              </div>

              {a.materiais.length ? (
                <p className="mt-2 truncate text-xs text-muted-foreground">
                  Produtos: {a.materiais.map((m) => `${m.nome} (${m.quantidade})`).join(", ")}
                </p>
              ) : null}

              <div className="mt-3 flex flex-wrap gap-2">
                {a.status === "agendado" ? (
                  <>
                    <Button size="sm" onClick={() => setFinalizar(a)}>
                      <CheckCircle2 className="size-4" />
                      Finalizar
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => {
                        setEditando(a);
                        setFormAberto(true);
                      }}
                    >
                      <Pencil className="size-4" />
                      Editar
                    </Button>
                    <Button size="sm" variant="ghost" onClick={() => setCancelar(a)}>
                      <X className="size-4" />
                      Cancelar
                    </Button>
                  </>
                ) : a.status === "finalizado" ? (
                  <Button size="sm" variant="ghost" onClick={() => setCancelar(a)}>
                    <X className="size-4" />
                    Cancelar
                  </Button>
                ) : null}
              </div>
            </Card>
          ))}
        </div>
      )}

      <FormularioAtendimento
        aberto={formAberto}
        onFechar={() => setFormAberto(false)}
        atendimento={editando}
      />
      <DialogFinalizar atendimento={finalizar} onFechar={() => setFinalizar(null)} />

      <AlertDialog open={cancelar !== null} onOpenChange={(o) => !o && setCancelar(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Cancelar este atendimento?</AlertDialogTitle>
            <AlertDialogDescription>
              O atendimento de {cancelar?.cliente_nome} ficará marcado como cancelado e não entrará
              no faturamento do mês.
              {cancelar?.status === "finalizado"
                ? " Os produtos usados voltam para o estoque."
                : ""}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={cancelamento.isPending}>Voltar</AlertDialogCancel>
            <AlertDialogAction
              disabled={cancelamento.isPending}
              onClick={(e) => {
                e.preventDefault();
                if (!cancelar) return;
                cancelamento.mutate(cancelar.id, {
                  onSuccess: () => {
                    toast.success("Atendimento cancelado.");
                    setCancelar(null);
                  },
                  onError: (erro) => toast.error(textoDoErro(erro)),
                });
              }}
            >
              Sim, cancelar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </AppShell>
  );
}

function FormularioAtendimento({
  aberto,
  onFechar,
  atendimento,
}: {
  aberto: boolean;
  onFechar: () => void;
  atendimento: Atendimento | null;
}) {
  const { data: catalogo } = useServicos();
  const servicos = catalogo?.servicos ?? [];
  const criar = useCriarAtendimento();
  const editar = useEditarAtendimento();

  const [cliente, setCliente] = useState("");
  const [telefone, setTelefone] = useState("");
  const [data, setData] = useState(diaIso(new Date()));
  const [hora, setHora] = useState("09:00");
  const [escolhidos, setEscolhidos] = useState<string[]>([]);
  const [chave, setChave] = useState("");

  // Sincroniza os campos quando o diálogo abre (padrão do protótipo: estado
  // derivado da chave, sem `useEffect`).
  const chaveAtual = `${String(aberto)}-${atendimento?.id ?? "novo"}`;
  if (chave !== chaveAtual) {
    setChave(chaveAtual);
    if (aberto) {
      const quando = atendimento ? new Date(atendimento.data) : new Date();
      setCliente(atendimento?.cliente_nome ?? "");
      setTelefone(atendimento?.cliente_telefone ?? "");
      setData(diaIso(quando));
      setHora(
        atendimento
          ? formatHora(atendimento.data)
          : `${String(quando.getHours()).padStart(2, "0")}:00`,
      );
      setEscolhidos(
        atendimento
          ? atendimento.servicos.map((s) => s.servico_id).filter((id): id is string => id !== null)
          : [],
      );
    }
  }

  const total = servicos.filter((s) => escolhidos.includes(s.id)).reduce((t, s) => t + s.preco, 0);
  const salvando = criar.isPending || editar.isPending;

  function alternar(id: string) {
    setEscolhidos((atual) => (atual.includes(id) ? atual.filter((x) => x !== id) : [...atual, id]));
  }

  function submeter(e: React.FormEvent) {
    e.preventDefault();
    if (escolhidos.length === 0) {
      toast.error("Escolha pelo menos um serviço.");
      return;
    }
    const body: AtendimentoBody = {
      cliente_nome: cliente.trim(),
      cliente_telefone: telefone.trim() === "" ? null : telefone.trim(),
      data: paraIso(data, hora),
      servicos: escolhidos.map((id) => ({ servico_id: id })),
    };
    const opcoes = {
      onSuccess: () => {
        onFechar();
        toast.success(atendimento ? "Atendimento atualizado." : "Atendimento agendado!");
      },
      onError: (erro: unknown) => toast.error(textoDoErro(erro)),
    };
    if (atendimento) editar.mutate({ id: atendimento.id, body }, opcoes);
    else criar.mutate(body, opcoes);
  }

  return (
    <Dialog open={aberto} onOpenChange={(o) => !o && onFechar()}>
      <DialogContent className="max-h-[92vh] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle className="font-display">
            {atendimento ? "Editar atendimento" : "Agendar atendimento"}
          </DialogTitle>
          <DialogDescription>Preencha os dados do atendimento.</DialogDescription>
        </DialogHeader>
        <form onSubmit={submeter} className="space-y-3">
          <div className="space-y-1.5">
            <Label htmlFor="cliente">Cliente</Label>
            <Input
              id="cliente"
              value={cliente}
              onChange={(e) => setCliente(e.target.value)}
              className="h-11 rounded-xl"
              required
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="telefone">Telefone (opcional)</Label>
            <Input
              id="telefone"
              value={telefone}
              onChange={(e) => setTelefone(e.target.value)}
              className="h-11 rounded-xl"
              placeholder="(11) 90000-0000"
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <Label htmlFor="data">Data</Label>
              <Input
                id="data"
                type="date"
                value={data}
                onChange={(e) => setData(e.target.value)}
                className="h-11 rounded-xl"
                required
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="hora">Horário</Label>
              <Input
                id="hora"
                type="time"
                value={hora}
                onChange={(e) => setHora(e.target.value)}
                className="h-11 rounded-xl"
                required
              />
            </div>
          </div>

          {/*
            Um atendimento tem N serviços: "sobrancelha + cílios na mesma
            cadeira" é um atendimento só, e é assim que o saldo do dia fecha.
            O preço é o do catálogo, congelado no ato pelo servidor.
          */}
          <div className="space-y-1.5">
            <Label>Serviços</Label>
            <ul className="space-y-2">
              {servicos.map((s) => (
                <li key={s.id}>
                  <label className="flex items-center justify-between gap-3 rounded-xl border border-border p-2.5">
                    <span className="flex min-w-0 items-center gap-2.5">
                      <Checkbox
                        checked={escolhidos.includes(s.id)}
                        onCheckedChange={() => alternar(s.id)}
                      />
                      <span className="min-w-0 truncate text-sm font-medium">{s.nome}</span>
                    </span>
                    <span className="shrink-0 text-sm text-muted-foreground">
                      {formatBRL(s.preco)}
                    </span>
                  </label>
                </li>
              ))}
            </ul>
            {servicos.length === 0 ? (
              <p className="text-xs text-muted-foreground">
                Cadastre seus serviços no perfil para agendar.
              </p>
            ) : null}
          </div>

          <div className="flex items-center justify-between rounded-xl bg-surface-2 p-3 text-sm">
            <span className="text-muted-foreground">Total do atendimento</span>
            <Money value={total} />
          </div>

          <DialogFooter>
            <Button type="button" variant="ghost" onClick={onFechar} disabled={salvando}>
              Voltar
            </Button>
            <Button type="submit" disabled={salvando}>
              {salvando ? "Salvando..." : "Salvar"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

function DialogFinalizar({
  atendimento,
  onFechar,
}: {
  atendimento: Atendimento | null;
  onFechar: () => void;
}) {
  const { data: estoque } = useEstoque();
  const { data: catalogo } = useServicos();
  const finalizar = useFinalizarAtendimento();

  const [quantidades, setQuantidades] = useState<Record<string, number>>({});
  const [chave, setChave] = useState("");
  const [faltantes, setFaltantes] = useState<FaltanteEstoque[] | null>(null);

  const itens = estoque?.itens ?? [];
  const servicos = catalogo?.servicos ?? [];

  // Ao abrir, já vem marcado o que o serviço costuma gastar: ela não deveria
  // ter que lembrar quanta cola sai numa aplicação.
  const chaveAtual = atendimento?.id ?? "";
  if (chave !== chaveAtual) {
    setChave(chaveAtual);
    const inicial: Record<string, number> = {};
    atendimento?.servicos.forEach((s) => {
      const doCatalogo = servicos.find((x) => x.id === s.servico_id);
      doCatalogo?.produtos_padrao.forEach((p) => {
        inicial[p.item_estoque_id] = (inicial[p.item_estoque_id] ?? 0) + p.quantidade;
      });
    });
    setQuantidades(inicial);
    setFaltantes(null);
  }

  if (!atendimento) return null;

  // Sem anotar `MaterialEntrada[]`: a união com o material avulso (`nome`/`preco`)
  // apagaria `item_estoque_id` da prévia de custo logo abaixo. A conversão para o
  // corpo da requisição acontece na chamada.
  const materiais = Object.entries(quantidades)
    .filter(([, q]) => q > 0)
    .map(([item_estoque_id, quantidade]) => ({ item_estoque_id, quantidade }));

  // Prévia local do custo, só para ela ver o lucro antes de confirmar. O número
  // que vale é o que o servidor grava com o custo médio do momento da baixa.
  const custo = materiais.reduce((t, m) => {
    const item = itens.find((i) => i.id === m.item_estoque_id);
    return t + (item ? item.custo_medio * m.quantidade : 0);
  }, 0);
  const lucro = atendimento.total_servicos - custo;

  function concluir(confirmarEstoqueInsuficiente: boolean) {
    if (!atendimento) return;
    finalizar.mutate(
      {
        id: atendimento.id,
        body: {
          materiais,
          confirmar_estoque_insuficiente: confirmarEstoqueInsuficiente,
        },
      },
      {
        onSuccess: () => {
          setFaltantes(null);
          onFechar();
          toast.success("Atendimento finalizado!");
        },
        onError: (erro) => {
          // A5: a primeira passada não grava nada; o servidor diz o que falta e
          // ela decide se registra assim mesmo.
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

  return (
    <>
      <Dialog open onOpenChange={(o) => !o && onFechar()}>
        <DialogContent className="max-h-[92vh] overflow-y-auto sm:max-w-lg">
          <DialogHeader>
            <DialogTitle className="font-display">Finalizar atendimento</DialogTitle>
            <DialogDescription>
              {atendimento.cliente_nome} • {nomesDosServicos(atendimento)}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4">
            <div className="grid grid-cols-3 gap-2 rounded-xl bg-surface-2 p-3 text-center">
              <div>
                <p className="text-[10px] font-semibold text-muted-foreground uppercase">Receita</p>
                <Money value={atendimento.total_servicos} className="text-sm" />
              </div>
              <div>
                <p className="text-[10px] font-semibold text-muted-foreground uppercase">
                  Produtos
                </p>
                <Money value={custo} className="text-sm" />
              </div>
              <div>
                <p className="text-[10px] font-semibold text-muted-foreground uppercase">Lucro</p>
                <Money value={lucro} colorir className="text-sm" />
              </div>
            </div>

            <div>
              <SectionTitle hint="Marque o que foi usado — o estoque é baixado automaticamente">
                Produtos utilizados
              </SectionTitle>
              <ul className="space-y-2">
                {itens.map((p) => {
                  const quantidade = quantidades[p.id] ?? 0;
                  return (
                    <li
                      key={p.id}
                      className="flex items-center justify-between gap-3 rounded-xl border border-border p-2.5"
                    >
                      <label className="flex min-w-0 items-center gap-2.5">
                        <Checkbox
                          checked={quantidade > 0}
                          onCheckedChange={(v) =>
                            setQuantidades((s) => ({ ...s, [p.id]: v ? 1 : 0 }))
                          }
                        />
                        <span className="min-w-0">
                          <span className="block truncate text-sm font-medium">{p.nome}</span>
                          <span className="block text-xs text-muted-foreground">
                            Saldo: {p.quantidade_atual} {p.unidade} • {formatBRL(p.custo_medio)}
                          </span>
                        </span>
                      </label>
                      {quantidade > 0 ? (
                        <Input
                          type="number"
                          min={1}
                          value={quantidade}
                          onChange={(e) =>
                            setQuantidades((s) => ({ ...s, [p.id]: Number(e.target.value) }))
                          }
                          className="h-9 w-16 rounded-lg text-center"
                        />
                      ) : null}
                    </li>
                  );
                })}
              </ul>
            </div>
          </div>

          <DialogFooter>
            <Button variant="ghost" onClick={onFechar} disabled={finalizar.isPending}>
              Voltar
            </Button>
            <Button onClick={() => concluir(false)} disabled={finalizar.isPending}>
              Finalizar atendimento
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <EstoqueInsuficienteDialog
        faltantes={faltantes}
        acao="finalizar este atendimento"
        confirmando={finalizar.isPending}
        onCancelar={() => setFaltantes(null)}
        onConfirmar={() => concluir(true)}
      />
    </>
  );
}
