import 'package:flutter/material.dart';
import 'package:flutter_examples/shared_scaffold/gestures/gesture_tuning.dart';
import 'package:flutter_examples/shared_scaffold/gestures/pan_intent.dart';
import 'package:flutter_examples/shared_scaffold/gestures/sub_state_controller.dart';
import 'package:flutter_examples/shared_scaffold/gestures/velocity_tracker_1d.dart';

/// Горизонтальный pager двух вкладок super-page, управляемый `subState`.
///
/// Заменяет полотно из приёма gesture-coexistence сильно упрощённой версией:
/// здесь нужны только два жеста — горизонтальный свайп между tab1/tab2 и
/// вертикальный scroll внутри вкладки. Pinch/zoom выпилены полностью.
///
/// Горизонтальный свайп ловится raw [Listener]'ом вне арены и двигает
/// `subState` (0..1); вертикальный жест намеренно игнорируется здесь —
/// translucent-`Listener` только наблюдает, поэтому обычный вертикальный
/// `ListView` каждой вкладки скроллится сам.
///
/// При overflow (subState упёрся в 0/1, палец продолжает) excess форвардится
/// наружу через [onOverflowDelta]; на отпускании, если был overflow, —
/// [onOverflowRelease]. Тот же контракт overflow-колбеков, что в приёме
/// gesture-coexistence, — так два приёма стыкуются.
class SubStatePager extends StatefulWidget {
  const SubStatePager({
    super.key,
    required this.subStateController,
    required this.onOverflowDelta,
    required this.onOverflowRelease,
    required this.tab1,
    required this.tab2,
  });

  final SubStateController subStateController;
  final ValueChanged<double> onOverflowDelta;
  final ValueChanged<double> onOverflowRelease;
  final Widget tab1;
  final Widget tab2;

  @override
  State<SubStatePager> createState() => _SubStatePagerState();
}

class _SubStatePagerState extends State<SubStatePager> {
  SubStateController get _subState => widget.subStateController;

  final Map<int, Offset> _pointers = <int, Offset>{};

  Offset _singleStart = Offset.zero;
  PanIntent _singleIntent = PanIntent.undetermined;

  double _subStateAtGestureStart = 0.0;
  bool _outerMovedDuringGesture = false;
  final VelocityTracker1D _horizontalVelocity = VelocityTracker1D();

  double _viewportWidth = 0.0;

  void _onPointerDown(PointerDownEvent e) {
    _subState.stopAnimation();
    _pointers[e.pointer] = e.position;
    if (_pointers.length == 1) {
      _singleStart = e.position;
      _singleIntent = PanIntent.undetermined;
      _subStateAtGestureStart = _subState.value.value;
      _outerMovedDuringGesture = false;
      _horizontalVelocity.reset();
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.position;
    if (_pointers.length >= 2) return;

    if (_singleIntent == PanIntent.undetermined) {
      _singleIntent = classifyPanIntent(
        start: _singleStart,
        current: e.position,
      );
    }
    if (_singleIntent == PanIntent.horizontal) {
      _horizontalVelocity.record(e.timeStamp, e.delta.dx);
      _applyHorizontalDelta(e.delta.dx);
    }
    // PanIntent.vertical намеренно не обрабатывается — вертикальный scroll
    // делает ListView вкладки сам, под translucent-Listener'ом.
  }

  /// Палец двигается на dx (>0 = вправо, <0 = влево). Сначала двигаем
  /// subState; если упёрлись в [0, 1] — excess форвардится наружу.
  void _applyHorizontalDelta(double dx) {
    if (_viewportWidth <= 0) return;
    final subDelta = -dx / _viewportWidth; // палец влево → subState++
    final newSub = _subState.value.value + subDelta;

    if (newSub >= 0.0 && newSub <= 1.0) {
      _subState.setRaw(newSub);
    } else if (newSub > 1.0) {
      _subState.setRaw(1.0);
      final excessSub = newSub - 1.0;
      _outerMovedDuringGesture = true;
      widget.onOverflowDelta(-excessSub * _viewportWidth);
    } else {
      _subState.setRaw(0.0);
    }
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
    if (_pointers.isNotEmpty) return;
    if (_singleIntent == PanIntent.horizontal) {
      _settleHorizontal();
    }
    _singleIntent = PanIntent.undetermined;
  }

  /// Доводит горизонтальный жест до устойчивого состояния. Если был overflow
  /// в outer — снапит его через [SubStatePager.onOverflowRelease]; иначе
  /// снапит subState tab1↔tab2.
  void _settleHorizontal() {
    if (_outerMovedDuringGesture) {
      widget.onOverflowRelease(_horizontalVelocity.velocity);
      return;
    }
    _snapSubState();
  }

  void _snapSubState() {
    final value = _subState.value.value;
    final velocityInSubPerSec = _viewportWidth > 0
        ? -_horizontalVelocity.velocity / _viewportWidth
        : 0.0;
    final delta = value - _subStateAtGestureStart;
    final velocityThresholdInSub = _viewportWidth > 0
        ? kSnapVelocityThreshold / _viewportWidth
        : kSnapVelocityThreshold;
    double target = _subStateAtGestureStart.round().toDouble();
    if (delta > kSnapDistanceFraction ||
        velocityInSubPerSec > velocityThresholdInSub) {
      target = (_subStateAtGestureStart.round() + 1).toDouble();
    } else if (delta < -kSnapDistanceFraction ||
        velocityInSubPerSec < -velocityThresholdInSub) {
      target = (_subStateAtGestureStart.round() - 1).toDouble();
    }
    target = target.clamp(0.0, 1.0);
    _subState.animateTo(target);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportWidth = constraints.maxWidth;
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _subState.value,
              builder: (context, _) {
                final sub = _subState.value.value.clamp(0.0, 1.0);
                final offsetX = -sub * _viewportWidth;
                return Transform.translate(
                  offset: Offset(offsetX, 0),
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    minWidth: _viewportWidth * 2,
                    maxWidth: _viewportWidth * 2,
                    child: Row(
                      children: [
                        SizedBox(width: _viewportWidth, child: widget.tab1),
                        SizedBox(width: _viewportWidth, child: widget.tab2),
                      ],
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
