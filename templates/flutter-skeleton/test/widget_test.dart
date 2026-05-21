import 'package:flutter_skeleton/app/app.dart';
import 'package:flutter_skeleton/app/di/app_di.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(configureDependencies);

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('app boots to the placeholder home screen', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('flutter_skeleton'), findsOneWidget);
  });
}
