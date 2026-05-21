import 'package:flutter_test/flutter_test.dart';

import 'layer_check.dart';

/// Purity rule for `lib/app_ports/`: cross-cutting port interfaces
/// (navigation, logging, analytics, …). They may import `domain/` for
/// the types they expose and sibling `app_ports/` files — but no Flutter,
/// no concrete implementations, and nothing from `ui/`, `ex_systems/` or
/// `app/`.
///
/// Extend [allowedExternalPackages] only for pure-value-object / code-gen
/// dependencies (e.g. `meta`); transport and UI packages do not belong here.
void main() {
  test('lib/app_ports/ imports only dart:*, domain/, app_ports/, allowed packages', () {
    checkLayer(
      layer: 'app_ports',
      packageName: 'flutter_skeleton',
      allowedInternalLayers: const <String>{'domain', 'app_ports'},
      allowedExternalPackages: const <String>{},
    );
  });
}
