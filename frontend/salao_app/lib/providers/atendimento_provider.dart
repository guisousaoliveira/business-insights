// ─────────────────────────────────────────────────────────────────────────────
// providers/atendimento_provider.dart
//
// Fluxo:
//   1. AtendimentosScreen chama provider.carregar()
//   2. Provider busca dados mockados em memória
//   3. notifyListeners() → widgets com context.watch() rebuildam
//   4. AtendimentoTile lê dados e renderiza collapsable
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/atendimento.dart';
import '../services/api_service.dart';

class AtendimentoProvider extends ChangeNotifier {
  List<Atendimento> _atendimentos = [];
  bool _loading = false;
  String? _erro;

  List<Atendimento> get atendimentos => _atendimentos;
  bool    get loading => _loading;
  String? get erro    => _erro;

  // Totais computados — usados nos chips rápidos da AppBar
  double get receitaTotal  => _atendimentos.fold(0.0, (a, x) => a + x.totalGanho);
  double get custosTotal   => _atendimentos.fold(0.0, (a, x) => a + x.totalMateriais);

  Future<void> carregar({DateTime? inicio, DateTime? fim}) async {
    _loading = true;
    _erro = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final ini = inicio ?? DateTime(now.year, now.month);
      final f   = fim    ?? DateTime(now.year, now.month + 1);

      _atendimentos = await ApiService.getAtendimentos(inicio: ini, fim: f);
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
    required List<Map<String, dynamic>> materiais,
  }) async {
    await ApiService.criarAtendimento(
      clienteNome:     clienteNome,
      clienteTelefone: clienteTelefone,
      data:            data,
      servicos:        servicos,
      materiais:       materiais,
    );
    await carregar();
  }
}
