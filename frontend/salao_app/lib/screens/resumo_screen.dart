import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ResumoScreen extends StatelessWidget {
  const ResumoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Cálculos
    final totalServicos = atendimentosExemplo.fold(
        0.0, (s, a) => s + a.totalServicos);
    final totalInsumos = atendimentosExemplo.fold(
        0.0, (s, a) => s + a.totalInsumos);
    final totalGastos =
        gastosExemplo.fold(0.0, (s, g) => s + g.valor);
    final totalFixos =
        custosFixosExemplo.fold(0.0, (s, c) => s + c.valor);
    final totalEntrou = totalServicos - totalInsumos;
    final totalSaiu = totalGastos + totalFixos;
    final saldo = totalEntrou - totalSaiu;

    return Scaffold(
      appBar: AppBar(title: const Text('Resumo — maio 2025')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saldo principal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: saldo >= 0
                    ? AppTheme.successLight
                    : AppTheme.dangerLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo do mês',
                    style: TextStyle(
                      fontSize: 13,
                      color: saldo >= 0
                          ? AppTheme.success
                          : AppTheme.danger,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatBRL(saldo),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: saldo >= 0
                          ? AppTheme.success
                          : AppTheme.danger,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MiniMetric(
                          label: 'Entrou',
                          value: formatBRL(totalEntrou),
                          color: AppTheme.success),
                      const SizedBox(width: 16),
                      _MiniMetric(
                          label: 'Saiu',
                          value: formatBRL(totalSaiu),
                          color: AppTheme.danger),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Barra visual entrou vs saiu
            _ProgressBar(entrou: totalEntrou, saiu: totalSaiu),

            const SizedBox(height: 20),

            // Receita
            const SectionLabel('Receita de atendimentos'),
            _ResumoCard(
              items: [
                _ResumoItem('Serviços realizados', totalServicos,
                    isPositive: true),
                _ResumoItem('Insumos descartáveis', totalInsumos,
                    isNegative: true),
                _ResumoItem('Líquido de atendimentos', totalEntrou,
                    isTotal: true, isPositive: true),
              ],
            ),

            const SizedBox(height: 16),

            // Gastos
            const SectionLabel('Gastos do mês'),
            _ResumoCard(
              items: [
                _ResumoItem('Custos fixos (aluguel, etc.)', totalFixos,
                    isNegative: true),
                _ResumoItem('Compras e reposição', totalGastos,
                    isNegative: true),
                _ResumoItem('Total saiu', totalSaiu,
                    isTotal: true, isNegative: true),
              ],
            ),

            const SizedBox(height: 16),

            // Atendimentos por serviço
            const SectionLabel('Serviços mais realizados'),
            _ResumoCard(
              items: [
                _ResumoItem('Extensão de cílios', 360, isPositive: true,
                    label2: '2×'),
                _ResumoItem('Sobrancelha fio a fio', 120, isPositive: true,
                    label2: '1×'),
                _ResumoItem('Limpeza de pele', 150, isPositive: true,
                    label2: '1×'),
              ],
            ),

            const SizedBox(height: 24),

            // Aviso se está no zero
            if (saldo.abs() < 100)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.amberLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.amber.withOpacity(0.3), width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: AppTheme.amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Você está quase no zero a zero. Considere revisar a precificação dos serviços.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.amber,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniMetric(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
        Text(value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double entrou;
  final double saiu;

  const _ProgressBar({required this.entrou, required this.saiu});

  @override
  Widget build(BuildContext context) {
    final total = entrou + saiu;
    final frac = total == 0 ? 0.5 : (entrou / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              Expanded(
                flex: (frac * 100).round(),
                child: Container(
                    height: 8, color: AppTheme.success),
              ),
              Expanded(
                flex: ((1 - frac) * 100).round(),
                child: Container(
                    height: 8, color: AppTheme.dangerLight),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: AppTheme.success,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              const Text('Entrou',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
            ]),
            Row(children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: AppTheme.dangerLight,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              const Text('Saiu',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
            ]),
          ],
        ),
      ],
    );
  }
}

class _ResumoItem {
  final String label;
  final double valor;
  final bool isPositive;
  final bool isNegative;
  final bool isTotal;
  final String? label2;

  _ResumoItem(
    this.label,
    this.valor, {
    this.isPositive = false,
    this.isNegative = false,
    this.isTotal = false,
    this.label2,
  });
}

class _ResumoCard extends StatelessWidget {
  final List<_ResumoItem> items;

  const _ResumoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isLast = i == items.length - 1;

          Color valueColor = AppTheme.textPrimary;
          if (item.isPositive) valueColor = AppTheme.success;
          if (item.isNegative) valueColor = AppTheme.danger;

          return Container(
            decoration: BoxDecoration(
              color: item.isTotal
                  ? AppTheme.surfaceSecondary
                  : Colors.transparent,
              border: i > 0
                  ? const Border(
                      top: BorderSide(color: AppTheme.border, width: 0.5))
                  : null,
              borderRadius: isLast
                  ? const BorderRadius.vertical(
                      bottom: Radius.circular(12))
                  : (i == 0
                      ? const BorderRadius.vertical(
                          top: Radius.circular(12))
                      : null),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Text(item.label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: item.isTotal
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: AppTheme.textSecondary)),
                  if (item.label2 != null) ...[
                    const SizedBox(width: 6),
                    AppTag(
                      label: item.label2!,
                      backgroundColor: AppTheme.primaryLight,
                      textColor: AppTheme.primary,
                    ),
                  ],
                ]),
                Text(
                  '${item.isNegative ? '− ' : ''}${formatBRL(item.valor)}',
                  style: TextStyle(
                      fontSize: item.isTotal ? 15 : 13,
                      fontWeight: item.isTotal
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: valueColor),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
