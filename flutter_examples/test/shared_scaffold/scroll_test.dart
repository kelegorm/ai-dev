import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/_index.dart';

/// Вертикальный scroll контента вкладки super-page.
///
/// Контент каждой вкладки — обычный `ListView` (без pinch/zoom). `SubStatePager`
/// ставит translucent-`Listener`, который только наблюдает: вертикальный жест
/// он намеренно игнорирует, поэтому `ListView` вкладки скроллится сам.
///
/// `SubStatePager` строит обе вкладки в `Row`, поэтому в дереве два `ListView`;
/// активная (tab1) — первая, к ней и обращаемся через `.first`.
///
/// Регрессии:
///   - Обработать `PanIntent.vertical` в `SubStatePager._onPointerMove` →
///     вертикальный жест начнёт перехватываться и `ListView` перестанет
///     скроллиться / subState задёргается.
void main() {
  testWidgets('вертикальный свайп скроллит ListView вкладки', (tester) async {
    await pumpSharedScaffoldApp(tester);

    final tab1List = find.byType(ListView).first;
    final scrollable = find.descendant(
      of: tab1List,
      matching: find.byType(Scrollable),
    );
    // Позицию читаем со ScrollableState напрямую: обе вкладки делят
    // PrimaryScrollController, поэтому `controller.position` неоднозначен.
    final before = tester.state<ScrollableState>(scrollable).position.pixels;

    await tester.drag(tab1List, const Offset(0, -300));
    await tester.pumpAndSettle();

    final after = tester.state<ScrollableState>(scrollable).position.pixels;
    // ListView уехал вверх: позиция выросла относительно стартовой.
    expect(after, greaterThan(before));
  });

  testWidgets('вертикальный свайп не двигает subState', (tester) async {
    await pumpSharedScaffoldApp(tester);
    expect(readSubState(tester), closeTo(0.0, 0.001));

    await swipe(tester, direction: SwipeDirection.up, fraction: 0.5);

    // subState не сдвинулся — вертикальный жест не классифицируется как
    // горизонтальный и не трогает tab1↔tab2.
    expect(readSubState(tester), closeTo(0.0, 0.001));
    expect(readOuterPage(tester), closeTo(0.0, 0.001));
  });

  testWidgets('после vertical scroll нижние item\'ы вкладки доступны', (
    tester,
  ) async {
    await pumpSharedScaffoldApp(tester);

    // Скроллим вкладку tab1 вниз и проверяем, что появился поздний item.
    await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(find.text('Tab 1 · item 30'), findsOneWidget);
  });
}
