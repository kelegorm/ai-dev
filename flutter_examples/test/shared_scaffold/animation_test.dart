import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/_index.dart';

/// Анимации subState:
///   - nav-tap Tab 2 анимирует subState 0 → 1 через `SubStateController`
///     (~250ms, easeOut) — не прыгает за один тик.
///   - snap-on-release читает `kSnapDistanceFraction` = 0.18: drag 0.10 →
///     snap back, drag 0.25 → snap forward.
///
/// Регрессии:
///   - Заменить duration nav-анимации на «мгновенно» → тест на длительность
///     поймает (subState прыгнет за один тик).
///   - Понизить `kSnapDistanceFraction` → drag 0.10 пойдёт forward, тест на
///     snap-back упадёт.
void main() {
  testWidgets(
    'nav-tap Tab 2: subState не доходит до 1 за первые 50ms (идёт анимация)',
    (tester) async {
      await pumpSharedScaffoldApp(tester);
      // pumpAndSettle сделан внутри pump-хелпера → subState = 0.
      await tester.tap(find.byIcon(Icons.looks_two));
      // Пропускаем только 50ms из ~250 → значение должно быть «в пути».
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(readSubState(tester), greaterThan(0.0));
      expect(readSubState(tester), lessThan(1.0));

      await tester.pumpAndSettle();
      expect(readSubState(tester), closeTo(1.0, 0.001));
    },
  );

  testWidgets(
    'nav-tap Tab 1 после Tab 2: subState анимирует 1 → 0, outer не двигается',
    (tester) async {
      await pumpSharedScaffoldApp(tester);
      await tester.tap(find.byIcon(Icons.looks_two));
      await tester.pumpAndSettle();
      expect(readSubState(tester), closeTo(1.0, 0.001));

      await tester.tap(find.byIcon(Icons.looks_one));
      await tester.pumpAndSettle();

      expect(readSubState(tester), closeTo(0.0, 0.001));
      expect(readOuterPage(tester), closeTo(0.0, 0.001));
    },
  );

  testWidgets('snap-on-release: drag 0.10 < threshold → snap back к 0', (
    tester,
  ) async {
    await pumpSharedScaffoldApp(tester);
    await swipe(tester, direction: SwipeDirection.left, fraction: 0.10);

    expect(readSubState(tester), closeTo(0.0, 0.01));
  });

  testWidgets('snap-on-release: drag 0.25 > threshold → snap forward к 1', (
    tester,
  ) async {
    await pumpSharedScaffoldApp(tester);
    await swipe(tester, direction: SwipeDirection.left, fraction: 0.25);

    expect(readSubState(tester), closeTo(1.0, 0.01));
  });
}
