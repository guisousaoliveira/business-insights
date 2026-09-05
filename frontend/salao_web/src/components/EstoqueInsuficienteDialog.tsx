import { TriangleAlert } from "lucide-react";
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
import { ApiError, AppErrorCodes } from "@/lib/error-codes";
import type { FaltanteEstoque } from "@/lib/types";

/**
 * A segunda passada da decisão A5.
 *
 * Estoque insuficiente **avisa, não bloqueia**: a primeira chamada vai com
 * `confirmar_estoque_insuficiente: false`, o servidor não grava nada e devolve
 * `409 ESTOQUE_INSUFICIENTE` com `result.faltantes`. Este diálogo mostra a lista
 * e, se ela confirmar, a tela repete a chamada com `true` — o saldo fica
 * negativo de propósito, porque o produto foi usado de verdade.
 *
 * A conta de quanto falta é do servidor: a tela nunca soma saldo por conta
 * própria, senão duas contas diferentes acabariam divergindo.
 */
export function faltantesDoErro(erro: unknown): FaltanteEstoque[] | null {
  if (!(erro instanceof ApiError) || !erro.is(AppErrorCodes.insufficientStock)) return null;
  const result = erro.result;
  if (typeof result !== "object" || result === null) return [];
  const lista = (result as { faltantes?: unknown }).faltantes;
  return Array.isArray(lista) ? (lista as FaltanteEstoque[]) : [];
}

export function EstoqueInsuficienteDialog({
  faltantes,
  acao,
  confirmando = false,
  onCancelar,
  onConfirmar,
}: {
  /** `null` mantém o diálogo fechado. */
  faltantes: FaltanteEstoque[] | null;
  /** O que será registrado mesmo assim: "finalizar o atendimento", "montar 3 kits". */
  acao: string;
  confirmando?: boolean;
  onCancelar: () => void;
  onConfirmar: () => void;
}) {
  return (
    <AlertDialog open={faltantes !== null} onOpenChange={(aberto) => !aberto && onCancelar()}>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle className="flex items-center gap-2">
            <TriangleAlert className="size-5 text-warning" />
            Estoque insuficiente
          </AlertDialogTitle>
          <AlertDialogDescription>
            Falta produto para {acao}. Você pode registrar assim mesmo — o saldo fica negativo e um
            alerta é criado para você repor.
          </AlertDialogDescription>
        </AlertDialogHeader>

        <ul className="space-y-2 rounded-xl border border-warning/25 bg-warning-soft p-3 text-sm">
          {(faltantes ?? []).map((f) => (
            <li key={f.item_estoque_id} className="flex items-start justify-between gap-3">
              <span className="min-w-0 truncate font-medium text-warning">{f.nome}</span>
              <span className="shrink-0 text-xs text-warning">
                precisa {f.quantidade_solicitada} {f.unidade} • tem {f.quantidade_disponivel}{" "}
                (faltam {f.deficit})
              </span>
            </li>
          ))}
        </ul>

        <AlertDialogFooter>
          <AlertDialogCancel disabled={confirmando}>Voltar</AlertDialogCancel>
          <AlertDialogAction
            disabled={confirmando}
            onClick={(e) => {
              // O diálogo fecha sozinho no clique; aqui quem manda fechar é o
              // resultado da segunda chamada.
              e.preventDefault();
              onConfirmar();
            }}
          >
            Registrar mesmo assim
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
