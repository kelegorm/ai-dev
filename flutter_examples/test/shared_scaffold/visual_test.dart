import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/_index.dart';

/// Голдены ключевых статических и переходных состояний super-page.
///
/// Поведенческие тесты живут отдельно (swipe/navigation/animation/scroll) —
/// эти snapshot'ы ловят только визуальные регрессии (цвет UnifiedAppBar,
/// положение индикатора, выбранный BottomNav item, фаза свайпа).
///
/// Перегенерация:
///   flutter test --update-goldens test/shared_scaffold/visual_test.dart
void main() {
  testWidgets('голден: initial (tab 1, subState=0)', (tester) async {
    await pumpSharedScaffoldApp(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/tab1_initial.png'),
    );
  });

  testWidgets('голден: tab 2 после nav-tap', (tester) async {
    await pumpSharedScaffoldApp(tester);
    await tester.tap(find.byIcon(Icons.looks_two));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/tab2_after_nav_tap.png'),
    );
  });

  testWidgets('голден: tab 3 stub-экран', (tester) async {
    await pumpSharedScaffoldApp(tester);
    await tester.tap(find.byIcon(Icons.looks_3));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/tab3_stub.png'),
    );
  });

  testWidgets('голден: mid-swipe tab1 → tab2 (палец ещё не отпущен)', (
    tester,
  ) async {
    await pumpSharedScaffoldApp(tester);
    final gesture = await beginSwipe(
      tester,
      direction: SwipeDirection.left,
      fraction: 0.5,
    );
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/mid_swipe_tab1_to_tab2.png'),
    );
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
