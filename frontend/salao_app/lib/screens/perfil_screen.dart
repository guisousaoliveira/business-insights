// ─────────────────────────────────────────────────────────────────────────────
// screens/perfil_screen.dart — Fase 1
//
// Configura:
//   • Aluguel mensal
//   • Outros custos fixos (streaming, softwares, etc.)
//   • Limite de alerta de gasto
//   • WhatsApp para receber alertas automáticos
//
// Dados mockados localmente em memória.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _key     = GlobalKey<FormState>();
  final _aluguel = TextEditingController();
  final _outros  = TextEditingController();
  final _limite  = TextEditingController();
  final _whats   = TextEditingController();

  bool _loading = true;
  bool _saving  = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.getPerfil();
      if (mounted) {
        _aluguel.text = (res['aluguel'] ?? 0).toString();
        _outros.text  = (res['outros_fixos'] ?? 0).toString();
        _limite.text  = (res['limite_gasto_alerta'] ?? 0).toString();
        _whats.text   = res['telefone_whatsapp'] ?? '';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _aluguel.dispose();
    _outros.dispose();
    _limite.dispose();
    _whats.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil e custos fixos'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Salvar'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _key,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Custos fixos ──────────────────────────────────────────
                  const _SecHeader(
                    icon:    Icons.home_outlined,
                    titulo:  'Custos fixos mensais',
                    sub:     'Usados automaticamente no cálculo do resultado',
                  ),
                  const SizedBox(height: 12),
                  _MoneyField(
                    ctrl:  _aluguel,
                    label: 'Aluguel',
                    hint:  'Ex: 900.00',
                  ),
                  const SizedBox(height: 10),
                  _MoneyField(
                    ctrl:  _outros,
                    label: 'Outros custos fixos',
                    hint:  'Conta de luz, internet...',
                  ),
                  const Divider(height: 32),

                  // ── Alertas ───────────────────────────────────────────────
                  const _SecHeader(
                    icon:   Icons.notifications_outlined,
                    titulo: 'Alertas automáticos',
                    sub:    'Insira o limite para alertas de gastos por item',
                  ),
                  const SizedBox(height: 12),
                  _MoneyField(
                    ctrl:  _limite,
                    label: 'Limite de gasto por item',
                    hint:  'Acima disso você recebe alerta',
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _whats,
                    decoration: const InputDecoration(
                      labelText:   'WhatsApp para alertas',
                      hintText:    '+5511999999999',
                      border:      OutlineInputBorder(),
                      prefixIcon:  Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const Divider(height: 32),

                  // ── Conta ─────────────────────────────────────────────────
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Sair da conta',
                        style: TextStyle(color: Colors.red)),
                    onTap: ApiService.signOut,
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await ApiService.savePerfil(
        aluguel:             double.tryParse(_aluguel.text) ?? 0,
        outrosFixos:         double.tryParse(_outros.text) ?? 0,
        limiteGastoAlerta:   double.tryParse(_limite.text) ?? 0,
        telefoneWhatsApp:    _whats.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil salvo com sucesso'),
            backgroundColor: Color(0xFF1D9E75),
          ),
        );
      }
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

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SecHeader extends StatelessWidget {
  final IconData icon;
  final String titulo, sub;
  const _SecHeader({
    required this.icon,
    required this.titulo,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: const Color(0xFF1D9E75)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(sub,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF9A9A96))),
        ]),
      ),
    ],
  );
}

class _MoneyField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  const _MoneyField({required this.ctrl, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    decoration: InputDecoration(
      labelText:  label,
      hintText:   hint,
      border:     const OutlineInputBorder(),
      prefixText: 'R\$ ',
    ),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    validator: (v) {
      if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
        return 'Valor inválido';
      }
      return null;
    },
  );
}
