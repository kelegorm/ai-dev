import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/_index.dart';

/// Поведение горизонтальных свайпов внутри super-page (tab1 ↔ tab2 через
/// `subState`) и overflow tab2 → tab3 (excess форвардится в outer PageView).
///
/// Все assertions — поведенческие (state inspection), не голдены.
///
/// Регрессии:
///   - Убрать overflow forwarding в `SubStatePager._applyHorizontalDelta` →
///     overflow-свайп tab2→tab3 перестанет переключать outer-страницу.
///   - Убрать clamp `[0, 1]` для subState → свайп уведёт subState за пределы.
///   - Убрать clamp в `_snapOuterToNearest` → overflow уйдёт за пределы routes.
void main() {
  group('Свайпы внутри super-page (tab1 ↔ tab2)', () {
    testWidgets('tab1 → tab2 переключает subState, outer остаётся на 0', (
      tester,
    ) async {
      await pumpSharedScaffoldApp(tester);
      await swipe(tester, direction: SwipeDirection.left);

      expect(readSubState(tester), closeTo(1.0, 0.01));
      expect(readOuterPage(tester), closeTo(0.0, 0.001));
      expect(readBottomNavIndex(tester), 1);
    });

    testWidgets('tab2 → tab1 свайпом вправо возвращает subState к 0', (
      tester,
    ) async {
      await pumpSharedScaffoldApp(tester);
      await swipe(tester, direction: SwipeDirection.left);
      await swipe(tester, direction: SwipeDirection.right);

      expect(readSubState(tester), closeTo(0.0, 0.01));
      expect(readOuterPage(tester), closeTo(0.0, 0.001));
      expect(readBottomNavIndex(tester), 0);
    });

    testWidgets(
      'tab1 левый край: свайп вправо не двигает subState ниже 0',
      (tester) async {
        await pumpSharedScaffoldApp(tester);
        await swipe(tester, direction: SwipeDirection.right);

        expect(readSubState(tester), closeTo(0.0, 0.001));
        expect(readOuterPage(tester), closeTo(0.0, 0.001));
        expect(readBottomNavIndex(tester), 0);
      },
    );
  });

  group('Overflow forwarding tab2 → tab3', () {
    testWidgets(
      'overflow-свайп с tab2 уводит outer на tab3 (page index = 1)',
      (tester) async {
        await pumpSharedScaffoldApp(tester);
        // На tab2.
        await swipe(tester, direction: SwipeDirection.left);
        expect(readSubState(tester), closeTo(1.0, 0.01));
        // Длинный свайп влево — упирается в subState=1 и форвардит outer.
        await swipe(
          tester,
          direction: SwipeDirection.left,
          fraction: kOverflowSwipeFraction,
        );

        expect(readOuterPage(tester), closeTo(1.0, 0.001));
        expect(readBottomNavIndex(tester), 2);
      },
    );

    testWidgets(
      'tab3 → super-page свайпом вправо сохраняет subState (был tab2)',
      (tester) async {
        await pumpSharedScaffoldApp(tester);
        // На tab2 (subState=1), затем на tab3 тапом BottomNav.
        await swipe(tester, direction: SwipeDirection.left);
        await tester.tap(find.byIcon(Icons.looks_3));
        await tester.pumpAndSettle();
        expect(readOuterPage(tester), closeTo(1.0, 0.001));
        // Свайп вправо — возврат на super-page.
        await swipe(tester, direction: SwipeDirection.right);

        expect(readOuterPage(tester), closeTo(0.0, 0.001));
        // subState сохранился = 1: мы были на tab2 перед уходом на tab3.
        expect(readSubState(tester), closeTo(1.0, 0.05));
        expect(readBottomNavIndex(tester), 1);
      },
    );
  });

  group('Snap-on-release subState', () {
    testWidgets(
      'короткий drag (< distance threshold) snap-back к subState 0',
      (tester) async {
        await pumpSharedScaffoldApp(tester);
        // distanceThreshold = 0.18; drag = 0.10 → snap back к subState 0.
        await swipe(
          tester,
          direction: SwipeDirection.left,
          fraction: kShortDragFraction,
        );

        expect(readSubState(tester), closeTo(0.0, 0.01));
        expect(readBottomNavIndex(tester), 0);
      },
    );

    testWidgets(
      'средний drag (> distance threshold) snap-forward к subState 1',
      (tester) async {
        await pumpSharedScaffoldApp(tester);
        await swipe(
          tester,
          direction: SwipeDirection.left,
          fraction: kMediumDragFraction,
        );

        expect(readSubState(tester), closeTo(1.0, 0.01));
        expect(readBottomNavIndex(tester), 1);
      },
    );
  });

  group('Pointer-cancel во время свайпа', () {
    testWidgets(
      'cancel свайпа на super-page снапит subState к целому значению',
      (tester) async {
        await pumpSharedScaffoldApp(tester);

        // Horizontal-drag на tab1, затем отмена жеста вместо up().
        await swipeThenCancel(
          tester,
          direction: SwipeDirection.left,
          fraction: kMediumDragFraction,
        );

        // subState снапнут к целому (0.0 или 1.0) — не застрял на дробной.
        final sub = readSubState(tester);
        expect(sub, closeTo(sub.roundToDouble(), 0.01));
      },
    );
  });
}
