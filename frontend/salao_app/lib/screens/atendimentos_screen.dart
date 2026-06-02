import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart' hide Atendimento, Gasto;
import '../models/atendimento.dart';

import '../providers/atendimento_provider.dart';
import '../providers/perfil_provider.dart';
import '../providers/estoque_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AtendimentosScreen extends StatefulWidget {
  const AtendimentosScreen({super.key});

  @override
  State<AtendimentosScreen> createState() => _AtendimentosScreenState();
}

class _AtendimentosScreenState extends State<AtendimentosScreen> {
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AtendimentoProvider>().carregar();
    });
  }

  void _toggle(String id) {
    setState(() {
      if (_expanded.contains(id))
        _expanded.remove(id);
      else
        _expanded.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AtendimentoProvider>();
    // Filtramos os cancelados da métrica visual do topo
    final atendimentosValidos = provider.atendimentos.where((a) => !a.isCancelado).toList();
    final totalEntrou = atendimentosValidos.fold(0.0, (s, a) => s + a.lucroBruto);

    return Scaffold(
      appBar: AppBar(title: const Text('Atendimentos')),
      body: RefreshIndicator(
        onRefresh: () => context.read<AtendimentoProvider>().carregar(),
        color: AppTheme.primary,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppTheme.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: AppTheme.successLight, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saldo líquido no período', style: TextStyle(fontSize: 12, color: AppTheme.success)),
                        const SizedBox(height: 2),
                        Text(formatBRL(totalEntrou), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppTheme.success)),
                      ],
                    ),
                    Text('${atendimentosValidos.length} atend.', style: const TextStyle(fontSize: 12, color: AppTheme.success)),
                  ],
                ),
              ),
            ),
            Expanded(child: _buildContent(provider)),
          ],
        ),
      ),
      floatingActionButton: AppFAB(
        label: 'Agendar',
        onPressed: () => _showNovoAtendimento(context),
      ),
    );
  }

  Widget _buildContent(AtendimentoProvider provider) {
    if (provider.loading && provider.atendimentos.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (provider.atendimentos.isEmpty) return const _EmptyState();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: provider.atendimentos.length,
      itemBuilder: (context, i) {
        final a = provider.atendimentos[i];
        return _AtendimentoCard(
          atendimento: a,
          isExpanded: _expanded.contains(a.id),
          onTap: () => _toggle(a.id),
        );
      },
    );
  }

  void _showNovoAtendimento(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => const _FormAgendamento(),
    );
  }
}

// ── Card colapsável ────────────────────────────────────────────────
class _AtendimentoCard extends StatelessWidget {
  final Atendimento atendimento;
  final bool isExpanded;
  final VoidCallback onTap;

  const _AtendimentoCard({required this.atendimento, required this.isExpanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = atendimento;

    // Configura a cor de fundo baseado no status
    Color bgColor = AppTheme.surface;
    if (a.isAgendado) bgColor = AppTheme.amberLight.withOpacity(0.3);
    if (a.isCancelado) bgColor = AppTheme.surfaceSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: isExpanded ? const BorderRadius.vertical(top: Radius.circular(12)) : BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: a.isCancelado ? AppTheme.border : (a.isAgendado ? AppTheme.amberLight : AppTheme.primaryLight),
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: Center(
                      child: Text(
                        a.clienteNome.isNotEmpty ? a.clienteNome[0].toUpperCase() : '?',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: a.isCancelado ? AppTheme.textSecondary : (a.isAgendado ? AppTheme.amber : AppTheme.primary)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(a.clienteNome, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, decoration: a.isCancelado ? TextDecoration.lineThrough : null, color: a.isCancelado ? AppTheme.textTertiary : AppTheme.textPrimary)),
                            const SizedBox(width: 6),
                            if (a.isAgendado) const AppTag(label: 'Agendado', backgroundColor: AppTheme.amberLight, textColor: AppTheme.amber),
                            if (a.isCancelado) const AppTag(label: 'Cancelado', backgroundColor: AppTheme.surfaceSecondary, textColor: AppTheme.textTertiary),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(a.dataFormatada, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  if (!a.isCancelado)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatBRL(a.lucroBruto), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.success)),
                        const SizedBox(height: 1),
                        Text(a.isAgendado ? 'previsto' : 'líquido', style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
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

  void _confirmarCancelamento(BuildContext context) {
    showDialog(
        context: context,
        builder: (c) => AlertDialog(
              title: const Text('Cancelar atendimento?', style: TextStyle(fontSize: 16)),
              content: const Text('O atendimento será cancelado e nenhum insumo será cobrado do estoque.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c), child: const Text('Voltar')),
                TextButton(
                    onPressed: () {
                      context.read<AtendimentoProvider>().cancelar(atendimento.id);
                      Navigator.pop(c);
                    },
                    child: const Text('Sim, cancelar', style: TextStyle(color: AppTheme.danger))),
              ],
            ));
  }

  void _showFinalizarSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _FinalizarAtendimentoSheet(atendimento: atendimento),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = atendimento;
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.border, width: 0.5))),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (a.clienteTelefone.isNotEmpty) ...[
            Row(children: [const Icon(Icons.phone_outlined, size: 14, color: AppTheme.textSecondary), const SizedBox(width: 6), Text(a.clienteTelefone, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))]),
            const SizedBox(height: 12),
          ],

          const Text('Serviços', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textTertiary)),
          const SizedBox(height: 6),
          ...a.servicos.map((s) => DetailRow(label: s.nome, value: formatBRL(s.preco))),
          const SizedBox(height: 4),
          DetailRow(label: 'Total serviços', value: formatBRL(a.totalGanho), valueColor: a.isCancelado ? AppTheme.textTertiary : AppTheme.primary),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),

          // Mostrar materiais apenas se estiver finalizado
          if (a.isFinalizado) ...[
            const Text('Materiais usados', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textTertiary)),
            const SizedBox(height: 6),
            if (a.materiais.isEmpty)
              const Text('Nenhum material listado.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary))
            else ...[
              ...a.materiais.map((m) => DetailRow(label: m.nome, value: '− ${formatBRL(m.preco)}', valueColor: AppTheme.danger)),
              const SizedBox(height: 4),
              DetailRow(label: 'Total materiais', value: '− ${formatBRL(a.totalMateriais)}', valueColor: AppTheme.danger),
            ],
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppTheme.successLight, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Saldo líquido', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.success)),
                  Text(formatBRL(a.lucroBruto), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.success)),
                ],
              ),
            ),
          ],

          // Botões de Ação para atendimentos AGENDADOS
          if (a.isAgendado)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _confirmarCancelamento(context),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger, side: const BorderSide(color: AppTheme.dangerLight)),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _showFinalizarSheet(context),
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.success),
                    child: const Text('Finalizar'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── 1. SHEET DE AGENDAMENTO (Cria apenas o compromisso) ────────────
class _FormAgendamento extends StatefulWidget {
  const _FormAgendamento();
  @override
  State<_FormAgendamento> createState() => _FormAgendamentoState();
}

class _FormAgendamentoState extends State<_FormAgendamento> {
  final _key = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _tel = TextEditingController();
  final List<_SelecaoServico> _servs = [_SelecaoServico()];
  DateTime _data = DateTime.now(); // Variável da data aqui
  bool _saving = false;

  @override
  void dispose() {
    _nome.dispose();
    _tel.dispose();
    for (var s in _servs) {
      s.precoCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<AtendimentoProvider>().criar(
            clienteNome: _nome.text.trim(),
            clienteTelefone: _tel.text.trim(),
            data: _data, // Envia a data selecionada
            servicos: _servs
                .where((s) => s.servico != null)
                .map((s) => {
                      'nome': s.servico!.nome,
                      'preco': double.tryParse(s.precoCtrl.text.replaceAll(',', '.')) ?? 0.0,
                    })
                .toList(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listaServicos = context.read<PerfilProvider>().servicos;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Agendar Atendimento', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 16),

              TextFormField(controller: _nome, decoration: const InputDecoration(labelText: 'Nome do cliente', border: OutlineInputBorder()), validator: (v) => (v?.isEmpty ?? true) ? 'Informe o nome' : null),
              const SizedBox(height: 10),

              // 🔴 BOTÃO DA DATA VOLTOU AQUI 🔴
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
                    lastDate: DateTime.now().add(const Duration(days: 365)), // Permite agendar 1 ano pra frente
                  );
                  if (d != null) setState(() => _data = d);
                },
              ),
              const Divider(),

              _SecRow('Serviços previstos', onAdd: () => setState(() => _servs.add(_SelecaoServico()))),
              ..._servs.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(children: [
                      Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<Servico>(
                            decoration: const InputDecoration(labelText: 'Serviço', isDense: true, border: OutlineInputBorder()),
                            value: e.value.servico,
                            items: listaServicos.map((s) => DropdownMenuItem(value: s, child: Text(s.nome, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (v) {
                              setState(() {
                                e.value.servico = v;
                                if (v != null) e.value.precoCtrl.text = v.preco.toStringAsFixed(2);
                              });
                            },
                          )),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: TextFormField(controller: e.value.precoCtrl, decoration: const InputDecoration(labelText: 'R\$ Cobrado', isDense: true, border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                      if (_servs.length > 1) IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppTheme.danger), onPressed: () => setState(() => _servs.removeAt(e.key))),
                    ]),
                  )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _salvar,
                  child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Confirmar Agendamento'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 2. SHEET DE FINALIZAÇÃO (Confirma insumos e dá baixa) ───────────
class _FinalizarAtendimentoSheet extends StatefulWidget {
  final Atendimento atendimento;
  const _FinalizarAtendimentoSheet({required this.atendimento});

  @override
  State<_FinalizarAtendimentoSheet> createState() => _FinalizarAtendimentoSheetState();
}

class _FinalizarAtendimentoSheetState extends State<_FinalizarAtendimentoSheet> {
  final _key = GlobalKey<FormState>(); // 🔴 Adicionado o controle de formulário
  final List<_SelecaoMaterial> _mats = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final estoque = context.read<EstoqueProvider>().itens;
      final servicosDoPerfil = context.read<PerfilProvider>().servicos;

      for (var sAtend in widget.atendimento.servicos) {
        final servicoOriginal = servicosDoPerfil.where((s) => s.nome == sAtend.nome).firstOrNull;
        if (servicoOriginal != null && servicoOriginal.produtosPadrao.isNotEmpty) {
          for (var prod in servicoOriginal.produtosPadrao) {
            try {
              final itemEstoque = estoque.firstWhere((i) => i.id == prod.produtoId);
              final mat = _SelecaoMaterial();
              mat.produto = itemEstoque;
              mat.precoOuQtdCtrl.text = prod.quantidade.toStringAsFixed(0);
              _mats.add(mat);
            } catch (_) {}
          }
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    for (var m in _mats) {
      m.precoOuQtdCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _salvarFinal() async {
    // 🔴 Verifica se ela não digitou mais do que tem no estoque!
    if (!_key.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final materiaisFinais = _mats
          .where((m) => m.produto != null)
          .map((m) => {
                'nome': m.produto!.nome,
                'quantidade': double.tryParse(m.precoOuQtdCtrl.text.replaceAll(',', '.')) ?? 0.0,
                'preco': (double.tryParse(m.precoOuQtdCtrl.text.replaceAll(',', '.')) ?? 0.0) * m.produto!.custoUnitario,
              })
          .toList();

      await context.read<AtendimentoProvider>().finalizar(widget.atendimento.id, materiaisFinais);
      await context.read<EstoqueProvider>().registrarSaidaList(materiaisFinais, widget.atendimento.clienteNome);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔴 SÓ LISTA O QUE TEM QUANTIDADE MAIOR QUE ZERO
    final listaEstoque = context.read<EstoqueProvider>().itens.where((i) => i.ativo && i.quantidadeAtual > 0).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        // 🔴 Formulário encapsulado aqui
        key: _key,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Finalizar Atendimento', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Confirme os insumos utilizados. Itens sem estoque não aparecem na lista.', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
              ),
              _SecRow('Materiais consumidos', onAdd: () => setState(() => _mats.add(_SelecaoMaterial()))),
              if (_mats.isEmpty)
                Padding(padding: const EdgeInsets.only(bottom: 16), child: Text('Nenhum material carregado', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)))
              else
                ..._mats.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start, // Para alinhar o erro do validador
                          children: [
                            Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<ItemEstoque>(
                                  decoration: const InputDecoration(labelText: 'Produto do estoque', isDense: true, border: OutlineInputBorder()),
                                  value: e.value.produto,
                                  items: listaEstoque.map((p) => DropdownMenuItem(value: p, child: Text('${p.nome} (${p.quantidadeAtual}${p.unidade} disp.)', overflow: TextOverflow.ellipsis))).toList(),
                                  onChanged: (v) => setState(() => e.value.produto = v),
                                )),
                            const SizedBox(width: 8),
                            Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: e.value.precoOuQtdCtrl,
                                  decoration: InputDecoration(labelText: 'Qtd gasta', suffixText: e.value.produto?.unidade ?? '', isDense: true, border: const OutlineInputBorder()),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  // 🔴 VALIDADOR DE ESTOQUE
                                  validator: (v) {
                                    final digitado = double.tryParse(v!.replaceAll(',', '.'));
                                    if (digitado == null || digitado <= 0) return 'Inválido';
                                    if (e.value.produto != null && digitado > e.value.produto!.quantidadeAtual) {
                                      return 'Máx: ${e.value.produto!.quantidadeAtual}';
                                    }
                                    return null;
                                  },
                                )),
                            IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppTheme.danger), onPressed: () => setState(() => _mats.removeAt(e.key))),
                          ]),
                    )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _salvarFinal,
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.success),
                  child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('✓ Confirmar e Finalizar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Classes Auxiliares ─────────────────────────────────────────────
class _SelecaoServico {
  Servico? servico;
  final precoCtrl = TextEditingController();
}

class _SelecaoMaterial {
  ItemEstoque? produto;
  final precoOuQtdCtrl = TextEditingController();
}

class _SecRow extends StatelessWidget {
  final String titulo;
  final VoidCallback onAdd;
  const _SecRow(this.titulo, {required this.onAdd});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(titulo.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: .8, color: AppTheme.textTertiary)),
          TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, size: 16), label: const Text('Adicionar', style: TextStyle(fontSize: 12))),
        ]),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.content_cut, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Nenhum atendimento listado', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ]),
      );
}
