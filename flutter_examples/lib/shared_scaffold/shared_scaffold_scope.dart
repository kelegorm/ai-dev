import 'package:flutter/material.dart';
import 'package:flutter_examples/shared_scaffold/gestures/sub_state_controller.dart';

/// Проброс shared-зависимостей в route-страницы примера.
///
/// auto_route сам конструирует `@RoutePage`-виджеты, поэтому живые объекты
/// ([SubStateController]) и колбеки (`onOverflowDelta` / `onOverflowRelease`)
/// нельзя передать через конструктор route-страницы. Решение — положить их в
/// [InheritedWidget] над `AutoTabsRouter`: route-страница (`SuperPageScreen`)
/// достаёт их из `context` через [SharedScaffoldScope.of].
class SharedScaffoldScope extends InheritedWidget {
  const SharedScaffoldScope({
    super.key,
    required this.subStateController,
    required this.onOverflowDelta,
    required this.onOverflowRelease,
    required super.child,
  });

  final SubStateController subStateController;
  final ValueChanged<double> onOverflowDelta;
  final ValueChanged<double> onOverflowRelease;

  static SharedScaffoldScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<SharedScaffoldScope>();
    assert(scope != null, 'SharedScaffoldScope not found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(SharedScaffoldScope oldWidget) {
    // Зависимости создаются один раз в RootShellState и живут весь lifecycle
    // примера — перестраивать зависимые поддеревья не нужно.
    return false;
  }
}
