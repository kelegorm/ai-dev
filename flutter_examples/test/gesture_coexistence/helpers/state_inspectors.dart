import 'package:flutter/material.dart';
import 'package:flutter_examples/gesture_coexistence/canvas/canvas_overlay.dart';
import 'package:flutter_test/flutter_test.dart';

/// Достаёт state канвас-полотна.
///
/// `CanvasOverlayState` публичный — полотно живёт на центральной странице
/// bounded-пейджера и существует, пока активна канвас-страница (или соседняя,
/// благодаря keepAlive `PageView`).
CanvasOverlayState readCanvasOverlay(WidgetTester tester) =>
    tester.state<CanvasOverlayState>(find.byType(CanvasOverlay));

/// Дробная позиция bounded-пейджера (0 = Left, 1 = Canvas, 2 = Right).
///
/// Хост `PagerShell` держит layout на собственном `PageController`,
/// прикреплённом к outer `PageView`. `_PagerShellState` приватный, поэтому
/// позиция читается напрямую с контроллера `PageView` — это единственный
/// `PageView` в дереве примера.
double readPagerPage(WidgetTester tester) {
  final pageView = tester.widget<PageView>(find.byType(PageView));
  final controller = pageView.controller;
  if (controller == null || !controller.hasClients) {
    throw StateError('Pager PageController has no clients');
  }
  return controller.page ?? controller.initialPage.toDouble();
}
