import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/error_model.dart';
import '../../models/kits/kit_model.dart';
import '../../repositories/app_repositories.dart';
import '../../repositories/kits_repository.dart';
import '../../settings/app_enums.dart';
import '../../settings/app_logger.dart';
import '../bloc_substate.dart';

part 'kits_state.dart';

/// Módulo próprio, e não parte de `estoque`, porque juntos passariam de ~8
/// operações — módulo é unidade de dado, não de tela (ambos aparecem na tela de
/// Estoque).
class KitsCubit extends Cubit<KitsState> {
  KitsCubit({KitsRepository? repository})
      : _repository = repository ?? AppRepositories.kits,
        super(const KitsState());

  final KitsRepository _repository;

  Future<void> getKits() async {
    emit(state.copyWith(getKitsSubState: state.getKitsSubState.toLoading()));

    try {
      final response = await _repository.getKits();
      emit(state.copyWith(getKitsSubState: BlocSubState.completed(response)));
    } on DioException catch (e) {
      emit(state.copyWith(
        getKitsSubState: BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao buscar kits', e, s);
      emit(state.copyWith(
        getKitsSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  Future<void> createKit({
    required String nome,
    required double precoVenda,
    required List<KitItemModel> itens,
  }) async {
    emit(state.copyWith(createKitSubState: BlocSubState.loading));

    try {
      await _repository.createKit(
        nome: nome,
        precoVenda: precoVenda,
        itens: itens,
      );
      emit(state.copyWith(createKitSubState: BlocSubState.completed(null)));
    } on DioException catch (e) {
      emit(state.copyWith(
        createKitSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao criar kit', e, s);
      emit(state.copyWith(
        createKitSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  Future<void> deleteKit(String id) async {
    emit(state.copyWith(deleteKitSubState: BlocSubState.loading));

    try {
      await _repository.deleteKit(id);
      emit(state.copyWith(deleteKitSubState: BlocSubState.completed(null)));
    } on DioException catch (e) {
      emit(state.copyWith(
        deleteKitSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao excluir kit', e, s);
      emit(state.copyWith(
        deleteKitSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  /// Consome os insumos e soma ao saldo de kits prontos.
  ///
  /// Passa pelo mesmo protocolo de duas passadas da finalização de atendimento:
  /// sem [confirmarEstoqueInsuficiente] o servidor recusa com
  /// `ESTOQUE_INSUFICIENTE` sem gravar nada; quem decide se insiste é a tela.
  Future<void> montarKit({
    required String id,
    required double quantidade,
    bool confirmarEstoqueInsuficiente = false,
  }) async {
    emit(state.copyWith(montarKitSubState: BlocSubState.loading));

    try {
      await _repository.montarKit(
        id: id,
        quantidade: quantidade,
        confirmarEstoqueInsuficiente: confirmarEstoqueInsuficiente,
      );
      emit(state.copyWith(montarKitSubState: BlocSubState.completed(null)));
    } on DioException catch (e) {
      emit(state.copyWith(
        montarKitSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao montar kit', e, s);
      emit(state.copyWith(
        montarKitSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }

  /// Baixa do saldo de kits montados e grava a receita.
  ///
  /// Diferente de [montarKit], não tem segunda passada: vender mais do que está
  /// montado devolve `KIT_NAO_MONTADO` e para por aí — um kit que não foi
  /// montado não existe para ser vendido.
  Future<void> venderKit({
    required String id,
    required double quantidade,
    required FormaPagamento formaPagamento,
    double? precoUnitario,
  }) async {
    emit(state.copyWith(venderKitSubState: BlocSubState.loading));

    try {
      await _repository.venderKit(
        id: id,
        quantidade: quantidade,
        formaPagamento: formaPagamento,
        precoUnitario: precoUnitario,
      );
      emit(state.copyWith(venderKitSubState: BlocSubState.completed(null)));
    } on DioException catch (e) {
      emit(state.copyWith(
        venderKitSubState:
            BlocSubState.completed(ErrorModel.fromDioException(e)),
      ));
    } catch (e, s) {
      AppLogger.error('Falha inesperada ao vender kit', e, s);
      emit(state.copyWith(
        venderKitSubState: BlocSubState.completed(ErrorModel.generic()),
      ));
    }
  }
}
