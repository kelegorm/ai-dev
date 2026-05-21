import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_examples/shared_scaffold/app_router.dart';
import 'package:flutter_examples/shared_scaffold/gestures/gesture_tuning.dart';
import 'package:flutter_examples/shared_scaffold/gestures/pan_intent.dart';
import 'package:flutter_examples/shared_scaffold/gestures/sub_state_controller.dart';
import 'package:flutter_examples/shared_scaffold/gestures/velocity_tracker_1d.dart';
import 'package:flutter_examples/shared_scaffold/pages/stub_tab_page.dart';
import 'package:flutter_examples/shared_scaffold/pages/super_page.dart';
import 'package:flutter_examples/shared_scaffold/shared_scaffold_scope.dart';

/// Корневая оболочка примера shared-scaffold.
///
/// Архитектура — **super-page для tab1/2 поверх auto_route**:
/// - Это `@RoutePage()`-shell с 3 outer-children-routes: `SuperPageRoute`,
///   `Tab3Route`, `Tab4Route`.
/// - Внутри строится `AutoTabsRouter.builder`: tabsRouter управляет ТОЛЬКО
///   route-state (`activeIndex`), а layout (outer PageView + собственный
///   [PageController]) собирается в builder-колбеке. Это даёт доступ к
///   дробному `pageController.page`, которого `AutoTabsRouter.pageView` не
///   предоставляет.
/// - SuperPage — единый Scaffold с единым UnifiedAppBar; tab1/tab2 — это
///   разные значения внутреннего `subState` (0..1).
/// - BottomNav — **4 элемента**: Tab1→outer 0 + subState 0, Tab2→outer 0 +
///   subState 1, Tab3/Tab4→outer 1/2.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

/// auto_route-обёртка для корневого shell-route.
@RoutePage()
class RootShellScreen extends StatelessWidget {
  const RootShellScreen({super.key});

  @override
  Widget build(BuildContext context) => const RootShell();
}

class _RootShellState extends State<RootShell>
    with SingleTickerProviderStateMixin {
  final PageController _pc = PageController();
  late final SubStateController _subState;

  TabsRouter? _tabsRouter;

  /// Дробная позиция outer PageView'а. [ValueNotifier], а не поле + `setState`:
  /// точечный rebuild только зависимых поддеревьев (BottomNav).
  final ValueNotifier<double> _outerPage = ValueNotifier<double>(0.0);

  // Outer-Listener state: ловит горизонтальные свайпы на tab3/4, потому что
  // outer PageView держит NeverScrollableScrollPhysics.
  final Map<int, Offset> _outerPointers = <int, Offset>{};
  Offset _outerStart = Offset.zero;
  PanIntent _outerIntent = PanIntent.undetermined;
  final VelocityTracker1D _outerVelocity = VelocityTracker1D();

  @override
  void initState() {
    super.initState();
    _subState = SubStateController(vsync: this);
    _pc.addListener(_onOuterPageChanged);
  }

  void _onOuterPageChanged() {
    _outerPage.value = _pc.page ?? 0.0;
    _syncTabsRouterFromOuterPage();
  }

  /// Свайп/overflow двигают [PageController] напрямую — синхронизируем
  /// auto_route tabsRouter, когда дробная позиция приходит к целой странице.
  void _syncTabsRouterFromOuterPage() {
    final router = _tabsRouter;
    if (router == null) return;
    final page = _pc.page;
    if (page == null) return;
    final rounded = page.round();
    if ((page - rounded).abs() < 0.001 && router.activeIndex != rounded) {
      router.setActiveIndex(rounded);
    }
  }

  @override
  void dispose() {
    _tabsRouter?.removeListener(_onTabsRouterChanged);
    _pc.removeListener(_onOuterPageChanged);
    _pc.dispose();
    _subState.dispose();
    _outerPage.dispose();
    super.dispose();
  }

  int get _currentBottomNavIndex {
    final outer = _outerPage.value.round().clamp(0, kLastOuterPage);
    if (outer == 0) {
      return _subState.value.value >= kSubStateNavThreshold ? 1 : 0;
    }
    return outer + 1;
  }

  // --- Overflow-колбеки из SubStatePager ---------------------------------

  /// Super-page сообщает overflow во время drag'а: двигаем outer PageView.
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

  /// Super-page сообщает отпускание пальца после overflow: снапим outer
  /// к ближайшей странице.
  void _onOverflowRelease(double velocityDxPerSec) {
    _snapOuterToNearest(velocityDxPerSec);
  }

  // --- Outer Listener (свайпы на tab3/4) ---------------------------------

  void _onOuterPointerDown(PointerDownEvent e) {
    // Свайпами на SuperPage управляет SubStatePager (subState + overflow).
    // Outer Listener трогает только tab3/4.
    if (_outerPage.value.round() == 0) return;
    _outerPointers[e.pointer] = e.position;
    if (_outerPointers.length == 1) {
      _outerStart = e.position;
      _outerIntent = PanIntent.undetermined;
      _outerVelocity.reset();
    }
  }

  void _onOuterPointerMove(PointerMoveEvent e) {
    if (!_outerPointers.containsKey(e.pointer)) return;
    _outerPointers[e.pointer] = e.position;
    if (_outerIntent == PanIntent.undetermined) {
      _outerIntent = classifyPanIntent(start: _outerStart, current: e.position);
    }
    if (_outerIntent == PanIntent.horizontal) {
      _outerVelocity.record(e.timeStamp, e.delta.dx);
      final pos = _pc.position;
      final newPx = (pos.pixels - e.delta.dx).clamp(
        pos.minScrollExtent,
        pos.maxScrollExtent,
      );
      pos.jumpTo(newPx);
    }
  }

  void _onOuterPointerUp(PointerUpEvent e) {
    _outerPointers.remove(e.pointer);
    _endOuterGesture();
  }

  void _onOuterPointerCancel(PointerCancelEvent e) {
    // cancel идёт тем же путём, что и up: иначе outer PageView застрял бы
    // на дробной позиции.
    _outerPointers.remove(e.pointer);
    _endOuterGesture();
  }

  void _endOuterGesture() {
    if (_outerPointers.isNotEmpty) return;
    if (_outerIntent == PanIntent.horizontal) {
      _snapOuterToNearest(_outerVelocity.velocity);
    }
    _outerIntent = PanIntent.undetermined;
  }

  /// Снапит outer PageView к ближайшей целой странице с учётом горизонтальной
  /// [velocityDxPerSec] (px/sec) для fling'а.
  void _snapOuterToNearest(double velocityDxPerSec) {
    if (!_pc.hasClients) return;
    final current = _outerPage.value;
    int target = current.round();
    if (velocityDxPerSec < -kSnapVelocityThreshold) {
      target = current.floor() + 1;
    } else if (velocityDxPerSec > kSnapVelocityThreshold) {
      target = current.ceil() - 1;
    }
    target = target.clamp(0, kLastOuterPage);
    _pc.animateToPage(
      target,
      duration: kOuterSnapDuration,
      curve: Curves.easeOut,
    );
  }

  void _onNavTap(int navIndex) {
    // 4 nav items → 3 outer routes:
    //   0,1 → outer 0 (super-page tab1/2) + subState 0/1
    //   2,3 → outer 1,2 (tab3,4)
    if (navIndex <= 1) {
      _pc.animateToPage(0, duration: kOuterSnapDuration, curve: Curves.easeOut);
      _subState.animateTo(navIndex == 0 ? 0.0 : 1.0);
    } else {
      _pc.animateToPage(
        navIndex - 1,
        duration: kOuterSnapDuration,
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SharedScaffoldScope(
      subStateController: _subState,
      onOverflowDelta: _onOverflowDelta,
      onOverflowRelease: _onOverflowRelease,
      child: AutoTabsRouter.builder(
        routes: const [SuperPageRoute(), Tab3Route(), Tab4Route()],
        builder: (context, _, tabsRouter) {
          if (!identical(_tabsRouter, tabsRouter)) {
            _tabsRouter?.removeListener(_onTabsRouterChanged);
            _tabsRouter = tabsRouter;
            tabsRouter.addListener(_onTabsRouterChanged);
          }
          return _buildShell();
        },
      ),
    );
  }

  /// Программное переключение tab'а (deep-link) → подтягиваем [PageController]
  /// к новой целевой странице.
  void _onTabsRouterChanged() {
    final router = _tabsRouter;
    if (router == null || !_pc.hasClients) return;
    final target = router.activeIndex;
    if (_outerPage.value.round() != target) {
      _pc.animateToPage(
        target,
        duration: kOuterSnapDuration,
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildShell() {
    final pageView = PageView(
      controller: _pc,
      physics: const NeverScrollableScrollPhysics(),
      children: const [SuperPageScreen(), Tab3Screen(), Tab4Screen()],
    );

    return Scaffold(
      // Root-level Listener — перехватывает горизонтальные свайпы tab3/4 raw-
      // указателями: outer PageView держит NeverScrollableScrollPhysics
      // (чтобы не конфликтовать с SubStatePager внутри SuperPage), поэтому
      // листание tab3↔4 делается вручную здесь.
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onOuterPointerDown,
        onPointerMove: _onOuterPointerMove,
        onPointerUp: _onOuterPointerUp,
        onPointerCancel: _onOuterPointerCancel,
        child: pageView,
      ),
      bottomNavigationBar: ValueListenableBuilder<double>(
        valueListenable: _outerPage,
        builder: (context, _, _) {
          return ValueListenableBuilder<double>(
            valueListenable: _subState.value,
            builder: (context, _, _) {
              return BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _currentBottomNavIndex,
                onTap: _onNavTap,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.looks_one),
                    label: 'Tab 1',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.looks_two),
                    label: 'Tab 2',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.looks_3),
                    label: 'Tab 3',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.looks_4),
                    label: 'Tab 4',
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
