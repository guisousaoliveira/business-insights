// ─────────────────────────────────────────────────────────────────────────────
// widgets/atendimento_tile.dart
//
// Widget CENTRAL do projeto — collapsable de atendimento.
//
// Estrutura visual:
//   ┌─ [sempre visível] ────────────────────────────────────────────────────┐
//   │  Ana Paula                      · 15/05 · (11) 99999-0001            │
//   │                                                        + R$ 180,00   │ ← verde
//   └───────────────────────────────────────────────────────────────────────┘
//   ┌─ [expandido ao tocar] ─────────────────────────────────────────────────┐
//   │  SERVIÇOS                                                              │
//   │  Extensão fio a fio ...................................... R$ 180,00   │
//   │  ┌─ TOTAL GANHO ........................................... R$ 180,00 ┐ │ ← verde
//   │  MATERIAIS UTILIZADOS                                                  │
//   │  Fios (bandeja) ........................................... R$  12,00  │
//   │  Adesivo (dose) ........................................... R$   8,00  │
//   │  ┌─ TOTAL MATERIAIS ...................................... R$  20,00 ┐ │ ← vermelho
//   │  Lucro bruto: R$ 160,00                                               │ ← itálico
//   └───────────────────────────────────────────────────────────────────────┘
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/atendimento.dart';

class AtendimentoTile extends StatelessWidget {
  final Atendimento atendimento;
  static final _cur = NumberFormat.simpleCurrency(locale: 'pt_BR');

  const AtendimentoTile({super.key, required this.atendimento});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

        // ── Cabeçalho (sempre visível) ─────────────────────────────────────
        title: Text(
          atendimento.clienteNome,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Text(
          '${atendimento.dataFormatada}'
          '${atendimento.clienteTelefone.isNotEmpty ? " · ${atendimento.clienteTelefone}" : ""}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        // Receita sempre visível — informação mais importante sem expandir
        trailing: Text(
          _cur.format(atendimento.totalGanho),
          style: const TextStyle(
            color: Color(0xFF1D9E75),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),

        // ── Corpo colapsável ───────────────────────────────────────────────
        children: [
          // SERVIÇOS
          const _SecLabel('Serviços'),
          ...atendimento.servicos.map(
            (s) => _Item(label: s.nome, value: _cur.format(s.preco)),
          ),
          _Total(
            label:    'Total ganho',
            value:    _cur.format(atendimento.totalGanho),
            positive: true,
          ),
          const SizedBox(height: 10),

          // MATERIAIS
          const _SecLabel('Materiais utilizados'),
          if (atendimento.materiais.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Nenhum material registrado',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            )
          else
            ...atendimento.materiais.map(
              (m) => _Item(label: m.nome, value: _cur.format(m.preco)),
            ),
          _Total(
            label:    'Total materiais',
            value:    _cur.format(atendimento.totalMateriais),
            positive: false,
          ),

          // LUCRO BRUTO — bônus no rodapé
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Lucro bruto: ${_cur.format(atendimento.lucroBruto)}',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: atendimento.lucroBruto >= 0
                    ? const Color(0xFF1D9E75)
                    : const Color(0xFFA32D2D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets privados ──────────────────────────────────────────────────────

class _SecLabel extends StatelessWidget {
  final String label;
  const _SecLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 5),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: .9,
        color: Color(0xFF9A9A96),
      ),
    ),
  );
}

class _Item extends StatelessWidget {
  final String label, value;
  const _Item({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Expanded(
        child: Text(label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
      ),
      Text(value, style: const TextStyle(fontSize: 13)),
    ]),
  );
}

class _Total extends StatelessWidget {
  final String label, value;
  final bool positive;
  const _Total({required this.label, required this.value, required this.positive});

  @override
  Widget build(BuildContext context) {
    final cor  = positive ? const Color(0xFF1D9E75) : const Color(0xFFA32D2D);
    final txtC = positive ? const Color(0xFF085041) : const Color(0xFF791F1F);
    final bg   = positive ? const Color(0xFFE1F5EE) : const Color(0xFFFCEBEB);

    return Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: txtC)),
          Text(value, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: cor)),
        ],
      ),
    );
  }
}
