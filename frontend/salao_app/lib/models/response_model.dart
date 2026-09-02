/// Envelope de resposta do FastAPI, codificado **uma vez só**.
///
/// Toda resposta tem a mesma forma (§0 de `.specs/endpoints-backend.md`):
/// ```json
/// { "total": 12, "mensagem": "ok", "codigo": null, "result": { } }
/// ```
///
/// Backend mudou de envelope? Altere **apenas** este arquivo.
abstract class ResponseModel {
  final int total;
  final String message;

  const ResponseModel({required this.total, required this.message});

  static const totalKey = 'total';
  static const messageKey = 'mensagem';
  static const resultKey = 'result';

  /// Código de erro de negócio. Lido pelo `ErrorModel`, nunca em sucesso.
  static const errorCodeKey = 'codigo';

  /// Lê o envelope com tolerância: campo ausente não pode derrubar o parse de
  /// uma resposta cujo `result` veio certo.
  static int totalFrom(Map<String, dynamic> map) =>
      (map[totalKey] as num?)?.toInt() ?? 0;

  static String messageFrom(Map<String, dynamic> map) =>
      map[messageKey] as String? ?? '';
}
