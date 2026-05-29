import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final List<CustoFixo> _fixos = List.from(custosFixosExemplo);
  final List<Servico> _servicos = List.from(servicosExemplo);
  final String _nomeSalao = 'Studio Bela';
  final String _nomeProprietaria = 'Proprietária';

  double get _totalFixos => _fixos.fold(0.0, (s, c) => s + c.valor);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil do salão')),
      body: SingleChildScrollView(
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
                      child: Icon(Icons.store_outlined,
                          size: 26, color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_nomeSalao,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(_nomeProprietaria,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: AppTheme.textSecondary),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Custos fixos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionLabel('Custos fixos mensais'),
                TextButton.icon(
                  onPressed: () => _showNovoCustoFixo(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Adicionar',
                      style: TextStyle(fontSize: 12)),
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
                  ..._fixos.asMap().entries.map((e) {
                    final i = e.key;
                    final c = e.value;
                    return Container(
                      decoration: BoxDecoration(
                        border: i > 0
                            ? const Border(
                                top: BorderSide(
                                    color: AppTheme.border, width: 0.5))
                            : null,
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 0),
                        title: Text(c.descricao,
                            style: const TextStyle(fontSize: 13)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(formatBRL(c.valor),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.danger)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _fixos.removeAt(i)),
                              child: const Icon(Icons.delete_outline,
                                  size: 18,
                                  color: AppTheme.textTertiary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  // Total
                  Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.surfaceSecondary,
                      border: Border(
                          top: BorderSide(
                              color: AppTheme.border, width: 0.5)),
                      borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(12)),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total mensal',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary)),
                        Text(formatBRL(_totalFixos),
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.danger)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Serviços
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionLabel('Tabela de serviços'),
                TextButton.icon(
                  onPressed: () => _showNovoServico(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Adicionar',
                      style: TextStyle(fontSize: 12)),
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
                children: _servicos.asMap().entries.map((e) {
                  final i = e.key;
                  final s = e.value;
                  return Container(
                    decoration: BoxDecoration(
                      border: i > 0
                          ? const Border(
                              top: BorderSide(
                                  color: AppTheme.border, width: 0.5))
                          : null,
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 0),
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.content_cut,
                              size: 15, color: AppTheme.primary),
                        ),
                      ),
                      title: Text(s.nome,
                          style: const TextStyle(fontSize: 13)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(formatBRL(s.preco),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _servicos.removeAt(i)),
                            child: const Icon(Icons.delete_outline,
                                size: 18,
                                color: AppTheme.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showNovoCustoFixo(BuildContext context) {
    final descCtrl = TextEditingController();
    final valorCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Novo custo fixo',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                  controller: descCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Descrição')),
              const SizedBox(height: 10),
              TextField(
                  controller: valorCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Valor mensal', prefixText: 'R\$ '),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final v = double.tryParse(
                        valorCtrl.text.replaceAll(',', '.'));
                    if (descCtrl.text.isNotEmpty && v != null) {
                      setState(() => _fixos.add(CustoFixo(
                          id: DateTime.now().toString(),
                          descricao: descCtrl.text,
                          valor: v)));
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Salvar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNovoServico(BuildContext context) {
    final nomeCtrl = TextEditingController();
    final precoCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Novo serviço',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                  controller: nomeCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nome do serviço')),
              const SizedBox(height: 10),
              TextField(
                  controller: precoCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Preço', prefixText: 'R\$ '),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final v = double.tryParse(
                        precoCtrl.text.replaceAll(',', '.'));
                    if (nomeCtrl.text.isNotEmpty && v != null) {
                      setState(() => _servicos.add(Servico(
                          id: DateTime.now().toString(),
                          nome: nomeCtrl.text,
                          preco: v)));
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Salvar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
