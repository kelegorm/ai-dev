import 'package:flutter/material.dart';
import 'package:flutter_examples/shared_scaffold/app_router.dart';

/// Корневой `MaterialApp` примера shared-scaffold.
///
/// Outer-навигация — на auto_route ([SharedScaffoldRouter]); `MaterialApp`
/// конфигурируется через `.router`, а tab-state управляется `AutoTabsRouter`
/// внутри `RootShell`.
class SharedScaffoldApp extends StatelessWidget {
  SharedScaffoldApp({super.key});

  final SharedScaffoldRouter _router = SharedScaffoldRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Shared Scaffold',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueGrey),
      routerConfig: _router.config(),
    );
  }
}
