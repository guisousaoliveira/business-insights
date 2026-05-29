// ─────────────────────────────────────────────────────────────────────────────
// screens/home_screen.dart — Painel Mensal (Fase 2)
//
// DRE simplificado do mês:
//   Receita de serviços
//   − Custo de materiais diretos
//   − Gastos variáveis lançados
//   − Custos fixos (aluguel + outros do perfil)
//   = Resultado líquido  ← cor e ícone indicativo
//
// + Banner de vencimentos nos próximos 7 dias
// + Total de atendimentos do mês
//
// Dados: RelatorioProvider → FastAPI /relatorio/mensal
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/relatorio_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final _cur = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RelatorioProvider>().carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RelatorioProvider>();
    final rel  = prov.relatorio;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel do mês'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<RelatorioProvider>().carregar(),
          ),
        ],
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.erro != null
              ? _Erro(prov.erro!)
              : rel == null
                  ? const Center(child: Text('Sem dados ainda'))
                  : RefreshIndicator(
                      onRefresh: () => context.read<RelatorioProvider>().carregar(),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _MesHeader(
                            mes:   rel.mes,
                            ano:   rel.ano,
                            total: rel.totalAtendimentos,
                          ),
                          const SizedBox(height: 16),
                          _ResultadoDestaque(
                            valor:      rel.resultadoLiquido,
                            isPositivo: rel.isPositivo,
                          ),
                          const SizedBox(height: 16),
                          _Linha('Receita de serviços',
                              _cur.format(rel.receitaServicos), true),
                          _Linha('Custo de materiais diretos',
                              '− ${_cur.format(rel.custoMateriais)}', false),
                          _Linha('Gastos variáveis',
                              '− ${_cur.format(rel.gastosVariaveis)}', false),
                          _Linha('Custos fixos (aluguel etc.)',
                              '− ${_cur.format(rel.custoFixos)}', false),
                          const Divider(height: 28),
                          if (rel.vencimentosProximos.isNotEmpty) ...[
                            const _Label('Vencimentos nos próximos 7 dias'),
                            const SizedBox(height: 8),
                            ...rel.vencimentosProximos.map(
                              (v) => _VencRow(v: v),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _MesHeader extends StatelessWidget {
  final int mes, ano, total;
  const _MesHeader({required this.mes, required this.ano, required this.total});

  static const _meses = [
    '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text('${_meses[mes]} $ano',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      Chip(
        label: Text('$total atendimentos'),
        backgroundColor: const Color(0xFFE1F5EE),
        labelStyle: const TextStyle(
            fontSize: 12, color: Color(0xFF085041), fontWeight: FontWeight.w500),
        padding: EdgeInsets.zero,
      ),
    ],
  );
}

class _ResultadoDestaque extends StatelessWidget {
  final double valor;
  final bool isPositivo;
  const _ResultadoDestaque({required this.valor, required this.isPositivo});
  static final _cur = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  Widget build(BuildContext context) {
    final cor  = isPositivo ? const Color(0xFF1D9E75) : const Color(0xFFA32D2D);
    final bg   = isPositivo ? const Color(0xFFE1F5EE) : const Color(0xFFFCEBEB);
    final icon = isPositivo ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(icon, color: cor, size: 28),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Resultado do mês',
              style: TextStyle(fontSize: 13, color: cor.withOpacity(.7))),
          Text(_cur.format(valor),
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700, color: cor)),
        ]),
      ]),
    );
  }
}

class _Linha extends StatelessWidget {
  final String label, valor;
  final bool pos;
  const _Linha(this.label, this.valor, this.pos);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Expanded(child: Text(label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF5A5A56)))),
      Text(valor, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
          color: pos ? const Color(0xFF1D9E75) : const Color(0xFFA32D2D))),
    ]),
  );
}

class _VencRow extends StatelessWidget {
  final Map<String, dynamic> v;
  const _VencRow({required this.v});
  static final _cur = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  Widget build(BuildContext context) {
    final prazo  = DateTime.parse(v['prazo_pagamento'] as String);
    final alerta = prazo.difference(DateTime.now()).inDays <= 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: alerta ? const Color(0xFFFAEEDA) : const Color(0xFFF9F9F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: alerta ? const Color(0xFFF5C05A) : Colors.grey.shade200),
      ),
      child: Row(children: [
        if (alerta) const Icon(Icons.warning_amber,
            size: 16, color: Color(0xFF854F0B)),
        if (alerta) const SizedBox(width: 6),
        Expanded(child: Text(v['nome'] as String,
            style: const TextStyle(fontSize: 13))),
        Text(_cur.format((v['valor'] as num).toDouble()),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Text('dia ${prazo.day.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF9A9A96))),
      ]),
    );
  }
}

class _Label extends StatelessWidget {
  final String t;
  const _Label(this.t);

  @override
  Widget build(BuildContext context) => Text(t.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          letterSpacing: .8, color: Color(0xFF9A9A96)));
}

class _Erro extends StatelessWidget {
  final String e;
  const _Erro(this.e);

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 40, color: Colors.red),
      const SizedBox(height: 8),
      Text(e, textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red)),
    ]),
  );
}
