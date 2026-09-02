/// Configuração de ambiente resolvida em **tempo de compilação**.
///
/// ```bash
/// flutter run -d chrome --dart-define-from-file=env/demo.json   # modo demo
/// flutter run -d chrome --dart-define-from-file=env/dev.json    # backend real
/// ```
class AppEnvironment {
  const AppEnvironment._();

  /// Troca os repositories reais por um servidor falso em memória
  /// (`lib/repositories/demo/`), para o app ser navegável antes do backend
  /// existir.
  ///
  /// É `const`: com `false`, o tree shaking do build de produção descarta a
  /// pasta `demo/` inteira. Nenhum outro lugar do app pergunta por isto — quem
  /// decide é só a `AppRepositories`.
  static const isDemo = bool.fromEnvironment('DEMO_MODE');
}
