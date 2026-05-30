import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  final List<Gasto> _gastos = gastosExemplo;
  bool _semanaExpanded = true;

  double get _totalPendente => _gastos.where((g) => !g.pago).fold(0.0, (s, g) => s + g.valor);

  double get _totalPago => _gastos.where((g) => g.pago).fold(0.0, (s, g) => s + g.valor);

  @override
  Widget build(BuildContext context) {
    final pendentes = _gastos.where((g) => !g.pago).toList();
    final pagos = _gastos.where((g) => g.pago).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),
      body: Column(
        children: [
          // Métricas topo
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: MetricCard(
                    label: 'Pendente',
                    value: formatBRL(_totalPendente),
                    backgroundColor: AppTheme.dangerLight,
                    textColor: AppTheme.danger,
                    valueColor: AppTheme.danger,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricCard(
                    label: 'Pago em maio',
                    value: formatBRL(_totalPago),
                    backgroundColor: AppTheme.successLight,
                    textColor: AppTheme.success,
                    valueColor: AppTheme.success,
                  ),
                ),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Seção pendentes
                _SemanaSection(
                  titulo: 'Semana 12–18 mai',
                  gastos: pendentes,
                  isExpanded: _semanaExpanded,
                  onToggle: () => setState(() => _semanaExpanded = !_semanaExpanded),
                  onPagarToggle: (id, valor) {
                    setState(() {
                      final idx = _gastos.indexWhere((g) => g.id == id);
                      if (idx != -1) {
                        final g = _gastos[idx];
                        _gastos[idx] = Gasto(
                          id: g.id,
                          descricao: g.descricao,
                          valor: g.valor,
                          prazo: g.prazo,
                          formaPagamento: g.formaPagamento,
                          prioridade: g.prioridade,
                          pago: !g.pago,
                        );
                      }
                    });
                  },
                ),

                if (pagos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const SectionLabel('Já pagos'),
                  ...pagos.map((g) => _GastoTile(
                        gasto: g,
                        onToggle: () {
                          setState(() {
                            final idx = _gastos.indexWhere((x) => x.id == g.id);
                            if (idx != -1) {
                              final old = _gastos[idx];
                              _gastos[idx] = Gasto(
                                id: old.id,
                                descricao: old.descricao,
                                valor: old.valor,
                                prazo: old.prazo,
                                formaPagamento: old.formaPagamento,
                                prioridade: old.prioridade,
                                pago: !old.pago,
                              );
                            }
                          });
                        },
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AppFAB(
        label: 'Novo gasto',
        onPressed: () => _showNovoGasto(context),
      ),
    );
  }

  void _showNovoGasto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _NovoGastoSheet(),
    );
  }
}

// ── Seção semanal colapsável ────────────────────────────────────────
class _SemanaSection extends StatelessWidget {
  final String titulo;
  final List<Gasto> gastos;
  final bool isExpanded;
  final VoidCallback onToggle;
  final void Function(String id, double valor) onPagarToggle;

  const _SemanaSection({
    required this.titulo,
    required this.gastos,
    required this.isExpanded,
    required this.onToggle,
    required this.onPagarToggle,
  });

  @override
  Widget build(BuildContext context) {
    final total = gastos.fold(0.0, (s, g) => s + g.valor);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onToggle,
            borderRadius: isExpanded ? const BorderRadius.vertical(top: Radius.circular(12)) : BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, size: 18, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                  Text(formatBRL(total), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.danger)),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 0),
                ...gastos.map((g) => _GastoTile(
                      gasto: g,
                      onToggle: () => onPagarToggle(g.id, g.valor),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile de gasto ──────────────────────────────────────────────────
class _GastoTile extends StatelessWidget {
  final Gasto gasto;
  final VoidCallback onToggle;

  const _GastoTile({required this.gasto, required this.onToggle});

  Color _prioridadeColor() {
    switch (gasto.prioridade) {
      case 'alta':
        return AppTheme.danger;
      case 'média':
        return AppTheme.amber;
      default:
        return AppTheme.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: gasto.pago ? AppTheme.surfaceSecondary : AppTheme.surface,
        border: const Border(
          top: BorderSide(color: AppTheme.border, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Checkbox estilizado
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: gasto.pago ? AppTheme.success : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: gasto.pago ? AppTheme.success : AppTheme.border,
                    width: 1.5,
                  ),
                ),
                child: gasto.pago ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
            ),
            const SizedBox(width: 10),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gasto.descricao,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: gasto.pago ? AppTheme.textSecondary : AppTheme.textPrimary,
                      decoration: gasto.pago ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      AppTag(
                        label: gasto.prioridade,
                        backgroundColor: _prioridadeColor().withOpacity(0.1),
                        textColor: _prioridadeColor(),
                      ),
                      const SizedBox(width: 6),
                      Text(gasto.formaPagamento, style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                      const SizedBox(width: 6),
                      Text('até ${formatDate(gasto.prazo)}', style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                    ],
                  ),
                ],
              ),
            ),

            // Valor
            Text(
              formatBRL(gasto.valor),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: gasto.pago ? AppTheme.textSecondary : AppTheme.danger,
                decoration: gasto.pago ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottomsheet novo gasto ─────────────────────────────────────────
class _NovoGastoSheet extends StatefulWidget {
  const _NovoGastoSheet();

  @override
  State<_NovoGastoSheet> createState() => _NovoGastoSheetState();
}

class _NovoGastoSheetState extends State<_NovoGastoSheet> {
  final _descCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  String _prioridade = 'alta';
  String _forma = 'à vista';
  String _cat = 'material';

  DateTime _prazo = DateTime.now().add(const Duration(days: 7));

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Novo gasto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Descrição'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _valorCtrl,
            decoration: const InputDecoration(labelText: 'Valor (R\$)', prefixText: 'R\$ '),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, size: 18),
            title: Text('Prazo: ${DateFormat('dd/MM/yyyy', 'pt_BR').format(_prazo)}'),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _prazo,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (d != null) setState(() => _prazo = d);
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _prioridade,
                  decoration: const InputDecoration(labelText: 'Prioridade'),
                  items: ['alta', 'média', 'baixa'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setState(() => _prioridade = v!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _forma,
                  decoration: const InputDecoration(labelText: 'Pagamento'),
                  items: ['à vista', 'cartão'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) => setState(() => _forma = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _cat,
            decoration: const InputDecoration(labelText: 'Categoria', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'material', child: Text('Material / reposição')),
              DropdownMenuItem(value: 'fixo', child: Text('Custo fixo')),
              DropdownMenuItem(value: 'outros', child: Text('Outros')),
            ],
            onChanged: (v) => setState(() => _cat = v!),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Salvar gasto'),
            ),
          ),
        ],
      ),
    );
  }
}
