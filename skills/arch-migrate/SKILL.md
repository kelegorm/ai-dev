---
name: arch-migrate
description: Use when asked to migrate, restructure, or bring an existing Flutter project — one that already has real code but no layered architecture — to the reference architecture.
---

# arch-migrate

You orchestrate migrating an existing Flutter project to the reference
architecture. You are thin: you **survey and delegate**, you do not refactor
code yourself.

## Procedure

### 1. Survey

Gather, without changing anything:
- Does `pubspec.yaml` have a `flutter:` section? Is `lib/` present and
  non-empty?
- Does `docs/architecture/README.md` exist with first line
  `<!-- ai-dev:arch-contract v1 -->`?
- Does `docs/architecture/migration-progress.md` exist? If so, read it.

### 2. Decide

| State | Action |
|---|---|
| `lib/` empty / bare `flutter create` | Not a migration. Tell the user: this is greenfield — use `arch-bootstrap`. Stop. |
| Real code, no marker | Structure not laid out → go to step 3. |
| Marker present, ledger lists unfinished files | Structure done. Report the remaining work (bloc/service extraction) from the ledger to the user. The extraction skills do not exist yet — say so plainly. Stop. |
| Marker present, ledger says structure готова and lists nothing remaining | Migration complete. Report. Stop. |

**"Bare `flutter create`"** means `lib/` holds only the generated
`main.dart` counter template and nothing else. Any additional file — or
substantive edits to that `main.dart` — counts as real code (row 2).

### 3. Dispatch the structure worker

Launch a sub-agent (general-purpose) whose task is to run the
`arch-migrate-structure` skill on this project. It works in its own context
and returns a summary. Do not do the structure work in your own context.

### 4. Report

Relay the structure worker's summary to the user: layer folders created,
files moved, what is left in `docs/architecture/migration-progress.md` and
therefore needs extraction later.
