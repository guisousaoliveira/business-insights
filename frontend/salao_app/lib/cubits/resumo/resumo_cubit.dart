import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/error_model.dart';
import '../../repositories/app_repositories.dart';
import '../../repositories/resumo_repository.dart';
import '../../settings/app_logger.dart';
import '../bloc_substate.dart';

part 'resumo_state.dart';

class ResumoCubit extends Cubit<ResumoState> {
  ResumoCubit({ResumoRepository? repository})
      : _repository = repository ?? AppRepositories.resumo,
        super(ResumoState());

  final ResumoRepository _repository;

  Future<void> getResumoMensal({DateTime? periodo}) async {
    final target = periodo ?? state.periodo;

    emit(state.copyWith(
      getResumoMensalSubState: BlocSubState.loading,
      periodo: target,
    ));

    try {
      final response = await _repository.getResumoMensal(
        ano: target.year,
        mes: target.month,
      );
      emit(state.copyWith(
        getResumoMensalSubState: BlocSubState.completed(response),
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        getResumoMensalSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao buscar o resumo mensal', e, s);
      emit(state.copyWith(
        getResumoMensalSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }
}
