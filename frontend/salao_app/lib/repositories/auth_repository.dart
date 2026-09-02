import '../models/auth/login_request_model.dart';
import '../models/auth/login_response_model.dart';
import '../settings/app_api.dart';

abstract interface class AuthRepository {
  Future<LoginResponseModel> login(LoginRequestModel model);
  Future<void> logout();
}

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl();

  @override
  Future<LoginResponseModel> login(LoginRequestModel model) async {
    final response = await AppApi.postWithoutToken(
      AppApi.loginPath,
      data: model.toBody,
    );
    return LoginResponseModel.fromResponse(
        response.data as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    await AppApi.post(AppApi.logoutPath);
  }
}
