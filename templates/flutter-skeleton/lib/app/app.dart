import 'package:flutter/material.dart';
import 'package:flutter_skeleton/app/navigation/app_router.dart';
import 'package:flutter_skeleton/ui/design_system/app_theme.dart';
import 'package:get_it/get_it.dart';

/// Root application widget.
///
/// Wires [MaterialApp.router] to the [AppRouter] and the design-system
/// theme. Dependencies must already be registered via
/// `configureDependencies()` (see `main.dart`).
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = GetIt.instance<AppRouter>();
    return MaterialApp.router(
      title: 'flutter_skeleton',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: appRouter.config(),
    );
  }
}
