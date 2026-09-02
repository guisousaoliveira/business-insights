part of 'perfil_cubit.dart';

class PerfilState {
  final BlocSubState getPerfilSubState;
  final BlocSubState updatePerfilSubState;
  final BlocSubState getCustosFixosSubState;
  final BlocSubState createCustoFixoSubState;
  final BlocSubState editCustoFixoSubState;
  final BlocSubState deleteCustoFixoSubState;
  final BlocSubState pagarCustoFixoSubState;

  const PerfilState({
    this.getPerfilSubState = const BlocSubState(),
    this.updatePerfilSubState = const BlocSubState(),
    this.getCustosFixosSubState = const BlocSubState(),
    this.createCustoFixoSubState = const BlocSubState(),
    this.editCustoFixoSubState = const BlocSubState(),
    this.deleteCustoFixoSubState = const BlocSubState(),
    this.pagarCustoFixoSubState = const BlocSubState(),
  });

  PerfilState copyWith({
    BlocSubState? getPerfilSubState,
    BlocSubState? updatePerfilSubState,
    BlocSubState? getCustosFixosSubState,
    BlocSubState? createCustoFixoSubState,
    BlocSubState? editCustoFixoSubState,
    BlocSubState? deleteCustoFixoSubState,
    BlocSubState? pagarCustoFixoSubState,
  }) =>
      PerfilState(
        getPerfilSubState: getPerfilSubState ?? this.getPerfilSubState,
        updatePerfilSubState: updatePerfilSubState ?? this.updatePerfilSubState,
        getCustosFixosSubState:
            getCustosFixosSubState ?? this.getCustosFixosSubState,
        createCustoFixoSubState:
            createCustoFixoSubState ?? this.createCustoFixoSubState,
        editCustoFixoSubState:
            editCustoFixoSubState ?? this.editCustoFixoSubState,
        deleteCustoFixoSubState:
            deleteCustoFixoSubState ?? this.deleteCustoFixoSubState,
        pagarCustoFixoSubState:
            pagarCustoFixoSubState ?? this.pagarCustoFixoSubState,
      );
}
