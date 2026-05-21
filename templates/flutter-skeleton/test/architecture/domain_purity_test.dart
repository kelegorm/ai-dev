import 'package:flutter_test/flutter_test.dart';

import 'layer_check.dart';

/// Strict purity rule for `lib/domain/`: only Dart SDK and code-gen /
/// pure-value-object packages may be imported. No Flutter, no transport
/// libs, no app code from outside `domain/`.
///
/// Extend [allowedExternalPackages] when adding a freezed/json_serializable
/// style dependency that domain code legitimately needs.
void main() {
  test('lib/domain/ imports only dart:*, allowed packages, and itself', () {
    checkLayer(
      layer: 'domain',
      packageName: 'flutter_skeleton',
      allowedInternalLayers: const <String>{'domain'},
      allowedExternalPackages: const <String>{
        // 'freezed_annotation',
        // 'json_annotation',
        // 'meta',
        // 'collection',
      },
    );
  });
}
