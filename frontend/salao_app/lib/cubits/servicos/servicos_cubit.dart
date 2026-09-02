import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/error_model.dart';
import '../../models/servicos/servico_model.dart';
import '../../repositories/app_repositories.dart';
import '../../repositories/servicos_repository.dart';
import '../../settings/app_logger.dart';
import '../bloc_substate.dart';

part 'servicos_state.dart';

/// A tabela de preços do salão. Alimenta a tela de Perfil **e** o diálogo de
/// agendamento — por isso é módulo próprio, e não parte de `perfil`.
class ServicosCubit extends Cubit<ServicosState> {
  ServicosCubit({ServicosRepository? repository})
      : _repository = repository ?? AppRepositories.servicos,
        super(const ServicosState());

  final ServicosRepository _repository;

  Future<void> getServicos() async {
    emit(state.copyWith(getServicosSubState: BlocSubState.loading));

    try {
      final response = await _repository.getServicos();
      emit(state.copyWith(
        getServicosSubState: BlocSubState.completed(response),
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        getServicosSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao buscar serviços', e, s);
      emit(state.copyWith(
        getServicosSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  Future<void> createServico({
    required String nome,
    required double preco,
    List<ProdutoPadraoModel> produtosPadrao = const [],
  }) async {
    emit(state.copyWith(createServicoSubState: BlocSubState.loading));

    try {
      await _repository.createServico(
        ServicoModel(
          id: '',
          nome: nome,
          preco: preco,
          produtosPadrao: produtosPadrao,
        ),
      );
      emit(state.copyWith(createServicoSubState: BlocSubState.completed(null)));
    } on DioException catch (e) {
      emit(state.copyWith(
        createServicoSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao criar serviço', e, s);
      emit(state.copyWith(
        createServicoSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  Future<void> deleteServico(String id) async {
    emit(state.copyWith(deleteServicoSubState: BlocSubState.loading));

    try {
      await _repository.deleteServico(id);
      emit(state.copyWith(deleteServicoSubState: BlocSubState.completed(null)));
    } on DioException catch (e) {
      emit(state.copyWith(
        deleteServicoSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao excluir serviço', e, s);
      emit(state.copyWith(
        deleteServicoSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }
}
