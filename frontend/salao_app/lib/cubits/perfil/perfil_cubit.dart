import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/error_model.dart';
import '../../models/perfil/custo_fixo_model.dart';
import '../../models/perfil/perfil_model.dart';
import '../../repositories/app_repositories.dart';
import '../../repositories/perfil_repository.dart';
import '../../settings/app_logger.dart';
import '../bloc_substate.dart';

part 'perfil_state.dart';

class PerfilCubit extends Cubit<PerfilState> {
  PerfilCubit({PerfilRepository? repository})
      : _repository = repository ?? AppRepositories.perfil,
        super(const PerfilState());

  final PerfilRepository _repository;

  Future<void> getPerfil() async {
    emit(
        state.copyWith(getPerfilSubState: state.getPerfilSubState.toLoading()));

    try {
      final response = await _repository.getPerfil();
      emit(state.copyWith(getPerfilSubState: BlocSubState.completed(response)));
    } on DioException catch (e) {
      emit(state.copyWith(
        getPerfilSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao buscar o perfil', e, s);
      emit(state.copyWith(
        getPerfilSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  Future<void> getCustosFixos() async {
    emit(state.copyWith(
        getCustosFixosSubState: state.getCustosFixosSubState.toLoading()));

    try {
      final response = await _repository.getCustosFixos();
      emit(state.copyWith(
        getCustosFixosSubState: BlocSubState.completed(response),
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        getCustosFixosSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao buscar custos fixos', e, s);
      emit(state.copyWith(
        getCustosFixosSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  Future<void> createCustoFixo({
    required String descricao,
    required double valor,
    required int diaVencimento,
  }) async {
    emit(state.copyWith(createCustoFixoSubState: BlocSubState.loading));

    try {
      await _repository.createCustoFixo(
        CustoFixoModel(
          id: '',
          descricao: descricao,
          valor: valor,
          diaVencimento: diaVencimento,
        ),
      );
      emit(state.copyWith(
        createCustoFixoSubState: BlocSubState.completed(null),
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        createCustoFixoSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao criar custo fixo', e, s);
      emit(state.copyWith(
        createCustoFixoSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  Future<void> editCustoFixo({
    required String id,
    required String descricao,
    required double valor,
    required int diaVencimento,
  }) async {
    emit(state.copyWith(editCustoFixoSubState: BlocSubState.loading));

    try {
      await _repository.editCustoFixo(
        CustoFixoModel(
          id: id,
          descricao: descricao,
          valor: valor,
          diaVencimento: diaVencimento,
        ),
      );
      emit(state.copyWith(editCustoFixoSubState: BlocSubState.completed(null)));
    } on DioException catch (e) {
      emit(state.copyWith(
        editCustoFixoSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao editar custo fixo', e, s);
      emit(state.copyWith(
        editCustoFixoSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  Future<void> deleteCustoFixo(String id) async {
    emit(state.copyWith(deleteCustoFixoSubState: BlocSubState.loading));

    try {
      await _repository.deleteCustoFixo(id);
      emit(state.copyWith(
        deleteCustoFixoSubState: BlocSubState.completed(null),
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        deleteCustoFixoSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao excluir custo fixo', e, s);
      emit(state.copyWith(
        deleteCustoFixoSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  /// Pagar não lança gasto: custo fixo já está no cálculo do mês pelo perfil.
  /// O que este toque muda é só se ela ainda deve ou não — e, com isso, se o
  /// alerta de vencimento continua de pé.
  Future<void> pagarCustoFixo({
    required String id,
    required String competencia,
    required bool pago,
  }) async {
    emit(state.copyWith(pagarCustoFixoSubState: BlocSubState.loading));

    try {
      await _repository.pagarCustoFixo(
        id: id,
        competencia: competencia,
        pago: pago,
      );
      emit(
          state.copyWith(pagarCustoFixoSubState: BlocSubState.completed(null)));
    } on DioException catch (e) {
      emit(state.copyWith(
        pagarCustoFixoSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao pagar custo fixo', e, s);
      emit(state.copyWith(
        pagarCustoFixoSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  Future<void> updatePerfil(PerfilModel model) async {
    emit(state.copyWith(updatePerfilSubState: BlocSubState.loading));

    try {
      await _repository.updatePerfil(model);
      emit(state.copyWith(updatePerfilSubState: BlocSubState.completed(null)));
    } on DioException catch (e) {
      emit(state.copyWith(
        updatePerfilSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao salvar o perfil', e, s);
      emit(state.copyWith(
        updatePerfilSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }
}
