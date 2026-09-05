import { createFileRoute, useNavigate } from "@tanstack/react-router";
import {
  CalendarClock,
  Check,
  Copy,
  Link2,
  LogOut,
  Pencil,
  Plus,
  Scissors,
  Target,
  Trash2,
  TriangleAlert,
} from "lucide-react";
import { useEffect, useState } from "react";
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
import { Switch } from "@/components/ui/switch";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { formatBRL, nomeMes } from "@/lib/format";
import {
  textoDoErro,
  useCriarCustoFixo,
  useCriarServico,
  useCustosFixos,
  useEditarServico,
  useEstoque,
  useExcluirCustoFixo,
  useExcluirServico,
  useHorarioFuncionamento,
  useLinkAgendamento,
  useLogout,
  usePagarCustoFixo,
  usePerfil,
  useSalvarHorarioFuncionamento,
  useSalvarPerfil,
  useServicos,
} from "@/lib/queries";
import type { CustoFixo, HorarioDia, Servico } from "@/lib/types";

/** domingo=0 … sábado=6, mesma convenção do backend. */
const DIAS_SEMANA = [
  "Domingo",
  "Segunda",
  "Terça",
  "Quarta",
  "Quinta",
  "Sexta",
  "Sábado",
];

function horariosPadrao(): HorarioDia[] {
  return DIAS_SEMANA.map((_, dia_semana) => ({
    dia_semana,
    ativo: dia_semana >= 1 && dia_semana <= 5,
    hora_inicio: dia_semana >= 1 && dia_semana <= 5 ? "09:00" : null,
    hora_fim: dia_semana >= 1 && dia_semana <= 5 ? "19:00" : null,
  }));
}

export const Route = createFileRoute("/perfil")({
  head: () => ({
    meta: [
      { title: "Perfil e serviços — GlowApp" },
      {
        name: "description",
        content:
          "Dados do salão, meta de faturamento, custos fixos recorrentes e cadastro de serviços com insumos padrão.",
      },
      { property: "og:title", content: "Perfil e serviços — GlowApp" },
      {
        property: "og:description",
        content: "Configure meta, custos fixos e a tabela de serviços do seu salão.",
      },
    ],
  }),
  component: PerfilPage,
});

interface FormServico {
  id?: string;
  nome: string;
  preco: string;
  produtos: { item_estoque_id: string; quantidade: number }[];
}

/** Competência do mês corrente, no formato `AAAA-MM` que o contrato pede. */
function competenciaAtual(): string {
  const hoje = new Date();
  return `${hoje.getFullYear()}-${String(hoje.getMonth() + 1).padStart(2, "0")}`;
}

function PerfilPage() {
  const navigate = useNavigate();
  const competencia = competenciaAtual();

  const { data: perfilServidor, isPending: carregandoPerfil } = usePerfil();
  const { data: custos, isPending: carregandoCustos } = useCustosFixos(competencia);
  const { data: listaServicos, isPending: carregandoServicos } = useServicos();
  const { data: estoque } = useEstoque();
  const { data: horarioServidor, isPending: carregandoHorario } = useHorarioFuncionamento();
  const { data: link, isPending: carregandoLink } = useLinkAgendamento();

  const salvar = useSalvarPerfil();
  const criarCusto = useCriarCustoFixo();
  const excluirCusto = useExcluirCustoFixo();
  const pagarCusto = usePagarCustoFixo();
  const criarServico = useCriarServico();
  const editarServico = useEditarServico();
  const excluirServico = useExcluirServico();
  const salvarHorario = useSalvarHorarioFuncionamento();
  const sair = useLogout();

  const [horarios, setHorarios] = useState<HorarioDia[]>(horariosPadrao());
  const [linkCopiado, setLinkCopiado] = useState(false);

  useEffect(() => {
    if (horarioServidor?.horarios.length) setHorarios(horarioServidor.horarios);
  }, [horarioServidor]);

  const alternarDia = (dia_semana: number) => {
    setHorarios((atual) =>
      atual.map((h) =>
        h.dia_semana === dia_semana
          ? {
              ...h,
              ativo: !h.ativo,
              hora_inicio: h.ativo ? null : (h.hora_inicio ?? "09:00"),
              hora_fim: h.ativo ? null : (h.hora_fim ?? "18:00"),
            }
          : h,
      ),
    );
  };

  const alterarHorarioDia = (dia_semana: number, campo: "hora_inicio" | "hora_fim", valor: string) => {
    setHorarios((atual) =>
      atual.map((h) => (h.dia_semana === dia_semana ? { ...h, [campo]: valor } : h)),
    );
  };

  const salvarHorarios = () => {
    salvarHorario.mutate(horarios, {
      onSuccess: () => toast.success("Horário de funcionamento salvo."),
      onError: (erro) => toast.error(textoDoErro(erro)),
    });
  };

  const copiarLink = () => {
    if (!link) return;
    navigator.clipboard.writeText(link.url).then(() => {
      setLinkCopiado(true);
      setTimeout(() => setLinkCopiado(false), 2000);
    });
  };

  const [perfil, setPerfil] = useState({
    nome: "",
    proprietaria: "",
    telefone: "",
    meta: "",
  });

  // O formulário é rascunho local; o servidor é a fonte. Ao chegar (ou trocar
  // de salão), o rascunho é reescrito pelo que veio.
  useEffect(() => {
    const s = perfilServidor?.salao;
    if (!s) return;
    setPerfil({
      nome: s.nome,
      proprietaria: s.proprietaria,
      telefone: s.telefone_whatsapp ?? "",
      meta: String(s.meta_faturamento_mensal),
    });
  }, [perfilServidor]);

  const [custoAberto, setCustoAberto] = useState(false);
  const [formCusto, setFormCusto] = useState({ descricao: "", valor: "", dia: "5" });
  const [custoParaExcluir, setCustoParaExcluir] = useState<CustoFixo | null>(null);

  const [aberto, setAberto] = useState(false);
  const [form, setForm] = useState<FormServico>({ nome: "", preco: "", produtos: [] });
  const [servicoParaExcluir, setServicoParaExcluir] = useState<Servico | null>(null);

  const itens = estoque?.itens ?? [];
  const servicos = listaServicos?.servicos ?? [];

  /** Prévia local pelo custo médio de hoje — o custo real de cada atendimento é gravado no servidor. */
  const custoInsumos = (produtos: FormServico["produtos"]) =>
    produtos.reduce((t, i) => {
      const p = itens.find((x) => x.id === i.item_estoque_id);
      return t + (p ? p.custo_medio * i.quantidade : 0);
    }, 0);

  const salvarDados = () => {
    const meta = Number(perfil.meta.replace(",", "."));
    if (!perfil.nome.trim() || !perfil.proprietaria.trim()) {
      toast.error("Informe o nome do salão e da profissional.");
      return;
    }
    salvar.mutate(
      {
        nome: perfil.nome.trim(),
        proprietaria: perfil.proprietaria.trim(),
        telefone_whatsapp: perfil.telefone.trim() || null,
        meta_faturamento_mensal: Number.isFinite(meta) ? meta : 0,
      },
      {
        onSuccess: () => toast.success("Dados salvos."),
        onError: (erro) => toast.error(textoDoErro(erro)),
      },
    );
  };

  const cadastrarCusto = () => {
    const valor = Number(formCusto.valor.replace(",", "."));
    const dia = Number(formCusto.dia);
    if (!formCusto.descricao.trim() || !(valor > 0) || !(dia >= 1 && dia <= 31)) {
      toast.error("Informe descrição, valor e um dia de vencimento entre 1 e 31.");
      return;
    }
    criarCusto.mutate(
      { descricao: formCusto.descricao.trim(), valor, dia_vencimento: dia },
      {
        onSuccess: () => {
          setCustoAberto(false);
          setFormCusto({ descricao: "", valor: "", dia: "5" });
          toast.success("Custo fixo cadastrado.");
        },
        onError: (erro) => toast.error(textoDoErro(erro)),
      },
    );
  };

  const alternarPagamento = (c: CustoFixo) => {
    pagarCusto.mutate(
      { id: c.id, competencia, pago: !c.pago },
      {
        onSuccess: () =>
          toast.success(c.pago ? "Pagamento desmarcado." : `${c.descricao} marcado como pago.`),
        onError: (erro) => toast.error(textoDoErro(erro)),
      },
    );
  };

  const confirmarExclusaoCusto = () => {
    if (!custoParaExcluir) return;
    excluirCusto.mutate(custoParaExcluir.id, {
      onSuccess: () => {
        setCustoParaExcluir(null);
        toast.success("Custo fixo excluído.");
      },
      onError: (erro) => toast.error(textoDoErro(erro)),
    });
  };

  const abrirNovoServico = () => {
    setForm({ nome: "", preco: "", produtos: [] });
    setAberto(true);
  };

  const abrirEdicao = (s: Servico) => {
    setForm({
      id: s.id,
      nome: s.nome,
      preco: String(s.preco),
      produtos: s.produtos_padrao.map((p) => ({
        item_estoque_id: p.item_estoque_id,
        quantidade: p.quantidade,
      })),
    });
    setAberto(true);
  };

  const salvarServicoForm = () => {
    const preco = Number(form.preco.replace(",", "."));
    if (!form.nome.trim() || !(preco > 0)) {
      toast.error("Informe o nome do serviço e um preço válido.");
      return;
    }
    const body = {
      nome: form.nome.trim(),
      preco,
      produtos_padrao: form.produtos,
    };
    const feito = {
      onSuccess: () => {
        setAberto(false);
        toast.success(form.id ? "Serviço atualizado." : "Serviço cadastrado.");
      },
      onError: (erro: unknown) => toast.error(textoDoErro(erro)),
    };
    if (form.id) editarServico.mutate({ id: form.id, body }, feito);
    else criarServico.mutate(body, feito);
  };

  const confirmarExclusaoServico = () => {
    if (!servicoParaExcluir) return;
    excluirServico.mutate(servicoParaExcluir.id, {
      onSuccess: () => {
        setServicoParaExcluir(null);
        toast.success("Serviço excluído.");
      },
      onError: (erro) => toast.error(textoDoErro(erro)),
    });
  };

  const alternarInsumo = (itemId: string) => {
    const existe = form.produtos.some((p) => p.item_estoque_id === itemId);
    setForm({
      ...form,
      produtos: existe
        ? form.produtos.filter((p) => p.item_estoque_id !== itemId)
        : [...form.produtos, { item_estoque_id: itemId, quantidade: 1 }],
    });
  };

  const encerrarSessao = () => {
    sair.mutate(undefined, {
      // `onSettled` no hook já limpa a sessão local mesmo se o servidor recusar.
      onSettled: () => void navigate({ to: "/login" }),
    });
  };

  const meta = perfilServidor?.salao.meta_faturamento_mensal ?? 0;

  return (
    <AppShell
      titulo="Perfil"
      subtitulo="Dados do salão, custos fixos e serviços"
      acaoLabel="Novo serviço"
      onAcao={abrirNovoServico}
    >
      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <StatCard
          label="Meta de faturamento"
          value={formatBRL(meta)}
          icon={<Target className="size-4" />}
          destaque
        />
        <StatCard
          label="Custos fixos"
          value={formatBRL(custos?.total_mensal ?? 0)}
          hint="por mês"
        />
        <StatCard
          label={`A pagar em ${nomeMes(Number(competencia.slice(5)))}`}
          value={formatBRL(custos?.total_pendente ?? 0)}
          tone={custos && custos.total_pendente > 0 ? "warning" : "positive"}
        />
        <StatCard label="Serviços" value={String(servicos.length)} />
      </div>

      <Tabs defaultValue="dados" className="mt-5">
        <TabsList className="h-11 rounded-xl">
          <TabsTrigger value="dados">Dados e meta</TabsTrigger>
          <TabsTrigger value="custos">Custos fixos</TabsTrigger>
          <TabsTrigger value="servicos">Serviços</TabsTrigger>
          <TabsTrigger value="agendamento">Agendamento online</TabsTrigger>
        </TabsList>

        <TabsContent value="dados" className="mt-4">
          <Card className="p-4">
            <SectionTitle hint="Usados nos cálculos de lucro e meta">Dados do salão</SectionTitle>
            {carregandoPerfil ? (
              <ListSkeleton linhas={3} />
            ) : (
              <>
                <div className="grid gap-3 sm:grid-cols-2">
                  <div className="space-y-1.5">
                    <Label htmlFor="salao">Nome do salão</Label>
                    <Input
                      id="salao"
                      value={perfil.nome}
                      onChange={(e) => setPerfil({ ...perfil, nome: e.target.value })}
                    />
                  </div>
                  <div className="space-y-1.5">
                    <Label htmlFor="profissional">Profissional</Label>
                    <Input
                      id="profissional"
                      value={perfil.proprietaria}
                      onChange={(e) => setPerfil({ ...perfil, proprietaria: e.target.value })}
                    />
                  </div>
                  <div className="space-y-1.5">
                    <Label htmlFor="telefone">WhatsApp</Label>
                    <Input
                      id="telefone"
                      value={perfil.telefone}
                      onChange={(e) => setPerfil({ ...perfil, telefone: e.target.value })}
                      placeholder="(00) 00000-0000"
                    />
                  </div>
                  <div className="space-y-1.5">
                    <Label htmlFor="meta-fat">Meta de faturamento mensal (R$)</Label>
                    <Input
                      id="meta-fat"
                      inputMode="decimal"
                      value={perfil.meta}
                      onChange={(e) => setPerfil({ ...perfil, meta: e.target.value })}
                    />
                  </div>
                </div>
                <div className="mt-4 flex flex-wrap gap-2">
                  <Button onClick={salvarDados} disabled={salvar.isPending}>
                    Salvar alterações
                  </Button>
                  <Button variant="ghost" onClick={encerrarSessao} disabled={sair.isPending}>
                    <LogOut className="size-4" />
                    Sair da conta
                  </Button>
                </div>
              </>
            )}
          </Card>
        </TabsContent>

        <TabsContent value="custos" className="mt-4">
          <SectionTitle
            hint="Cadastro recorrente: o mesmo aluguel vale para todo mês"
            action={
              <Button size="sm" onClick={() => setCustoAberto(true)}>
                <Plus className="size-4" />
                Novo
              </Button>
            }
          >
            Custos fixos de {nomeMes(Number(competencia.slice(5)))}
          </SectionTitle>
          {carregandoCustos ? (
            <ListSkeleton />
          ) : custos?.custos.length ? (
            <ul className="space-y-3">
              {custos.custos.map((c) => (
                <li key={c.id}>
                  <Card className="p-4">
                    <div className="flex items-start justify-between gap-3">
                      <div className="min-w-0">
                        <p className="truncate font-semibold">{c.descricao}</p>
                        <p className="mt-0.5 text-xs text-muted-foreground">
                          todo dia {c.dia_vencimento}
                        </p>
                        <div className="mt-2 flex flex-wrap items-center gap-1.5">
                          <Pill tone="brand">{formatBRL(c.valor)}</Pill>
                          <Pill tone={c.pago ? "positive" : "warning"}>
                            {c.pago ? "Pago" : "Pendente"}
                          </Pill>
                        </div>
                      </div>
                      <div className="flex shrink-0 flex-col items-end gap-2">
                        <div className="flex items-center gap-2">
                          <span className="text-xs text-muted-foreground">Pago</span>
                          <Switch
                            checked={c.pago}
                            onCheckedChange={() => alternarPagamento(c)}
                            disabled={pagarCusto.isPending}
                            aria-label={`Marcar ${c.descricao} como pago`}
                          />
                        </div>
                        <Button
                          size="icon"
                          variant="ghost"
                          aria-label="Excluir custo fixo"
                          onClick={() => setCustoParaExcluir(c)}
                        >
                          <Trash2 className="size-4 text-negative" />
                        </Button>
                      </div>
                    </div>
                  </Card>
                </li>
              ))}
            </ul>
          ) : (
            <EmptyState
              icon={<CalendarClock className="size-5" />}
              titulo="Nenhum custo fixo cadastrado"
              descricao="Aluguel, energia e internet entram aqui uma vez e voltam todo mês."
              acao={<Button onClick={() => setCustoAberto(true)}>Novo custo fixo</Button>}
            />
          )}
        </TabsContent>

        <TabsContent value="servicos" className="mt-4">
          <SectionTitle
            hint="Os insumos padrão são sugeridos ao finalizar um atendimento"
            action={
              <Button size="sm" onClick={abrirNovoServico}>
                <Plus className="size-4" />
                Novo
              </Button>
            }
          >
            Serviços
          </SectionTitle>
          {carregandoServicos ? (
            <ListSkeleton />
          ) : servicos.length ? (
            <ul className="space-y-3">
              {servicos.map((s) => {
                const custo = custoInsumos(
                  s.produtos_padrao.map((p) => ({
                    item_estoque_id: p.item_estoque_id,
                    quantidade: p.quantidade,
                  })),
                );
                return (
                  <li key={s.id}>
                    <Card className="p-4">
                      <div className="grid grid-cols-[minmax(0,1fr)_auto] items-start gap-3">
                        <div className="min-w-0">
                          <p className="truncate font-semibold">{s.nome}</p>
                          <p className="mt-0.5 text-xs text-muted-foreground">
                            {s.produtos_padrao.length
                              ? s.produtos_padrao
                                  .map((p) => `${p.quantidade}${p.unidade} ${p.nome}`)
                                  .join(", ")
                              : "sem insumos padrão"}
                          </p>
                          <div className="mt-2 flex flex-wrap items-center gap-1.5">
                            <Pill tone="brand">Preço {formatBRL(s.preco)}</Pill>
                            <Pill>Custo {formatBRL(custo)}</Pill>
                            <Pill tone={s.preco - custo >= 0 ? "positive" : "negative"}>
                              Lucro {formatBRL(s.preco - custo)}
                            </Pill>
                          </div>
                        </div>
                        <div className="flex shrink-0 gap-1">
                          <Button
                            size="icon"
                            variant="ghost"
                            aria-label="Editar serviço"
                            onClick={() => abrirEdicao(s)}
                          >
                            <Pencil className="size-4" />
                          </Button>
                          <Button
                            size="icon"
                            variant="ghost"
                            aria-label="Excluir serviço"
                            onClick={() => setServicoParaExcluir(s)}
                          >
                            <Trash2 className="size-4 text-negative" />
                          </Button>
                        </div>
                      </div>
                    </Card>
                  </li>
                );
              })}
            </ul>
          ) : (
            <EmptyState
              icon={<Scissors className="size-5" />}
              titulo="Nenhum serviço cadastrado"
              descricao="A tabela de preços alimenta o agendamento e o lucro por serviço."
              acao={<Button onClick={abrirNovoServico}>Novo serviço</Button>}
            />
          )}
        </TabsContent>

        <TabsContent value="agendamento" className="mt-4 space-y-4">
          <Card className="p-4">
            <SectionTitle hint="Link fixo — não expira, envie uma vez só">
              Link para o cliente agendar
            </SectionTitle>
            {carregandoLink ? (
              <ListSkeleton linhas={1} />
            ) : link ? (
              <div className="flex items-center gap-2 rounded-xl border border-border bg-surface-2 p-3">
                <Link2 className="size-4 shrink-0 text-muted-foreground" />
                <span className="min-w-0 flex-1 truncate text-sm">{link.url}</span>
                <Button size="sm" variant="outline" onClick={copiarLink}>
                  {linkCopiado ? <Check className="size-4" /> : <Copy className="size-4" />}
                  {linkCopiado ? "Copiado" : "Copiar"}
                </Button>
              </div>
            ) : null}
          </Card>

          <Card className="p-4">
            <SectionTitle hint="Só aparecem horários dentro do expediente de cada dia">
              Horário de funcionamento
            </SectionTitle>
            {carregandoHorario ? (
              <ListSkeleton linhas={3} />
            ) : (
              <>
                <ul className="space-y-2">
                  {horarios.map((h) => (
                    <li
                      key={h.dia_semana}
                      className="flex flex-wrap items-center gap-3 rounded-xl border border-border p-3"
                    >
                      <div className="flex min-w-[7rem] items-center gap-2">
                        <Switch
                          checked={h.ativo}
                          onCheckedChange={() => alternarDia(h.dia_semana)}
                          aria-label={`Abrir ${DIAS_SEMANA[h.dia_semana]}`}
                        />
                        <span className="text-sm font-medium">{DIAS_SEMANA[h.dia_semana]}</span>
                      </div>
                      {h.ativo ? (
                        <div className="flex items-center gap-2">
                          <Input
                            type="time"
                            value={h.hora_inicio ?? ""}
                            onChange={(e) =>
                              alterarHorarioDia(h.dia_semana, "hora_inicio", e.target.value)
                            }
                            className="h-9 w-28"
                          />
                          <span className="text-sm text-muted-foreground">às</span>
                          <Input
                            type="time"
                            value={h.hora_fim ?? ""}
                            onChange={(e) =>
                              alterarHorarioDia(h.dia_semana, "hora_fim", e.target.value)
                            }
                            className="h-9 w-28"
                          />
                        </div>
                      ) : (
                        <span className="text-sm text-muted-foreground">Fechado</span>
                      )}
                    </li>
                  ))}
                </ul>
                <div className="mt-4">
                  <Button onClick={salvarHorarios} disabled={salvarHorario.isPending}>
                    Salvar horário
                  </Button>
                </div>
              </>
            )}
          </Card>
        </TabsContent>
      </Tabs>

      {/* Novo custo fixo */}
      <Dialog open={custoAberto} onOpenChange={setCustoAberto}>
        <DialogContent className="sm:max-w-sm">
          <DialogHeader>
            <DialogTitle>Novo custo fixo</DialogTitle>
            <DialogDescription>
              Vale para todo mês. O dia é literal: "todo dia 31" continua 31 em fevereiro.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-3">
            <div className="space-y-1.5">
              <Label htmlFor="desc-custo">Descrição</Label>
              <Input
                id="desc-custo"
                value={formCusto.descricao}
                onChange={(e) => setFormCusto({ ...formCusto, descricao: e.target.value })}
                placeholder="Ex.: aluguel da sala"
              />
            </div>
            <div className="grid gap-3 sm:grid-cols-2">
              <div className="space-y-1.5">
                <Label htmlFor="valor-custo">Valor (R$)</Label>
                <Input
                  id="valor-custo"
                  inputMode="decimal"
                  value={formCusto.valor}
                  onChange={(e) => setFormCusto({ ...formCusto, valor: e.target.value })}
                  placeholder="0,00"
                />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="dia-custo">Dia do vencimento</Label>
                <Input
                  id="dia-custo"
                  inputMode="numeric"
                  value={formCusto.dia}
                  onChange={(e) => setFormCusto({ ...formCusto, dia: e.target.value })}
                />
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setCustoAberto(false)}
              disabled={criarCusto.isPending}
            >
              Cancelar
            </Button>
            <Button onClick={cadastrarCusto} disabled={criarCusto.isPending}>
              Cadastrar
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Novo / editar serviço */}
      <Dialog open={aberto} onOpenChange={setAberto}>
        <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-md">
          <DialogHeader>
            <DialogTitle>{form.id ? "Editar serviço" : "Novo serviço"}</DialogTitle>
            <DialogDescription>
              Escolha os insumos padrão: eles já vêm preenchidos ao finalizar um atendimento.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-3">
            <div className="space-y-1.5">
              <Label htmlFor="nome-servico">Nome do serviço</Label>
              <Input
                id="nome-servico"
                value={form.nome}
                onChange={(e) => setForm({ ...form, nome: e.target.value })}
                placeholder="Ex.: extensão de cílios"
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="preco-servico">Preço (R$)</Label>
              <Input
                id="preco-servico"
                inputMode="decimal"
                value={form.preco}
                onChange={(e) => setForm({ ...form, preco: e.target.value })}
                placeholder="0,00"
              />
            </div>
            <div className="space-y-2">
              <Label>Insumos padrão</Label>
              <div className="max-h-52 space-y-1.5 overflow-y-auto rounded-xl border border-border p-2">
                {itens.map((p) => {
                  const item = form.produtos.find((x) => x.item_estoque_id === p.id);
                  return (
                    <div key={p.id} className="flex items-center gap-2 rounded-lg px-2 py-1.5">
                      <Checkbox
                        checked={item !== undefined}
                        onCheckedChange={() => alternarInsumo(p.id)}
                        aria-label={p.nome}
                      />
                      <span className="min-w-0 flex-1 truncate text-sm">{p.nome}</span>
                      {item ? (
                        <Input
                          className="h-9 w-16"
                          inputMode="numeric"
                          value={String(item.quantidade)}
                          onChange={(e) =>
                            setForm({
                              ...form,
                              produtos: form.produtos.map((x) =>
                                x.item_estoque_id === p.id
                                  ? { ...x, quantidade: Number(e.target.value) || 1 }
                                  : x,
                              ),
                            })
                          }
                        />
                      ) : (
                        <span className="text-xs text-muted-foreground">{p.unidade}</span>
                      )}
                    </div>
                  );
                })}
              </div>
              <p className="text-xs text-muted-foreground">
                Custo estimado pelo custo médio de hoje:{" "}
                <Money value={custoInsumos(form.produtos)} />
              </p>
            </div>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setAberto(false)}
              disabled={criarServico.isPending || editarServico.isPending}
            >
              Cancelar
            </Button>
            <Button
              onClick={salvarServicoForm}
              disabled={criarServico.isPending || editarServico.isPending}
            >
              <Scissors className="size-4" />
              Salvar serviço
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <AlertDialog
        open={custoParaExcluir !== null}
        onOpenChange={(o) => !o && setCustoParaExcluir(null)}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle className="flex items-center gap-2">
              <TriangleAlert className="size-5 text-negative" />
              Excluir custo fixo
            </AlertDialogTitle>
            <AlertDialogDescription>
              {custoParaExcluir?.descricao} deixa de entrar no cálculo dos próximos meses. Os meses
              já fechados não mudam.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={excluirCusto.isPending}>Voltar</AlertDialogCancel>
            <AlertDialogAction
              disabled={excluirCusto.isPending}
              onClick={(e) => {
                e.preventDefault();
                confirmarExclusaoCusto();
              }}
            >
              Excluir
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <AlertDialog
        open={servicoParaExcluir !== null}
        onOpenChange={(o) => !o && setServicoParaExcluir(null)}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle className="flex items-center gap-2">
              <TriangleAlert className="size-5 text-negative" />
              Excluir serviço
            </AlertDialogTitle>
            <AlertDialogDescription>
              {servicoParaExcluir?.nome} sai da tabela de preços. Os atendimentos já registrados
              continuam com o preço congelado.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={excluirServico.isPending}>Voltar</AlertDialogCancel>
            <AlertDialogAction
              disabled={excluirServico.isPending}
              onClick={(e) => {
                e.preventDefault();
                confirmarExclusaoServico();
              }}
            >
              Excluir
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </AppShell>
  );
}
