part of 'auth_cubit.dart';

class AuthState {
  final BlocSubState loginSubState;
  final BlocSubState logoutSubState;

  const AuthState({
    this.loginSubState = const BlocSubState(),
    this.logoutSubState = const BlocSubState(),
  });

  /// `x ?? this.x` em **todos** os campos: é o que preserva a identidade dos
  /// sub-estados intocados e faz o `buildWhen` funcionar (regra 10).
  AuthState copyWith({
    BlocSubState? loginSubState,
    BlocSubState? logoutSubState,
  }) =>
      AuthState(
        loginSubState: loginSubState ?? this.loginSubState,
        logoutSubState: logoutSubState ?? this.logoutSubState,
      );
}
