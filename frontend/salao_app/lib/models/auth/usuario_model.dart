/// Entidade de sessão. Circula entre API, storage e cabeçalho da tela, por isso
/// tem as três conversões.
class UsuarioModel {
  static const _idKey = 'id';
  static const _nomeKey = 'nome';
  static const _emailKey = 'email';

  final String id;
  final String nome;
  final String email;

  const UsuarioModel({
    required this.id,
    required this.nome,
    required this.email,
  });

  factory UsuarioModel.fromResponse(Map<String, dynamic> map) => UsuarioModel(
        id: map[_idKey] as String? ?? '',
        nome: map[_nomeKey] as String? ?? '',
        email: map[_emailKey] as String? ?? '',
      );

  /// Chaves de storage são **em inglês e independentes das da API**, para que
  /// mudança no backend não invalide o que já está salvo no aparelho.
  factory UsuarioModel.fromStorage(Map<String, dynamic> map) => UsuarioModel(
        id: map['userId'] as String? ?? '',
        nome: map['userName'] as String? ?? '',
        email: map['userEmail'] as String? ?? '',
      );

  Map<String, dynamic> get toStorage => {
        'userId': id,
        'userName': nome,
        'userEmail': email,
      };
}
