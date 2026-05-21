import 'dart:ui' show Offset, Size;

import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

/// Направление одно-пальцевого жеста.
enum SwipeDirection { left, right, up, down }

/// Количество шагов в дроблении drag'а — приближает к реальному жесту и
/// помогает intent-classifier'у пересечь порог 4 px.
const int kSwipeSteps = 16;

/// Длительность тика между шагами drag'а (≈60 Гц).
const Duration kSwipeStepDuration = Duration(milliseconds: 16);

/// Длительность тика между шагами pinch'а.
const Duration kPinchStepDuration = Duration(milliseconds: 16);

/// Доля экрана для «полноразмерного» свайпа.
const double kFullSwipeFraction = 0.6;

/// Короткий drag — недостаточно, чтобы сработал distance-snap (порог 0.25).
const double kShortDragFraction = 0.10;

/// Средний drag — больше kNavDistanceFraction (0.25).
const double kMediumDragFraction = 0.4;

/// Расположение по центру экрана.
Offset _center(Size size) => Offset(size.width / 2, size.height / 2);

Offset _delta(Size size, SwipeDirection direction, double fraction) {
  return switch (direction) {
    SwipeDirection.left => Offset(-size.width * fraction, 0),
    SwipeDirection.right => Offset(size.width * fraction, 0),
    SwipeDirection.up => Offset(0, -size.height * fraction),
    SwipeDirection.down => Offset(0, size.height * fraction),
  };
}

/// Базовый «slow drag» — без явной velocity, intent определяется направлением.
Future<void> swipe(
  WidgetTester tester, {
  required SwipeDirection direction,
  double fraction = kFullSwipeFraction,
  Offset? from,
  int steps = kSwipeSteps,
}) async {
  final size = getViewSize(tester);
  final origin = from ?? _center(size);
  final delta = _delta(size, direction, fraction);
  final gesture = await tester.startGesture(origin);
  final stepDelta = delta / steps.toDouble();
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(stepDelta);
    await tester.pump(kSwipeStepDuration);
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

/// «Fling»-свайп: тот же drag, но с явной финальной velocity. Под капотом
/// использует встроенный [WidgetTester.flingFrom], который корректно
/// распределяет timestamps между событиями (самописный moveBy+pump триггерит
/// velocity tracker'у dt=0 → velocity не считается).
Future<void> fling(
  WidgetTester tester, {
  required SwipeDirection direction,
  double fraction = kMediumDragFraction,
  double speed = 2000,
  Offset? from,
}) async {
  final size = getViewSize(tester);
  final origin = from ?? _center(size);
  final delta = _delta(size, direction, fraction);
  await tester.flingFrom(origin, delta, speed);
  await tester.pumpAndSettle();
}

/// Mid-swipe drag без отпускания пальца. Возвращает активный жест — caller
/// обязан вызвать `.up()` и `pumpAndSettle()` сам.
Future<TestGesture> beginSwipe(
  WidgetTester tester, {
  required SwipeDirection direction,
  double fraction = 0.5,
  Offset? from,
  int steps = kSwipeSteps,
}) async {
  final size = getViewSize(tester);
  final origin = from ?? _center(size);
  final delta = _delta(size, direction, fraction);
  final gesture = await tester.startGesture(origin);
  final stepDelta = delta / steps.toDouble();
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(stepDelta);
    await tester.pump(kSwipeStepDuration);
  }
  return gesture;
}

/// Horizontal-drag, который завершается **отменой** жеста ([TestGesture.cancel])
/// вместо штатного `up()`. Моделирует pointer-cancel (например, перехват жеста
/// системным навигационным сёрфейсом).
Future<void> swipeThenCancel(
  WidgetTester tester, {
  required SwipeDirection direction,
  double fraction = kFullSwipeFraction,
  Offset? from,
  int steps = kSwipeSteps,
}) async {
  final size = getViewSize(tester);
  final origin = from ?? _center(size);
  final delta = _delta(size, direction, fraction);
  final gesture = await tester.startGesture(origin);
  final stepDelta = delta / steps.toDouble();
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(stepDelta);
    await tester.pump(kSwipeStepDuration);
  }
  await gesture.cancel();
  await tester.pumpAndSettle();
}

/// Pinch двумя пальцами по вертикальной оси.
///
/// [scaleFactor] >1 = «открыть» (zoom in), <1 = «закрыть» (zoom out).
/// Точки начинаются на расстоянии [baselineSpread] логических px вокруг
/// [center] и расходятся/сходятся по вертикали в [scaleFactor] раз.
Future<void> verticalPinch(
  WidgetTester tester, {
  required double scaleFactor,
  Offset? center,
  double baselineSpread = 200,
  int steps = 24,
}) async {
  final size = getViewSize(tester);
  final c = center ?? _center(size);
  final half = baselineSpread / 2;
  final p1Start = Offset(c.dx, c.dy - half);
  final p2Start = Offset(c.dx, c.dy + half);
  final p1End = Offset(c.dx, c.dy - half * scaleFactor);
  final p2End = Offset(c.dx, c.dy + half * scaleFactor);

  final g1 = await tester.startGesture(p1Start, pointer: 1);
  final g2 = await tester.startGesture(p2Start, pointer: 2);

  for (var i = 1; i <= steps; i++) {
    final t = i / steps;
    await g1.moveTo(Offset.lerp(p1Start, p1End, t)!);
    await g2.moveTo(Offset.lerp(p2Start, p2End, t)!);
    await tester.pump(kPinchStepDuration);
  }
  await g1.up();
  await g2.up();
  await tester.pumpAndSettle();
}

/// Pinch по горизонтальной оси — для regression-теста, что overlay игнорирует
/// horizontal stretch (canvas не должен растягиваться по ширине, scaleY ~= 1).
Future<void> horizontalPinch(
  WidgetTester tester, {
  required double scaleFactor,
  Offset? center,
  double baselineSpread = 200,
  int steps = 24,
}) async {
  final size = getViewSize(tester);
  final c = center ?? _center(size);
  final half = baselineSpread / 2;
  final p1Start = Offset(c.dx - half, c.dy);
  final p2Start = Offset(c.dx + half, c.dy);
  final p1End = Offset(c.dx - half * scaleFactor, c.dy);
  final p2End = Offset(c.dx + half * scaleFactor, c.dy);

  final g1 = await tester.startGesture(p1Start, pointer: 1);
  final g2 = await tester.startGesture(p2Start, pointer: 2);

  for (var i = 1; i <= steps; i++) {
    final t = i / steps;
    await g1.moveTo(Offset.lerp(p1Start, p1End, t)!);
    await g2.moveTo(Offset.lerp(p2Start, p2End, t)!);
    await tester.pump(kPinchStepDuration);
  }
  await g1.up();
  await g2.up();
  await tester.pumpAndSettle();
}

/// Pinch двумя пальцами, затем подъём одного пальца и продолжение движения
/// оставшимся — моделирует pinch-tail (2→1 палец).
///
/// Шаги: оба пальца расходятся вертикально на [scaleFactor]; затем второй
/// палец отрывается, а первый делает горизонтальный drag длиной [tailFraction]
/// от ширины экрана и отпускается. Используется для проверки, что pinch-tail
/// не триггерит навигацию пейджера ([PanIntent.consumed]).
Future<void> pinchThenDragRemaining(
  WidgetTester tester, {
  required double scaleFactor,
  SwipeDirection tailDirection = SwipeDirection.left,
  double tailFraction = kFullSwipeFraction,
  Offset? center,
  double baselineSpread = 200,
  int steps = 24,
}) async {
  final size = getViewSize(tester);
  final c = center ?? _center(size);
  final half = baselineSpread / 2;
  final p1Start = Offset(c.dx, c.dy - half);
  final p2Start = Offset(c.dx, c.dy + half);
  final p1End = Offset(c.dx, c.dy - half * scaleFactor);
  final p2End = Offset(c.dx, c.dy + half * scaleFactor);

  final g1 = await tester.startGesture(p1Start, pointer: 1);
  final g2 = await tester.startGesture(p2Start, pointer: 2);

  for (var i = 1; i <= steps; i++) {
    final t = i / steps;
    await g1.moveTo(Offset.lerp(p1Start, p1End, t)!);
    await g2.moveTo(Offset.lerp(p2Start, p2End, t)!);
    await tester.pump(kPinchStepDuration);
  }

  // Второй палец отрывается — остаётся pinch-tail из одного пальца.
  await g2.up();
  await tester.pump(kPinchStepDuration);

  // Оставшийся палец делает горизонтальный drag.
  final tailDelta = _delta(size, tailDirection, tailFraction);
  final tailStep = tailDelta / kSwipeSteps.toDouble();
  for (var i = 0; i < kSwipeSteps; i++) {
    await g1.moveBy(tailStep);
    await tester.pump(kSwipeStepDuration);
  }
  await g1.up();
  await tester.pumpAndSettle();
}
