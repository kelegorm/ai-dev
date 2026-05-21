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

/// Доля экрана для «полноразмерного» свайпа.
const double kFullSwipeFraction = 0.6;

/// Доля экрана для overflow-свайпа (tab2 → tab3): должна гарантированно
/// упереться в правый край subState и протолкнуть outer.
const double kOverflowSwipeFraction = 0.9;

/// Короткий drag — меньше distanceThreshold (0.18) → snap-back.
const double kShortDragFraction = 0.10;

/// Средний drag — больше distanceThreshold (0.18) → snap-forward.
const double kMediumDragFraction = 0.25;

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
/// распределяет timestamps между событиями.
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
