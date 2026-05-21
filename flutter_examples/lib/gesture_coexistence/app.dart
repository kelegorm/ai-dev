import 'package:flutter/material.dart';
import 'package:flutter_examples/gesture_coexistence/router/app_router.dart';

/// Корневой `MaterialApp` примера gesture-coexistence.
class GestureCoexistenceApp extends StatelessWidget {
  GestureCoexistenceApp({super.key});

  final GestureCoexistenceRouter _router = GestureCoexistenceRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gesture Coexistence',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueGrey),
      routerConfig: _router.config(),
    );
  }
}
