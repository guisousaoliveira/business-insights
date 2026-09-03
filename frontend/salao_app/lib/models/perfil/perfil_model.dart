import '../response_model.dart';

class PerfilModel {
  static const _idKey = 'id';
  static const _nomeKey = 'nome';
  static const _proprietariaKey = 'proprietaria';
  static const _fotoUrlKey = 'foto_url';
  static const _telefoneWhatsappKey = 'telefone_whatsapp';
  static const _metaFaturamentoMensalKey = 'meta_faturamento_mensal';

  final String id;
  final String nome;
  final String proprietaria;
  final String? fotoUrl;
  final String? telefoneWhatsapp;
  final double metaFaturamentoMensal;

  const PerfilModel({
    required this.id,
    required this.nome,
    required this.proprietaria,
    this.fotoUrl,
    this.telefoneWhatsapp,
    this.metaFaturamentoMensal = 0,
  });

  factory PerfilModel.fromResponse(Map<String, dynamic> map) => PerfilModel(
        id: map[_idKey] as String? ?? '',
        nome: map[_nomeKey] as String? ?? '',
        proprietaria: map[_proprietariaKey] as String? ?? '',
        fotoUrl: map[_fotoUrlKey] as String?,
        telefoneWhatsapp: map[_telefoneWhatsappKey] as String?,
        metaFaturamentoMensal:
            (map[_metaFaturamentoMensalKey] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> get toBody => {
        _nomeKey: nome,
        _proprietariaKey: proprietaria,
        _telefoneWhatsappKey: telefoneWhatsapp,
        _metaFaturamentoMensalKey: metaFaturamentoMensal,
      };
}

class GetPerfilResponseModel extends ResponseModel {
  static const _salaoKey = 'salao';

  final PerfilModel perfil;

  const GetPerfilResponseModel({
    required super.total,
    required super.message,
    required this.perfil,
  });

  factory GetPerfilResponseModel.fromResponse(Map<String, dynamic> map) {
    final result =
        map[ResponseModel.resultKey] as Map<String, dynamic>? ?? const {};

    return GetPerfilResponseModel(
      total: ResponseModel.totalFrom(map),
      message: ResponseModel.messageFrom(map),
      perfil: PerfilModel.fromResponse(
        result[_salaoKey] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
