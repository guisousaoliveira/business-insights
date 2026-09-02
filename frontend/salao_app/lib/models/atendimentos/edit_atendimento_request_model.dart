import 'servico_atendimento_model.dart';

/// Corpo do `PATCH /atendimentos/{id}` — cliente, data e serviços.
///
/// Materiais **não** entram aqui: quem mexe em material é a finalização, que é
/// a operação que dá baixa no estoque. Editar um atendimento nunca move saldo
/// de item.
class EditAtendimentoRequestModel {
  final String id;
  final String clienteNome;
  final String clienteTelefone;
  final DateTime data;
  final List<ServicoAtendimentoModel> servicos;

  const EditAtendimentoRequestModel({
    required this.id,
    required this.clienteNome,
    required this.clienteTelefone,
    required this.data,
    required this.servicos,
  });

  Map<String, dynamic> get toBody => {
        'cliente_nome': clienteNome,
        'cliente_telefone': clienteTelefone,
        'data': data.toIso8601String(),
        'servicos': servicos.map((e) => e.toBody).toList(),
      };
}
