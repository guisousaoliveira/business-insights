import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import {
  ArrowDownRight,
  ArrowUpRight,
  CalendarPlus,
  Crown,
  Lightbulb,
  Package,
  Receipt,
  Target,
  TrendingUp,
  TriangleAlert,
  Users,
  Wallet,
} from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Legend,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { AppShell } from "@/components/AppShell";
import {
  Card,
  CardsSkeleton,
  EmptyState,
  Money,
  Pill,
  SectionTitle,
  StatCard,
} from "@/components/ui-kit";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { formatBRL, formatDate, formatPercent, MESES, nomeMes } from "@/lib/format";
import { textoDoErro, useEstoque, useGastos, useResumo, useSessao } from "@/lib/queries";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Resumo financeiro — Thamires Beauty" },
      {
        name: "description",
        content:
          "Veja em segundos quanto você faturou, gastou e lucrou no mês, além de pendências e produtos para repor.",
      },
      { property: "og:title", content: "Resumo financeiro — Thamires Beauty" },
      {
        property: "og:description",
        content: "Faturamento, gastos, lucro, ticket médio e alertas do seu salão em uma tela.",
      },
    ],
  }),
  component: ResumoPage,
});

const hoje = new Date();
const anoAtual = hoje.getFullYear();
const mesAtual = hoje.getMonth() + 1;

/** Rótulo curto do eixo do gráfico: "Set/26". */
function rotuloDoPonto(ano: number, mes: number): string {
  return `${nomeMes(mes).slice(0, 3)}/${String(ano).slice(2)}`;
}

function ResumoPage() {
  const navigate = useNavigate();
  const [mes, setMes] = useState(mesAtual);
  const [ano, setAno] = useState(anoAtual);

  // Recharts mede o container no cliente: no SSR o gráfico sairia com 0px.
  const [montado, setMontado] = useState(false);
  useEffect(() => setMontado(true), []);

  const { data: sessao } = useSessao();
  const { data: resumo, isPending, isError, error } = useResumo(ano, mes);
  const { data: gastos } = useGastos(ano, mes);
  const { data: estoque } = useEstoque();

  const primeiroNome = sessao?.usuario?.nome.split(" ")[0] ?? "";

  const serie = useMemo(
    () =>
      (resumo?.historico_seis_meses ?? []).map((p) => ({
        mes: rotuloDoPonto(p.ano, p.mes),
        receitas: p.receitas,
        despesas: p.despesas,
      })),
    [resumo],
  );

  // Só os pendentes, do mais próximo de vencer para o mais distante.
  const proximos = useMemo(
    () =>
      (gastos?.gastos ?? [])
        .filter((g) => !g.pago)
        .sort((a, b) => a.vence_em_dias - b.vence_em_dias)
        .slice(0, 4),
    [gastos],
  );

  // Quem classifica o item é o servidor (`status`), não a tela.
  const baixos = useMemo(() => (estoque?.itens ?? []).filter((i) => i.status !== "ok"), [estoque]);

  const servicos = resumo?.receita.servicos_mais_realizados ?? [];
  const melhor = servicos[0];
  const variacao = resumo?.insights.variacao_percentual_mes_anterior ?? 0;
  const temAnterior = (resumo?.insights.saldo_mes_anterior ?? 0) !== 0;
  const mesAnterior = mes === 1 ? 12 : mes - 1;

  const metaProgresso =
    resumo && resumo.meta_faturamento_mensal > 0
      ? Math.min(100, (resumo.entrou / resumo.meta_faturamento_mensal) * 100)
      : 0;

  const insights: string[] = [];
  if (resumo) {
    if (resumo.alerta_zero_a_zero) {
      insights.push(
        "Você faturou bem, mas os gastos comeram quase tudo: o mês está no zero a zero.",
      );
    }
    if (temAnterior) {
      insights.push(
        variacao >= 0
          ? `Seu lucro aumentou ${formatPercent(Math.abs(variacao))} em relação a ${nomeMes(mesAnterior)}.`
          : `Seu lucro caiu ${formatPercent(Math.abs(variacao))} em relação a ${nomeMes(mesAnterior)}.`,
      );
    }
    if (resumo.insights.servico_mais_lucrativo) {
      insights.push(
        `${resumo.insights.servico_mais_lucrativo.nome} foi o serviço mais lucrativo do mês.`,
      );
    }
    if (resumo.receita.quantidade_kits_vendidos > 0) {
      insights.push(
        `Você vendeu ${resumo.receita.quantidade_kits_vendidos} kits, somando ${formatBRL(resumo.receita.total_kits)}.`,
      );
    }
    if (baixos.length) insights.push(`${baixos.length} produtos precisam de reposição.`);
    if (metaProgresso < 80 && resumo.meta_faturamento_mensal > 0) {
      insights.push(
        `Você alcançou ${formatPercent(metaProgresso)} da meta de faturamento de ${formatBRL(resumo.meta_faturamento_mensal)}.`,
      );
    }
  }

  return (
    <AppShell
      titulo={primeiroNome ? `Olá, ${primeiroNome}` : "Resumo"}
      subtitulo={`Resumo de ${nomeMes(mes)} de ${ano}`}
      acaoLabel="Agendar atendimento"
      onAcao={() => void navigate({ to: "/atendimentos" })}
    >
      <div className="mb-4 flex flex-wrap items-center gap-2">
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

      {isPending ? (
        <CardsSkeleton qtd={6} />
      ) : isError || !resumo ? (
        <EmptyState
          icon={<TriangleAlert className="size-5" />}
          titulo="Não deu para carregar o resumo"
          descricao={textoDoErro(error)}
        />
      ) : (
        <div className="space-y-4">
          {/* Lucro em destaque */}
          <StatCard
            label={resumo.saldo_final >= 0 ? "Lucro do mês" : "Prejuízo do mês"}
            value={formatBRL(resumo.saldo_final)}
            destaque
            tone={resumo.saldo_final >= 0 ? "positive" : "negative"}
            icon={
              resumo.saldo_final >= 0 ? (
                <TrendingUp className="size-5" />
              ) : (
                <ArrowDownRight className="size-5" />
              )
            }
            hint={
              temAnterior
                ? `${variacao >= 0 ? "+" : "-"}${formatPercent(Math.abs(variacao))} em relação a ${nomeMes(mesAnterior)}`
                : "Sem comparação com o mês anterior"
            }
          />

          <div className="grid grid-cols-2 gap-3 lg:grid-cols-5">
            <StatCard
              label="Faturamento"
              value={formatBRL(resumo.entrou)}
              icon={<Wallet className="size-4" />}
            />
            <StatCard
              label="Gastos"
              value={formatBRL(resumo.saiu)}
              icon={<Receipt className="size-4" />}
            />
            <StatCard
              label="Margem de lucro"
              value={formatPercent(resumo.insights.margem_lucro_percentual, 1)}
              icon={<Target className="size-4" />}
            />
            <StatCard
              label="Ticket médio"
              value={formatBRL(resumo.insights.ticket_medio)}
              icon={<ArrowUpRight className="size-4" />}
            />
            <StatCard
              label="Atendimentos"
              value={String(resumo.receita.quantidade_atendimentos)}
              icon={<Users className="size-4" />}
              hint="finalizados no mês"
            />
          </div>

          {/* Atalhos */}
          <div className="grid gap-3 sm:grid-cols-2">
            <Button
              variant="outline"
              className="h-14 justify-start gap-3 rounded-2xl bg-surface"
              onClick={() => void navigate({ to: "/atendimentos" })}
            >
              <span className="grid size-9 place-items-center rounded-xl bg-accent text-accent-foreground">
                <CalendarPlus className="size-4" />
              </span>
              Agendar atendimento
            </Button>
            <Button
              variant="outline"
              className="h-14 justify-start gap-3 rounded-2xl bg-surface"
              onClick={() => void navigate({ to: "/gastos" })}
            >
              <span className="grid size-9 place-items-center rounded-xl bg-accent text-accent-foreground">
                <Receipt className="size-4" />
              </span>
              Novo gasto
            </Button>
          </div>

          {/* Gráfico */}
          <Card className="p-4">
            <SectionTitle hint="Últimos 6 meses">Receitas e despesas</SectionTitle>
            <div className="h-64 w-full">
              {montado ? (
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={serie} margin={{ top: 8, right: 4, bottom: 0, left: -18 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" vertical={false} />
                    <XAxis dataKey="mes" tickLine={false} axisLine={false} fontSize={12} />
                    <YAxis tickLine={false} axisLine={false} fontSize={11} width={56} />
                    <Tooltip
                      formatter={(v: number) => formatBRL(v)}
                      contentStyle={{
                        borderRadius: 12,
                        border: "1px solid var(--border)",
                        fontSize: 12,
                      }}
                    />
                    <Legend iconType="circle" wrapperStyle={{ fontSize: 12 }} />
                    <Bar
                      dataKey="receitas"
                      name="Receitas"
                      fill="var(--primary)"
                      radius={[6, 6, 0, 0]}
                    />
                    <Bar
                      dataKey="despesas"
                      name="Despesas"
                      fill="var(--primary-light)"
                      radius={[6, 6, 0, 0]}
                    />
                  </BarChart>
                </ResponsiveContainer>
              ) : null}
            </div>
          </Card>

          <div className="grid gap-4 lg:grid-cols-2">
            {/* Serviço mais lucrativo + insights */}
            <div className="space-y-4">
              <Card className="p-4">
                <SectionTitle>Serviço mais lucrativo</SectionTitle>
                {melhor ? (
                  <div className="space-y-3">
                    <div className="flex items-center gap-3 rounded-xl bg-accent/60 p-3">
                      <span className="grid size-10 shrink-0 place-items-center rounded-xl bg-brand-gradient text-primary-foreground">
                        <Crown className="size-5" />
                      </span>
                      <div className="min-w-0">
                        <p className="truncate font-semibold">{melhor.nome}</p>
                        <p className="text-xs text-muted-foreground">
                          {melhor.quantidade} atendimentos • lucro de <Money value={melhor.lucro} />
                        </p>
                      </div>
                    </div>
                    {servicos.slice(1, 4).map((s) => (
                      <div
                        key={s.nome}
                        className="flex items-center justify-between gap-3 border-t border-border pt-2 text-sm"
                      >
                        <span className="min-w-0 truncate text-muted-foreground">{s.nome}</span>
                        <Money value={s.lucro} colorir />
                      </div>
                    ))}
                  </div>
                ) : (
                  <EmptyState
                    titulo="Nenhum atendimento finalizado"
                    descricao="Finalize um atendimento para ver qual serviço dá mais lucro."
                  />
                )}
              </Card>

              <Card className="p-4">
                <SectionTitle hint="Gerado a partir dos seus números">Para você saber</SectionTitle>
                {insights.length ? (
                  <ul className="space-y-2">
                    {insights.map((texto) => (
                      <li key={texto} className="flex items-start gap-2.5 text-sm">
                        <Lightbulb className="mt-0.5 size-4 shrink-0 text-primary-accent" />
                        <span className="text-muted-foreground">{texto}</span>
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="text-sm text-muted-foreground">
                    Ainda não há movimento suficiente neste mês para gerar observações.
                  </p>
                )}
              </Card>
            </div>

            {/* Próximos gastos + estoque */}
            <div className="space-y-4">
              <Card className="p-4">
                <SectionTitle
                  action={
                    <Link to="/gastos" className="text-xs font-semibold text-primary-accent">
                      Ver todos
                    </Link>
                  }
                >
                  Próximos gastos a vencer
                </SectionTitle>
                {proximos.length ? (
                  <ul className="divide-y divide-border">
                    {proximos.map((g) => (
                      <li key={g.id} className="flex items-center justify-between gap-3 py-2.5">
                        <div className="min-w-0">
                          <p className="truncate text-sm font-medium">{g.nome}</p>
                          <p className="text-xs text-muted-foreground">
                            Vence em {formatDate(g.prazo_pagamento)}
                          </p>
                        </div>
                        <div className="shrink-0 text-right">
                          <Money value={g.valor} className="text-sm" />
                          <div className="mt-1">
                            <Pill tone={g.vence_em_dias < 0 ? "negative" : "warning"}>
                              {g.vence_em_dias < 0 ? "Vencido" : "Pendente"}
                            </Pill>
                          </div>
                        </div>
                      </li>
                    ))}
                  </ul>
                ) : (
                  <EmptyState
                    titulo="Nada pendente"
                    descricao="Todos os gastos do período estão pagos. Ótimo trabalho!"
                  />
                )}
              </Card>

              <Card tone={baixos.length ? "warning" : "default"} className="p-4">
                <SectionTitle
                  action={
                    <Link to="/estoque" className="text-xs font-semibold text-primary-accent">
                      Ver estoque
                    </Link>
                  }
                >
                  Estoque para repor
                </SectionTitle>
                {baixos.length ? (
                  <ul className="space-y-2">
                    {baixos.slice(0, 5).map((p) => (
                      <li key={p.id} className="flex items-center justify-between gap-3 text-sm">
                        <span className="flex min-w-0 items-center gap-2">
                          <Package className="size-4 shrink-0 text-warning" />
                          <span className="truncate">{p.nome}</span>
                        </span>
                        <Pill tone={p.status === "alerta" ? "warning" : "negative"}>
                          {p.quantidade_atual} {p.unidade}
                        </Pill>
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="text-sm text-muted-foreground">
                    Todos os produtos estão com estoque saudável.
                  </p>
                )}
              </Card>
            </div>
          </div>
        </div>
      )}
    </AppShell>
  );
}
