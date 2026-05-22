---
name: arch-migrate-structure
description: Use to lay out the layer-folder structure of an existing Flutter project during migration — creates the layer folders, drops the architecture docs, marker and purity tests, and moves clean files into their layers. Normally launched by the arch-migrate orchestrator.
---

# arch-migrate-structure

You are migrating an **existing** Flutter project (real code in `lib/`, no
`ai-dev` marker) into the reference architecture's folder structure.

This skill does **structure only**: layer folders, architecture docs, purity
tests, and moving files that move *cleanly*. It does **not** extract blocs,
extract services, or rewrite any file's contents. Tangled files are recorded
in a ledger and left untouched for later extraction skills.

**Do not introduce strict lint.** The reference `analysis_options.yaml` is not
copied — on legacy code it would light up immediately. Strict lint is added
later, per architectural unit, by the extraction skills.

## Procedure

### 1. Re-check preconditions

- `pubspec.yaml` has a `flutter:` section AND `lib/` is non-empty?
  - `lib/` empty → this is greenfield, wrong skill. Stop, say so.
- `docs/architecture/README.md` exists and its first line is exactly
  `<!-- ai-dev:arch-contract v1 -->`?
  - Yes → structure already laid out. Stop. Do not overwrite anything.

### 2. Create the layer folders

Create `lib/{app, app_ports, domain, ex_systems, ui}/`. Put an empty
`.gitkeep` in each so git tracks it. Do **not** copy any skeleton `lib/`
code; the project has its own. Commit.

### 3. Drop architecture docs, marker, purity tests, agent index

- Copy verbatim from `${CLAUDE_PLUGIN_ROOT}/docs/reference-architecture/`:
  `tech.md`, `ui.md`, `enforcement.md` → the project's `docs/architecture/`.
- Produce `docs/architecture/README.md` from the эталон `README.md`: drop the
  "это эталон" framing, make it *this* project's architecture map. Fill in
  project specifics — run the dialog in
  `${CLAUDE_PLUGIN_ROOT}/skills/arch-bootstrap/references/customization.md`,
  but for a migration most answers are visible in `pubspec.yaml` and the
  existing code: infer them, ask the user only what you genuinely cannot see.
  Its **first line must be** `<!-- ai-dev:arch-contract v1 -->`.
- Copy `${CLAUDE_PLUGIN_ROOT}/templates/flutter-skeleton/test/architecture/`
  (`layer_check.dart` + the four `*_purity_test.dart` files) into the
  project's `test/architecture/`. In each `*_purity_test.dart`, set the
  `packageName:` argument to the project's package name (from `pubspec.yaml`).
  Do **not** copy `widget_test.dart`. Do **not** copy `analysis_options.yaml`.
- Create the `AGENTS.md` index from
  `${CLAUDE_PLUGIN_ROOT}/skills/arch-bootstrap/references/agents-md-template.md`,
  and `CLAUDE.md` containing exactly `@AGENTS.md`. If the project already has
  an `AGENTS.md` or `CLAUDE.md`, **append** the architecture section — do not
  clobber existing content.
- Commit.

### 4. Classify every file in `lib/`

For each `.dart` file under `lib/` except `main.dart`, follow
`references/file-classification.md` to decide: its target layer, and whether
it is **clean** (fits that layer without breaking the layer's purity rule) or
**dirty/blocked**. Build the internal-import dependency graph.

### 5. Move clean files, leaves first

Loop: pick a file that is **clean** AND all of whose internal dependencies are
already in their target layer. Move it into `lib/<layer>/<...>/`, rewrite its
own import paths and **every** import of it across the project, then run
`flutter analyze` and `flutter test` — they must show no new failures vs. the
pre-migration baseline. Commit (one file, or one tight mutually-dependent
cluster, per commit). Repeat until no such file remains.

Never move a file that would break a purity test. If a file is clean in
isolation but its dependency is stuck, it is blocked — it waits in the ledger.

### 6. Write the ledger

Create `docs/architecture/migration-progress.md` from
`references/ledger-template.md`: what was moved where, and every file still in
`lib/` root — why it is stuck (dirty / blocked), what it needs (bloc or
service extraction), and where it will go afterward.

Set `Статус структуры: готова` — a finished pass means the structure phase
is **done**, even though dirty files remain listed for later extraction. The
remaining files are extraction work, not structure work. Use `в работе` only
if the pass was interrupted before all clean files were moved. Commit.

### 7. Report

Run `flutter analyze` and `flutter test`. Return a summary: layer folders
created, files moved, files left in the ledger, gate status.

## Discipline

- No scope creep: do not reformat, rename, or "clean up" anything that is not
  a file move. Contents of moved files are not edited beyond import paths.
- **Do not extract blocs.** Do not extract services. Do not add interfaces.
  Do not make models Equatable. Do not rewrite any file's logic — not even
  "small improvements". This skill moves files; it does not refactor code.
- Never leave the project non-compiling. If a move cascades into trouble,
  revert that move, record the file in the ledger, move on.
- One move = one commit (for review and `git bisect`).
- Tangled files are **not** dragged into a layer folder — they stay in `lib/`
  root where the purity tests do not scan them.
- **Fixed layer names — do not rename.** `lib/{app, app_ports, domain,
  ex_systems, ui}/`. Not `features/`, not `data/`, not `presentation/`, not
  `core/`. The top-level grouping is by layer, not by feature; features are
  sub-folders *inside* `domain/` and `ui/`.

## Result checklist

- [ ] `lib/{app, app_ports, domain, ex_systems, ui}/` exist
- [ ] `docs/architecture/{README,tech,ui,enforcement}.md` — README first line is the marker
- [ ] `test/architecture/` purity tests present, `packageName` set, all green
- [ ] `AGENTS.md` indexes the arch docs; `CLAUDE.md` is `@AGENTS.md`
- [ ] every clean leaf-reachable file moved into its layer
- [ ] `docs/architecture/migration-progress.md` lists every remaining file
- [ ] `flutter analyze` + `flutter test` — no new failures
