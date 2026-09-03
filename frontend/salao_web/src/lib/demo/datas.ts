/**
 * Datas do modo demo — em horário local, sempre.
 *
 * `new Date("2026-09-01")` é interpretado como **UTC** pelo JS e, a oeste de
 * Greenwich, volta como 31/08 às 21h. Um app que fecha o mês não pode ter um
 * gasto do dia 1º aparecendo no mês anterior, então nada aqui usa o parser
 * nativo de string: os componentes são lidos na mão e a data é montada local.
 */

/** Meia-noite de hoje, local. */
export function hoje(): Date {
  const agora = new Date();
  return new Date(agora.getFullYear(), agora.getMonth(), agora.getDate());
}

export function emDias(quantidade: number): Date {
  const base = hoje();
  return new Date(base.getFullYear(), base.getMonth(), base.getDate() + quantidade);
}

/** `mes` é 1–12 (como no contrato), não o 0–11 do `Date`. */
export function ultimoDiaDoMes(ano: number, mes: number): number {
  return new Date(ano, mes, 0).getDate();
}

/**
 * O dia do mês resolvido em data. Dia 31 em fevereiro é o último dia de
 * fevereiro — o dia guardado não muda, quem resolve é o cálculo.
 */
export function vencimentoNoMes(dia: number, ano: number, mes: number): Date {
  return new Date(ano, mes - 1, Math.min(dia, ultimoDiaDoMes(ano, mes)));
}

/** Aceita `AAAA-MM-DD` e ISO com hora; devolve sempre uma data local. */
export function parseData(valor: string): Date {
  const [dataParte, horaParte] = valor.split("T");
  const [ano, mes, dia] = (dataParte ?? "").split("-").map(Number);
  const [hora, minuto] = (horaParte ?? "").split(":").map(Number);
  return new Date(ano ?? 1970, (mes ?? 1) - 1, dia ?? 1, hora ?? 0, minuto ?? 0);
}

/** `AAAA-MM-DD` — o `date` puro do contrato. */
export function paraDataApi(data: Date): string {
  const mes = String(data.getMonth() + 1).padStart(2, "0");
  const dia = String(data.getDate()).padStart(2, "0");
  return `${data.getFullYear()}-${mes}-${dia}`;
}

/**
 * ISO-8601 **com offset local**, como o contrato pede.
 *
 * `toISOString()` devolveria em UTC, e um atendimento das 21h viraria do dia
 * seguinte na agenda.
 */
export function paraIso(data: Date): string {
  const doisDigitos = (n: number) => String(n).padStart(2, "0");
  const minutosDeOffset = -data.getTimezoneOffset();
  const sinal = minutosDeOffset >= 0 ? "+" : "-";
  const absoluto = Math.abs(minutosDeOffset);
  return (
    `${paraDataApi(data)}T${doisDigitos(data.getHours())}:${doisDigitos(data.getMinutes())}:` +
    `${doisDigitos(data.getSeconds())}` +
    `${sinal}${doisDigitos(Math.floor(absoluto / 60))}:${doisDigitos(absoluto % 60)}`
  );
}

export function agoraIso(): string {
  return paraIso(new Date());
}

/** `AAAA-MM`. */
export function competenciaDe(data: Date): string {
  return `${data.getFullYear()}-${String(data.getMonth() + 1).padStart(2, "0")}`;
}

export function noMes(data: Date, ano: number, mes: number): boolean {
  return data.getFullYear() === ano && data.getMonth() + 1 === mes;
}

/**
 * Diferença em dias entre duas meia-noites.
 *
 * `Math.round` em vez de divisão seca porque o dia da virada de horário de
 * verão tem 23 ou 25 horas — truncar transformaria "vence hoje" em "venceu
 * ontem" uma vez por ano.
 */
export function diferencaEmDias(alvo: Date, referencia: Date): number {
  return Math.round((alvo.getTime() - referencia.getTime()) / 86_400_000);
}
