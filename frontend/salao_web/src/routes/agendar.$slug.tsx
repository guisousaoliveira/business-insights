import { createFileRoute } from "@tanstack/react-router";
import { CalendarCheck, CheckCircle2, Clock, Scissors, Sparkles, TriangleAlert } from "lucide-react";
import { useMemo, useState } from "react";
import { Card, EmptyState, ListSkeleton, Money, Pill, SectionTitle } from "@/components/ui-kit";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { formatDate, formatTelefone } from "@/lib/format";
import {
  textoDoErro,
  useAgendamentoPublico,
  useAgendarPublico,
  useHorariosDisponiveisPublico,
} from "@/lib/queries";

export const Route = createFileRoute("/agendar/$slug")({
  head: () => ({
    meta: [
      { title: "Agendar horário" },
      { name: "description", content: "Marque seu horário direto com o salão, sem precisar ligar." },
    ],
  }),
  component: AgendarPublicoPage,
});

/** "AAAA-MM-DD" de hoje, no fuso do navegador — só para o mínimo do input. */
function hojeISO(): string {
  const hoje = new Date();
  const mes = String(hoje.getMonth() + 1).padStart(2, "0");
  const dia = String(hoje.getDate()).padStart(2, "0");
  return `${hoje.getFullYear()}-${mes}-${dia}`;
}

function AgendarPublicoPage() {
  const { slug } = Route.useParams();
  const { data: pagina, isPending, isError } = useAgendamentoPublico(slug);

  const [servicoIds, setServicoIds] = useState<string[]>([]);
  const [data, setData] = useState(hojeISO());
  const [horario, setHorario] = useState<string | null>(null);
  const [clienteNome, setClienteNome] = useState("");
  const [clienteTelefone, setClienteTelefone] = useState("");

  const { data: disponibilidade, isFetching: buscandoHorarios } = useHorariosDisponiveisPublico(
    slug,
    data,
    servicoIds,
  );
  const agendar = useAgendarPublico(slug);

  const servicos = pagina?.servicos ?? [];
  const servicosEscolhidos = useMemo(
    () => servicos.filter((s) => servicoIds.includes(s.id)),
    [servicos, servicoIds],
  );
  const precoTotal = servicosEscolhidos.reduce((t, s) => t + s.preco, 0);

  const alternarServico = (id: string) => {
    setHorario(null);
    setServicoIds((atual) => (atual.includes(id) ? atual.filter((x) => x !== id) : [...atual, id]));
  };

  const confirmar = () => {
    if (!horario || !clienteNome.trim() || !clienteTelefone.trim()) return;
    agendar.mutate({
      cliente_nome: clienteNome.trim(),
      cliente_telefone: clienteTelefone.trim(),
      data: `${data}T${horario}:00-03:00`,
      servicos: servicoIds.map((servico_id) => ({ servico_id })),
    });
  };

  if (isPending) {
    return (
      <div className="mx-auto min-h-screen max-w-lg px-5 py-10">
        <ListSkeleton linhas={4} />
      </div>
    );
  }

  if (isError || !pagina) {
    return (
      <div className="mx-auto flex min-h-screen max-w-lg items-center px-5 py-10">
        <EmptyState
          icon={<TriangleAlert className="size-5" />}
          titulo="Link inválido"
          descricao="Esse link de agendamento não existe ou não está mais ativo. Confira com o salão."
        />
      </div>
    );
  }

  if (agendar.isSuccess) {
    const resultado = agendar.data;
    return (
      <div className="mx-auto flex min-h-screen max-w-lg items-center px-5 py-10">
        <Card className="w-full p-6 text-center">
          <div className="mx-auto grid size-14 place-items-center rounded-full bg-positive-soft text-positive">
            <CheckCircle2 className="size-7" />
          </div>
          <h1 className="mt-4 font-display text-xl font-semibold">Horário confirmado!</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            {formatDate(resultado.data)} às {horario} — {pagina.salao.nome}
          </p>
          <ul className="mt-4 space-y-1.5 text-left text-sm">
            {resultado.servicos.map((s) => (
              <li key={s.servico_id} className="flex items-center justify-between gap-3">
                <span className="min-w-0 truncate">{s.nome}</span>
                <Money value={s.preco} />
              </li>
            ))}
          </ul>
          <p className="mt-4 text-xs text-muted-foreground">
            Guarde a data — o salão já foi avisado do seu agendamento.
          </p>
        </Card>
      </div>
    );
  }

  return (
    <div className="mx-auto min-h-screen max-w-lg px-5 py-8 pb-24">
      <div className="mb-6 flex items-center gap-3">
        <span className="grid size-11 shrink-0 place-items-center rounded-2xl bg-brand-gradient text-primary-foreground shadow-glow">
          <Sparkles className="size-5" />
        </span>
        <div className="min-w-0">
          <h1 className="truncate font-display text-lg font-semibold">{pagina.salao.nome}</h1>
          <p className="text-xs text-muted-foreground">Agendar horário online</p>
        </div>
      </div>

      <SectionTitle hint="Selecione um ou mais">Serviços</SectionTitle>
      {servicos.length ? (
        <ul className="space-y-2">
          {servicos.map((s) => (
            <li key={s.id}>
              <label className="flex cursor-pointer items-center justify-between gap-3 rounded-xl border border-border bg-surface p-3">
                <span className="flex min-w-0 items-center gap-2.5">
                  <Checkbox
                    checked={servicoIds.includes(s.id)}
                    onCheckedChange={() => alternarServico(s.id)}
                  />
                  <span className="min-w-0">
                    <span className="block truncate text-sm font-medium">{s.nome}</span>
                    <span className="text-xs text-muted-foreground">{s.duracao_minutos} min</span>
                  </span>
                </span>
                <Money value={s.preco} className="shrink-0" />
              </label>
            </li>
          ))}
        </ul>
      ) : (
        <EmptyState
          icon={<Scissors className="size-5" />}
          titulo="Nenhum serviço disponível"
          descricao="O salão ainda não cadastrou serviços para agendamento online."
        />
      )}

      {servicoIds.length > 0 ? (
        <div className="mt-6">
          <SectionTitle hint="Só aparecem horários realmente livres">Data e horário</SectionTitle>
          <div className="space-y-1.5">
            <Label htmlFor="data-agendamento">Data</Label>
            <Input
              id="data-agendamento"
              type="date"
              min={hojeISO()}
              value={data}
              onChange={(e) => {
                setData(e.target.value);
                setHorario(null);
              }}
              className="h-11 rounded-xl"
            />
          </div>

          <div className="mt-3">
            {buscandoHorarios ? (
              <ListSkeleton linhas={1} />
            ) : disponibilidade?.horarios.length ? (
              <div className="flex flex-wrap gap-2">
                {disponibilidade.horarios.map((h) => (
                  <button
                    key={h}
                    type="button"
                    onClick={() => setHorario(h)}
                    className="focus-visible:outline-none"
                  >
                    <Pill tone={horario === h ? "brand" : "neutral"} className="cursor-pointer px-3 py-2 text-sm">
                      <Clock className="size-3.5" />
                      {h}
                    </Pill>
                  </button>
                ))}
              </div>
            ) : (
              <p className="rounded-xl border border-dashed border-border px-3 py-3 text-center text-sm text-muted-foreground">
                Nenhum horário livre nesse dia. Tente outra data.
              </p>
            )}
          </div>
        </div>
      ) : null}

      {horario ? (
        <div className="mt-6">
          <SectionTitle>Seus dados</SectionTitle>
          <div className="space-y-3">
            <div className="space-y-1.5">
              <Label htmlFor="nome-cliente">Nome</Label>
              <Input
                id="nome-cliente"
                value={clienteNome}
                onChange={(e) => setClienteNome(e.target.value)}
                className="h-11 rounded-xl"
                maxLength={80}
                required
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="telefone-cliente">WhatsApp</Label>
              <Input
                id="telefone-cliente"
                value={clienteTelefone}
                onChange={(e) => setClienteTelefone(formatTelefone(e.target.value))}
                placeholder="(00) 00000-0000"
                className="h-11 rounded-xl"
                inputMode="numeric"
                maxLength={15}
                required
              />
            </div>
          </div>

          <Card tone="brand" className="mt-4 p-4">
            <div className="flex items-center justify-between gap-3 text-sm">
              <span>
                {formatDate(data)} às {horario}
              </span>
              <Money value={precoTotal} className="text-primary-foreground" />
            </div>
          </Card>

          {agendar.isError ? (
            <p role="alert" className="mt-3 rounded-xl border border-negative-mid/60 bg-negative-soft px-3 py-2.5 text-sm text-negative">
              {textoDoErro(agendar.error)}
            </p>
          ) : null}

          <Button
            className="mt-4 h-12 w-full rounded-xl text-base"
            onClick={confirmar}
            disabled={agendar.isPending || !clienteNome.trim() || !clienteTelefone.trim()}
          >
            <CalendarCheck className="size-4" />
            Confirmar agendamento
          </Button>
        </div>
      ) : null}
    </div>
  );
}
