import 'package:flutter_test/flutter_test.dart';

import 'helpers/_index.dart';

/// Свайп-навигация по bounded 3-страничному пейджеру (Left ↔ Canvas ↔ Right).
///
/// Канвас — центральная страница (index 1). Горизонтальный свайп по полотну
/// форвардится в хост-пейджер: влево уводит на Right (2), вправо — на Left (0).
/// На краях пейджер упирается — листать дальше нечего.
///
/// Снап пейджера (`PagerShell._snapToNearest`) — round-to-nearest по дробной
/// позиции плюс fling-ветка по скорости: быстрый свайп уводит на соседнюю
/// страницу даже при малой дистанции. Поэтому навигационные жесты здесь —
/// `fling` (реальная velocity через `flingFrom`), а не медленный `swipe`.
///
/// Все assertions — поведенческие (позиция `PageController`'а), не голдены.
///
/// Регрессии:
///   - Убрать overflow forwarding в `CanvasOverlay._settleHorizontal` →
///     свайп по полотну перестанет переключать страницу пейджера.
///   - Убрать clamp в `_snapToNearest` → свайп на краю уйдёт за пределы.
///   - Убрать root-level side-`Listener` в `PagerShell` → свайп назад с
///     бокового экрана перестанет работать.
void main() {
  group('Свайп с канваса переключает страницу пейджера', () {
    testWidgets('fling влево уводит Canvas → Right (page 2)', (tester) async {
      await pumpGestureApp(tester);
      expect(readPagerPage(tester), closeTo(1.0, 0.001));

      await fling(tester, direction: SwipeDirection.left);

      expect(readPagerPage(tester), closeTo(2.0, 0.001));
      // SideScreen рисует label и в AppBar, и в body — отсюда findsWidgets.
      expect(find.text('Right screen'), findsWidgets);
    });

    testWidgets('fling вправо уводит Canvas → Left (page 0)', (tester) async {
      await pumpGestureApp(tester);

      await fling(tester, direction: SwipeDirection.right);

      expect(readPagerPage(tester), closeTo(0.0, 0.001));
      // SideScreen рисует label и в AppBar, и в body — отсюда findsWidgets.
      expect(find.text('Left screen'), findsWidgets);
    });
  });

  group('Упор на краях пейджера', () {
    testWidgets('на правом краю (Right) fling влево остаётся на page 2', (
      tester,
    ) async {
      await pumpGestureApp(tester);
      // Canvas → Right.
      await fling(tester, direction: SwipeDirection.left);
      expect(readPagerPage(tester), closeTo(2.0, 0.001));
      // Ещё свайп влево — упор: листать дальше нечего.
      await swipe(tester, direction: SwipeDirection.left);

      expect(readPagerPage(tester), closeTo(2.0, 0.001));
    });

    testWidgets('на левом краю (Left) fling вправо остаётся на page 0', (
      tester,
    ) async {
      await pumpGestureApp(tester);
      // Canvas → Left.
      await fling(tester, direction: SwipeDirection.right);
      expect(readPagerPage(tester), closeTo(0.0, 0.001));
      // Ещё свайп вправо — упор.
      await swipe(tester, direction: SwipeDirection.right);

      expect(readPagerPage(tester), closeTo(0.0, 0.001));
    });
  });

  group('Свайп назад с бокового экрана', () {
    testWidgets('с Right свайпом вправо возврат на Canvas (page 1)', (
      tester,
    ) async {
      await pumpGestureApp(tester);
      await fling(tester, direction: SwipeDirection.left); // → Right
      expect(readPagerPage(tester), closeTo(2.0, 0.001));

      // Свайп вправо ловится root-level side-Listener'ом хоста.
      await fling(tester, direction: SwipeDirection.right);

      expect(readPagerPage(tester), closeTo(1.0, 0.001));
    });

    testWidgets('с Left свайпом влево возврат на Canvas (page 1)', (
      tester,
    ) async {
      await pumpGestureApp(tester);
      await fling(tester, direction: SwipeDirection.right); // → Left
      expect(readPagerPage(tester), closeTo(0.0, 0.001));

      await fling(tester, direction: SwipeDirection.left);

      expect(readPagerPage(tester), closeTo(1.0, 0.001));
    });
  });

  group('Snap-on-release', () {
    testWidgets(
      'короткий медленный drag без скорости snap-back к Canvas',
      (tester) async {
        await pumpGestureApp(tester);
        // Малая дистанция, без fling-скорости: round-to-nearest даёт 1.
        await swipe(
          tester,
          direction: SwipeDirection.left,
          fraction: kShortDragFraction,
          steps: 40,
        );

        expect(readPagerPage(tester), closeTo(1.0, 0.001));
      },
    );

    testWidgets('быстрый fling snap-forward к Right даже на малой дистанции', (
      tester,
    ) async {
      await pumpGestureApp(tester);
      // Малая дистанция, но реальная velocity > kNavVelocityThreshold.
      await fling(
        tester,
        direction: SwipeDirection.left,
        fraction: kShortDragFraction,
        speed: 2500,
      );

      expect(readPagerPage(tester), closeTo(2.0, 0.001));
    });
  });

  group('Pointer-cancel во время свайпа', () {
    testWidgets('cancel жеста снапит пейджер к целой странице', (tester) async {
      await pumpGestureApp(tester);

      // Horizontal-drag по полотну, затем cancel вместо up().
      await swipeThenCancel(
        tester,
        direction: SwipeDirection.left,
        fraction: kMediumDragFraction,
      );

      // Пейджер снапнут к целой странице — не застрял на дробной.
      final page = readPagerPage(tester);
      expect(page, closeTo(page.roundToDouble(), 0.001));
    });
  });

  group('Один свайп = одна соседняя страница', () {
    testWidgets(
      'очень длинный свайп влево переводит максимум на соседнюю Right',
      (tester) async {
        await pumpGestureApp(tester);
        // Очень длинный overflow-свайп от правого края.
        final size = getViewSize(tester);
        await swipe(
          tester,
          direction: SwipeDirection.left,
          fraction: 0.95,
          from: Offset(size.width * 0.98, size.height / 2),
        );

        // Один жест переводит ровно на соседнюю страницу, не дальше:
        // дробная позиция упирается шириной одного экрана, snap round'ится.
        expect(readPagerPage(tester), closeTo(2.0, 0.001));
      },
    );
  });
}
