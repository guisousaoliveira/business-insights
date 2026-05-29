import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/estoque_widgets.dart';

class EstoqueScreen extends StatefulWidget {
  const EstoqueScreen({super.key});

  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  List<ItemEstoque> _itens = List.from(estoqueExemplo);
  bool _alertasExpanded = true;
  bool _okExpanded = true;

  List<ItemEstoque> get _emAlerta =>
      _itens.where((i) => i.emAlerta && i.ativo).toList()
        ..sort((a, b) => a.status.index.compareTo(b.status.index));

  List<ItemEstoque> get _emOk =>
      _itens.where((i) => !i.emAlerta && i.ativo).toList();

  int get totalAlertas => _emAlerta.length;

  double get _valorTotalEstoque => _itens
      .where((i) => i.ativo)
      .fold(0.0, (s, i) => s + i.quantidadeAtual * i.custoUnitario);

  void _registrarEntrada(ItemEstoque item, double quantidade) {
    setState(() {
      final idx = _itens.indexWhere((i) => i.id == item.id);
      if (idx != -1) {
        _itens[idx] = _itens[idx].copyWith(
          quantidadeAtual: _itens[idx].quantidadeAtual + quantidade,
        );
      }
    });
  }

  void _adicionarItem(ItemEstoque novoItem) {
    setState(() => _itens.add(novoItem));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'Histórico de movimentações',
            onPressed: () => _showHistorico(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Métricas topo ──────────────────────────────────────────
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: MetricCard(
                    label: 'Itens em alerta',
                    value: '$totalAlertas',
                    backgroundColor: totalAlertas > 0
                        ? AppTheme.dangerLight
                        : AppTheme.successLight,
                    textColor: totalAlertas > 0
                        ? AppTheme.danger
                        : AppTheme.success,
                    valueColor: totalAlertas > 0
                        ? AppTheme.danger
                        : AppTheme.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricCard(
                    label: 'Valor em estoque',
                    value: formatBRL(_valorTotalEstoque),
                    backgroundColor: AppTheme.primaryLight,
                    textColor: AppTheme.primary,
                    valueColor: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // ── Lista ──────────────────────────────────────────────────
          Expanded(
            child: _itens.isEmpty
                ? _EmptyState(onAdicionar: () => _showNovoItem(context))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Seção em alerta
                      if (_emAlerta.isNotEmpty) ...[
                        _SecaoEstoque(
                          titulo: 'Precisam de reposição',
                          quantidade: _emAlerta.length,
                          isExpanded: _alertasExpanded,
                          onToggle: () => setState(
                              () => _alertasExpanded = !_alertasExpanded),
                          corHeader: AppTheme.danger,
                          corHeaderBg: AppTheme.dangerLight,
                          itens: _emAlerta,
                          onEntrada: (item) =>
                              _showEntrada(context, item),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Seção em ok
                      if (_emOk.isNotEmpty)
                        _SecaoEstoque(
                          titulo: 'Estoque ok',
                          quantidade: _emOk.length,
                          isExpanded: _okExpanded,
                          onToggle: () =>
                              setState(() => _okExpanded = !_okExpanded),
                          corHeader: AppTheme.success,
                          corHeaderBg: AppTheme.successLight,
                          itens: _emOk,
                          onEntrada: (item) =>
                              _showEntrada(context, item),
                        ),

                      const SizedBox(height: 80), // espaço para FAB
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: AppFAB(
        label: 'Novo item',
        onPressed: () => _showNovoItem(context),
      ),
    );
  }

  // ── Bottomsheets ───────────────────────────────────────────────────

  void _showEntrada(BuildContext context, ItemEstoque item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EntradaSheet(
        item: item,
        onConfirmar: (qtd) => _registrarEntrada(item, qtd),
      ),
    );
  }

  void _showNovoItem(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _NovoItemSheet(
        onSalvar: _adicionarItem,
      ),
    );
  }

  void _showHistorico(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _HistoricoSheet(),
    );
  }
}

// ── Seção colapsável ────────────────────────────────────────────────

class _SecaoEstoque extends StatelessWidget {
  final String titulo;
  final int quantidade;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Color corHeader;
  final Color corHeaderBg;
  final List<ItemEstoque> itens;
  final void Function(ItemEstoque) onEntrada;

  const _SecaoEstoque({
    required this.titulo,
    required this.quantidade,
    required this.isExpanded,
    required this.onToggle,
    required this.corHeader,
    required this.corHeaderBg,
    required this.itens,
    required this.onEntrada,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        children: [
          // Header clicável
          InkWell(
            onTap: onToggle,
            borderRadius: isExpanded
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : BorderRadius.circular(12),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: corHeaderBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$quantidade',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: corHeader,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
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

          // Itens
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 0),
                ...itens.map((item) => ItemEstoqueTile(
                      item: item,
                      onEntrada: () => onEntrada(item),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdicionar;

  const _EmptyState({required this.onAdicionar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                size: 28, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum item no estoque',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Adicione os produtos que você usa\nnos atendimentos.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: onAdicionar,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar primeiro item'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sheet: registrar entrada ────────────────────────────────────────

class _EntradaSheet extends StatefulWidget {
  final ItemEstoque item;
  final void Function(double quantidade) onConfirmar;

  const _EntradaSheet({required this.item, required this.onConfirmar});

  @override
  State<_EntradaSheet> createState() => _EntradaSheetState();
}

class _EntradaSheetState extends State<_EntradaSheet> {
  final _qtdCtrl = TextEditingController();

  @override
  void dispose() {
    _qtdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final item = widget.item;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Entrada — ${item.nome}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Status atual
          Row(
            children: [
              StatusBadge(status: item.status),
              const SizedBox(width: 8),
              Text(
                'Atual: ${item.quantidadeAtual.toStringAsFixed(0)} ${item.unidade} · Mínimo: ${item.quantidadeMinima.toStringAsFixed(0)} ${item.unidade}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _qtdCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Quantidade recebida',
              suffixText: item.unidade,
            ),
          ),
          const SizedBox(height: 8),

          // Preview do novo saldo
          AnimatedBuilder(
            animation: _qtdCtrl,
            builder: (_, __) {
              final entrada =
                  double.tryParse(_qtdCtrl.text.replaceAll(',', '.')) ??
                      0;
              final novoSaldo = item.quantidadeAtual + entrada;
              final novoStatus = novoSaldo == 0
                  ? StatusEstoque.critico
                  : novoSaldo <= item.quantidadeMinima
                      ? StatusEstoque.alerta
                      : StatusEstoque.ok;

              if (entrada <= 0) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Novo saldo',
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.primary)),
                    Row(
                      children: [
                        Text(
                          '${novoSaldo.toStringAsFixed(0)} ${item.unidade}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: novoStatus),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final qtd = double.tryParse(
                    _qtdCtrl.text.replaceAll(',', '.'));
                if (qtd != null && qtd > 0) {
                  widget.onConfirmar(qtd);
                  Navigator.pop(context);
                }
              },
              child: const Text('Confirmar entrada'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sheet: novo item ────────────────────────────────────────────────

class _NovoItemSheet extends StatefulWidget {
  final void Function(ItemEstoque) onSalvar;

  const _NovoItemSheet({required this.onSalvar});

  @override
  State<_NovoItemSheet> createState() => _NovoItemSheetState();
}

class _NovoItemSheetState extends State<_NovoItemSheet> {
  final _nomeCtrl = TextEditingController();
  final _qtdCtrl = TextEditingController();
  final _minimoCtrl = TextEditingController();
  final _custoCtrl = TextEditingController();
  String _unidade = 'un.';
  CategoriaEstoque _categoria = CategoriaEstoque.outro;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _qtdCtrl.dispose();
    _minimoCtrl.dispose();
    _custoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Novo item de estoque',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
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
              decoration: const InputDecoration(labelText: 'Nome do item'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<CategoriaEstoque>(
                    value: _categoria,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    isExpanded: true,
                    items: CategoriaEstoque.values
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.label,
                                  style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _categoria = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _unidade,
                    decoration:
                        const InputDecoration(labelText: 'Unidade'),
                    items: ['un.', 'ml', 'g', 'cx.', 'L']
                        .map((u) => DropdownMenuItem(
                            value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _unidade = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtdCtrl,
                    decoration: InputDecoration(
                        labelText: 'Qtd. atual',
                        suffixText: _unidade),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _minimoCtrl,
                    decoration: InputDecoration(
                        labelText: 'Qtd. mínima',
                        suffixText: _unidade),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _custoCtrl,
              decoration: const InputDecoration(
                  labelText: 'Custo unitário', prefixText: 'R\$ '),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final qtd = double.tryParse(
                      _qtdCtrl.text.replaceAll(',', '.'));
                  final minimo = double.tryParse(
                      _minimoCtrl.text.replaceAll(',', '.'));
                  final custo = double.tryParse(
                      _custoCtrl.text.replaceAll(',', '.'));

                  if (_nomeCtrl.text.isNotEmpty &&
                      qtd != null &&
                      minimo != null &&
                      custo != null) {
                    widget.onSalvar(ItemEstoque(
                      id: DateTime.now().millisecondsSinceEpoch
                          .toString(),
                      nome: _nomeCtrl.text.trim(),
                      unidade: _unidade,
                      categoria: _categoria,
                      quantidadeAtual: qtd,
                      quantidadeMinima: minimo,
                      custoUnitario: custo,
                    ));
                    Navigator.pop(context);
                  }
                },
                child: const Text('Salvar item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sheet: histórico ────────────────────────────────────────────────

class _HistoricoSheet extends StatelessWidget {
  const _HistoricoSheet();

  @override
  Widget build(BuildContext context) {
    final movs = movimentacoesExemplo.reversed.toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollCtrl) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Histórico de movimentações',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: movs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final m = movs[i];
                  final item = estoqueExemplo
                      .firstWhere((it) => it.id == m.itemId,
                          orElse: () => estoqueExemplo.first);
                  final isEntrada =
                      m.tipo == TipoMovimentacao.entrada;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isEntrada
                                ? AppTheme.successLight
                                : AppTheme.dangerLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isEntrada
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            size: 16,
                            color: isEntrada
                                ? AppTheme.success
                                : AppTheme.danger,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(item.nome,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(m.motivo,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isEntrada ? '+' : '−'} ${m.quantidade.toStringAsFixed(0)} ${item.unidade}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isEntrada
                                    ? AppTheme.success
                                    : AppTheme.danger,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(formatDate(m.criadoEm),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textTertiary)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
