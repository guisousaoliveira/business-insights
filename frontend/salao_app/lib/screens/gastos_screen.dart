// ─────────────────────────────────────────────────────────────────────────────
// screens/gastos_screen.dart — Fase 1
//
// Lista gastos como collapsables com badge de urgência (vence ≤ 3 dias),
// itens detalhados ao expandir e botão "Marcar como pago".
// Banner no topo alerta sobre gastos urgentes.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/atendimento.dart';
import '../providers/gasto_provider.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  bool _soPendentes = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GastoProvider>().carregar(apenasNaoPagos: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<GastoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos'),
        actions: [
          FilterChip(
            label: Text(_soPendentes ? 'Pendentes' : 'Todos'),
            selected: _soPendentes,
            onSelected: (v) {
              setState(() => _soPendentes = v);
              prov.carregar(apenasNaoPagos: v ? true : null);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(children: [
        // Banner de urgência
        if (prov.urgentes.isNotEmpty)
          Container(
            width: double.infinity,
            color: const Color(0xFFFAEEDA),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              const Icon(Icons.warning_amber,
                  color: Color(0xFF854F0B), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${prov.urgentes.length} gasto(s) vencendo em até 3 dias',
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF633806),
                      fontWeight: FontWeight.w500),
                ),
              ),
            ]),
          ),

        Expanded(
          child: prov.loading
              ? const Center(child: CircularProgressIndicator())
              : prov.gastos.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum gasto ${_soPendentes ? "pendente" : ""} registrado',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => prov.carregar(
                          apenasNaoPagos: _soPendentes ? true : null),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: prov.gastos.length,
                        itemBuilder: (ctx, i) =>
                            _GastoTile(gasto: prov.gastos[i]),
                      ),
                    ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => const _FormGasto(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Novo gasto'),
      ),
    );
  }
}

// ── GastoTile ─────────────────────────────────────────────────────────────────

class _GastoTile extends StatelessWidget {
  final Gasto gasto;
  static final _cur = NumberFormat.simpleCurrency(locale: 'pt_BR');
  const _GastoTile({required this.gasto});

  @override
  Widget build(BuildContext context) {
    final urgente = gasto.venceEm3Dias;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      // Borda laranja em gastos urgentes
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: urgente ? const Color(0xFFF5C05A) : Colors.grey.shade200,
          width: urgente ? 1.0 : 0.5,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

        title: Row(children: [
          Expanded(
            child: Text(gasto.nome,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 14)),
          ),
          if (gasto.pago)
            _Badge('Pago', const Color(0xFF1D9E75), const Color(0xFFE1F5EE))
          else if (urgente)
            _Badge(
                'Urgente', const Color(0xFF854F0B), const Color(0xFFFAEEDA)),
        ]),
        subtitle: Text(
          'Vence ${gasto.prazoFormatado} · ${_fmtPag(gasto.formaPagamento)}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        trailing: Text(
          _cur.format(gasto.valor),
          style: const TextStyle(
              color: Color(0xFFA32D2D),
              fontWeight: FontWeight.w500,
              fontSize: 14),
        ),

        children: [
          // Itens detalhados
          if (gasto.itens.isNotEmpty) ...[
            const _SecLabel('Itens'),
            ...gasto.itens.map((i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Expanded(
                  child: Text(i.nome,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700)),
                ),
                Text(_cur.format(i.preco),
                    style: const TextStyle(fontSize: 13)),
              ]),
            )),
            const Divider(height: 16),
          ],

          // Botão marcar como pago
          if (!gasto.pago)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.read<GastoProvider>().marcarPago(gasto.id),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Marcar como pago'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1D9E75),
                  side: const BorderSide(color: Color(0xFF1D9E75)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _fmtPag(FormaPagamento f) {
    switch (f) {
      case FormaPagamento.pix:     return 'PIX';
      case FormaPagamento.avista:  return 'À vista';
      case FormaPagamento.credito: return 'Crédito';
      case FormaPagamento.debito:  return 'Débito';
    }
  }
}

class _Badge extends StatelessWidget {
  final String l;
  final Color cor, bg;
  const _Badge(this.l, this.cor, this.bg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration:
        BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(l,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: cor)),
  );
}

class _SecLabel extends StatelessWidget {
  final String l;
  const _SecLabel(this.l);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 6),
    child: Text(l.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
            letterSpacing: .9, color: Color(0xFF9A9A96))),
  );
}

// ── Formulário de novo gasto ──────────────────────────────────────────────────

class _FormGasto extends StatefulWidget {
  const _FormGasto();

  @override
  State<_FormGasto> createState() => _FormGastoState();
}

class _FormGastoState extends State<_FormGasto> {
  final _key   = GlobalKey<FormState>();
  final _nome  = TextEditingController();
  final _valor = TextEditingController();

  DateTime _prazo  = DateTime.now().add(const Duration(days: 7));
  String   _fp     = 'pix';
  String   _cat    = 'material';
  bool     _saving = false;

  @override
  void dispose() {
    _nome.dispose();
    _valor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Novo gasto',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600)),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nome,
                decoration: const InputDecoration(
                    labelText: 'Nome do gasto',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    (v?.isEmpty ?? true) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _valor,
                decoration: const InputDecoration(
                    labelText: 'Valor (R\$)', border: OutlineInputBorder()),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Informe o valor';
                  if (double.tryParse(v!) == null) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 10),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, size: 18),
                title: Text(
                    'Prazo: ${DateFormat('dd/MM/yyyy', 'pt_BR').format(_prazo)}'),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _prazo,
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _prazo = d);
                },
              ),

              DropdownButtonFormField<String>(
                value: _fp,
                decoration: const InputDecoration(
                    labelText: 'Forma de pagamento',
                    border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'pix',     child: Text('PIX')),
                  DropdownMenuItem(value: 'avista',  child: Text('À vista')),
                  DropdownMenuItem(value: 'credito', child: Text('Cartão de crédito')),
                  DropdownMenuItem(value: 'debito',  child: Text('Cartão de débito')),
                ],
                onChanged: (v) => setState(() => _fp = v!),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _cat,
                decoration: const InputDecoration(
                    labelText: 'Categoria', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'material', child: Text('Material / reposição')),
                  DropdownMenuItem(value: 'fixo',     child: Text('Custo fixo')),
                  DropdownMenuItem(value: 'outros',   child: Text('Outros')),
                ],
                onChanged: (v) => setState(() => _cat = v!),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _salvar,
                  child: _saving
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Salvar gasto'),
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
      await context.read<GastoProvider>().registrar(
        nome:           _nome.text.trim(),
        valor:          double.parse(_valor.text),
        prazo:          _prazo,
        formaPagamento: _fp,
        categoria:      _cat,
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
