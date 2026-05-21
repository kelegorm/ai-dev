import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/_index.dart';

/// Tap по полоске открывает modal bottom sheet с её номером.
///
/// Регрессии:
///   - Убрать `OversizedHitTestBox` → tap по полоскам, которые после vertical
///     scroll оказались в overflow-области относительно parent constraints,
///     перестанет работать. Тест после scroll'а упадёт.
///   - Дать raw-`Listener` полотна «съесть» tap → тест на открытие modal
///     упадёт; при этом drag НЕ должен открывать modal.
void main() {
  testWidgets('tap по полоске #1 открывает modal "Stripe #1"', (tester) async {
    await pumpGestureApp(tester);
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    expect(find.text('Stripe #1'), findsOneWidget);
  });

  testWidgets('tap по нижней полоске #24 после scroll вверх открывает modal', (
    tester,
  ) async {
    await pumpGestureApp(tester);
    // Полоска #24 — последняя; чтобы попасть в viewport, скроллим вверх.
    await swipe(tester, direction: SwipeDirection.up, fraction: 0.7);
    await swipe(tester, direction: SwipeDirection.up, fraction: 0.7);

    // Тапаем text "24" — он внутри OversizedHitTestBox (overflow-область).
    await tester.tap(find.text('24'));
    await tester.pumpAndSettle();

    expect(find.text('Stripe #24'), findsOneWidget);
  });

  testWidgets('свайп (drag) НЕ открывает modal', (tester) async {
    await pumpGestureApp(tester);
    await swipe(tester, direction: SwipeDirection.up, fraction: 0.3);

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.textContaining('Stripe #'), findsNothing);
  });
}
