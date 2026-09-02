part of 'perfil_cubit.dart';

class PerfilState {
  final BlocSubState getPerfilSubState;
  final BlocSubState updatePerfilSubState;
  final BlocSubState getCustosFixosSubState;
  final BlocSubState createCustoFixoSubState;
  final BlocSubState deleteCustoFixoSubState;

  const PerfilState({
    this.getPerfilSubState = const BlocSubState(),
    this.updatePerfilSubState = const BlocSubState(),
    this.getCustosFixosSubState = const BlocSubState(),
    this.createCustoFixoSubState = const BlocSubState(),
    this.deleteCustoFixoSubState = const BlocSubState(),
  });

  PerfilState copyWith({
    BlocSubState? getPerfilSubState,
    BlocSubState? updatePerfilSubState,
    BlocSubState? getCustosFixosSubState,
    BlocSubState? createCustoFixoSubState,
    BlocSubState? deleteCustoFixoSubState,
  }) =>
      PerfilState(
        getPerfilSubState: getPerfilSubState ?? this.getPerfilSubState,
        updatePerfilSubState: updatePerfilSubState ?? this.updatePerfilSubState,
        getCustosFixosSubState:
            getCustosFixosSubState ?? this.getCustosFixosSubState,
        createCustoFixoSubState:
            createCustoFixoSubState ?? this.createCustoFixoSubState,
        deleteCustoFixoSubState:
            deleteCustoFixoSubState ?? this.deleteCustoFixoSubState,
      );
}
