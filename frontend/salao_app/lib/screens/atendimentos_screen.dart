import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salon_app/providers/atendimento_provider.dart';
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
                      const Text('Saldo líquido em maio', style: TextStyle(fontSize: 12, color: AppTheme.success)),
                      const SizedBox(height: 2),
                      Text(formatBRL(totalEntrou), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppTheme.success)),
                    ],
                  ),
                  Text('${_atendimentos.length} atendimentos', style: const TextStyle(fontSize: 12, color: AppTheme.success)),
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
      builder: (_) => const _FormAtendimento(),
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
            borderRadius: isExpanded ? const BorderRadius.vertical(top: Radius.circular(12)) : BorderRadius.circular(12),
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
                        Text(a.nomeCliente, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 1),
                        Text(formatDate(a.data), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  // Saldo
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatBRL(a.saldo), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.success)),
                      const SizedBox(height: 1),
                      const Text('líquido', style: TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          // Conteúdo expandido
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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
              const Icon(Icons.phone_outlined, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(a.telefoneCliente, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),

          // Serviços
          const Text('Serviços', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textTertiary)),
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
          const Text('Insumos usados', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textTertiary)),
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
                const Text('Saldo líquido', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.success)),
                Text(formatBRL(a.saldo), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.success)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottomsheet novo atendimento ────────────────────────────────────
class _FormAtendimento extends StatefulWidget {
  const _FormAtendimento();

  @override
  State<_FormAtendimento> createState() => _FormAtendimentoState();
}

class _FormAtendimentoState extends State<_FormAtendimento> {
  final _key = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _tel = TextEditingController();

  // Listas dinâmicas — cada _IC tem controllers de nome e preço
  final List<_IC> _servs = [_IC()];
  final List<_IC> _mats = [];

  DateTime _data = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _nome.dispose();
    _tel.dispose();
    for (final ic in [..._servs, ..._mats]) {
      ic.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Novo atendimento', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 16),

              // Cliente
              TextFormField(
                controller: _nome,
                decoration: const InputDecoration(labelText: 'Nome do cliente', border: OutlineInputBorder()),
                validator: (v) => (v?.isEmpty ?? true) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _tel,
                decoration: const InputDecoration(labelText: 'WhatsApp (opcional)', border: OutlineInputBorder(), prefixText: '+55 '),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),

              // Data
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, size: 18),
                title: Text(DateFormat('dd/MM/yyyy', 'pt_BR').format(_data)),
                subtitle: const Text('Data do atendimento'),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _data,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _data = d);
                },
              ),
              const Divider(),

              // Serviços
              _SecRow('Serviços', onAdd: () => setState(() => _servs.add(_IC()))),
              ..._servs.asMap().entries.map((e) => _ItemRow(
                    ic: e.value,
                    label: 'Serviço ${e.key + 1}',
                    onRemove: _servs.length > 1
                        ? () => setState(() {
                              e.value.dispose();
                              _servs.removeAt(e.key);
                            })
                        : null,
                  )),
              const Divider(),

              // Materiais
              _SecRow('Materiais utilizados', onAdd: () => setState(() => _mats.add(_IC()))),
              if (_mats.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Nenhum material adicionado', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                )
              else
                ..._mats.asMap().entries.map((e) => _ItemRow(
                      ic: e.value,
                      label: 'Material ${e.key + 1}',
                      onRemove: () => setState(() {
                        e.value.dispose();
                        _mats.removeAt(e.key);
                      }),
                    )),
              const SizedBox(height: 16),

              // Salvar
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _salvar,
                  child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Salvar atendimento'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<AtendimentoProvider>().criar(
            clienteNome: _nome.text.trim(),
            clienteTelefone: _tel.text.trim(),
            data: _data,
            servicos: _servs
                .map((ic) => {
                      'nome': ic.n.text.trim(),
                      'preco': double.tryParse(ic.p.text) ?? 0.0,
                    })
                .toList(),
            materiais: _mats
                .map((ic) => {
                      'nome': ic.n.text.trim(),
                      'preco': double.tryParse(ic.p.text) ?? 0.0,
                    })
                .toList(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _IC {
  final n = TextEditingController(); // nome
  final p = TextEditingController(); // preço
  void dispose() {
    n.dispose();
    p.dispose();
  }
}

class _ItemRow extends StatelessWidget {
  final _IC ic;
  final String label;
  final VoidCallback? onRemove;
  const _ItemRow({required this.ic, required this.label, this.onRemove});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: ic.n,
              decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
              validator: (v) => (v?.isEmpty ?? true) ? 'Informe o nome' : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: ic.p,
              decoration: const InputDecoration(labelText: 'R\$', border: OutlineInputBorder(), isDense: true),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Informe';
                if (double.tryParse(v!) == null) return 'Inválido';
                return null;
              },
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: onRemove,
            ),
        ]),
      );
}

class _SecRow extends StatelessWidget {
  final String titulo;
  final VoidCallback onAdd;
  const _SecRow(this.titulo, {required this.onAdd});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(titulo.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: .8, color: Color(0xFF9A9A96))),
          TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, size: 16), label: const Text('Adicionar', style: TextStyle(fontSize: 12))),
        ]),
      );
}

class _Chip extends StatelessWidget {
  final String label, valor;
  final bool pos;
  const _Chip(this.label, this.valor, this.pos);

  @override
  Widget build(BuildContext context) {
    final cor = pos ? const Color(0xFF1D9E75) : const Color(0xFFA32D2D);
    final bg = pos ? const Color(0xFFE1F5EE) : const Color(0xFFFCEBEB);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text('$label: $valor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cor)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.content_cut, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Nenhum atendimento este mês', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          Text('Toque em + para registrar', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ]),
      );
}
