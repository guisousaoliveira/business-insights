part of 'kits_cubit.dart';

class KitsState {
  final BlocSubState getKitsSubState;
  final BlocSubState createKitSubState;
  final BlocSubState deleteKitSubState;
  final BlocSubState montarKitSubState;
  final BlocSubState venderKitSubState;

  const KitsState({
    this.getKitsSubState = const BlocSubState(),
    this.createKitSubState = const BlocSubState(),
    this.deleteKitSubState = const BlocSubState(),
    this.montarKitSubState = const BlocSubState(),
    this.venderKitSubState = const BlocSubState(),
  });

  KitsState copyWith({
    BlocSubState? getKitsSubState,
    BlocSubState? createKitSubState,
    BlocSubState? deleteKitSubState,
    BlocSubState? montarKitSubState,
    BlocSubState? venderKitSubState,
  }) =>
      KitsState(
        getKitsSubState: getKitsSubState ?? this.getKitsSubState,
        createKitSubState: createKitSubState ?? this.createKitSubState,
        deleteKitSubState: deleteKitSubState ?? this.deleteKitSubState,
        montarKitSubState: montarKitSubState ?? this.montarKitSubState,
        venderKitSubState: venderKitSubState ?? this.venderKitSubState,
      );
}
