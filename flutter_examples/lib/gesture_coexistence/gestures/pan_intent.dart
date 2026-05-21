import 'dart:ui' show Offset;

import 'package:flutter_examples/gesture_coexistence/gestures/gesture_tuning.dart';

/// Намерение одно-пальцевого pan-жеста.
///
/// Пока смещение пальца мало, намерение [undetermined]; как только пересечён
/// порог по одной из осей — фиксируется [horizontal] или [vertical] и больше
/// не меняется до конца жеста.
///
/// [consumed] — особое «инертное» состояние: жест уже отработан другим
/// механизмом (например, был pinch), и оставшиеся на экране пальцы не должны
/// ни pan'ить, ни триггерить snap/fling до полного отрыва. Назначается, а не
/// возвращается из [classifyPanIntent].
enum PanIntent { undetermined, horizontal, vertical, consumed }

/// Классифицирует намерение pan-жеста по смещению от точки старта.
///
/// Чистая функция: горизонталь требует заметного `dx`, доминирующего над
/// `dy`; вертикаль требует более крупного `dy`, доминирующего над `dx`.
/// Если ни одно условие не выполнено — [PanIntent.undetermined], и caller
/// должен вызвать функцию снова на следующем move-событии.
PanIntent classifyPanIntent({required Offset start, required Offset current}) {
  final dx = (current.dx - start.dx).abs();
  final dy = (current.dy - start.dy).abs();
  if (dx > kIntentMinDx && dx > dy * kIntentDxDyRatio) {
    return PanIntent.horizontal;
  }
  if (dy > kIntentMinDy && dy > dx) {
    return PanIntent.vertical;
  }
  return PanIntent.undetermined;
}
