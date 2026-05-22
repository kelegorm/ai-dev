# Classifying a lib/ file

For each `.dart` file under `lib/` (skip `main.dart` — it stays at `lib/`
root), decide a **target layer** and whether it is **clean** or
**dirty/blocked**.

## Target layer

| The file is… | Layer |
|---|---|
| A pure-Dart model / value object / business rule, no Flutter import | `domain/<feature>/` |
| A concrete storage or transport implementation (HTTP client, DB, in-memory store, prefs wrapper) | `ex_systems/` |
| A widget / screen / UI helper | `ui/<screen>/` |
| A cross-cutting interface (navigation, logging, analytics port) | `app_ports/` |
| Composition root / DI wiring | `app/` |

Group `domain/` and `ui/` by feature/screen, not by technical type.

## Clean vs. dirty/blocked

A file is **clean** for its target layer only if every import it makes is
allowed there (see the layer rules in the project's
`docs/architecture/enforcement.md` and the `test/architecture/` purity tests):

- `domain/` — only `dart:*` and pure packages. Any Flutter or transport
  import → dirty.
- `ex_systems/` — `dart:*`, `domain/`, `app_ports/`, storage/transport
  packages. If it uses a transport package not yet in
  `ex_systems_purity_test.dart`'s `allowedExternalPackages`, extend that set
  in the same commit.
- `ui/` — `dart:*`, `domain/`, `app_ports/`, same-screen `ui/`, shared `ui/`
  (`common/`, `design_system/`), and `auto_route/flutter/flutter_bloc/get_it`.
  A widget that imports `ex_systems/` directly, imports another screen, or
  prepares data in `initState`/`build` → **dirty**.
- `app_ports/` — `dart:*`, `domain/`, `app_ports/`. Any Flutter → dirty.

A file is **blocked** if it is clean in isolation but depends on a file that
is itself dirty or not yet moved.

Dirty and blocked files are **not moved** — they go in the ledger.
