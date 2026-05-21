import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Shared engine for per-layer purity tests under `test/architecture/`.
///
/// Each layer (domain, ex_systems, ui, …) has its own `*_purity_test.dart`
/// file that calls [checkLayer] with an allowlist describing what its
/// files may import. The check is allowlist-only: anything not
/// explicitly permitted is reported as a violation.
///
/// Internal imports are resolved to the lib-relative path
/// (`lib/<segment>/...`) regardless of whether they were written as a
/// relative import or a `package:<self>/...` import. The first segment
/// after `lib/` is then matched against [allowedInternalLayers] and
/// [allowedInternalPaths].
///
/// When [isolateSiblingSubdirs] is true, files inside `lib/<layer>/<a>/`
/// must not import from `lib/<layer>/<b>/` (cross-screen isolation).
/// First-level subdirs listed in [sharedSiblings] are exempt — both
/// from the source side (any file may import them) and from the target
/// side (treated as shared, not as a sibling). This is how a UI layer
/// with shared building blocks like `common/` or `design_system/` can
/// still enforce isolation between its actual screen folders.
void checkLayer({
  required String layer,
  required String packageName,
  required Set<String> allowedInternalLayers,
  Set<String> allowedInternalPaths = const <String>{},
  required Set<String> allowedExternalPackages,
  bool isolateSiblingSubdirs = false,
  Set<String> sharedSiblings = const <String>{},
}) {
  final layerDir = Directory('lib/$layer');
  expect(layerDir.existsSync(), isTrue,
      reason: 'expected lib/$layer/ at project root');

  final ownPackagePrefix = 'package:$packageName/';
  final importLine = RegExp('^\\s*import\\s+[\'"]([^\'"]+)[\'"]');

  final dartFiles = layerDir
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  final violations = <String>[];

  for (final file in dartFiles) {
    final relPath =
        file.path.split(Platform.pathSeparator).join('/');

    // Sibling-isolation key: the first subdir inside the layer.
    // For `lib/ui/home/foo.dart` this is `home`. Imports inside the
    // same layer must keep the same key when [isolateSiblingSubdirs]
    // is on, unless the source or target sibling is in
    // [sharedSiblings].
    String? sourceSibling;
    if (isolateSiblingSubdirs) {
      final segs = relPath.split('/');
      // Expected: ['lib', layer, '<sibling>', ...].
      if (segs.length >= 3 && segs[0] == 'lib' && segs[1] == layer) {
        sourceSibling = segs[2];
      }
    }

    final lines = file.readAsLinesSync();

    for (var i = 0; i < lines.length; i++) {
      final m = importLine.firstMatch(lines[i]);
      if (m == null) continue;
      final uri = m.group(1);
      if (uri == null) continue;

      // Conditional imports keep only the unconditional default URI here;
      // good enough for the layer rules we enforce.
      if (uri.startsWith('dart:')) continue;

      // Resolve to a lib-relative path if internal, or null if external.
      String? resolved;
      if (uri.startsWith(ownPackagePrefix)) {
        resolved = 'lib/${uri.substring(ownPackagePrefix.length)}';
      } else if (uri.startsWith('package:')) {
        final pkg =
            uri.substring('package:'.length).split('/').first;
        if (!allowedExternalPackages.contains(pkg)) {
          violations.add(
            '$relPath:${i + 1}: $layer/ imports forbidden external "$uri"',
          );
        }
        continue;
      } else {
        // Relative import.
        final dir = File(file.path)
            .parent
            .path
            .split(Platform.pathSeparator)
            .join('/');
        resolved = _normalize('$dir/$uri');
      }

      // Internal: must hit lib/<allowed-layer>/... or lib/<allowed-path>.
      final resolvedPath = resolved;
      if (!resolvedPath.startsWith('lib/')) {
        violations.add(
          '$relPath:${i + 1}: $layer/ imports outside lib/ "$uri" '
          '(resolves to "$resolvedPath")',
        );
        continue;
      }

      final isAllowedPath = allowedInternalPaths
          .any((p) => resolvedPath.startsWith('lib/$p'));
      if (isAllowedPath) continue;

      final segments = resolvedPath.split('/');
      // Expected: ['lib', '<layer>', ...].
      if (segments.length < 2) {
        violations.add(
          '$relPath:${i + 1}: $layer/ imports unparseable lib path "$uri"',
        );
        continue;
      }
      final targetLayer = segments[1];
      if (!allowedInternalLayers.contains(targetLayer)) {
        violations.add(
          '$relPath:${i + 1}: $layer/ imports forbidden layer "$targetLayer/" '
          'via "$uri"',
        );
        continue;
      }

      // Sibling isolation: within the same layer, imports must stay in
      // the same first-level subdir, except for shared siblings.
      if (isolateSiblingSubdirs &&
          targetLayer == layer &&
          sourceSibling != null &&
          segments.length >= 3) {
        final targetSibling = segments[2];
        final isSharedSource = sharedSiblings.contains(sourceSibling);
        final isSharedTarget = sharedSiblings.contains(targetSibling);
        if (!isSharedSource &&
            !isSharedTarget &&
            targetSibling != sourceSibling) {
          violations.add(
            '$relPath:${i + 1}: $layer/$sourceSibling/ imports sibling '
            '$layer/$targetSibling/ via "$uri" '
            '(cross-screen imports are forbidden)',
          );
        }
      }
    }
  }

  expect(
    violations,
    isEmpty,
    reason: '$layer/ purity violations found:\n${violations.join('\n')}',
  );
}

String _normalize(String path) {
  final segments = <String>[];
  for (final seg in path.split('/')) {
    if (seg.isEmpty || seg == '.') continue;
    if (seg == '..') {
      if (segments.isNotEmpty) segments.removeLast();
      continue;
    }
    segments.add(seg);
  }
  return segments.join('/');
}
