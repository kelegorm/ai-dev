import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/_index.dart';

/// BottomNav-маппинг 4 items → 3 outer routes:
///   nav 0 → outer 0 + subState 0 (Tab 1)
///   nav 1 → outer 0 + subState 1 (Tab 2)
///   nav 2 → outer 1 (Tab 3)
///   nav 3 → outer 2 (Tab 4)
///
/// Регрессии:
///   - Поломать маппинг в `_onNavTap` → один из тестов на конкретный таб
///     даст неправильный outerPage / subState.
///   - Поломать `_currentBottomNavIndex` → currentIndex после tap'а станет
///     неверным.
void main() {
  testWidgets('tap Tab 1: outer = 0, subState = 0, nav = 0', (tester) async {
    await pumpSharedScaffoldApp(tester);
    // Сначала уходим с tab1.
    await tester.tap(find.byIcon(Icons.looks_3));
    await tester.pumpAndSettle();
    // Возвращаемся.
    await tester.tap(find.byIcon(Icons.looks_one));
    await tester.pumpAndSettle();

    expect(readOuterPage(tester), closeTo(0.0, 0.001));
    expect(readSubState(tester), closeTo(0.0, 0.001));
    expect(readBottomNavIndex(tester), 0);
  });

  testWidgets('tap Tab 2: outer = 0, subState = 1, nav = 1', (tester) async {
    await pumpSharedScaffoldApp(tester);
    await tester.tap(find.byIcon(Icons.looks_two));
    await tester.pumpAndSettle();

    expect(readOuterPage(tester), closeTo(0.0, 0.001));
    expect(readSubState(tester), closeTo(1.0, 0.001));
    expect(readBottomNavIndex(tester), 1);
  });

  testWidgets('tap Tab 3: outer = 1, nav = 2', (tester) async {
    await pumpSharedScaffoldApp(tester);
    await tester.tap(find.byIcon(Icons.looks_3));
    await tester.pumpAndSettle();

    expect(readOuterPage(tester), closeTo(1.0, 0.001));
    expect(readBottomNavIndex(tester), 2);
    expect(isSuperPageVisible(tester), isFalse);
  });

  testWidgets('tap Tab 4: outer = 2, nav = 3', (tester) async {
    await pumpSharedScaffoldApp(tester);
    await tester.tap(find.byIcon(Icons.looks_4));
    await tester.pumpAndSettle();

    expect(readOuterPage(tester), closeTo(2.0, 0.001));
    expect(readBottomNavIndex(tester), 3);
  });

  testWidgets('tap Tab 3 → Tab 4 свайпом влево', (tester) async {
    await pumpSharedScaffoldApp(tester);
    await tester.tap(find.byIcon(Icons.looks_3));
    await tester.pumpAndSettle();

    // На tab3 свайпами управляет root-level outer-Listener.
    await swipe(tester, direction: SwipeDirection.left);

    expect(readOuterPage(tester), closeTo(2.0, 0.05));
    expect(readBottomNavIndex(tester), 3);
  });

  testWidgets(
    'tab4 правый край: свайп влево остаётся на tab4 (clamp на outer)',
    (tester) async {
      await pumpSharedScaffoldApp(tester);
      await tester.tap(find.byIcon(Icons.looks_4));
      await tester.pumpAndSettle();
      // Ещё свайп влево — листать дальше нечего.
      await swipe(tester, direction: SwipeDirection.left);

      expect(readOuterPage(tester), closeTo(2.0, 0.05));
      expect(readBottomNavIndex(tester), 3);
    },
  );

  testWidgets(
    'pointer-cancel на tab3 снапит outer к целой странице',
    (tester) async {
      await pumpSharedScaffoldApp(tester);
      await tester.tap(find.byIcon(Icons.looks_3));
      await tester.pumpAndSettle();

      // Horizontal-drag на tab3, затем отмена жеста вместо up().
      await swipeThenCancel(
        tester,
        direction: SwipeDirection.left,
        fraction: kMediumDragFraction,
      );

      final outer = readOuterPage(tester);
      expect(outer, closeTo(outer.roundToDouble(), 0.001));
    },
  );
}
