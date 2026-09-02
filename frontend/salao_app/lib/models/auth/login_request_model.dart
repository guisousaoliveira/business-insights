class LoginRequestModel {
  final String email;
  final String senha;

  const LoginRequestModel({required this.email, required this.senha});

  Map<String, dynamic> get toBody => {'email': email, 'senha': senha};
}
