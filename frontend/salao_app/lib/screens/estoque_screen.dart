import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salon_app/providers/gasto_provider.dart';
import 'package:salon_app/screens/perfil_screen.dart';
import '../providers/estoque_provider.dart';
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
  bool _alertasExpanded = true;
  bool _okExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EstoqueProvider>().carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EstoqueProvider>();

    if (provider.loading && provider.itens.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (provider.erro != null && provider.itens.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Estoque')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
              const SizedBox(height: 12),
              Text('Erro: ${provider.erro}', style: const TextStyle(color: AppTheme.danger)),
              TextButton(
                onPressed: () => context.read<EstoqueProvider>().carregar(),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'Histórico de ',
            onPressed: () => _showHistorico(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<EstoqueProvider>().carregar(),
        color: AppTheme.primary,
        child: Column(
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
                      value: '${provider.totalAlertas}',
                      backgroundColor: provider.totalAlertas > 0 ? AppTheme.dangerLight : AppTheme.successLight,
                      textColor: provider.totalAlertas > 0 ? AppTheme.danger : AppTheme.success,
                      valueColor: provider.totalAlertas > 0 ? AppTheme.danger : AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricCard(
                      label: 'Valor em estoque',
                      value: formatBRL(provider.valorTotalEstoque),
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
              child: provider.itens.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: _EmptyState(onAdicionar: () => _showNovoItem(context)),
                      ),
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (provider.emAlerta.isNotEmpty) ...[
                          _SecaoEstoque(
                            titulo: 'Precisam de reposição',
                            quantidade: provider.emAlerta.length,
                            isExpanded: _alertasExpanded,
                            onToggle: () => setState(() => _alertasExpanded = !_alertasExpanded),
                            corHeader: AppTheme.danger,
                            corHeaderBg: AppTheme.dangerLight,
                            itens: provider.emAlerta,
                            onEntrada: (item) => _showEntrada(context, item),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (provider.emOk.isNotEmpty)
                          _SecaoEstoque(
                            titulo: 'Estoque ok',
                            quantidade: provider.emOk.length,
                            isExpanded: _okExpanded,
                            onToggle: () => setState(() => _okExpanded = !_okExpanded),
                            corHeader: AppTheme.success,
                            corHeaderBg: AppTheme.successLight,
                            itens: provider.emOk,
                            onEntrada: (item) => _showEntrada(context, item),
                          ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SectionLabel('Kits de Revenda (Combos)'),
                            TextButton.icon(
                              onPressed: () => _showNovoKit(context), // Crie esta função chamando o _NovoKitSheet
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Novo Kit', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        if (provider.kits.isEmpty)
                          const Text('Nenhum kit de revenda montado.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))
                        else
                          Container(
                            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border, width: 0.5)),
                            child: Column(
                              children: provider.kits
                                  .map((k) => ListTile(
                                        title: Text(k.nome, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                        subtitle: Text(k.produtos.map((p) => '${p.quantidade.toStringAsFixed(0)}x ${p.nomeProduto}').join(', '), style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                                        trailing: Text(formatBRL(k.precoVenda), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.success)),
                                      ))
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: AppFAB(
        label: 'Novo item',
        onPressed: () => _showNovoItem(context),
      ),
    );
  }

  void _showEntrada(BuildContext context, ItemEstoque item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _EntradaSheet(item: item),
    );
  }

  void _showNovoItem(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => const _NovoItemSheet(),
    );
  }

  void _showHistorico(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => const _HistoricoSheet(),
    );
  }

  void _showNovoKit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _NovoKitSheet(),
    );
  }
}

// ── Seção colapsável (Mantida igual, apenas otimizada) ─────────────────
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
          InkWell(
            onTap: onToggle,
            borderRadius: isExpanded ? const BorderRadius.vertical(top: Radius.circular(12)) : BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: corHeaderBg, borderRadius: BorderRadius.circular(6)),
                    child: Text('$quantidade', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: corHeader)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
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
                ...itens.map((item) => ItemEstoqueTile(item: item, onEntrada: () => onEntrada(item))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
            decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.inventory_2_outlined, size: 28, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          const Text('Nenhum item no estoque', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text('Adicione os produtos que você usa\nnos atendimentos.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: onAdicionar,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar primeiro item'),
          ),
        ],
      ),
    );
  }
}

// ── Sheets Refatorados para o Provider ─────────────────────────────────

class _EntradaSheet extends StatefulWidget {
  final ItemEstoque item;
  const _EntradaSheet({required this.item});

  @override
  State<_EntradaSheet> createState() => _EntradaSheetState();
}

class _EntradaSheetState extends State<_EntradaSheet> {
  final _qtdCtrl = TextEditingController(); // Usado se for unidade avulsa
  final _caixasCtrl = TextEditingController(); // Qtd de caixas/pacotes comprados
  final _unidadesPorCaixaCtrl = TextEditingController(); // Quantas vieram dentro
  final _valorTotalCtrl = TextEditingController(); // Valor pago na compra toda

  bool _compradoEmCaixa = false; // O novo interruptor mágico
  bool _salvando = false;
  String _formaPagamento = 'pix';

  Future<void> _confirmar() async {
    double qtdFinal = 0.0;
    double valorDaCompra = 0.0;

    // A mágica da calculadora
    if (_compradoEmCaixa) {
      final caixas = double.tryParse(_caixasCtrl.text.replaceAll(',', '.')) ?? 0.0;
      final unids = double.tryParse(_unidadesPorCaixaCtrl.text.replaceAll(',', '.')) ?? 0.0;
      final pago = double.tryParse(_valorTotalCtrl.text.replaceAll(',', '.')) ?? 0.0;

      if (caixas <= 0 || unids <= 0 || pago <= 0) return;
      qtdFinal = caixas * unids; // Transforma as caixas nas unidades do app
      valorDaCompra = pago;
    } else {
      final qtd = double.tryParse(_qtdCtrl.text.replaceAll(',', '.')) ?? 0.0;
      if (qtd <= 0) return;
      qtdFinal = qtd;
      valorDaCompra = qtd * widget.item.custoUnitario;
    }

    setState(() => _salvando = true);

    try {
      // 1. Registra a entrada com a quantidade convertida
      await context.read<EstoqueProvider>().registrarEntrada(widget.item, qtdFinal);

      // 2. Lança nos Gastos
      await context.read<GastoProvider>().registrar(
            nome: 'Reposição: ${widget.item.nome}',
            valor: valorDaCompra,
            prazo: DateTime.now(),
            formaPagamento: _formaPagamento,
            categoria: 'material',
          );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: AppTheme.danger));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final item = widget.item;

    double valorExibicao = 0.0;
    if (_compradoEmCaixa) {
      valorExibicao = double.tryParse(_valorTotalCtrl.text.replaceAll(',', '.')) ?? 0.0;
    } else {
      final q = double.tryParse(_qtdCtrl.text.replaceAll(',', '.')) ?? 0.0;
      valorExibicao = q * item.custoUnitario;
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('Entrada — ${item.nome}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
            ],
          ),
          Text('Atual: ${item.quantidadeAtual.toStringAsFixed(0)} ${item.unidade} (Custo Un.: ${formatBRL(item.custoUnitario)})', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),

          // Switch de Calculadora de Caixa
          SwitchListTile(
            title: const Text('Comprei pacote/caixa fechada', style: TextStyle(fontSize: 14)),
            subtitle: const Text('O app converterá para a menor unidade para você.', style: TextStyle(fontSize: 11)),
            value: _compradoEmCaixa,
            activeColor: AppTheme.primary,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _compradoEmCaixa = v),
          ),

          if (_compradoEmCaixa) ...[
            Row(
              children: [
                Expanded(child: TextField(controller: _caixasCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Qtd Pacotes'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _unidadesPorCaixaCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Unids. por pacote', suffixText: item.unidade))),
              ],
            ),
            const SizedBox(height: 10),
            TextField(controller: _valorTotalCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Valor Total Pago na Compra', prefixText: 'R\$ ')),
          ] else
            TextField(
              controller: _qtdCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: 'Quantidade avulsa recebida', suffixText: item.unidade),
            ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.surfaceSecondary, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Lançamento nos Gastos:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
                    Text(formatBRL(valorExibicao), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.danger)),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _formaPagamento,
                  decoration: const InputDecoration(labelText: 'Como foi pago?', isDense: true, border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'pix', child: Text('PIX')),
                    DropdownMenuItem(value: 'credito', child: Text('Cartão de Crédito')),
                    DropdownMenuItem(value: 'debito', child: Text('Cartão de Débito')),
                    DropdownMenuItem(value: 'avista', child: Text('Dinheiro Espécie')),
                  ],
                  onChanged: (v) => setState(() => _formaPagamento = v!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _salvando ? null : _confirmar,
              child: _salvando ? const CircularProgressIndicator(color: Colors.white) : const Text('Confirmar entrada'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NovoItemSheet extends StatefulWidget {
  const _NovoItemSheet();
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
  bool _salvando = false;

  Future<void> _salvar() async {
    final qtd = double.tryParse(_qtdCtrl.text.replaceAll(',', '.'));
    final minimo = double.tryParse(_minimoCtrl.text.replaceAll(',', '.'));
    final custo = double.tryParse(_custoCtrl.text.replaceAll(',', '.'));

    if (_nomeCtrl.text.isEmpty || qtd == null || minimo == null || custo == null) return;

    setState(() => _salvando = true);

    final novo = ItemEstoque(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: _nomeCtrl.text.trim(),
      unidade: _unidade,
      categoria: _categoria,
      quantidadeAtual: qtd,
      quantidadeMinima: minimo,
      custoUnitario: custo,
    );

    await context.read<EstoqueProvider>().adicionarItem(novo);
    if (mounted) Navigator.pop(context);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Novo item de estoque', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _nomeCtrl, decoration: const InputDecoration(labelText: 'Nome do item'), textCapitalization: TextCapitalization.sentences),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<CategoriaEstoque>(
                    value: _categoria,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    isExpanded: true,
                    items: CategoriaEstoque.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _categoria = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _unidade,
                    decoration: const InputDecoration(labelText: 'Unidade'),
                    items: ['un.', 'ml', 'g', 'cx.', 'L'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _unidade = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: _qtdCtrl, decoration: InputDecoration(labelText: 'Qtd. atual', suffixText: _unidade), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _minimoCtrl, decoration: InputDecoration(labelText: 'Qtd. mínima', suffixText: _unidade), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
              ],
            ),
            const SizedBox(height: 10),
            TextField(controller: _custoCtrl, decoration: const InputDecoration(labelText: 'Custo unitário', prefixText: 'R\$ '), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                child: _salvando ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Salvar item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoricoSheet extends StatelessWidget {
  const _HistoricoSheet();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EstoqueProvider>();
    final movs = provider.movimentacoes;

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
                  const Text('Histórico de ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 20),
            Expanded(
              child: movs.isEmpty
                  ? const Center(child: Text("Nenhuma movimentação registrada.", style: TextStyle(color: AppTheme.textSecondary)))
                  : ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: movs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final m = movs[i];
                        final item = provider.itens.firstWhere((it) => it.id == m.itemId, orElse: () => provider.itens.first);
                        final isEntrada = m.tipo == TipoMovimentacao.entrada;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(color: isEntrada ? AppTheme.successLight : AppTheme.dangerLight, borderRadius: BorderRadius.circular(8)),
                                child: Icon(isEntrada ? Icons.arrow_downward : Icons.arrow_upward, size: 16, color: isEntrada ? AppTheme.success : AppTheme.danger),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.nome, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 2),
                                    Text(m.motivo, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${isEntrada ? '+' : '−'} ${m.quantidade.toStringAsFixed(0)} ${item.unidade}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isEntrada ? AppTheme.success : AppTheme.danger)),
                                  const SizedBox(height: 2),
                                  Text(formatDate(m.criadoEm), style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
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

class _NovoKitSheet extends StatefulWidget {
  const _NovoKitSheet();
  @override
  State<_NovoKitSheet> createState() => _NovoKitSheetState();
}

class _NovoKitSheetState extends State<_NovoKitSheet> {
  final _nomeCtrl = TextEditingController();
  final _precoCtrl = TextEditingController();
  final List<ItemFichaTecnica> _produtosSelecionados = [ItemFichaTecnica()];
  bool _salvando = false;

  Future<void> _salvar() async {
    final v = double.tryParse(_precoCtrl.text.replaceAll(',', '.'));
    if (_nomeCtrl.text.isEmpty || v == null) return;
    setState(() => _salvando = true);

    final produtosAssociados = _produtosSelecionados
        .where((p) => p.produto != null)
        .map((p) => ProdutoAssociado(
              produtoId: p.produto!.id,
              nomeProduto: p.produto!.nome,
              quantidade: double.tryParse(p.qtdCtrl.text.replaceAll(',', '.')) ?? 1.0,
              unidade: p.produto!.unidade,
            ))
        .toList();

    final novoKit = KitRevenda(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: _nomeCtrl.text.trim(),
      precoVenda: v,
      produtos: produtosAssociados,
    );

    await context.read<EstoqueProvider>().adicionarKit(novoKit);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final itensEstoque = context.read<EstoqueProvider>().itens.where((i) => i.ativo).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Montar Kit de Revenda', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 16),
            TextField(controller: _nomeCtrl, decoration: const InputDecoration(labelText: 'Nome do Kit (Ex: Kit Skincare)')),
            const SizedBox(height: 10),
            TextField(controller: _precoCtrl, decoration: const InputDecoration(labelText: 'Preço de Venda', prefixText: 'R\$ '), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Produtos do Kit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                TextButton.icon(onPressed: () => setState(() => _produtosSelecionados.add(ItemFichaTecnica())), icon: const Icon(Icons.add, size: 14), label: const Text('Add Produto', style: TextStyle(fontSize: 12)))
              ],
            ),
            ..._produtosSelecionados.asMap().entries.map((e) {
              final idx = e.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(children: [
                  Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<ItemEstoque>(
                        decoration: const InputDecoration(labelText: 'Produto', isDense: true),
                        value: e.value.produto,
                        items: itensEstoque.map((p) => DropdownMenuItem(value: p, child: Text(p.nome, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setState(() => e.value.produto = v),
                      )),
                  const SizedBox(width: 8),
                  Expanded(
                      flex: 2,
                      child: TextField(
                        controller: e.value.qtdCtrl,
                        decoration: InputDecoration(labelText: 'Qtd', suffixText: e.value.produto?.unidade ?? '', isDense: true),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      )),
                  IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                      onPressed: () => setState(() {
                            e.value.qtdCtrl.dispose();
                            _produtosSelecionados.removeAt(idx);
                          }))
                ]),
              );
            }),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _salvando ? null : _salvar, child: _salvando ? const CircularProgressIndicator(color: Colors.white) : const Text('Salvar Kit'))),
          ],
        ),
      ),
    );
  }
}
