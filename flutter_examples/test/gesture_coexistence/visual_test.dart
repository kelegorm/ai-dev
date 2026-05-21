import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/_index.dart';

/// Голдены ключевых статических и переходных состояний bounded-пейджера.
///
/// Поведенческие тесты живут отдельно (navigation/zoom/scroll/tap) — эти
/// snapshot'ы ловят только визуальные регрессии (layout полотна, цвета
/// боковых экранов, фаза свайпа).
///
/// Перегенерация:
///   flutter test --update-goldens test/gesture_coexistence/visual_test.dart
void main() {
  testWidgets('голден: initial (канвас по центру пейджера)', (tester) async {
    await pumpGestureApp(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/canvas_initial.png'),
    );
  });

  testWidgets('голден: Right screen после fling влево', (tester) async {
    await pumpGestureApp(tester);
    await fling(tester, direction: SwipeDirection.left);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/right_screen.png'),
    );
  });

  testWidgets('голден: mid-swipe канвас → Right (палец ещё не отпущен)', (
    tester,
  ) async {
    await pumpGestureApp(tester);
    final gesture = await beginSwipe(
      tester,
      direction: SwipeDirection.left,
      fraction: 0.5,
    );
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/mid_swipe_canvas_to_right.png'),
    );
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
