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

/**
 * Máscara de telefone BR: aceita só dígitos, limita a 11 (DDD + 9 dígitos) e
 * formata como "(11) 90000-0000" (celular) ou "(11) 0000-0000" (fixo).
 */
export function formatTelefone(value: string): string {
  const digitos = value.replace(/\D/g, "").slice(0, 11);
  const ddd = digitos.slice(0, 2);
  const resto = digitos.slice(2);
  if (digitos.length === 0) return "";
  if (digitos.length <= 2) return `(${ddd}`;
  const tamanhoPrefixo = resto.length > 4 ? (digitos.length > 10 ? 5 : 4) : resto.length;
  const prefixo = resto.slice(0, tamanhoPrefixo);
  const sufixo = resto.slice(tamanhoPrefixo);
  return sufixo ? `(${ddd}) ${prefixo}-${sufixo}` : `(${ddd}) ${prefixo}`;
}
