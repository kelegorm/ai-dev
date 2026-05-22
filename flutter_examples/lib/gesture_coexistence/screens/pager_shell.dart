import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_examples/gesture_coexistence/gestures/gesture_tuning.dart';
import 'package:flutter_examples/gesture_coexistence/gestures/pan_intent.dart';
import 'package:flutter_examples/gesture_coexistence/gestures/velocity_tracker_1d.dart';
import 'package:flutter_examples/gesture_coexistence/router/app_router.dart';
import 'package:flutter_examples/gesture_coexistence/screens/canvas_screen.dart';
import 'package:flutter_examples/gesture_coexistence/screens/pager_scope.dart';
import 'package:flutter_examples/gesture_coexistence/screens/side_screen.dart';

/// Корневая оболочка примера — **bounded 3-страничный пейджер**.
///
/// Архитектура повторяет `shared_scaffold/root_shell.dart`, но проще: три
/// обычных таба ([LeftRoute], [CanvasRoute], [RightRoute]), без super-page,
/// без `SubStateController` и без BottomNav. Навигация — только свайпом.
///
/// - `@RoutePage()`-shell с 3 tab-children.
/// - Внутри — `AutoTabsRouter.builder`: tabsRouter держит route-state
///   (`activeIndex`), а layout (наш `PageView` + собственный
///   [PageController]) собирается в builder-колбеке.
/// - Канвас — в середине (initial index [kCanvasPagerPage]).
/// - Горизонтальный overflow с канваса (через [PagerScope]) двигает
///   [PageController] и синхронит `tabsRouter.setActiveIndex`. На краях
///   свайп упирается — листать дальше нечего, ничего не плодится.
/// - Outer `PageView` держит `NeverScrollableScrollPhysics`; свайп назад с
///   боковых экранов ловится root-level [Listener]'ом (на канвас-странице
///   листенер молчит — там работает собственный raw-Listener полотна).
class PagerShell extends StatefulWidget {
  const PagerShell({super.key});

  @override
  State<PagerShell> createState() => _PagerShellState();
}

/// auto_route-обёртка для корневого shell-route.
@RoutePage()
class PagerShellScreen extends StatelessWidget {
  const PagerShellScreen({super.key});

  @override
  Widget build(BuildContext context) => const PagerShell();
}

class _PagerShellState extends State<PagerShell> {
  final PageController _pc = PageController(initialPage: kCanvasPagerPage);

  TabsRouter? _tabsRouter;

  // Side-Listener state: ловит горизонтальные свайпы назад на боковых
  // экранах (outer PageView держит NeverScrollableScrollPhysics).
  final Map<int, Offset> _sidePointers = <int, Offset>{};
  Offset _sideStart = Offset.zero;
  PanIntent _sideIntent = PanIntent.undetermined;
  final VelocityTracker1D _sideVelocity = VelocityTracker1D();

  @override
  void initState() {
    super.initState();
    _pc.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _tabsRouter?.removeListener(_onTabsRouterChanged);
    _pc.removeListener(_onPageChanged);
    _pc.dispose();
    super.dispose();
  }

  /// Свайп/overflow двигают [PageController] напрямую — синхронизируем
  /// auto_route tabsRouter, когда дробная позиция приходит к целой странице.
  void _onPageChanged() {
    final router = _tabsRouter;
    if (router == null) return;
    final page = _pc.page;
    if (page == null) return;
    final rounded = page.round();
    if ((page - rounded).abs() < 0.001 && router.activeIndex != rounded) {
      router.setActiveIndex(rounded);
    }
  }

  /// Программное переключение таба (deep-link) → подтягиваем [PageController].
  void _onTabsRouterChanged() {
    final router = _tabsRouter;
    if (router == null || !_pc.hasClients) return;
    final target = router.activeIndex;
    final current = (_pc.page ?? target.toDouble()).round();
    if (current != target) {
      _pc.animateToPage(
        target,
        duration: kPagerSnapDuration,
        curve: Curves.easeOut,
      );
    }
  }

  // --- Overflow-колбеки из канваса (через PagerScope) --------------------

  /// Канвас сообщает overflow во время drag'а: двигаем outer PageView.
  void _onOverflowDelta(double dxPixels) {
    if (!_pc.hasClients) return;
    final pos = _pc.position;
    final newPx = (pos.pixels - dxPixels).clamp(
      pos.minScrollExtent,
      pos.maxScrollExtent,
    );
    if (newPx != pos.pixels) {
      pos.jumpTo(newPx);
    }
  }

  /// Канвас сообщает отпускание пальца после overflow: снапим к ближайшей
  /// странице с учётом скорости. На краях clamp не даёт уйти за пределы.
  void _onOverflowRelease(double velocityDxPerSec) {
    _snapToNearest(velocityDxPerSec);
  }

  // --- Side-Listener (свайп назад с боковых экранов) ---------------------

  /// Идёт ли сейчас snap-анимация пейджера (`animateToPage`), а не покой или
  /// ручной drag через `jumpTo`.
  bool get _isPagerAnimating =>
      _pc.hasClients && _pc.position.isScrollingNotifier.value;

  void _onSidePointerDown(PointerDownEvent e) {
    // На устойчиво стоящей канвас-странице свайпами управляет собственный
    // raw-Listener полотна — side-Listener молчит. Но пока идёт snap-анимация
    // пейджера, side-Listener остаётся владельцем жеста: повторный тач
    // перебивает анимацию через jumpTo, иначе она доигрывает до конца
    // игнорируя палец (полотно не владеет PageController'ом напрямую).
    if ((_pc.page ?? kCanvasPagerPage).round() == kCanvasPagerPage &&
        !_isPagerAnimating) {
      return;
    }
    _sidePointers[e.pointer] = e.position;
    if (_sidePointers.length == 1) {
      _sideStart = e.position;
      _sideIntent = PanIntent.undetermined;
      _sideVelocity.reset();
    }
  }

  void _onSidePointerMove(PointerMoveEvent e) {
    if (!_sidePointers.containsKey(e.pointer)) return;
    _sidePointers[e.pointer] = e.position;
    if (_sideIntent == PanIntent.undetermined) {
      _sideIntent = classifyPanIntent(start: _sideStart, current: e.position);
    }
    if (_sideIntent == PanIntent.horizontal) {
      _sideVelocity.record(e.timeStamp, e.delta.dx);
      final pos = _pc.position;
      final newPx = (pos.pixels - e.delta.dx).clamp(
        pos.minScrollExtent,
        pos.maxScrollExtent,
      );
      pos.jumpTo(newPx);
    }
  }

  void _onSidePointerUp(PointerUpEvent e) {
    _sidePointers.remove(e.pointer);
    _endSideGesture();
  }

  void _onSidePointerCancel(PointerCancelEvent e) {
    _sidePointers.remove(e.pointer);
    _endSideGesture();
  }

  void _endSideGesture() {
    if (_sidePointers.isNotEmpty) return;
    if (_sideIntent == PanIntent.horizontal) {
      _snapToNearest(_sideVelocity.velocity);
    }
    _sideIntent = PanIntent.undetermined;
  }

  /// Снапит outer PageView к ближайшей целой странице с учётом горизонтальной
  /// [velocityDxPerSec] (px/sec) для fling'а. Цель clamp'ится в [0, last] —
  /// на краях пейджер упирается.
  void _snapToNearest(double velocityDxPerSec) {
    if (!_pc.hasClients) return;
    final current = _pc.page ?? kCanvasPagerPage.toDouble();
    int target = current.round();
    if (velocityDxPerSec < -kNavVelocityThreshold) {
      target = current.floor() + 1;
    } else if (velocityDxPerSec > kNavVelocityThreshold) {
      target = current.ceil() - 1;
    }
    target = target.clamp(0, kLastPagerPage);
    _pc.animateToPage(
      target,
      duration: kPagerSnapDuration,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter.builder(
      routes: const [LeftRoute(), CanvasRoute(), RightRoute()],
      homeIndex: kCanvasPagerPage,
      builder: (context, _, tabsRouter) {
        if (!identical(_tabsRouter, tabsRouter)) {
          _tabsRouter?.removeListener(_onTabsRouterChanged);
          _tabsRouter = tabsRouter;
          tabsRouter.addListener(_onTabsRouterChanged);
        }
        return _buildShell();
      },
    );
  }

  Widget _buildShell() {
    final pageView = PageView(
      controller: _pc,
      physics: const NeverScrollableScrollPhysics(),
      children: const [LeftScreen(), CanvasScreen(), RightScreen()],
    );

    return Scaffold(
      // Root-level Listener — перехватывает горизонтальные свайпы назад на
      // боковых экранах raw-указателями: outer PageView держит
      // NeverScrollableScrollPhysics, а канвас-страница имеет собственный
      // raw-Listener, поэтому на ней этот листенер молчит.
      body: PagerScope(
        onOverflowDelta: _onOverflowDelta,
        onOverflowRelease: _onOverflowRelease,
        isPagerTransitioning: () => _isPagerAnimating,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _onSidePointerDown,
          onPointerMove: _onSidePointerMove,
          onPointerUp: _onSidePointerUp,
          onPointerCancel: _onSidePointerCancel,
          child: pageView,
        ),
      ),
    );
  }
}
