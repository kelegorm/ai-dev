import 'package:flutter/material.dart';
import 'package:flutter_examples/shared_scaffold/app.dart';
import 'package:flutter_test/flutter_test.dart';

/// Логический размер viewport'а тестового приложения.
///
/// Совпадает с типовым phone-портретом (~Pixel 5): 392.7 × 850.9 LP при
/// physicalSize 1080×2340 и DPR 2.75. Используется во всех drag/swipe-
/// сценариях через [getViewSize].
const Size kTestPhysicalSize = Size(1080, 2340);
const double kTestDevicePixelRatio = 2.75;

/// Настраивает view и mount'ит [SharedScaffoldApp].
///
/// Включает teardown, который восстанавливает дефолтные view-параметры —
/// иначе тесты «текут» друг в друга.
Future<void> pumpSharedScaffoldApp(WidgetTester tester) async {
  tester.view.physicalSize = kTestPhysicalSize;
  tester.view.devicePixelRatio = kTestDevicePixelRatio;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(SharedScaffoldApp());
  await tester.pumpAndSettle();
}

/// Логический размер экрана (physicalSize / DPR).
Size getViewSize(WidgetTester tester) =>
    tester.view.physicalSize / tester.view.devicePixelRatio;
