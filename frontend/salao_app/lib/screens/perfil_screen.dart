import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/perfil_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../providers/estoque_provider.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final String _nomeSalao = 'Studio Bela';
  final String _nomeProprietaria = 'Proprietária';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PerfilProvider>().carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PerfilProvider>();

    if (provider.loading && provider.fixos.isEmpty && provider.servicos.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil do salão')),
      body: RefreshIndicator(
        onRefresh: () => context.read<PerfilProvider>().carregar(),
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do salão
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(Icons.store_outlined, size: 26, color: AppTheme.primary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_nomeSalao, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(_nomeProprietaria, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textSecondary),
                      onPressed: () {
                        // TODO: Editar salão
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── CUSTOS FIXOS ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SectionLabel('Custos fixos mensais'),
                  TextButton.icon(
                    onPressed: () => _showNovoCustoFixo(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Adicionar', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),

              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border, width: 0.5),
                ),
                child: Column(
                  children: [
                    if (provider.fixos.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Nenhum custo fixo cadastrado.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      )
                    else
                      ...provider.fixos.asMap().entries.map((e) {
                        final i = e.key;
                        final c = e.value;
                        return Container(
                          decoration: BoxDecoration(
                            border: i > 0 ? const Border(top: BorderSide(color: AppTheme.border, width: 0.5)) : null,
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                            title: Text(c.descricao, style: const TextStyle(fontSize: 13)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(formatBRL(c.valor), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.danger)),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => provider.removerCustoFixo(c.id),
                                  child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.textTertiary),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    // Total Custos Fixos
                    Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.surfaceSecondary,
                        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total mensal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
                          Text(formatBRL(provider.totalFixos), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── SERVIÇOS ───────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SectionLabel('Tabela de serviços'),
                  TextButton.icon(
                    onPressed: () => _showNovoServico(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Adicionar', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),

              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border, width: 0.5),
                ),
                child: Column(
                  children: [
                    if (provider.servicos.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Nenhum serviço cadastrado.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      )
                    else
                      ...provider.servicos.asMap().entries.map((e) {
                        final i = e.key;
                        final s = e.value;
                        return Container(
                          decoration: BoxDecoration(
                            border: i > 0 ? const Border(top: BorderSide(color: AppTheme.border, width: 0.5)) : null,
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(Icons.content_cut, size: 15, color: AppTheme.primary),
                              ),
                            ),
                            title: Text(s.nome, style: const TextStyle(fontSize: 13)),
                            subtitle: s.produtosPadrao.isEmpty
                                ? null
                                : Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text('Ficha: ${s.produtosPadrao.map((p) => '${p.quantidade.toStringAsFixed(0)}${p.unidade} ${p.nomeProduto}').join(', ')}', style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                                  ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(formatBRL(s.preco), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => provider.removerServico(s.id),
                                  child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.textTertiary),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showNovoCustoFixo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => const _NovoCustoFixoSheet(),
    );
  }

  void _showNovoServico(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => const _NovoServicoSheet(),
    );
  }
}

// ── BottomSheets Refatorados com Estado de Loading ───────────────────────────

class _NovoCustoFixoSheet extends StatefulWidget {
  const _NovoCustoFixoSheet();
  @override
  State<_NovoCustoFixoSheet> createState() => _NovoCustoFixoSheetState();
}

class _NovoCustoFixoSheetState extends State<_NovoCustoFixoSheet> {
  final _descCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final v = double.tryParse(_valorCtrl.text.replaceAll(',', '.'));
    if (_descCtrl.text.isEmpty || v == null) return;

    setState(() => _salvando = true);
    await context.read<PerfilProvider>().adicionarCustoFixo(_descCtrl.text.trim(), v);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Novo custo fixo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
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
            decoration: const InputDecoration(labelText: 'Valor mensal', prefixText: 'R\$ '),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _salvando ? null : _salvar,
              child: _salvando ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Salvar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NovoServicoSheet extends StatefulWidget {
  const _NovoServicoSheet();
  @override
  State<_NovoServicoSheet> createState() => _NovoServicoSheetState();
}

class _NovoServicoSheetState extends State<_NovoServicoSheet> {
  final _nomeCtrl = TextEditingController();
  final _precoCtrl = TextEditingController();

  // Lista dinâmica para adicionar produtos ao serviço
  final List<ItemFichaTecnica> _produtosSelecionados = [];
  bool _salvando = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _precoCtrl.dispose();
    for (var p in _produtosSelecionados) {
      p.qtdCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    final v = double.tryParse(_precoCtrl.text.replaceAll(',', '.'));
    if (_nomeCtrl.text.isEmpty || v == null) return;

    setState(() => _salvando = true);

    // Mapeia os produtos selecionados
    final produtosAssociados = _produtosSelecionados
        .where((p) => p.produto != null)
        .map((p) => ProdutoAssociado(
              produtoId: p.produto!.id,
              nomeProduto: p.produto!.nome,
              quantidade: double.tryParse(p.qtdCtrl.text.replaceAll(',', '.')) ?? 1.0,
              unidade: p.produto!.unidade,
            ))
        .toList();

    await context.read<PerfilProvider>().adicionarServico(_nomeCtrl.text.trim(), v, produtosAssociados);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    // Puxa os itens do estoque disponíveis (para o Dropdown)
    final itensEstoque = context.read<EstoqueProvider>().itens.where((i) => i.ativo).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Novo serviço', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _nomeCtrl, decoration: const InputDecoration(labelText: 'Nome do serviço')),
            const SizedBox(height: 10),
            TextField(
              controller: _precoCtrl,
              decoration: const InputDecoration(labelText: 'Preço base', prefixText: 'R\$ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),

            const SizedBox(height: 16),
            // ── FICHA TÉCNICA (PRODUTOS VINCULADOS) ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Produtos Padrão (Ficha Técnica)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                TextButton.icon(
                  onPressed: () => setState(() => _produtosSelecionados.add(ItemFichaTecnica())),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add Produto', style: TextStyle(fontSize: 12)),
                )
              ],
            ),

            ..._produtosSelecionados.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<ItemEstoque>(
                        decoration: const InputDecoration(labelText: 'Produto', isDense: true),
                        value: item.produto,
                        items: itensEstoque.map((p) => DropdownMenuItem(value: p, child: Text(p.nome, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setState(() => item.produto = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: item.qtdCtrl,
                        decoration: InputDecoration(labelText: 'Qtd', suffixText: item.produto?.unidade ?? '', isDense: true),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                      onPressed: () => setState(() {
                        item.qtdCtrl.dispose();
                        _produtosSelecionados.removeAt(idx);
                      }),
                    )
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                child: _salvando ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Auxiliar para a lista dinâmica
class ItemFichaTecnica {
  ItemEstoque? produto;
  final qtdCtrl = TextEditingController();
}
