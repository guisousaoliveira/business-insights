/**
 * Ambiente — o único lugar que lê `import.meta.env`.
 *
 * `API_BASE_URL` nunca é fixa no código, espelhando o `--dart-define` do app
 * Flutter (`settings/app_environment.dart`). O `.env` de cada ambiente é quem
 * decide para onde o app aponta.
 */
export const AppEnvironment = {
  /** Base de todas as rotas. Sempre termina em `/v1`, nunca com barra final. */
  apiBaseUrl: (import.meta.env["VITE_API_BASE_URL"] ?? "http://localhost:8000/v1").replace(
    /\/+$/,
    "",
  ),

  /**
   * Modo demo: servidor falso em memória por trás do mesmo transporte.
   *
   * Existe pelo mesmo motivo do modo demo do Flutter (decisão F4): manter o app
   * navegável enquanto o FastAPI não responde às 53 operações. Não é cache e
   * não é offline-first — o estado vive na aba e some quando ela fecha.
   */
  isDemo: import.meta.env["VITE_DEMO_MODE"] === "true",
} as const;
