import 'package:flutter/widgets.dart';

import '../../settings/app_colors.dart';
import '../../settings/app_fonts.dart';
import 'app_card.dart';
import 'app_tappable.dart';

class AppTableColumn {
  final String label;

  /// Largura proporcional, como as porcentagens do protótipo (32/22/22/24).
  final int flex;
  final Alignment alignment;

  const AppTableColumn({
    required this.label,
    this.flex = 1,
    this.alignment = Alignment.centerLeft,
  });
}

class AppTableRow {
  final List<Widget> cells;
  final VoidCallback? onTap;
  final Color? background;

  const AppTableRow({required this.cells, this.onTap, this.background});
}

/// Tabela da casca web. **Não existe no mobile** — lá a mesma lista vira
/// cartões empilhados (S3). Quem escolhe é a tela, olhando `isWideLayout`.
class AppTable extends StatelessWidget {
  final List<AppTableColumn> columns;
  final List<AppTableRow> rows;
  final Widget? emptyState;

  const AppTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyState,
  });

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              child: Row(
                children: columns
                    .map(
                      (column) => Expanded(
                        flex: column.flex,
                        child: Align(
                          alignment: column.alignment,
                          child: Text(
                            column.label.toUpperCase(),
                            style: AppFonts.tableHeader(context),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            if (rows.isEmpty && emptyState != null)
              emptyState!
            else
              ...rows.asMap().entries.map(
                    (entry) => _Row(
                      columns: columns,
                      row: entry.value,
                      isLast: entry.key == rows.length - 1,
                    ),
                  ),
          ],
        ),
      );
}

class _Row extends StatelessWidget {
  final List<AppTableColumn> columns;
  final AppTableRow row;
  final bool isLast;

  const _Row({required this.columns, required this.row, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      color: row.background,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
      child: Row(
        children: List.generate(
          columns.length,
          (index) => Expanded(
            flex: columns[index].flex,
            child: Align(
              alignment: columns[index].alignment,
              child: index < row.cells.length
                  ? row.cells[index]
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );

    if (row.onTap == null) return content;
    return AppTappable(onTap: row.onTap, child: content);
  }
}
