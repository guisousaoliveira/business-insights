part of 'gastos_cubit.dart';

class GastosState {
  final BlocSubState getGastosSubState;
  final BlocSubState createGastoSubState;
  final BlocSubState pagarGastoSubState;
  final BlocSubState deleteGastoSubState;

  const GastosState({
    this.getGastosSubState = const BlocSubState(),
    this.createGastoSubState = const BlocSubState(),
    this.pagarGastoSubState = const BlocSubState(),
    this.deleteGastoSubState = const BlocSubState(),
  });

  GastosState copyWith({
    BlocSubState? getGastosSubState,
    BlocSubState? createGastoSubState,
    BlocSubState? pagarGastoSubState,
    BlocSubState? deleteGastoSubState,
  }) =>
      GastosState(
        getGastosSubState: getGastosSubState ?? this.getGastosSubState,
        createGastoSubState: createGastoSubState ?? this.createGastoSubState,
        pagarGastoSubState: pagarGastoSubState ?? this.pagarGastoSubState,
        deleteGastoSubState: deleteGastoSubState ?? this.deleteGastoSubState,
      );
}
