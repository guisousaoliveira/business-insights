import 'servico_atendimento_model.dart';

class CreateAtendimentoRequestModel {
  final String clienteNome;
  final String clienteTelefone;
  final DateTime data;
  final List<ServicoAtendimentoModel> servicos;

  const CreateAtendimentoRequestModel({
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
