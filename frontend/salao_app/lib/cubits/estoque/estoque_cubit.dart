import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/error_model.dart';
import '../../models/estoque/create_estoque_item_request_model.dart';
import '../../models/estoque/create_movimentacao_request_model.dart';
import '../../repositories/app_repositories.dart';
import '../../repositories/estoque_repository.dart';
import '../../settings/app_enums.dart';
import '../../settings/app_logger.dart';
import '../bloc_substate.dart';

part 'estoque_state.dart';

class EstoqueCubit extends Cubit<EstoqueState> {
  EstoqueCubit({EstoqueRepository? repository})
      : _repository = repository ?? AppRepositories.estoque,
        super(const EstoqueState());

  final EstoqueRepository _repository;

  Future<void> getItens() async {
    emit(state.copyWith(getItensSubState: state.getItensSubState.toLoading()));

    try {
      final response = await _repository.getItens();
      emit(state.copyWith(getItensSubState: BlocSubState.completed(response)));
    } on DioException catch (e) {
      emit(state.copyWith(
        getItensSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao buscar o estoque', e, s);
      emit(state.copyWith(
        getItensSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  Future<void> createItem({
    required String nome,
    required UnidadeEstoque unidade,
    required CategoriaEstoque categoria,
    required double quantidadeAtual,
    required double quantidadeMinima,
    required double custoUnitario,
  }) async {
    emit(state.copyWith(createItemSubState: BlocSubState.loading));

    try {
      await _repository.createItem(
        CreateEstoqueItemRequestModel(
          nome: nome,
          unidade: unidade,
          categoria: categoria,
          quantidadeAtual: quantidadeAtual,
          quantidadeMinima: quantidadeMinima,
          custoUnitario: custoUnitario,
        ),
      );
      emit(state.copyWith(createItemSubState: BlocSubState.completed(null)));
    } on DioException catch (e) {
      emit(state.copyWith(
        createItemSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao criar item de estoque', e, s);
      emit(state.copyWith(
        createItemSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  Future<void> registrarEntrada({
    required String itemId,
    required double quantidade,
    required String motivo,
    double? custoUnitario,
  }) async {
    emit(state.copyWith(createMovimentacaoSubState: BlocSubState.loading));

    try {
      await _repository.createMovimentacao(
        CreateMovimentacaoRequestModel(
          itemId: itemId,
          tipo: TipoMovimentacao.entrada,
          quantidade: quantidade,
          motivo: motivo,
          custoUnitario: custoUnitario,
        ),
      );
      emit(state.copyWith(
        createMovimentacaoSubState: BlocSubState.completed(null),
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        createMovimentacaoSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao registrar entrada de estoque', e, s);
      emit(state.copyWith(
        createMovimentacaoSubState:
            BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  Future<void> getMovimentacoes({String? itemId}) async {
    emit(state.copyWith(
        getMovimentacoesSubState: state.getMovimentacoesSubState.toLoading()));

    try {
      final response = await _repository.getMovimentacoes(itemId: itemId);
      emit(state.copyWith(
        getMovimentacoesSubState: BlocSubState.completed(response),
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        getMovimentacoesSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao buscar movimentações', e, s);
      emit(state.copyWith(
        getMovimentacoesSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  Future<void> deleteItem(String id) async {
    emit(state.copyWith(deleteItemSubState: BlocSubState.loading));

    try {
      await _repository.deleteItem(id);
      emit(state.copyWith(deleteItemSubState: BlocSubState.completed(null)));
    } on DioException catch (e) {
      emit(state.copyWith(
        deleteItemSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao excluir item de estoque', e, s);
      emit(state.copyWith(
        deleteItemSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }
}
