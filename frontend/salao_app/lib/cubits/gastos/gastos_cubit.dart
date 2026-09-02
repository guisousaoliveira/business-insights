import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/error_model.dart';
import '../../models/gastos/create_gasto_request_model.dart';
import '../../models/gastos/gasto_model.dart';
import '../../repositories/app_repositories.dart';
import '../../repositories/gastos_repository.dart';
import '../../settings/app_enums.dart';
import '../../settings/app_logger.dart';
import '../bloc_substate.dart';

part 'gastos_state.dart';

class GastosCubit extends Cubit<GastosState> {
  GastosCubit({GastosRepository? repository})
      : _repository = repository ?? AppRepositories.gastos,
        super(const GastosState());

  final GastosRepository _repository;

  Future<void> getGastos({required int ano, required int mes}) async {
    emit(state.copyWith(getGastosSubState: BlocSubState.loading));

    try {
      final response = await _repository.getGastos(ano: ano, mes: mes);
      emit(state.copyWith(getGastosSubState: BlocSubState.completed(response)));
    } on DioException catch (e) {
      emit(state.copyWith(
        getGastosSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao buscar gastos', e, s);
      emit(state.copyWith(
        getGastosSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  Future<void> createGasto({
    required String nome,
    required double valor,
    required DateTime prazoPagamento,
    required FormaPagamento formaPagamento,
    required CategoriaGasto categoria,
    List<ItemGastoModel> itens = const [],
  }) async {
    emit(state.copyWith(createGastoSubState: BlocSubState.loading));

    try {
      await _repository.createGasto(
        CreateGastoRequestModel(
          nome: nome,
          valor: valor,
          prazoPagamento: prazoPagamento,
          formaPagamento: formaPagamento,
          categoria: categoria,
          itens: itens,
        ),
      );
      emit(state.copyWith(createGastoSubState: BlocSubState.completed(null)));
    } on DioException catch (e) {
      emit(state.copyWith(
        createGastoSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao registrar gasto', e, s);
      emit(state.copyWith(
        createGastoSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  Future<void> pagarGasto(String id) async {
    emit(state.copyWith(pagarGastoSubState: BlocSubState.loading));

    try {
      await _repository.pagarGasto(id);
      emit(state.copyWith(pagarGastoSubState: BlocSubState.completed(null)));
    } on DioException catch (e) {
      emit(state.copyWith(
        pagarGastoSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao marcar gasto como pago', e, s);
      emit(state.copyWith(
        pagarGastoSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  Future<void> deleteGasto(String id) async {
    emit(state.copyWith(deleteGastoSubState: BlocSubState.loading));

    try {
      await _repository.deleteGasto(id);
      emit(state.copyWith(deleteGastoSubState: BlocSubState.completed(null)));
    } on DioException catch (e) {
      emit(state.copyWith(
        deleteGastoSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao excluir gasto', e, s);
      emit(state.copyWith(
        deleteGastoSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }
}
