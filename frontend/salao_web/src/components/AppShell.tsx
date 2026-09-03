import { Link, useNavigate } from "@tanstack/react-router";
import {
  Bell,
  CalendarHeart,
  LayoutDashboard,
  LogOut,
  Package,
  Plus,
  Receipt,
  Sparkles,
  TriangleAlert,
  UserRound,
} from "lucide-react";
import { useEffect, type ReactNode } from "react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { useAlertas, useLogout, useSessao } from "@/lib/queries";
import type { Alerta } from "@/lib/types";

const NAV = [
  { to: "/", label: "Resumo", icon: LayoutDashboard },
  { to: "/atendimentos", label: "Atendimentos", icon: CalendarHeart },
  { to: "/gastos", label: "Gastos", icon: Receipt },
  { to: "/estoque", label: "Estoque", icon: Package },
  { to: "/perfil", label: "Perfil", icon: UserRound },
] as const;

/** Para onde o alerta leva. O servidor manda a referência; a rota é do app. */
export type RotaAlerta = "/estoque" | "/gastos" | "/perfil" | "/alertas";

export function rotaDoAlerta(alerta: Alerta): RotaAlerta {
  switch (alerta.referencia_tipo) {
    case "estoque_item":
      return "/estoque";
    case "gasto":
      return "/gastos";
    case "custo_fixo":
      return "/perfil";
    default:
      return "/alertas";
  }
}

function Logo({ compacto = false }: { compacto?: boolean }) {
  return (
    <div className="flex min-w-0 items-center gap-2">
      <span className="grid size-9 shrink-0 place-items-center rounded-xl bg-brand-gradient text-primary-foreground shadow-glow">
        <Sparkles className="size-4" />
      </span>
      {!compacto ? (
        <span className="min-w-0">
          <span className="block truncate font-display text-[15px] leading-tight font-semibold">
            Thamires
          </span>
          <span className="block truncate text-[10px] font-semibold tracking-[0.18em] text-primary-dark uppercase">
            Beauty
          </span>
        </span>
      ) : null}
    </div>
  );
}

/**
 * Guard de rota (decisão A2).
 *
 * Roda no cliente porque a sessão vive no `localStorage`, que não existe no SSR
 * — enquanto `useSessao` não respondeu, a tela fica em branco em vez de piscar
 * o login para quem já está autenticado.
 */
function useGuard(): boolean {
  const { data: sessao, isPending } = useSessao();
  const navigate = useNavigate();

  useEffect(() => {
    if (!isPending && sessao === null) void navigate({ to: "/login", replace: true });
  }, [isPending, sessao, navigate]);

  return !isPending && sessao !== null;
}

export function AppShell({
  titulo,
  subtitulo,
  acaoLabel,
  onAcao,
  children,
}: {
  titulo: string;
  subtitulo?: string;
  acaoLabel?: string;
  onAcao?: () => void;
  children: ReactNode;
}) {
  const autenticada = useGuard();
  const navigate = useNavigate();
  const sair = useLogout();

  const { data: alertas } = useAlertas();
  const naoLidos = alertas?.total_nao_lidos ?? 0;
  // Um único crítico no topo: a lista inteira mora na central de alertas.
  const critico = alertas?.alertas.find((a) => a.lido_em === null && a.severidade === "critico");

  if (!autenticada) return <div className="min-h-screen bg-background" />;

  return (
    <div className="min-h-screen bg-background lg:flex">
      {/* Menu lateral — desktop */}
      <aside className="sticky top-0 hidden h-screen w-[172px] shrink-0 flex-col border-r border-border bg-sidebar px-3 py-5 lg:flex">
        <Logo />
        <nav className="mt-7 flex flex-1 flex-col gap-1">
          {NAV.map((item) => (
            <Link
              key={item.to}
              to={item.to}
              activeOptions={{ exact: item.to === "/" }}
              className="flex items-center gap-2.5 rounded-xl px-3 py-2.5 text-sm font-medium text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground data-[status=active]:bg-accent data-[status=active]:text-accent-foreground data-[status=active]:font-semibold"
            >
              <item.icon className="size-4 shrink-0" />
              <span className="truncate">{item.label}</span>
            </Link>
          ))}
        </nav>
        <Button
          variant="ghost"
          className="justify-start gap-2 px-3 text-muted-foreground"
          disabled={sair.isPending}
          onClick={() =>
            sair.mutate(undefined, {
              // A sessão local é limpa mesmo se o servidor recusar: quem clicou
              // em "sair" tem que sair.
              onSettled: () => void navigate({ to: "/login", replace: true }),
            })
          }
        >
          <LogOut className="size-4" />
          Sair
        </Button>
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        {/* Cabeçalho */}
        <header className="sticky top-0 z-30 border-b border-border bg-surface/90 backdrop-blur">
          <div className="mx-auto grid max-w-6xl grid-cols-[minmax(0,1fr)_auto] items-center gap-3 px-4 py-3 sm:px-6">
            <div className="flex min-w-0 items-center gap-3">
              <span className="lg:hidden">
                <Logo compacto />
              </span>
              <div className="min-w-0">
                <h1 className="truncate font-display text-lg leading-tight font-semibold sm:text-xl">
                  {titulo}
                </h1>
                {subtitulo ? (
                  <p className="truncate text-xs text-muted-foreground">{subtitulo}</p>
                ) : null}
              </div>
            </div>
            <div className="flex shrink-0 items-center gap-2">
              {acaoLabel && onAcao ? (
                <Button onClick={onAcao} className="hidden lg:inline-flex">
                  <Plus className="size-4" />
                  {acaoLabel}
                </Button>
              ) : null}
              <Link
                to="/alertas"
                aria-label="Alertas"
                className="relative grid size-11 place-items-center rounded-xl text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
              >
                <Bell className="size-5" />
                {naoLidos > 0 ? (
                  <span className="absolute top-1.5 right-1.5 grid min-w-4 place-items-center rounded-full bg-primary-accent px-1 text-[10px] font-bold text-primary-foreground">
                    {naoLidos}
                  </span>
                ) : null}
              </Link>
            </div>
          </div>
        </header>

        <main className="mx-auto w-full max-w-6xl flex-1 px-4 pt-4 pb-28 sm:px-6 lg:pb-10">
          {critico ? (
            <Link
              to={rotaDoAlerta(critico)}
              className="mb-4 flex items-start gap-3 rounded-2xl border border-negative-mid/60 bg-negative-soft px-4 py-3 text-left transition-shadow hover:shadow-soft"
            >
              <TriangleAlert className="mt-0.5 size-4 shrink-0 text-negative" />
              <span className="min-w-0">
                <span className="block text-sm font-semibold text-negative">{critico.titulo}</span>
                <span className="block truncate text-xs text-negative/80">{critico.mensagem}</span>
              </span>
            </Link>
          ) : null}
          {children}
        </main>

        {/* Botão flutuante — mobile/tablet */}
        {acaoLabel && onAcao ? (
          <button
            type="button"
            onClick={onAcao}
            aria-label={acaoLabel}
            className="fixed right-5 bottom-24 z-40 grid size-14 place-items-center rounded-full bg-brand-gradient text-primary-foreground shadow-glow transition-transform active:scale-95 lg:hidden"
          >
            <Plus className="size-6" />
          </button>
        ) : null}

        {/* Barra inferior — mobile/tablet */}
        <nav className="fixed inset-x-0 bottom-0 z-30 border-t border-border bg-surface/95 backdrop-blur lg:hidden">
          <div className="mx-auto flex max-w-md items-stretch justify-between px-2 py-1.5">
            {NAV.map((item) => (
              <Link
                key={item.to}
                to={item.to}
                activeOptions={{ exact: item.to === "/" }}
                className={cn(
                  "flex min-w-0 flex-1 flex-col items-center gap-1 rounded-xl px-1 py-2 text-[10px] font-medium text-muted-foreground transition-colors",
                  "data-[status=active]:text-primary-accent data-[status=active]:font-bold",
                )}
              >
                <item.icon className="size-5" />
                <span className="truncate">{item.label}</span>
              </Link>
            ))}
          </div>
        </nav>
      </div>
    </div>
  );
}
