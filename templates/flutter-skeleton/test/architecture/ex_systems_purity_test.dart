import 'package:flutter_test/flutter_test.dart';

import 'layer_check.dart';

/// Purity rule for `lib/ex_systems/`. Adapters bridge `domain/` ports to
/// concrete storage / transport implementations, so they may use Dart,
/// the domain types they implement, `app_ports/` interfaces, sibling
/// ex_systems files, and the storage packages listed below — but nothing
/// from `ui/` or `app/`.
///
/// Extend [allowedExternalPackages] when introducing a new storage or
/// transport dependency (e.g. `dio`, `sqflite`).
void main() {
  test('lib/ex_systems/ imports only dart:*, domain/, app_ports/, ex_systems/, allowed packages', () {
    checkLayer(
      layer: 'ex_systems',
      packageName: 'flutter_skeleton',
      allowedInternalLayers: const <String>{'domain', 'app_ports', 'ex_systems'},
      allowedExternalPackages: const <String>{
        'flutter', // typically only flutter/foundation
        'flutter_secure_storage',
        'shared_preferences',
      },
    );
  });
}
