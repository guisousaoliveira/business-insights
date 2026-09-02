import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app/settings/app_assets.dart';
import 'package:salon_app/ui/components/app_icon.dart';
import 'package:salon_app/ui/components/app_nav.dart';

/// O sino da app bar mora dentro de um `AppTappable` de 40dp de altura mínima,
/// bem maior que o ícone de 19. Quem centraliza o ícone nessa sobra é o próprio
/// `Icon`; o `Stack` do badge, se alinhar no canto, joga o ícone para o topo — e
/// aí ele muda de lugar toda vez que o contador cruza o zero.
void main() {
  Future<Offset> centroDoIcone(WidgetTester tester, int count) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: AppBadge(
              count: count,
              child: const AppIcon(AppAssets.alert, size: 19),
            ),
          ),
        ),
      ),
    );

    return tester.getCenter(find.byType(Icon));
  }

  testWidgets('o ícone não muda de lugar quando o badge aparece',
      (tester) async {
    final semBadge = await centroDoIcone(tester, 0);
    final comBadge = await centroDoIcone(tester, 3);

    expect(comBadge, semBadge);
  });

  testWidgets(
      'o badge fica ancorado no canto do ícone, não no do alvo de toque',
      (tester) async {
    await centroDoIcone(tester, 3);

    final icone = tester.getRect(find.byType(Icon));
    final badge = tester.getRect(find.byType(Container));

    expect(badge.top, icone.top - 4);
    expect(badge.right, icone.right + 6);
  });
}
