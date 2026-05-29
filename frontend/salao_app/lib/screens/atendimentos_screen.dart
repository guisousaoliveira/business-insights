import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AtendimentosScreen extends StatefulWidget {
  const AtendimentosScreen({super.key});

  @override
  State<AtendimentosScreen> createState() => _AtendimentosScreenState();
}

class _AtendimentosScreenState extends State<AtendimentosScreen> {
  final List<Atendimento> _atendimentos = atendimentosExemplo;
  final Set<String> _expanded = {};

  void _toggle(String id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalEntrou = _atendimentos.fold(0.0, (s, a) => s + a.saldo);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atendimentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner do mês
          Container(
            width: double.infinity,
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.successLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saldo líquido em maio',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.success)),
                      const SizedBox(height: 2),
                      Text(formatBRL(totalEntrou),
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.success)),
                    ],
                  ),
                  Text('${_atendimentos.length} atendimentos',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.success)),
                ],
              ),
            ),
          ),

          // Lista
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _atendimentos.length,
              itemBuilder: (context, i) {
                final a = _atendimentos[i];
                final isOpen = _expanded.contains(a.id);
                return _AtendimentoCard(
                  atendimento: a,
                  isExpanded: isOpen,
                  onTap: () => _toggle(a.id),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: AppFAB(
        label: 'Novo atendimento',
        onPressed: () => _showNovoAtendimento(context),
      ),
    );
  }

  void _showNovoAtendimento(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _NovoAtendimentoSheet(),
    );
  }
}

// ── Card colapsável ────────────────────────────────────────────────
class _AtendimentoCard extends StatelessWidget {
  final Atendimento atendimento;
  final bool isExpanded;
  final VoidCallback onTap;

  const _AtendimentoCard({
    required this.atendimento,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final a = atendimento;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        children: [
          // Cabeçalho clicável
          InkWell(
            onTap: onTap,
            borderRadius: isExpanded
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Avatar inicial
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: Center(
                      child: Text(
                        a.nomeCliente[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nome e data
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.nomeCliente,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 1),
                        Text(formatDate(a.data),
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  // Saldo
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatBRL(a.saldo),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.success)),
                      const SizedBox(height: 1),
                      const Text('líquido',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textTertiary)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down,
                        size: 20, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          // Conteúdo expandido
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: _AtendimentoDetalhe(atendimento: a),
          ),
        ],
      ),
    );
  }
}

class _AtendimentoDetalhe extends StatelessWidget {
  final Atendimento atendimento;

  const _AtendimentoDetalhe({required this.atendimento});

  @override
  Widget build(BuildContext context) {
    final a = atendimento;
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Telefone
          Row(
            children: [
              const Icon(Icons.phone_outlined,
                  size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(a.telefoneCliente,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),

          // Serviços
          const Text('Serviços',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textTertiary)),
          const SizedBox(height: 6),
          ...a.servicos.map((s) => DetailRow(
                label: s.nome,
                value: formatBRL(s.preco),
              )),
          const SizedBox(height: 4),
          DetailRow(
            label: 'Total serviços',
            value: formatBRL(a.totalServicos),
            valueColor: AppTheme.primary,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),

          // Insumos
          const Text('Insumos usados',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textTertiary)),
          const SizedBox(height: 6),
          ...a.insumos.map((i) => DetailRow(
                label: i.nome,
                value: '− ${formatBRL(i.preco)}',
                valueColor: AppTheme.danger,
              )),
          const SizedBox(height: 4),
          DetailRow(
            label: 'Total insumos',
            value: '− ${formatBRL(a.totalInsumos)}',
            valueColor: AppTheme.danger,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),

          // Saldo líquido
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.successLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Saldo líquido',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.success)),
                Text(formatBRL(a.saldo),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.success)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottomsheet novo atendimento ────────────────────────────────────
class _NovoAtendimentoSheet extends StatefulWidget {
  const _NovoAtendimentoSheet();

  @override
  State<_NovoAtendimentoSheet> createState() => _NovoAtendimentoSheetState();
}

class _NovoAtendimentoSheetState extends State<_NovoAtendimentoSheet> {
  final _nomeCtrl = TextEditingController();
  final _telCtrl = TextEditingController();

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
              const Text('Novo atendimento',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
            controller: _nomeCtrl,
            decoration: const InputDecoration(labelText: 'Nome do cliente'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _telCtrl,
            decoration: const InputDecoration(labelText: 'Telefone'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continuar'),
            ),
          ),
        ],
      ),
    );
  }
}
