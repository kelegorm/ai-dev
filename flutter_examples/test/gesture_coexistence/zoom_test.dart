import 'package:flutter_examples/gesture_coexistence/canvas/canvas_theme.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/_index.dart';

/// Pinch-зум канвас-полотна — только вертикальная ось (layout-zoom).
///
/// Ширина и horizontal layout не меняются: масштаб применяется только к высоте,
/// gap'ам, padding'у и font-size'у полосок.
///
/// Регрессии:
///   - Включить scaleX в `CanvasOverlay._applyPinch` → horizontal pinch начнёт
///     менять scaleY и тест на horizontal stretch упадёт.
///   - Убрать clamp `_effectiveMinScale` → pinch-close сделает scaleY ниже
///     viewport/contentHeight, тест на нижний край упадёт.
///   - Убрать `maxCanvasScale` clamp → pinch-open уведёт scaleY за предел.
void main() {
  group('Vertical pinch (single axis)', () {
    testWidgets('pinch-open двумя пальцами вертикально → scaleY > 1', (
      tester,
    ) async {
      await pumpGestureApp(tester);
      final initial = readCanvasOverlay(tester).debugScaleY;

      await verticalPinch(tester, scaleFactor: 1.6);

      final after = readCanvasOverlay(tester).debugScaleY;
      expect(after, greaterThan(initial));
      expect(after, lessThanOrEqualTo(maxCanvasScale));
    });

    testWidgets('pinch-close уменьшает scaleY, но не ниже viewport floor', (
      tester,
    ) async {
      await pumpGestureApp(tester);
      // pinch-open для headroom'а.
      await verticalPinch(tester, scaleFactor: 1.6);
      final afterOpen = readCanvasOverlay(tester).debugScaleY;
      // pinch-close агрессивный.
      await verticalPinch(tester, scaleFactor: 0.3);

      final overlay = readCanvasOverlay(tester);
      expect(overlay.debugScaleY, lessThan(afterOpen));
      // Эффективный минимум: max(minCanvasScale, viewport/contentHeight).
      final effectiveFloor = (overlay.debugViewportHeight / canvasContentHeight)
          .clamp(minCanvasScale, double.infinity);
      expect(overlay.debugScaleY, greaterThanOrEqualTo(effectiveFloor - 0.001));
    });

    testWidgets('максимальный pinch-open clamped на maxCanvasScale', (
      tester,
    ) async {
      await pumpGestureApp(tester);
      // Сильно «открыть» — больше, чем maxCanvasScale.
      await verticalPinch(tester, scaleFactor: 4.0);

      expect(
        readCanvasOverlay(tester).debugScaleY,
        closeTo(maxCanvasScale, 0.01),
      );
    });
  });

  group('Horizontal stretch не должен трогать scaleY', () {
    testWidgets('pinch с разъездом по горизонтали оставляет scaleY ~= 1', (
      tester,
    ) async {
      await pumpGestureApp(tester);
      final initial = readCanvasOverlay(tester).debugScaleY;

      await horizontalPinch(tester, scaleFactor: 2.0);

      // horizontal motion → dy ~= 0 → ratio span/initSpan ≈ 1.
      // Допускаем погрешность из-за дискретизации векторов.
      expect(readCanvasOverlay(tester).debugScaleY, closeTo(initial, 0.1));
    });
  });

  group('Pinch-tail (2→1 палец) не переключает страницу пейджера', () {
    testWidgets(
      'после pinch\'а подъём одного пальца + drag оставшимся не двигает '
      'страницу пейджера',
      (tester) async {
        await pumpGestureApp(tester);
        final pageBefore = readPagerPage(tester);

        // Pinch, затем отрыв одного пальца и длинный horizontal-drag
        // оставшимся — pinch-tail переводит палец в PanIntent.consumed,
        // overflow наружу не форвардится, пейджер стоит.
        await pinchThenDragRemaining(
          tester,
          scaleFactor: 1.6,
          tailDirection: SwipeDirection.left,
          tailFraction: kFullSwipeFraction,
        );

        expect(readPagerPage(tester), closeTo(pageBefore, 0.001));
      },
    );
  });
}
