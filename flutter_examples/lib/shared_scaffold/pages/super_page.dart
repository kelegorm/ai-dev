import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_examples/shared_scaffold/gestures/sub_state_controller.dart';
import 'package:flutter_examples/shared_scaffold/shared_scaffold_scope.dart';
import 'package:flutter_examples/shared_scaffold/theme.dart';
import 'package:flutter_examples/shared_scaffold/widgets/sub_state_pager.dart';
import 'package:flutter_examples/shared_scaffold/widgets/tab_list.dart';
import 'package:flutter_examples/shared_scaffold/widgets/unified_app_bar.dart';

/// auto_route-обёртка над [SuperPage].
///
/// auto_route конструирует route-страницы сам, поэтому живые зависимости
/// ([SubStateController], overflow-колбеки) берутся из [SharedScaffoldScope]
/// через `context`, а не из конструктора.
@RoutePage()
class SuperPageScreen extends StatelessWidget {
  const SuperPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = SharedScaffoldScope.of(context);
    return SuperPage(
      subStateController: scope.subStateController,
      onOverflowDelta: scope.onOverflowDelta,
      onOverflowRelease: scope.onOverflowRelease,
      isOuterTransitioning: scope.isOuterTransitioning,
    );
  }
}

/// Super-page для tab1 + tab2: единый Scaffold с единым [UnifiedAppBar].
///
/// tab1 и tab2 — это разные значения внутреннего `subState` (0..1), а НЕ
/// разные outer-route'ы. Свайп между ними двигает subState; AppBar (фон +
/// индикатор) едет за пальцем дробно. Когда subState упирается в границу и
/// палец продолжает, overflow форвардится наружу — RootShell запускает
/// outer-slide на соседний stub-экран.
///
/// Архитектурный смысл: tab1/tab2 визуально едины (один AppBar, один скролл-
/// контейнер), но при свайпе на tab3 super-page едет как одно целое — никаких
/// «двух AppBar'ов, заменяющих друг друга».
class SuperPage extends StatelessWidget {
  const SuperPage({
    super.key,
    required this.subStateController,
    required this.onOverflowDelta,
    required this.onOverflowRelease,
    required this.isOuterTransitioning,
  });

  final SubStateController subStateController;
  final ValueChanged<double> onOverflowDelta;
  final ValueChanged<double> onOverflowRelease;

  /// Идёт ли сейчас snap-анимация outer PageView — пробрасывается в
  /// [SubStatePager], чтобы тот не двигал subState во время outer-транзишена.
  final bool Function() isOuterTransitioning;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UnifiedAppBar(subState: subStateController.value),
      body: SubStatePager(
        subStateController: subStateController,
        onOverflowDelta: onOverflowDelta,
        onOverflowRelease: onOverflowRelease,
        isOuterTransitioning: isOuterTransitioning,
        tab1: const TabList(label: 'Tab 1', accent: tab1Accent),
        tab2: const TabList(label: 'Tab 2', accent: tab2Accent),
      ),
    );
  }
}
