import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

// ── Badge de status ────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final StatusEstoque status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case StatusEstoque.critico:
        bg = AppTheme.dangerLight;
        fg = AppTheme.danger;
        label = 'Esgotado';
        break;
      case StatusEstoque.alerta:
        bg = AppTheme.amberLight;
        fg = AppTheme.amber;
        label = 'Baixo';
        break;
      case StatusEstoque.ok:
        bg = AppTheme.successLight;
        fg = AppTheme.success;
        label = 'Ok';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

// ── Barra de progresso de estoque ─────────────────────────────────

class EstoqueProgressBar extends StatelessWidget {
  final double atual;
  final double minimo;
  final double maximo;
  final String unidade;

  const EstoqueProgressBar({
    super.key,
    required this.atual,
    required this.minimo,
    required this.maximo,
    required this.unidade,
  });

  @override
  Widget build(BuildContext context) {
    final max = maximo > 0 ? maximo : 1.0;
    final frac = (atual / max).clamp(0.0, 1.0);
    final fracMinimo = (minimo / max).clamp(0.0, 1.0);

    Color barColor;
    if (atual == 0) {
      barColor = AppTheme.danger;
    } else if (atual <= minimo) {
      barColor = AppTheme.amber;
    } else {
      barColor = AppTheme.success;
    }

    return Column(
      children: [
        Stack(
          children: [
            // Trilha
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Preenchimento
            FractionallySizedBox(
              widthFactor: frac,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            // Linha do mínimo
            if (fracMinimo > 0)
              Positioned(
                left: null,
                right: null,
                child: FractionallySizedBox(
                  widthFactor: fracMinimo,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Transform.translate(
                            offset: const Offset(0, -2),
                             child: Container(
                              width: 1.5,
                              height: 10,
                              color: AppTheme.textTertiary,
                              ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${atual.toStringAsFixed(0)} $unidade',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: barColor,
              ),
            ),
            Text(
              'mín. ${minimo.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Tile de item do estoque ────────────────────────────────────────

class ItemEstoqueTile extends StatefulWidget {
  final ItemEstoque item;
  final VoidCallback onEntrada;

  const ItemEstoqueTile({
    super.key,
    required this.item,
    required this.onEntrada,
  });

  @override
  State<ItemEstoqueTile> createState() => _ItemEstoqueTileState();
}

class _ItemEstoqueTileState extends State<ItemEstoqueTile> {
  bool _expandido = false;

  Color get _corStatus {
    switch (widget.item.status) {
      case StatusEstoque.critico:
        return AppTheme.danger;
      case StatusEstoque.alerta:
        return AppTheme.amber;
      case StatusEstoque.ok:
        return AppTheme.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    // Estima máximo como 2× o mínimo (para a barra de progresso)
    final maximo = item.quantidadeMinima * 2;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.border, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Linha principal
          InkWell(
            onTap: () => setState(() => _expandido = !_expandido),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  // Indicador de status (linha lateral)
                  Container(
                    width: 3,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _corStatus,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nome,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              item.categoria.label,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textTertiary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            StatusBadge(status: item.status),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Quantidade + botão entrada
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.quantidadeAtual.toStringAsFixed(0)} ${item.unidade}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _corStatus,
                        ),
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: widget.onEntrada,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            '+ Entrada',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _expandido ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down,
                        size: 18, color: AppTheme.textTertiary),
                  ),
                ],
              ),
            ),
          ),

          // Detalhe expandido
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _expandido
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding:
                  const EdgeInsets.fromLTRB(28, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EstoqueProgressBar(
                    atual: item.quantidadeAtual,
                    minimo: item.quantidadeMinima,
                    maximo: maximo,
                    unidade: item.unidade,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _DetalheChip(
                          label: 'Custo unit.',
                          valor: formatBRL(item.custoUnitario),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DetalheChip(
                          label: 'Valor total',
                          valor: formatBRL(
                              item.quantidadeAtual * item.custoUnitario),
                        ),
                      ),
                      if (item.emAlerta) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _DetalheChip(
                            label: 'Reposição',
                            valor:
                                '${item.deficit.toStringAsFixed(0)} ${item.unidade}',
                            destaque: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetalheChip extends StatelessWidget {
  final String label;
  final String valor;
  final bool destaque;

  const _DetalheChip({
    required this.label,
    required this.valor,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: destaque ? AppTheme.amberLight : AppTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: destaque ? AppTheme.amber : AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: destaque ? AppTheme.amber : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge numérico para BottomNav ──────────────────────────────────

class BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool ativo;

  const BadgeIcon({
    super.key,
    required this.icon,
    required this.count,
    required this.ativo,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon,
            size: 22,
            color: ativo ? AppTheme.primary : AppTheme.textTertiary),
        if (count > 0)
          Positioned(
            top: -4,
            right: -8,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppTheme.danger,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
