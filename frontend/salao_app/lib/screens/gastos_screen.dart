import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/gasto_provider.dart';
import '../models/atendimento.dart'; // Usando o modelo real da API
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  bool _semanaExpanded = true;

  @override
  void initState() {
    super.initState();
    // Carrega os dados assim que a tela abre
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GastoProvider>().carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GastoProvider>();
    final gastos = provider.gastos;

    if (provider.loading && gastos.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (provider.erro != null && gastos.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gastos')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
              const SizedBox(height: 12),
              Text('Erro: ${provider.erro}', style: const TextStyle(color: AppTheme.danger)),
              TextButton(
                onPressed: () => context.read<GastoProvider>().carregar(),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final pendentes = gastos.where((g) => !g.pago).toList();
    final pagos = gastos.where((g) => g.pago).toList();

    final totalPendente = pendentes.fold(0.0, (s, g) => s + g.valor);
    final totalPago = pagos.fold(0.0, (s, g) => s + g.valor);

    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),
      body: RefreshIndicator(
        onRefresh: () => context.read<GastoProvider>().carregar(),
        color: AppTheme.primary,
        child: Column(
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
                      value: formatBRL(totalPendente),
                      backgroundColor: AppTheme.dangerLight,
                      textColor: AppTheme.danger,
                      valueColor: AppTheme.danger,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricCard(
                      label: 'Pago no mês',
                      value: formatBRL(totalPago),
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
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (pendentes.isEmpty && pagos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          'Nenhum gasto registrado.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                  else ...[
                    // Seção pendentes
                    if (pendentes.isNotEmpty)
                      _SemanaSection(
                        titulo: 'Pendentes / Próximos',
                        gastos: pendentes,
                        isExpanded: _semanaExpanded,
                        onToggle: () => setState(() => _semanaExpanded = !_semanaExpanded),
                        onPagarToggle: (id) => context.read<GastoProvider>().marcarPago(id),
                      ),

                    if (pagos.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const SectionLabel('Já pagos'),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border, width: 0.5),
                        ),
                        child: Column(
                          children: pagos
                              .map((g) => _GastoTile(
                                    gasto: g,
                                    onToggle: () {
                                      // Se a API permitir desmarcar, chame aqui.
                                      // No momento, o Provider só tem "marcarPago".
                                    },
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
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
  final void Function(String id) onPagarToggle;

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
                      onToggle: () => onPagarToggle(g.id),
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

  Color _categoriaColor() {
    switch (gasto.categoria) {
      case CategoriaGasto.fixo:
        return AppTheme.danger;
      case CategoriaGasto.material:
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
                    gasto.nome, // Usando o modelo da API
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: gasto.pago ? AppTheme.textSecondary : AppTheme.textPrimary,
                      decoration: gasto.pago ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      AppTag(
                        label: gasto.categoria.name, // Usando enum
                        backgroundColor: _categoriaColor().withOpacity(0.1),
                        textColor: _categoriaColor(),
                      ),
                      const SizedBox(width: 6),
                      Text(gasto.formaPagamento.name, style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                      const SizedBox(width: 6),
                      Text('até ${gasto.prazoFormatado}', style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
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
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  String _forma = 'avista'; // Valores mapeados para o enum do backend
  String _cat = 'material';
  bool _salvando = false;

  DateTime _prazo = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _descCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvarGasto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    try {
      final valor = double.parse(_valorCtrl.text.replaceAll(',', '.'));

      await context.read<GastoProvider>().registrar(
            nome: _descCtrl.text.trim(),
            valor: valor,
            prazo: _prazo,
            formaPagamento: _forma,
            categoria: _cat,
          );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Form(
        key: _formKey,
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
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descrição'),
              validator: (v) => v!.isEmpty ? 'Informe a descrição' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _valorCtrl,
              decoration: const InputDecoration(labelText: 'Valor (R\$)', prefixText: 'R\$ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v!.isEmpty) return 'Informe o valor';
                if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Valor inválido';
                return null;
              },
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
                    value: _forma,
                    decoration: const InputDecoration(labelText: 'Pagamento'),
                    items: const [
                      DropdownMenuItem(value: 'avista', child: Text('À vista')),
                      DropdownMenuItem(value: 'credito', child: Text('Cartão de Crédito')),
                      DropdownMenuItem(value: 'debito', child: Text('Cartão de Débito')),
                      DropdownMenuItem(value: 'pix', child: Text('PIX')),
                    ],
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
                onPressed: _salvando ? null : _salvarGasto,
                child: _salvando ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Salvar gasto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
