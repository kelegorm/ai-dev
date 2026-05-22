import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_examples/gesture_coexistence/canvas/canvas_content.dart';
import 'package:flutter_examples/gesture_coexistence/canvas/canvas_theme.dart';
import 'package:flutter_examples/gesture_coexistence/canvas/oversized_hit_test_box.dart';
import 'package:flutter_examples/gesture_coexistence/gestures/gesture_tuning.dart';
import 'package:flutter_examples/gesture_coexistence/gestures/pan_intent.dart';
import 'package:flutter_examples/gesture_coexistence/gestures/velocity_tracker_1d.dart';

/// Полотно, на котором одновременно сосуществуют четыре конфликтующих жеста:
/// горизонтальный свайп (навигация), вертикальный pan (scroll контента),
/// двух-пальцевый pinch (zoom) и tap по полоске.
///
/// Все жесты наблюдаются через один raw [Listener] вне gesture arena —
/// арена не способна развести перекрывающиеся жесты, поэтому она обходится,
/// а намерение одно-пальцевого жеста классифицируется вручную.
///
/// **Горизонтальный свайп — навигация.** В этом примере у полотна нет
/// собственного внутреннего горизонтального состояния (в отличие от
/// super-page приёма, где свайп сначала двигал бы `subState`). Любой
/// горизонтальный delta форвардится наружу через [onOverflowDelta], а на
/// отпускании пальца — [onOverflowRelease] со скоростью. Хост-экран решает,
/// перейти ли на соседний route. `CanvasOverlay` не знает механику навигации.
class CanvasOverlay extends StatefulWidget {
  const CanvasOverlay({
    super.key,
    required this.onOverflowDelta,
    required this.onOverflowRelease,
    required this.isPagerTransitioning,
    this.onStripeTap,
  });

  /// Вызывается во время горизонтального drag'а: [dxPixels] — горизонтальное
  /// смещение пальца в пикселях (>0 = вправо).
  final ValueChanged<double> onOverflowDelta;

  /// Вызывается на отпускании пальца после горизонтального жеста:
  /// [velocityDxPerSec] — горизонтальная скорость в px/sec.
  final ValueChanged<double> onOverflowRelease;

  /// Идёт ли сейчас snap-анимация пейджера. Если да — на pointer-down полотно
  /// сразу помечает жест как [PanIntent.consumed] (инертный): пока идёт
  /// транзишен, горизонталь принадлежит side-Listener'у хоста (он перебивает
  /// анимацию через jumpTo). Иначе overflow-форвард полотна двигал бы пейджер
  /// параллельно с side-Listener'ом — двойной jumpTo.
  final bool Function() isPagerTransitioning;

  final ValueChanged<int>? onStripeTap;

  @override
  State<CanvasOverlay> createState() => CanvasOverlayState();
}

class CanvasOverlayState extends State<CanvasOverlay>
    with TickerProviderStateMixin {
  // Pinch/scroll state.
  double _scaleY = 1.0;
  double _translateY = 0.0;

  final Map<int, Offset> _pointers = <int, Offset>{};

  // Single-finger intent classifier.
  Offset _singleStart = Offset.zero;
  PanIntent _singleIntent = PanIntent.undetermined;

  // Horizontal gesture tracking.
  bool _horizontalMovedDuringGesture = false;
  final VelocityTracker1D _horizontalVelocity = VelocityTracker1D();

  // Vertical fling tracking.
  final VelocityTracker1D _verticalVelocity = VelocityTracker1D();
  late final AnimationController _flingCtrl;

  // Pinch baseline.
  double _pinchInitSpan = 1.0;
  double _pinchInitScaleY = 1.0;
  double _pinchInitWorldY = 0.0;

  // Viewport, обновляется в build через LayoutBuilder.
  double _viewportHeight = 0.0;

  @override
  void initState() {
    super.initState();
    _flingCtrl = AnimationController.unbounded(vsync: this)
      ..addListener(_onFlingTick);
  }

  @override
  void dispose() {
    _flingCtrl.dispose();
    super.dispose();
  }

  /// Текущий вертикальный масштаб полотна — для поведенческих тестов.
  @visibleForTesting
  double get debugScaleY => _scaleY;

  /// Текущее вертикальное смещение контента — для поведенческих тестов.
  @visibleForTesting
  double get debugTranslateY => _translateY;

  /// Высота viewport'а полотна — для поведенческих тестов.
  @visibleForTesting
  double get debugViewportHeight => _viewportHeight;

  /// Идёт ли сейчас inertia-анимация — для поведенческих тестов.
  @visibleForTesting
  bool get debugFlingIsAnimating => _flingCtrl.isAnimating;

  void _onFlingTick() {
    final raw = _flingCtrl.value;
    final clamped = _clampTranslate(raw, _scaleY);
    setState(() => _translateY = clamped);
    if (clamped != raw && _flingCtrl.isAnimating) {
      _flingCtrl.stop();
    }
  }

  void _startFling(double velocityDyPerSec) {
    if (velocityDyPerSec.abs() < kMinFlingVelocity) return;
    final sim = FrictionSimulation(
      kFlingFriction,
      _translateY,
      velocityDyPerSec,
    );
    _flingCtrl.value = _translateY;
    _flingCtrl.animateWith(sim);
  }

  void _stopFling() {
    if (_flingCtrl.isAnimating) _flingCtrl.stop();
  }

  double get _effectiveMinScale {
    if (_viewportHeight <= 0) return minCanvasScale;
    return math.max(minCanvasScale, _viewportHeight / canvasContentHeight);
  }

  double _clampTranslate(double ty, double scaleY) {
    if (_viewportHeight <= 0) return ty;
    final scaledH = canvasContentHeight * scaleY;
    if (scaledH <= _viewportHeight) return 0.0;
    return ty.clamp(_viewportHeight - scaledH, 0.0);
  }

  void _onPointerDown(PointerDownEvent e) {
    _stopFling();
    _pointers[e.pointer] = e.position;
    if (_pointers.length == 1) {
      _singleStart = e.position;
      // Во время snap-анимации пейджера горизонталь принадлежит side-Listener'у
      // хоста — полотно сразу делает жест инертным (как хвост pinch'а).
      _singleIntent = widget.isPagerTransitioning()
          ? PanIntent.consumed
          : PanIntent.undetermined;
      _horizontalMovedDuringGesture = false;
      _horizontalVelocity.reset();
      _verticalVelocity.reset();
    } else if (_pointers.length == 2) {
      _capturePinchBaseline();
    }
  }

  void _capturePinchBaseline() {
    final pts = _pointers.values.toList();
    final span = (pts[0].dy - pts[1].dy).abs();
    final midY = (pts[0].dy + pts[1].dy) / 2;
    _pinchInitSpan = span.clamp(kPinchMinSpan, double.infinity);
    _pinchInitScaleY = _scaleY;
    _pinchInitWorldY = (midY - _translateY) / _scaleY;
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.position;

    if (_pointers.length >= 2) {
      _applyPinch();
      return;
    }

    // Жест уже отработан pinch'ем — оставшийся палец инертен.
    if (_singleIntent == PanIntent.consumed) return;

    if (_singleIntent == PanIntent.undetermined) {
      _singleIntent = classifyPanIntent(
        start: _singleStart,
        current: e.position,
      );
    }
    if (_singleIntent == PanIntent.vertical) {
      _verticalVelocity.record(e.timeStamp, e.delta.dy);
      setState(() {
        _translateY = _clampTranslate(_translateY + e.delta.dy, _scaleY);
      });
    } else if (_singleIntent == PanIntent.horizontal) {
      _horizontalVelocity.record(e.timeStamp, e.delta.dx);
      _horizontalMovedDuringGesture = true;
      widget.onOverflowDelta(e.delta.dx);
    }
  }

  void _applyPinch() {
    final pts = _pointers.values.toList();
    final span = (pts[0].dy - pts[1].dy).abs().clamp(
      kPinchMinSpan,
      double.infinity,
    );
    final midY = (pts[0].dy + pts[1].dy) / 2;
    final ratio = span / _pinchInitSpan;
    final newScaleY = (_pinchInitScaleY * ratio).clamp(
      _effectiveMinScale,
      maxCanvasScale,
    );
    final anchoredTranslateY = midY - _pinchInitWorldY * newScaleY;
    setState(() {
      _scaleY = newScaleY;
      _translateY = _clampTranslate(anchoredTranslateY, newScaleY);
    });
  }

  void _onPointerUp(PointerUpEvent e) {
    _pointers.remove(e.pointer);
    _afterPointerRemoved();
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _pointers.remove(e.pointer);
    _afterPointerRemoved();
  }

  void _afterPointerRemoved() {
    if (_pointers.length == 1) {
      // Хвост pinch'а: 2→1 палец. Оставшийся палец переводим в инертное
      // состояние — он не должен ни pan'ить, ни на отпускании триггерить
      // навигацию/fling.
      final remaining = _pointers.values.first;
      _singleStart = remaining;
      _singleIntent = PanIntent.consumed;
    } else if (_pointers.isEmpty) {
      switch (_singleIntent) {
        case PanIntent.horizontal:
          _settleHorizontal();
        case PanIntent.vertical:
          _startFling(_verticalVelocity.velocity);
        case PanIntent.consumed:
          _settleHorizontal();
        case PanIntent.undetermined:
          break;
      }
      _singleIntent = PanIntent.undetermined;
    }
  }

  /// Сообщает хост-экрану об окончании горизонтального жеста: тот решит,
  /// перейти ли на соседний route. Если за жест горизонтального движения не
  /// было — release не отправляется.
  void _settleHorizontal() {
    if (!_horizontalMovedDuringGesture) return;
    widget.onOverflowRelease(_horizontalVelocity.velocity);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportHeight = constraints.maxHeight;
        final canvasWidth = constraints.maxWidth;

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: ClipRect(
            child: Builder(
              builder: (context) {
                final clampedTy = _clampTranslate(_translateY, _scaleY);
                final scaledContentHeight = canvasContentHeight * _scaleY;

                return Transform(
                  transform: Matrix4.identity()
                    ..translateByDouble(0, clampedTy, 0, 1),
                  child: OversizedHitTestBox(
                    childSize: Size(canvasWidth, scaledContentHeight),
                    child: CanvasContent(
                      canvasWidth: canvasWidth,
                      scaleY: _scaleY,
                      onStripeTap: widget.onStripeTap,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
