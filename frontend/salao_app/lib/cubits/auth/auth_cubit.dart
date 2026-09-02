import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/auth/login_request_model.dart';
import '../../models/error_model.dart';
import '../../repositories/app_repositories.dart';
import '../../repositories/auth_repository.dart';
import '../../settings/app_logger.dart';
import '../../settings/app_storage.dart';
import '../bloc_substate.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({AuthRepository? repository})
      : _repository = repository ?? AppRepositories.auth,
        super(const AuthState());

  final AuthRepository _repository;

  Future<void> login({required String email, required String senha}) async {
    emit(state.copyWith(loginSubState: BlocSubState.loading));

    try {
      final response = await _repository.login(
        LoginRequestModel(email: email, senha: senha),
      );

      // O cubit grava no storage **antes** de emitir `completed`, para que a UI
      // reaja com a sessão já consistente — o route guard lê o token na hora.
      await AppStorage.write(AppStorage.bearerToken, response.token);
      await AppStorage.write(AppStorage.refreshToken, response.refreshToken);
      await AppStorage.write(
          AppStorage.userInfoKey, response.usuario.toStorage);
      await AppStorage.write(AppStorage.salonInfoKey, response.salaoNome);

      emit(state.copyWith(loginSubState: BlocSubState.completed(response)));
    } on DioException catch (e) {
      emit(state.copyWith(
        loginSubState: BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada no login', e, s);
      emit(state.copyWith(
        loginSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  /// Limpar a sessão local não depende do servidor responder: se a chamada
  /// falhar, a usuária sai do mesmo jeito. Deixar alguém preso logado porque a
  /// rede caiu seria pior do que um refresh token órfão no backend.
  Future<void> logout() async {
    emit(state.copyWith(logoutSubState: BlocSubState.loading));

    try {
      await _repository.logout();
    } on DioException catch (e) {
      AppLogger.warning('Logout remoto falhou; encerrando sessão local', e);
    } catch (e, s) {
      AppLogger.warning('Logout remoto falhou; encerrando sessão local', e, s);
    }

    await AppStorage.clear();
    emit(state.copyWith(logoutSubState: BlocSubState.completed(null)));
  }
}
