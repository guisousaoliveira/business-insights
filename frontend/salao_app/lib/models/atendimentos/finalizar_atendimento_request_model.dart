import 'material_atendimento_model.dart';

/// Corpo da finalização. Os materiais com `item_estoque_id` são o que faz o
/// servidor dar baixa no estoque — regra de negócio que mora lá, não aqui.
class FinalizarAtendimentoRequestModel {
  static const _materiaisKey = 'materiais';
  static const _confirmarKey = 'confirmar_estoque_insuficiente';

  final String id;
  final List<MaterialAtendimentoModel> materiais;

  /// Segunda passada da finalização (§2 de `endpoints-backend.md`).
  ///
  /// O app manda `false` primeiro **sempre**. Se falta saldo, o servidor não
  /// grava nada e devolve `ESTOQUE_INSUFICIENTE` com a lista; a tela pergunta;
  /// se ela confirmar, a mesma chamada vai de novo com `true` e o saldo fica
  /// negativo.
  ///
  /// Não bloqueamos porque ela repõe **depois** de atender: travar o registro
  /// do atendimento por causa de um estoque desatualizado custaria o dado que
  /// sustenta todo o resumo financeiro.
  final bool confirmarEstoqueInsuficiente;

  const FinalizarAtendimentoRequestModel({
    required this.id,
    required this.materiais,
    this.confirmarEstoqueInsuficiente = false,
  });

  Map<String, dynamic> get toBody => {
        _materiaisKey: materiais.map((e) => e.toBody).toList(),
        _confirmarKey: confirmarEstoqueInsuficiente,
      };
}
