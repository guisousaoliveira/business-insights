import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/alertas/get_alertas_response_model.dart';
import '../../models/error_model.dart';
import '../../repositories/app_repositories.dart';
import '../../repositories/alertas_repository.dart';
import '../../settings/app_logger.dart';
import '../bloc_substate.dart';

part 'alertas_state.dart';

/// Alimenta a central de alertas **e** o badge que aparece em toda a casca.
///
/// O app não decide o que é alerta: busca prontos, com severidade calculada
/// pelo servidor (S7).
class AlertasCubit extends Cubit<AlertasState> {
  AlertasCubit({AlertasRepository? repository})
      : _repository = repository ?? AppRepositories.alertas,
        super(const AlertasState());

  final AlertasRepository _repository;

  Future<void> getAlertas({bool? apenasNaoLidos}) async {
    emit(state.copyWith(getAlertasSubState: BlocSubState.loading));

    try {
      final response =
          await _repository.getAlertas(apenasNaoLidos: apenasNaoLidos);
      emit(state.copyWith(
        getAlertasSubState: BlocSubState.completed(response),
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        getAlertasSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao buscar alertas', e, s);
      emit(state.copyWith(
        getAlertasSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  Future<void> marcarLido(String id) async {
    emit(state.copyWith(marcarLidoSubState: BlocSubState.loading));

    try {
      await _repository.marcarLido(id);
      emit(state.copyWith(marcarLidoSubState: BlocSubState.completed(null)));
    } on DioException catch (e) {
      emit(state.copyWith(
        marcarLidoSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao marcar alerta como lido', e, s);
      emit(state.copyWith(
        marcarLidoSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  Future<void> marcarTodosLidos() async {
    emit(state.copyWith(marcarTodosLidosSubState: BlocSubState.loading));

    try {
      await _repository.marcarTodosLidos();
      emit(state.copyWith(
        marcarTodosLidosSubState: BlocSubState.completed(null),
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        marcarTodosLidosSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao marcar todos os alertas', e, s);
      emit(state.copyWith(
        marcarTodosLidosSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }
}
