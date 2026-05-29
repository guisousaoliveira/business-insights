// ─────────────────────────────────────────────────────────────────────────────
// providers/gasto_provider.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/atendimento.dart';
import '../services/api_service.dart';

class GastoProvider extends ChangeNotifier {
  List<Gasto> _gastos = [];
  bool _loading = false;
  String? _erro;

  List<Gasto> get gastos   => _gastos;
  bool    get loading      => _loading;
  String? get erro         => _erro;

  // Gastos urgentes: vence em ≤ 3 dias e ainda não pago
  // Usados no banner de alerta da HomeScreen
  List<Gasto> get urgentes => _gastos.where((g) => g.venceEm3Dias).toList();

  Future<void> carregar({bool? apenasNaoPagos}) async {
    _loading = true;
    _erro = null;
    notifyListeners();

    try {
      _gastos = await ApiService.getGastos(apenasNaoPagos: apenasNaoPagos);
    } catch (e) {
      _erro = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> registrar({
    required String nome,
    required double valor,
    required DateTime prazo,
    required String formaPagamento,
    required String categoria,
    List<Map<String, dynamic>> itens = const [],
  }) async {
    await ApiService.registrarGasto(
      nome:            nome,
      valor:           valor,
      prazoPagamento:  prazo.toIso8601String().split('T').first,
      formaPagamento:  formaPagamento,
      categoria:       categoria,
      itens:           itens,
    );
    await carregar();
  }

  Future<void> marcarPago(String gastoId) async {
    await ApiService.marcarGastoPago(gastoId);
    await carregar();
  }
}
