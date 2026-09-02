import '../response_model.dart';
import 'usuario_model.dart';

class LoginResponseModel extends ResponseModel {
  static const _tokenKey = 'token';
  static const _refreshTokenKey = 'refresh_token';
  static const _expiraEmKey = 'expira_em';
  static const _usuarioKey = 'usuario';
  static const _salaoKey = 'salao';
  static const _salaoIdKey = 'id';
  static const _salaoNomeKey = 'nome';

  final String token;
  final String refreshToken;
  final int expiraEm;
  final UsuarioModel usuario;
  final String salaoId;
  final String salaoNome;

  const LoginResponseModel({
    required super.total,
    required super.message,
    required this.token,
    required this.refreshToken,
    required this.expiraEm,
    required this.usuario,
    required this.salaoId,
    required this.salaoNome,
  });

  factory LoginResponseModel.fromResponse(Map<String, dynamic> map) {
    final result = map[ResponseModel.resultKey] as Map<String, dynamic>;
    final salao = result[_salaoKey] as Map<String, dynamic>? ?? const {};

    return LoginResponseModel(
      total: ResponseModel.totalFrom(map),
      message: ResponseModel.messageFrom(map),
      token: result[_tokenKey] as String,
      refreshToken: result[_refreshTokenKey] as String,
      expiraEm: (result[_expiraEmKey] as num?)?.toInt() ?? 0,
      usuario: UsuarioModel.fromResponse(
        result[_usuarioKey] as Map<String, dynamic>? ?? const {},
      ),
      salaoId: salao[_salaoIdKey] as String? ?? '',
      salaoNome: salao[_salaoNomeKey] as String? ?? '',
    );
  }
}
