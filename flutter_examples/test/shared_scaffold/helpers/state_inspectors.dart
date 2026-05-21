import 'package:flutter/material.dart';
import 'package:flutter_examples/shared_scaffold/widgets/unified_app_bar.dart';
import 'package:flutter_test/flutter_test.dart';

/// Дробная позиция outer PageView'а (0 = super-page tab1/2, 1 = tab3, 2 = tab4).
///
/// `_RootShellState` приватный, поэтому позиция читается напрямую с
/// `PageController` единственного `PageView` в дереве примера. SubStatePager
/// и ListView вкладок не используют `PageView`, так что finder однозначен.
double readOuterPage(WidgetTester tester) {
  final pageView = tester.widget<PageView>(find.byType(PageView));
  final controller = pageView.controller;
  if (controller == null || !controller.hasClients) {
    throw StateError('Outer PageController has no clients');
  }
  return controller.page ?? 0.0;
}

/// Текущее значение `subState` (0 = tab1, 1 = tab2) super-page.
///
/// `UnifiedAppBar.subState` — публичный `ValueListenable<double>`, который
/// `RootShell` шарит между AppBar и swipe-логикой. Доступен только когда
/// активна super-page (outer-страница 0): на tab3/4 [UnifiedAppBar] вне дерева.
double readSubState(WidgetTester tester) {
  final appBar = tester.widget<UnifiedAppBar>(find.byType(UnifiedAppBar));
  return appBar.subState.value;
}

/// Активна ли сейчас super-page (есть ли [UnifiedAppBar] в дереве).
bool isSuperPageVisible(WidgetTester tester) =>
    find.byType(UnifiedAppBar).evaluate().isNotEmpty;

/// Текущий подсвеченный индекс BottomNav.
int readBottomNavIndex(WidgetTester tester) {
  final bar = tester.widget<BottomNavigationBar>(
    find.byType(BottomNavigationBar),
  );
  return bar.currentIndex;
}

/// Фон [UnifiedAppBar] (lerp tab1Accent ↔ tab2Accent).
Color readUnifiedAppBarColor(WidgetTester tester) {
  // UnifiedAppBar внутренне строит AppBar — ищем именно его. Под root'ом виден
  // только этот AppBar: outer PageView для tab3/4 рендерит StubTabPage отдельно.
  final appBar = tester.widget<AppBar>(
    find.descendant(
      of: find.byType(UnifiedAppBar),
      matching: find.byType(AppBar),
    ),
  );
  final color = appBar.backgroundColor;
  if (color == null) {
    throw StateError('UnifiedAppBar.backgroundColor is null');
  }
  return color;
}
