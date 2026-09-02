import '../../settings/app_enums.dart';
import '../../settings/app_utils.dart';

class AlertaModel {
  static const _idKey = 'id';
  static const _tipoKey = 'tipo';
  static const _severidadeKey = 'severidade';
  static const _tituloKey = 'titulo';
  static const _mensagemKey = 'mensagem';
  static const _referenciaTipoKey = 'referencia_tipo';
  static const _referenciaIdKey = 'referencia_id';
  static const _criadoEmKey = 'criado_em';
  static const _lidoEmKey = 'lido_em';

  final String id;
  final TipoAlerta tipo;
  final SeveridadeAlerta severidade;
  final String titulo;
  final String mensagem;
  final String? referenciaTipo;
  final String? referenciaId;
  final DateTime criadoEm;
  final DateTime? lidoEm;

  const AlertaModel({
    required this.id,
    required this.tipo,
    required this.severidade,
    required this.titulo,
    required this.mensagem,
    this.referenciaTipo,
    this.referenciaId,
    required this.criadoEm,
    this.lidoEm,
  });

  bool get isLido => lidoEm != null;

  /// O servidor não conhece rotas de UI; o mapeamento tipo → tela é do app.
  String get rota => AppUtils.routeForAlerta(tipo);

  factory AlertaModel.fromResponse(Map<String, dynamic> map) => AlertaModel(
        id: map[_idKey] as String? ?? '',
        tipo: AppUtils.decodeTipoAlerta(map[_tipoKey] as String?),
        severidade:
            AppUtils.decodeSeveridadeAlerta(map[_severidadeKey] as String?),
        titulo: map[_tituloKey] as String? ?? '',
        mensagem: map[_mensagemKey] as String? ?? '',
        referenciaTipo: map[_referenciaTipoKey] as String?,
        referenciaId: map[_referenciaIdKey] as String?,
        criadoEm:
            DateTime.tryParse(map[_criadoEmKey] as String? ?? '') ??
                DateTime.now(),
        lidoEm: DateTime.tryParse(map[_lidoEmKey] as String? ?? ''),
      );
}
