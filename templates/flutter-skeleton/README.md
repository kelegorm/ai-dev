# flutter-skeleton

Minimal runnable Flutter app in the project [reference architecture](../../docs/reference-architecture/README.md).
This is the skeleton the `arch-bootstrap` skill copies into a new project.

It is **not** a full app. It ships:

- the architecture's layer folders — `lib/{app, app_ports, domain, ex_systems, ui}/`;
- the enforcement infra — per-layer purity tests in `test/architecture/` and a
  strict `analysis_options.yaml`;
- the full stack wired up — `flutter_bloc`, `get_it`, `auto_route`, `dio`;
- exactly **one** placeholder screen (`lib/ui/home/home_screen.dart`).

`lib/domain/` and `lib/ex_systems/` are intentionally empty (`.gitkeep` only) —
feature code lands there per project.

## Package name

The package is named `flutter_skeleton`. The `arch-bootstrap` skill renames it
to the real project name when copying. Platform folders
(`android/ios/macos/linux/windows/web/`) are **not** vendored here — the skill
runs `flutter create` itself to generate them.

## Do not

- Do not add feature code, screens, blocs, or domain logic to this template.
  Keep it a skeleton; real features belong in the generated project.
- Do not weaken the purity tests or `analysis_options.yaml`.

## Gates

The skeleton passes all three reference gates (run inside a generated project,
after `flutter create` + `flutter pub get` + `dart run build_runner build`):

```
flutter analyze --no-pub
flutter test --no-pub
dart run dart_code_linter:metrics analyze lib | tee /tmp/dcl.out; ! grep -qE '^(ERROR|WARNING)' /tmp/dcl.out
```
