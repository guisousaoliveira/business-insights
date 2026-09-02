import '../../settings/app_enums.dart';
import '../../settings/app_utils.dart';
import 'material_atendimento_model.dart';
import 'servico_atendimento_model.dart';

class AtendimentoModel {
  static const _idKey = 'id';
  static const _clienteNomeKey = 'cliente_nome';
  static const _clienteTelefoneKey = 'cliente_telefone';
  static const _dataKey = 'data';
  static const _statusKey = 'status';
  static const _servicosKey = 'servicos';
  static const _materiaisKey = 'materiais';
  static const _totalServicosKey = 'total_servicos';
  static const _totalMateriaisKey = 'total_materiais';
  static const _saldoKey = 'saldo';

  final String id;
  final String clienteNome;
  final String clienteTelefone;
  final DateTime data;
  final StatusAtendimento status;
  final List<ServicoAtendimentoModel> servicos;
  final List<MaterialAtendimentoModel> materiais;

  /// Totais **vêm calculados do servidor**: a mesma conta alimenta o resumo, o
  /// alerta e o n8n, e não pode divergir entre eles.
  final double totalServicos;
  final double totalMateriais;
  final double saldo;

  const AtendimentoModel({
    required this.id,
    required this.clienteNome,
    required this.clienteTelefone,
    required this.data,
    required this.status,
    required this.servicos,
    required this.materiais,
    required this.totalServicos,
    required this.totalMateriais,
    required this.saldo,
  });

  bool get isAgendado => status == StatusAtendimento.agendado;
  bool get isFinalizado => status == StatusAtendimento.finalizado;
  bool get isCancelado => status == StatusAtendimento.cancelado;

  factory AtendimentoModel.fromResponse(Map<String, dynamic> map) =>
      AtendimentoModel(
        id: map[_idKey] as String? ?? '',
        clienteNome: map[_clienteNomeKey] as String? ?? '',
        clienteTelefone: map[_clienteTelefoneKey] as String? ?? '',
        data:
            DateTime.tryParse(map[_dataKey] as String? ?? '') ?? DateTime.now(),
        status: AppUtils.decodeStatusAtendimento(map[_statusKey] as String?),
        servicos: (map[_servicosKey] as List? ?? const [])
            .map((e) =>
                ServicoAtendimentoModel.fromResponse(e as Map<String, dynamic>))
            .toList(),
        materiais: (map[_materiaisKey] as List? ?? const [])
            .map((e) => MaterialAtendimentoModel.fromResponse(
                e as Map<String, dynamic>))
            .toList(),
        totalServicos: (map[_totalServicosKey] as num?)?.toDouble() ?? 0,
        totalMateriais: (map[_totalMateriaisKey] as num?)?.toDouble() ?? 0,
        saldo: (map[_saldoKey] as num?)?.toDouble() ?? 0,
      );
}
