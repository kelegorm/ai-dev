import 'package:flutter/material.dart';
import 'package:flutter_examples/shared_scaffold/gestures/gesture_tuning.dart';

/// Владелец `subState` (0..1) — внутреннего состояния super-page tab1↔tab2.
///
/// Объединяет [ValueNotifier] значения и **единственный**
/// [AnimationController]: и snap после свайпа, и анимация по тапу BottomNav
/// идут через один контроллер, что исключает race двух конкурирующих
/// анимаций одного значения.
///
/// - [setRaw] — мгновенное присваивание (gesture-drag); останавливает
///   текущую анимацию.
/// - [animateTo] — анимированный snap к цели.
class SubStateController {
  SubStateController({
    required TickerProvider vsync,
    double initialValue = 0.0,
    Duration duration = kSubStateSnapDuration,
  }) : value = ValueNotifier<double>(initialValue) {
    _ctrl = AnimationController(vsync: vsync, duration: duration)
      ..addListener(_onTick);
  }

  /// Текущее значение subState. Слушатели (AppBar, BottomNav) подписываются
  /// на него напрямую.
  final ValueNotifier<double> value;

  late final AnimationController _ctrl;
  Animation<double>? _tween;

  void _onTick() {
    final tween = _tween;
    if (tween != null) {
      value.value = tween.value;
    }
  }

  /// Мгновенно присваивает значение (без анимации) и останавливает
  /// текущую анимацию, если она идёт.
  void setRaw(double v) {
    stopAnimation();
    value.value = v;
  }

  /// Анимирует значение к [target] с easeOut-кривой.
  void animateTo(double target) {
    if (_ctrl.isAnimating) _ctrl.stop();
    _tween = Tween<double>(
      begin: value.value,
      end: target,
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_ctrl);
    _ctrl.forward(from: 0);
  }

  /// Останавливает текущую анимацию, если она идёт.
  void stopAnimation() {
    if (_ctrl.isAnimating) _ctrl.stop();
  }

  /// Освобождает контроллер и notifier.
  void dispose() {
    _ctrl.dispose();
    value.dispose();
  }
}
