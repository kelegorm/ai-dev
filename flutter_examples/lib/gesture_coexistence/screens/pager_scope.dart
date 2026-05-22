import 'package:flutter/material.dart';

/// Контракт, через который канвас-экран форвардит горизонтальный overflow
/// в bounded-пейджер хоста ([PagerShell]).
///
/// Канвас не знает ни про `PageController`, ни про `tabsRouter` — он лишь
/// сообщает delta во время drag'а и release со скоростью. Хост решает, на
/// какую страницу снапнуть.
class PagerScope extends InheritedWidget {
  const PagerScope({
    super.key,
    required this.onOverflowDelta,
    required this.onOverflowRelease,
    required this.isPagerTransitioning,
    required super.child,
  });

  /// Горизонтальное смещение пальца за тик (px, >0 = вправо).
  final ValueChanged<double> onOverflowDelta;

  /// Отпускание пальца после горизонтального жеста: скорость в px/sec.
  final ValueChanged<double> onOverflowRelease;

  /// Идёт ли сейчас snap-анимация пейджера. Полотно читает это на
  /// pointer-down: во время транзишена горизонталь принадлежит side-Listener'у
  /// хоста (он перебивает анимацию), а не overflow-форварду полотна.
  final bool Function() isPagerTransitioning;

  static PagerScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PagerScope>();
    assert(scope != null, 'PagerScope not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(PagerScope oldWidget) =>
      onOverflowDelta != oldWidget.onOverflowDelta ||
      onOverflowRelease != oldWidget.onOverflowRelease ||
      isPagerTransitioning != oldWidget.isPagerTransitioning;
}
