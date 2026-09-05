import { createFileRoute, Link } from "@tanstack/react-router";
import {
  BellOff,
  CalendarClock,
  CheckCheck,
  Package,
  Receipt,
  TrendingDown,
  TriangleAlert,
} from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";
import { AppShell, rotaDoAlerta } from "@/components/AppShell";
import {
  Card,
  EmptyState,
  ListSkeleton,
  Pill,
  SectionTitle,
  type BadgeTone,
} from "@/components/ui-kit";
import { Button } from "@/components/ui/button";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { formatDate } from "@/lib/format";
import {
  textoDoErro,
  useAlertas,
  useMarcarAlertaLido,
  useMarcarTodosAlertasLidos,
} from "@/lib/queries";
import type { TipoAlerta } from "@/lib/types";

export const Route = createFileRoute("/alertas")({
  head: () => ({
    meta: [
      { title: "Central de alertas — GlowApp" },
      {
        name: "description",
        content:
          "Estoque baixo, contas a vencer e metas em risco reunidos em um só lugar, com marcação de leitura.",
      },
      { property: "og:title", content: "Central de alertas — GlowApp" },
      {
        property: "og:description",
        content: "Acompanhe avisos de estoque, vencimentos e metas do seu salão.",
      },
    ],
  }),
  component: AlertasPage,
});

/**
 * Os nove tipos do §9 do contrato. Quem classifica é o servidor — a tela só
 * escolhe ícone e cor, e verde/vermelho seguem a leitura financeira do
 * protótipo.
 */
const config: Record<TipoAlerta, { rotulo: string; tone: BadgeTone; icone: typeof Package }> = {
  estoque_negativo: { rotulo: "Estoque negativo", tone: "negative", icone: TriangleAlert },
  estoque_critico: { rotulo: "Estoque zerado", tone: "negative", icone: Package },
  estoque_baixo: { rotulo: "Estoque baixo", tone: "warning", icone: Package },
  gasto_vencido: { rotulo: "Conta vencida", tone: "negative", icone: Receipt },
  gasto_a_vencer: { rotulo: "Conta a vencer", tone: "warning", icone: Receipt },
  custo_fixo_vencido: { rotulo: "Custo fixo vencido", tone: "negative", icone: CalendarClock },
  custo_fixo_a_vencer: { rotulo: "Custo fixo a vencer", tone: "warning", icone: CalendarClock },
  saldo_negativo: { rotulo: "Mês no vermelho", tone: "negative", icone: TrendingDown },
  zero_a_zero: { rotulo: "Zero a zero", tone: "brand", icone: TrendingDown },
};

function AlertasPage() {
  const [filtro, setFiltro] = useState<"todos" | "nao-lidos">("todos");

  const { data, isPending, isError, error } = useAlertas();
  const marcarLido = useMarcarAlertaLido();
  const marcarTodos = useMarcarTodosAlertasLidos();

  const todos = data?.alertas ?? [];
  const lista = filtro === "todos" ? todos : todos.filter((a) => a.lido_em === null);
  const naoLidos = data?.total_nao_lidos ?? 0;

  return (
    <AppShell titulo="Alertas" subtitulo={`${naoLidos} avisos não lidos`}>
      <div className="flex flex-wrap items-center justify-between gap-2">
        <Tabs value={filtro} onValueChange={(v) => setFiltro(v as typeof filtro)}>
          <TabsList className="h-11 rounded-xl">
            <TabsTrigger value="todos">Todos</TabsTrigger>
            <TabsTrigger value="nao-lidos">Não lidos</TabsTrigger>
          </TabsList>
        </Tabs>
        <Button
          variant="outline"
          disabled={marcarTodos.isPending || naoLidos === 0}
          onClick={() =>
            marcarTodos.mutate(undefined, {
              onSuccess: () => toast.success("Todos os alertas foram marcados como lidos."),
              onError: (erro) => toast.error(textoDoErro(erro)),
            })
          }
        >
          <CheckCheck className="size-4" />
          Marcar todos como lidos
        </Button>
      </div>

      <div className="mt-4">
        <SectionTitle hint="Gerados a partir do estoque, gastos e metas">Avisos</SectionTitle>
        {isPending ? (
          <ListSkeleton />
        ) : isError ? (
          <EmptyState
            icon={<TriangleAlert className="size-5" />}
            titulo="Não deu para carregar os alertas"
            descricao={textoDoErro(error)}
          />
        ) : lista.length ? (
          <ul className="space-y-3">
            {lista.map((a) => {
              const c = config[a.tipo];
              const Icone = c.icone;
              const lido = a.lido_em !== null;
              return (
                <li key={a.id}>
                  <Card className={lido ? "p-4 opacity-70" : "p-4"}>
                    <div className="flex items-start gap-3">
                      <span className="grid size-10 shrink-0 place-items-center rounded-xl bg-accent text-accent-foreground">
                        <Icone className="size-5" />
                      </span>
                      <div className="min-w-0 flex-1">
                        <div className="flex flex-wrap items-center gap-1.5">
                          <Pill tone={c.tone}>{c.rotulo}</Pill>
                          {!lido ? <Pill tone="brand">Novo</Pill> : null}
                        </div>
                        <p className="mt-1.5 font-semibold">{a.titulo}</p>
                        <p className="mt-0.5 text-sm text-muted-foreground">{a.mensagem}</p>
                        <p className="mt-1 text-xs text-muted-foreground">
                          {formatDate(a.criado_em)}
                        </p>
                        <div className="mt-3 flex flex-wrap gap-2">
                          <Button size="sm" variant="outline" asChild>
                            <Link to={rotaDoAlerta(a)}>Ver detalhes</Link>
                          </Button>
                          {!lido ? (
                            <Button
                              size="sm"
                              variant="ghost"
                              disabled={marcarLido.isPending}
                              onClick={() =>
                                marcarLido.mutate(a.id, {
                                  onError: (erro) => toast.error(textoDoErro(erro)),
                                })
                              }
                            >
                              Marcar como lido
                            </Button>
                          ) : null}
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
            icon={<BellOff className="size-5" />}
            titulo="Nenhum alerta por aqui"
            descricao="Quando algum produto ficar baixo ou uma conta vencer, o aviso aparece nesta tela."
          />
        )}
      </div>
    </AppShell>
  );
}
