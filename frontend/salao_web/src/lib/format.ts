export function formatBRL(value: number): string {
  return new Intl.NumberFormat("pt-BR", {
    style: "currency",
    currency: "BRL",
    minimumFractionDigits: 2,
  }).format(value);
}

export function formatBRLShort(value: number): string {
  if (Math.abs(value) >= 1000) {
    return `R$ ${(value / 1000).toFixed(1).replace(".", ",")}mil`;
  }
  return formatBRL(value);
}

/** Recebe "2026-09-02" ou Date e devolve "02/09/2026" */
export function formatDate(value: string | Date): string {
  const d = typeof value === "string" ? new Date(`${value.slice(0, 10)}T12:00:00`) : value;
  return new Intl.DateTimeFormat("pt-BR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  }).format(d);
}

export function formatDateShort(value: string): string {
  return formatDate(value).slice(0, 5);
}

export function formatPercent(value: number, digits = 0): string {
  return `${value.toFixed(digits).replace(".", ",")}%`;
}

export const MESES = [
  "Janeiro",
  "Fevereiro",
  "Março",
  "Abril",
  "Maio",
  "Junho",
  "Julho",
  "Agosto",
  "Setembro",
  "Outubro",
  "Novembro",
  "Dezembro",
];

export function nomeMes(mes: number): string {
  return MESES[mes - 1] ?? "";
}

/** "02/09/2026 às 14:30", no fuso do navegador. */
export function formatDateTime(value: string): string {
  const d = new Date(value);
  const data = new Intl.DateTimeFormat("pt-BR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  }).format(d);
  const hora = new Intl.DateTimeFormat("pt-BR", {
    hour: "2-digit",
    minute: "2-digit",
  }).format(d);
  return `${data} às ${hora}`;
}

/** Só a hora local de um ISO-8601: "14:30". */
export function formatHora(value: string): string {
  return new Intl.DateTimeFormat("pt-BR", { hour: "2-digit", minute: "2-digit" }).format(
    new Date(value),
  );
}
