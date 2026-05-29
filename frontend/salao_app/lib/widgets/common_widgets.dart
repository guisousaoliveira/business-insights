import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Chip de tag ────────────────────────────────────────────────────
class AppTag extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const AppTag({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

// ── Linha de detalhe chave-valor ───────────────────────────────────
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

// ── Card de métricas no topo ───────────────────────────────────────
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color backgroundColor;
  final Color textColor;
  final Color valueColor;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.textColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: textColor,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: valueColor)),
        ],
      ),
    );
  }
}

// ── Seção com título ───────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String title;

  const SectionLabel(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppTheme.textTertiary,
          letterSpacing: 0.08,
        ),
      ),
    );
  }
}

// ── Botão flutuante padrão ─────────────────────────────────────────
class AppFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const AppFAB({super.key, required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      label: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      icon: const Icon(Icons.add, size: 20),
    );
  }
}

// ── Formatação de moeda ─────────────────────────────────────────────
String formatBRL(double value) {
  return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

// ── Formatação de data ──────────────────────────────────────────────
String formatDate(DateTime date) {
  const months = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez'
  ];
  return '${date.day} ${months[date.month - 1]}';
}
