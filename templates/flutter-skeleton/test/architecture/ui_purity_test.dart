import 'package:flutter_test/flutter_test.dart';

import 'layer_check.dart';

/// Purity rule for `lib/ui/`. Screens may use Dart, Flutter, bloc &
/// friends, the domain layer, the `app_ports/` cross-cutting interfaces,
/// sibling files within their own screen, and a small set of shared UI
/// subfolders.
///
/// Cross-screen imports (`ui/home/` ↔ `ui/auth/`) are forbidden — screens
/// are composed in `app/navigation/`. The shared subfolders listed in
/// [sharedSiblings] (`common/`, `design_system/`) are exempt from sibling
/// isolation: any screen may import them, and they themselves don't count
/// as "siblings" when imported.
///
/// We chose option (b) from the brief: enable [isolateSiblingSubdirs]
/// AND mark the legitimate shared folders, instead of disabling
/// isolation entirely. This preserves the architectural intent while
/// matching the template's actual layout.
///
/// Extend [allowedExternalPackages] when introducing a new UI-facing
/// dependency (e.g. an animation package). Avoid leaking transport or
/// storage packages here — those belong to `ex_systems/`.
void main() {
  test('lib/ui/ imports only dart:*, domain/, app_ports/, same-screen ui/, shared ui/, allowed packages', () {
    checkLayer(
      layer: 'ui',
      packageName: 'flutter_skeleton',
      allowedInternalLayers: const <String>{'domain', 'app_ports', 'ui'},
      allowedExternalPackages: const <String>{
        'auto_route',
        'flutter',
        'flutter_bloc',
        'get_it',
      },
      isolateSiblingSubdirs: true,
      sharedSiblings: const <String>{
        'common',
        'design_system',
      },
    );
  });
}
