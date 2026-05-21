import 'package:flutter_examples/gesture_coexistence/canvas/canvas_theme.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/_index.dart';

/// Vertical pan + inertia (`FrictionSimulation`) + clamp границ контента.
///
/// Регрессии:
///   - Убрать `_clampTranslate` в `_onPointerMove` → drag вниз при translateY=0
///     уведёт content в пустоту (translateY станет положительным).
///   - Убрать `_clampTranslate` при тике fling'а → inertia уведёт content за
///     нижнюю границу.
///   - Убрать `_startFling` / `FrictionSimulation` → после release content
///     застынет мгновенно, inertia-тест упадёт.
///   - Убрать `_stopFling` из `_onPointerDown` → tap во время inertia
///     не остановит её.
void main() {
  testWidgets('vertical drag вверх смещает content (translateY < 0)', (
    tester,
  ) async {
    await pumpGestureApp(tester);
    final initial = readCanvasOverlay(tester).debugTranslateY;
    expect(initial, 0.0);

    await swipe(tester, direction: SwipeDirection.up, fraction: 0.4);

    expect(readCanvasOverlay(tester).debugTranslateY, lessThan(0));
  });

  testWidgets('clamp сверху: drag вниз при translateY=0 не уводит выше 0', (
    tester,
  ) async {
    await pumpGestureApp(tester);
    expect(readCanvasOverlay(tester).debugTranslateY, 0.0);

    await swipe(tester, direction: SwipeDirection.down, fraction: 0.5);

    // FrictionSimulation может «дёрнуть» в дельту, но clamp обнуляет.
    // После pumpAndSettle всё должно вернуться к 0 либо остаться 0.
    final overlay = readCanvasOverlay(tester);
    expect(overlay.debugTranslateY, lessThanOrEqualTo(0.001));
    expect(overlay.debugTranslateY, greaterThanOrEqualTo(-0.001));
  });

  testWidgets(
    'clamp снизу: длинный drag вверх упирается в нижнюю границу контента',
    (tester) async {
      await pumpGestureApp(tester);
      // Несколько свайпов вверх с pump'ом между ними, чтобы добраться до дна.
      for (var i = 0; i < 8; i++) {
        await swipe(tester, direction: SwipeDirection.up, fraction: 0.7);
      }
      final overlay = readCanvasOverlay(tester);
      final scaledH = canvasContentHeight * overlay.debugScaleY;
      final floor = overlay.debugViewportHeight - scaledH;
      expect(overlay.debugTranslateY, greaterThanOrEqualTo(floor - 0.5));
      // Дополнительный drag вверх не уведёт ниже floor'а.
      await swipe(tester, direction: SwipeDirection.up, fraction: 0.5);
      expect(
        readCanvasOverlay(tester).debugTranslateY,
        greaterThanOrEqualTo(floor - 0.5),
      );
    },
  );

  testWidgets('inertia: fling вверх → content продолжает ехать после release', (
    tester,
  ) async {
    await pumpGestureApp(tester);
    final size = getViewSize(tester);
    // tester.flingFrom — встроенный helper, корректно эмулирует velocity через
    // распределённые timestamps между событиями.
    await tester.flingFrom(
      Offset(size.width / 2, size.height * 0.6),
      Offset(0, -size.height * 0.3),
      2000, // px/sec
    );
    // Один кадр — fling уже animate.
    await tester.pump(const Duration(milliseconds: 16));
    final tyAfter16 = readCanvasOverlay(tester).debugTranslateY;
    expect(readCanvasOverlay(tester).debugFlingIsAnimating, isTrue);
    // Ещё кадр — должно проехать дальше.
    await tester.pump(const Duration(milliseconds: 50));
    final tyAfter66 = readCanvasOverlay(tester).debugTranslateY;
    expect(
      tyAfter66,
      lessThan(tyAfter16 - 1.0),
      reason: 'inertia должна сместить content за 50ms '
          '($tyAfter16 → $tyAfter66)',
    );
    await tester.pumpAndSettle();
  });

  testWidgets('tap во время inertia останавливает fling', (tester) async {
    await pumpGestureApp(tester);
    final size = getViewSize(tester);
    await tester.flingFrom(
      Offset(size.width / 2, size.height * 0.6),
      Offset(0, -size.height * 0.3),
      2000,
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(
      readCanvasOverlay(tester).debugFlingIsAnimating,
      isTrue,
      reason: 'после release fling должен быть в движении',
    );

    // Tap во время inertia → _stopFling в _onPointerDown.
    final tap = await tester.startGesture(
      Offset(size.width / 2, size.height * 0.5),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(
      readCanvasOverlay(tester).debugFlingIsAnimating,
      isFalse,
      reason: 'tap должен остановить fling через _stopFling',
    );
    await tap.up();
    await tester.pumpAndSettle();
  });
}
