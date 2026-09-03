import type { ReactNode } from "react";
import { cn } from "@/lib/utils";
import { Skeleton } from "@/components/ui/skeleton";
import { formatBRL } from "@/lib/format";

export function SectionTitle({
  children,
  action,
  hint,
}: {
  children: ReactNode;
  action?: ReactNode;
  hint?: string;
}) {
  return (
    <div className="mb-3 grid grid-cols-[minmax(0,1fr)_auto] items-end gap-3">
      <div className="min-w-0">
        <h2 className="font-display text-lg leading-tight tracking-tight">{children}</h2>
        {hint ? <p className="mt-0.5 text-xs text-muted-foreground">{hint}</p> : null}
      </div>
      {action}
    </div>
  );
}

export function Card({
  children,
  className,
  tone = "default",
}: {
  children: ReactNode;
  className?: string;
  tone?: "default" | "positive" | "negative" | "warning" | "brand";
}) {
  const tones = {
    default: "bg-surface border-border",
    positive: "bg-positive-soft border-positive-mid/60",
    negative: "bg-negative-soft border-negative-mid/60",
    warning: "bg-warning-soft border-warning/25",
    brand: "bg-brand-gradient border-transparent text-primary-foreground shadow-glow",
  } as const;
  return (
    <div
      className={cn(
        "rounded-2xl border shadow-soft transition-shadow hover:shadow-lift",
        tones[tone],
        className,
      )}
    >
      {children}
    </div>
  );
}

export function StatCard({
  label,
  value,
  hint,
  icon,
  tone = "default",
  destaque = false,
}: {
  label: string;
  value: string;
  hint?: string;
  icon?: ReactNode;
  tone?: "default" | "positive" | "negative" | "warning" | "brand";
  destaque?: boolean;
}) {
  const valueTone = {
    default: "text-foreground",
    positive: "text-positive",
    negative: "text-negative",
    warning: "text-warning",
    brand: "text-primary-foreground",
  } as const;
  return (
    <Card tone={tone} className={cn("p-4", destaque && "p-5")}>
      <div className="flex items-start justify-between gap-2">
        <p
          className={cn(
            "text-[11px] font-semibold tracking-wide uppercase",
            tone === "brand" ? "text-primary-foreground/80" : "text-muted-foreground",
          )}
        >
          {label}
        </p>
        {icon ? (
          <span className={tone === "brand" ? "text-primary-foreground/90" : "text-primary"}>
            {icon}
          </span>
        ) : null}
      </div>
      <p
        className={cn(
          "mt-2 font-display font-semibold tracking-tight",
          destaque ? "text-3xl sm:text-4xl" : "text-xl sm:text-2xl",
          valueTone[tone],
        )}
      >
        {value}
      </p>
      {hint ? (
        <p
          className={cn(
            "mt-1 text-xs",
            tone === "brand" ? "text-primary-foreground/85" : "text-muted-foreground",
          )}
        >
          {hint}
        </p>
      ) : null}
    </Card>
  );
}

const badgeTones = {
  neutral: "bg-secondary text-secondary-foreground",
  brand: "bg-accent text-accent-foreground",
  positive: "bg-positive-soft text-positive",
  negative: "bg-negative-soft text-negative",
  warning: "bg-warning-soft text-warning",
} as const;

export type BadgeTone = keyof typeof badgeTones;

export function Pill({
  children,
  tone = "neutral",
  className,
}: {
  children: ReactNode;
  tone?: BadgeTone;
  className?: string;
}) {
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-[11px] font-semibold",
        badgeTones[tone],
        className,
      )}
    >
      {children}
    </span>
  );
}

export function Money({
  value,
  colorir = false,
  className,
}: {
  value: number;
  colorir?: boolean;
  className?: string;
}) {
  return (
    <span
      className={cn(
        "font-semibold tabular-nums",
        colorir && (value >= 0 ? "text-positive" : "text-negative"),
        className,
      )}
    >
      {formatBRL(value)}
    </span>
  );
}

export function EmptyState({
  titulo,
  descricao,
  acao,
  icon,
}: {
  titulo: string;
  descricao: string;
  acao?: ReactNode;
  icon?: ReactNode;
}) {
  return (
    <div className="flex flex-col items-center rounded-2xl border border-dashed border-border bg-surface px-6 py-10 text-center">
      {icon ? (
        <div className="mb-3 grid size-12 place-items-center rounded-full bg-accent text-accent-foreground">
          {icon}
        </div>
      ) : null}
      <p className="font-display text-base font-semibold">{titulo}</p>
      <p className="mt-1 max-w-xs text-sm text-muted-foreground">{descricao}</p>
      {acao ? <div className="mt-4">{acao}</div> : null}
    </div>
  );
}

export function ListSkeleton({ linhas = 4 }: { linhas?: number }) {
  return (
    <div className="space-y-3">
      {Array.from({ length: linhas }).map((_, i) => (
        <div key={i} className="rounded-2xl border border-border bg-surface p-4 shadow-soft">
          <Skeleton className="h-4 w-2/5" />
          <Skeleton className="mt-3 h-3 w-3/5" />
          <Skeleton className="mt-3 h-3 w-1/4" />
        </div>
      ))}
    </div>
  );
}

export function CardsSkeleton({ qtd = 4 }: { qtd?: number }) {
  return (
    <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
      {Array.from({ length: qtd }).map((_, i) => (
        <div key={i} className="rounded-2xl border border-border bg-surface p-4 shadow-soft">
          <Skeleton className="h-3 w-1/2" />
          <Skeleton className="mt-3 h-7 w-3/4" />
        </div>
      ))}
    </div>
  );
}
