import { BarcodeFormat, DecodeHintType } from "@zxing/library";
import { BrowserMultiFormatReader } from "@zxing/browser";
import type { IScannerControls } from "@zxing/browser";
import { CameraOff, ScanLine } from "lucide-react";
import { useCallback, useEffect, useRef, useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

/**
 * Overlay de câmera para bipar código de barras (entrada de estoque).
 *
 * Só câmera do celular/notebook — sem leitor físico dedicado, é o que foi
 * pedido. Se a câmera não estiver disponível (permissão negada, sem
 * dispositivo), mostra o motivo em vez de travar a tela: ela ainda pode
 * fechar e cadastrar o item na mão pelo formulário normal.
 */

// Só os formatos usados em embalagem de produto — restringir ajuda o leitor a
// não perder tempo tentando reconhecer QR code/PDF417/etc. a cada quadro.
const FORMATOS_PRODUTO = [
  BarcodeFormat.EAN_13,
  BarcodeFormat.EAN_8,
  BarcodeFormat.UPC_A,
  BarcodeFormat.UPC_E,
  BarcodeFormat.CODE_128,
  BarcodeFormat.CODE_39,
];

const hints = new Map();
hints.set(DecodeHintType.POSSIBLE_FORMATS, FORMATOS_PRODUTO);
hints.set(DecodeHintType.TRY_HARDER, true);

export function BarcodeScannerDialog({
  open,
  onOpenChange,
  onDetectado,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onDetectado: (codigo: string) => void;
}) {
  const controlsRef = useRef<IScannerControls | null>(null);
  const [erro, setErro] = useState<string | null>(null);
  // O <video> vive dentro do Portal do Dialog (Radix só anexa o portal ao DOM
  // depois do primeiro commit, por causa de SSR). Um `ref` comum captura
  // `null` nesse primeiro efeito; um callback ref dispara re-render só quando
  // o nó realmente existe, então o efeito abaixo espera por ele em vez de
  // assumir que já está montado.
  const [video, setVideo] = useState<HTMLVideoElement | null>(null);
  // DEBUG TEMPORÁRIO — remover depois de confirmar o que a câmera desse celular
  // realmente aceita (zoom/foco reportados por getCapabilities costumam mentir).
  const [debug, setDebug] = useState("");

  const videoRef = useCallback((node: HTMLVideoElement | null) => {
    setVideo(node);
  }, []);

  useEffect(() => {
    if (!open || !video) return;
    setErro(null);
    let cancelado = false;
    const leitor = new BrowserMultiFormatReader(hints);

    leitor
      .decodeFromConstraints(
        {
          video: {
            facingMode: "environment",
            // 480x640 (o padrão do Chrome) é baixo demais pra ler linhas finas
            // de código de barras — pede a maior resolução que a câmera aceitar.
            width: { ideal: 1920 },
            height: { ideal: 1080 },
            // Zoom confirmado funcionando neste aparelho (capability 1x-8x). Focar de
            // perto demais sai da faixa que a lente consegue focar sozinha — em vez
            // disso, afasta um pouco o celular e usa zoom pra compensar.
            advanced: [{ focusMode: "continuous", zoom: 3 }] as any,
          },
        },
        video,
        (resultado) => {
          if (resultado && !cancelado) {
            cancelado = true;
            controlsRef.current?.stop();
            onDetectado(resultado.getText());
          }
        },
      )
      .then((controls) => {
        if (cancelado) {
          controls.stop();
          return;
        }
        controlsRef.current = controls;
        const track = (video.srcObject as MediaStream | null)?.getVideoTracks()[0];
        const caps = track?.getCapabilities?.() as
          | (MediaTrackCapabilities & { zoom?: { min: number; max: number; step: number }; focusMode?: string[] })
          | undefined;
        const settings = track?.getSettings?.() as
          | (MediaTrackSettings & { zoom?: number; focusMode?: string })
          | undefined;
        setDebug(
          `real=${video.videoWidth}x${video.videoHeight} ` +
            `zoom(cap)=${caps?.zoom ? JSON.stringify(caps.zoom) : "sem suporte"} ` +
            `zoom(aplicado)=${settings?.zoom ?? "?"} ` +
            `focusMode(cap)=${caps?.focusMode ? JSON.stringify(caps.focusMode) : "sem suporte"} ` +
            `focusMode(aplicado)=${settings?.focusMode ?? "?"}`,
        );
      })
      .catch((e: unknown) => {
        const nome = e instanceof Error ? e.name : "";
        setErro(
          nome === "NotAllowedError"
            ? "Permissão de câmera negada. Permita o acesso e tente de novo."
            : nome === "NotFoundError"
              ? "Nenhuma câmera encontrada neste dispositivo."
              : "Não foi possível abrir a câmera.",
        );
      });

    return () => {
      cancelado = true;
      controlsRef.current?.stop();
      controlsRef.current = null;
    };
  }, [open, video, onDetectado]);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-sm">
        <DialogHeader>
          <DialogTitle>Bipar produto</DialogTitle>
          <DialogDescription>
            Aponte a câmera para o código de barras, a uns 20-25 cm de distância (mais perto que
            isso a câmera desse celular não foca).
          </DialogDescription>
        </DialogHeader>
        {erro ? (
          <div className="flex flex-col items-center gap-2 rounded-xl border border-dashed border-border py-10 text-center">
            <CameraOff className="size-6 text-muted-foreground" />
            <p className="max-w-[80%] text-sm text-muted-foreground">{erro}</p>
          </div>
        ) : (
          <div className="relative overflow-hidden rounded-xl bg-black">
            {/* eslint-disable-next-line jsx-a11y/media-has-caption -- vídeo é só o preview da câmera, sem áudio */}
            <video
              ref={videoRef}
              className="aspect-square w-full object-cover"
              // O modal centraliza com `translate(-50%,-50%)`; em alguns Android/Chrome um
              // <video> dentro de ancestral com `transform` renderiza preto até ganhar sua
              // própria camada de composição — isso força essa camada.
              style={{ transform: "translateZ(0)" }}
              muted
              autoPlay
              playsInline
            />
            <div className="pointer-events-none absolute inset-8 rounded-lg border-2 border-primary-foreground/70" />
            <ScanLine className="pointer-events-none absolute top-1/2 left-1/2 size-6 -translate-x-1/2 -translate-y-1/2 text-primary-foreground/70" />
          </div>
        )}
        {/* DEBUG TEMPORÁRIO — remover depois de confirmar o que a câmera aceita. */}
        <p className="break-all rounded bg-muted px-2 py-1 font-mono text-[10px] text-muted-foreground">
          {debug}
        </p>
      </DialogContent>
    </Dialog>
  );
}
