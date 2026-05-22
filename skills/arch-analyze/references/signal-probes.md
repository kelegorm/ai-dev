# Signal probes

Cheap probes to understand a project — greps plus reading a few sample
files. Not a full scan. Form a one-line verdict for each.

## Presentation pattern

- `grep -rl "extends Bloc\|extends Cubit" lib/` and `flutter_bloc` in
  `pubspec.yaml` → bloc/cubit.
- `grep -rl "ChangeNotifier\|ValueNotifier" lib/`, or class names ending
  `Controller` → controller / MVVM-ish.
- `riverpod` / `get:` (GetX) / `mobx` in `pubspec.yaml` → that framework.
- None of the above, and widgets hold logic (see smells) → **no pattern,
  logic lives in widgets**.
Verdict: which pattern, or "none".

## Layer / entity mixing

- Do domain-looking files (models, entities) also carry `fromJson` /
  `toJson` / transport imports (`dart:io`, `http`, `dio`)? → data and
  domain concerns are mixed.
- Is there a single folder holding models, data access, and widgets
  together? → no separation.
Verdict: separated, or mixed (say where).

## Navigation

- `grep -rn "Navigator.push\|Navigator.pop\|Navigator.of(" lib/` — count
  and note whether these sit directly in screen/widget files.
- `auto_route` / `go_router` in `pubspec.yaml`, or a class named
  `*Navigator` / `*Router` → a real navigation abstraction.
- Many ad-hoc `Navigator.push` in widgets, no abstraction → navigation is
  not separated.
Verdict: abstraction present and how clean, or ad-hoc.

## Layers & dependency direction

- Top-level `lib/` subfolders — do they look like architecture layers?
  Compare names to the эталон (`app/ app_ports/ domain/ ex_systems/ ui/`).
- Spot-check imports for upward leaks — e.g.
  `grep -rn "import.*ui/" lib/domain/` (domain importing ui) or a deeper
  layer importing a higher one.
- Is `test/architecture/` (purity tests) present?
Verdict: layered or not; names match эталон or deviate (say how);
dependency direction looks clean or leaks.

## Basic smells

- `flutter analyze` — clean or not (safe to run; it does not modify source files).
- Data preparation inside `initState` / `build` (a repository or API call
  in `initState`) → logic in the widget.
- Very large widget files — `find lib -name '*.dart' | xargs wc -l` and
  flag anything over ~400 lines.
Verdict: notable smells, or none.
