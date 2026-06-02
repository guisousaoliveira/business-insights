import 'package:flutter/material.dart';
import '../models/atendimento.dart';
import '../services/api_service.dart';

class AtendimentoProvider extends ChangeNotifier {
  List<Atendimento> _atendimentos = [];
  bool _loading = false;
  String? _erro;

  List<Atendimento> get atendimentos => _atendimentos;
  bool get loading => _loading;
  String? get erro => _erro;

  // Totais ignoram os cancelados automaticamente graças ao getter no modelo
  double get receitaTotal => _atendimentos.fold(0.0, (a, x) => a + x.totalGanho);
  double get custosTotal => _atendimentos.fold(0.0, (a, x) => a + x.totalMateriais);

  Future<void> carregar({DateTime? inicio, DateTime? fim}) async {
    _loading = true;
    _erro = null;
    notifyListeners();
    try {
      final now = DateTime.now();
      _atendimentos = await ApiService.getAtendimentos(inicio: inicio ?? DateTime(now.year, now.month), fim: fim ?? DateTime(now.year, now.month + 1));
    } catch (e) {
      _erro = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> criar({
    required String clienteNome,
    required String clienteTelefone,
    required DateTime data,
    required List<Map<String, dynamic>> servicos,
  }) async {
    // Passa a bola pro ApiService (que cria como agendado)
    await ApiService.criarAtendimento(
      clienteNome: clienteNome,
      clienteTelefone: clienteTelefone,
      data: data,
      servicos: servicos,
      materiais: [], // Nasce sem material pois é agendamento
    );
    await carregar(); // Recarrega a lista do banco
  }

  Future<void> cancelar(String id) async {
    await ApiService.cancelarAtendimento(id);
    await carregar();
  }

  Future<void> finalizar(String id, List<Map<String, dynamic>> materiais) async {
    await ApiService.finalizarAtendimento(id, materiais);
    await carregar();
  }
}
