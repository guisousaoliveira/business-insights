import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/atendimentos/create_atendimento_request_model.dart';
import '../../models/atendimentos/finalizar_atendimento_request_model.dart';
import '../../models/atendimentos/material_atendimento_model.dart';
import '../../models/atendimentos/servico_atendimento_model.dart';
import '../../models/error_model.dart';
import '../../repositories/app_repositories.dart';
import '../../repositories/atendimentos_repository.dart';
import '../../settings/app_logger.dart';
import '../bloc_substate.dart';

part 'atendimentos_state.dart';

class AtendimentosCubit extends Cubit<AtendimentosState> {
  AtendimentosCubit({AtendimentosRepository? repository})
      : _repository = repository ?? AppRepositories.atendimentos,
        super(const AtendimentosState());

  final AtendimentosRepository _repository;

  Future<void> getAtendimentos({
    required DateTime inicio,
    required DateTime fim,
  }) async {
    emit(state.copyWith(getAtendimentosSubState: BlocSubState.loading));

    try {
      final response =
          await _repository.getAtendimentos(inicio: inicio, fim: fim);
      emit(state.copyWith(
        getAtendimentosSubState: BlocSubState.completed(response),
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        getAtendimentosSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao buscar atendimentos', e, s);
      emit(state.copyWith(
        getAtendimentosSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  Future<void> createAtendimento({
    required String clienteNome,
    required String clienteTelefone,
    required DateTime data,
    required List<ServicoAtendimentoModel> servicos,
  }) async {
    emit(state.copyWith(createAtendimentoSubState: BlocSubState.loading));

    try {
      await _repository.createAtendimento(
        CreateAtendimentoRequestModel(
          clienteNome: clienteNome,
          clienteTelefone: clienteTelefone,
          data: data,
          servicos: servicos,
        ),
      );
      emit(state.copyWith(
        createAtendimentoSubState: BlocSubState.completed(null),
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        createAtendimentoSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao criar atendimento', e, s);
      emit(state.copyWith(
        createAtendimentoSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  /// [confirmarEstoqueInsuficiente] só vem `true` na segunda tentativa, depois
  /// de a usuária confirmar no aviso. Ver `FinalizarAtendimentoRequestModel`.
  Future<void> finalizarAtendimento({
    required String id,
    required List<MaterialAtendimentoModel> materiais,
    bool confirmarEstoqueInsuficiente = false,
  }) async {
    emit(state.copyWith(finalizarAtendimentoSubState: BlocSubState.loading));

    try {
      await _repository.finalizarAtendimento(
        FinalizarAtendimentoRequestModel(
          id: id,
          materiais: materiais,
          confirmarEstoqueInsuficiente: confirmarEstoqueInsuficiente,
        ),
      );
      emit(state.copyWith(
        finalizarAtendimentoSubState: BlocSubState.completed(null),
      ));
    } on DioException catch (e) {
      // ESTOQUE_INSUFICIENTE chega aqui como qualquer outro erro, com a lista
      // de faltantes preservada em `ErrorModel.result`. Quem decide o que
      // fazer com ele é a tela — o cubit não abre diálogo.
      emit(state.copyWith(
        finalizarAtendimentoSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao finalizar atendimento', e, s);
      emit(state.copyWith(
        finalizarAtendimentoSubState:
            BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  Future<void> cancelarAtendimento(String id) async {
    emit(state.copyWith(cancelarAtendimentoSubState: BlocSubState.loading));

    try {
      await _repository.cancelarAtendimento(id);
      emit(state.copyWith(
        cancelarAtendimentoSubState: BlocSubState.completed(null),
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        cancelarAtendimentoSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao cancelar atendimento', e, s);
      emit(state.copyWith(
        cancelarAtendimentoSubState:
            BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }
}
