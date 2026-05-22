# arch-migrate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build two skills for the `ai-dev` plugin — `arch-migrate` (a thin orchestrator that surveys an existing Flutter project and dispatches workers) and `arch-migrate-structure` (the worker that lays the project out in the reference architecture's layer folders).

**Architecture:** Skills are authored by TDD per `superpowers:writing-skills` — a baseline scenario (RED) on a deliberately-messy fixture project before writing, the scenario re-run (GREEN) after. `arch-migrate-structure` is the substantive skill; `arch-migrate` is thin. The structure worker creates the five layer folders, copies architecture docs + marker + purity tests from the same sources `arch-bootstrap` uses, moves *clean* files into their layers leaves-first, and records everything else in a ledger. Strict lint is deliberately NOT introduced at this stage.

**Tech Stack:** Claude Code plugin (skills), Markdown, git, Flutter, Dart.

---

## Source spec

`docs/specs/2026-05-22-arch-migrate-design.md`. Family context: `docs/specs/2026-05-21-flutter-arch-skills-design.md`. This plan covers **only** the orchestrator + the structure worker. Extraction workers (`arch-extract-bloc`, `arch-extract-service`), orchestrator upgrades, `arch-audit`, and the hook are deferred to their own iterations.

## Assumptions / preconditions

- Flutter is installed; `flutter`, `dart`, `git` on PATH.
- `docs/reference-architecture/{README,tech,ui,enforcement}.md` and `templates/flutter-skeleton/test/architecture/` exist (built in the `arch-bootstrap` iteration) — the structure worker copies from them.
- `skills/arch-bootstrap/references/{customization.md,agents-md-template.md}` exist — the structure worker reuses them for the project README dialog and the `AGENTS.md` index.

## Key facts locked in (from reading the skeleton)

- `templates/flutter-skeleton/test/architecture/layer_check.dart` scans **every** `.dart` file in `lib/<layer>/`. There is **no per-file allowlist** — "allowlist" there means *which imports a layer may use*. Consequence: the structure worker may move a file into a layer **only if that file is clean for the layer**.
- Layer import rules (from the four `*_purity_test.dart` files):
  - `domain/` — only `dart:*` + listed pure packages + `domain/` itself. No Flutter.
  - `ex_systems/` — `dart:*` + `domain/` + `app_ports/` + `ex_systems/` + listed storage/transport packages.
  - `ui/` — `dart:*` + `domain/` + `app_ports/` + same-screen `ui/` + shared `ui/` (`common/`, `design_system/`) + `auto_route/flutter/flutter_bloc/get_it`. Cross-screen `ui/` imports are forbidden.
  - `app_ports/` — `dart:*` + `domain/` + `app_ports/`. No Flutter.

## File structure

| File | Responsibility |
|---|---|
| `skills/arch-migrate/SKILL.md` | Orchestrator: survey the project, dispatch the structure worker as a sub-agent, report the ledger remainder |
| `skills/arch-migrate-structure/SKILL.md` | Worker: create layer folders, drop docs+marker+purity tests+`AGENTS.md`, move clean files leaves-first, write the ledger |
| `skills/arch-migrate-structure/references/file-classification.md` | How to classify each `lib/` file → target layer; the clean-vs-ledger decision |
| `skills/arch-migrate-structure/references/ledger-template.md` | Template for the project's `docs/architecture/migration-progress.md` |
| `docs/plans/arch-migrate-baseline.md` | Baseline test findings (RED) — input to Task 3 |
| `../arch-migrate-fixture/` | Deliberately-messy Flutter project, test input. Lives **outside** the plugin repo, not committed. |

Reused as-is, no new files: `docs/reference-architecture/*.md`, `templates/flutter-skeleton/test/architecture/*`, `skills/arch-bootstrap/references/*`.

---

## Task 1: Build the messy fixture project

A small Flutter project written "flat" — everything in `lib/` root, one widget mixing data-fetch into `initState`. Both the baseline (Task 2) and GREEN (Task 5) tests run on a fresh copy of it.

**Files:**
- Create: `../arch-migrate-fixture/` (sibling of the plugin repo)

- [ ] **Step 1: Scaffold a Flutter project**

```bash
cd .. && flutter create --org com.example arch_migrate_fixture && mv arch_migrate_fixture arch-migrate-fixture
```

(`flutter create` rejects a hyphenated name, so create with an underscore and rename the directory. The Dart package stays `arch_migrate_fixture`.)

- [ ] **Step 2: Replace `lib/` with the messy file set**

Delete the generated `lib/main.dart` and `test/widget_test.dart`. Create exactly these five files under `../arch-migrate-fixture/lib/`:

`lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'home_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(home: HomePage());
}
```

`lib/note.dart`:
```dart
class Note {
  Note(this.id, this.title);

  final String id;
  final String title;
}
```

`lib/notes_repository.dart`:
```dart
import 'note.dart';

class NotesRepository {
  final List<Note> _notes = <Note>[
    Note('1', 'first note'),
    Note('2', 'second note'),
  ];

  List<Note> all() => List<Note>.unmodifiable(_notes);
}
```

`lib/note_detail_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'note.dart';

class NoteDetailPage extends StatelessWidget {
  const NoteDetailPage({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(note.title)),
      body: Center(child: Text('Note ${note.id}')),
    );
  }
}
```

`lib/home_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'note.dart';
import 'note_detail_page.dart';
import 'notes_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Note> _notes = <Note>[];

  @override
  void initState() {
    super.initState();
    _notes = NotesRepository().all();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: ListView(
        children: _notes
            .map((Note n) => ListTile(
                  title: Text(n.title),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => NoteDetailPage(note: n),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
```

The set is `main.dart`, `note.dart`, `notes_repository.dart`, `note_detail_page.dart`, `home_page.dart`.

- [ ] **Step 3: Verify it compiles and runs its (empty) test suite**

Run:
```bash
cd ../arch-migrate-fixture && flutter pub get && flutter analyze && flutter test
```
Expected: `flutter analyze` reports "No issues found!" (the fixture is messy *architecturally*, not lint-dirty). `flutter test` passes with no tests, or reports "All tests passed!".

- [ ] **Step 4: Commit the fixture as its own git repo**

The fixture needs git history so the structure worker can make per-move commits.
```bash
cd ../arch-migrate-fixture && git init -q && git add -A && git commit -q -m "messy fixture: flat lib/, logic in widget"
```

No commit in the plugin repo — the fixture lives outside it.

---

## Task 2: Baseline test — RED

Per `superpowers:writing-skills`: observe what an agent does WITHOUT the skills before writing them.

**Files:**
- Create: `docs/plans/arch-migrate-baseline.md`

- [ ] **Step 1: Take a fresh copy of the fixture**

```bash
rm -rf /tmp/arch-migrate-baseline && cp -r ../arch-migrate-fixture /tmp/arch-migrate-baseline && rm -rf /tmp/arch-migrate-baseline/.git
```

- [ ] **Step 2: Dispatch a baseline subagent**

Dispatch a general-purpose subagent, WITHOUT mentioning `arch-migrate`, the эталон, or any layer names, pointing it at `/tmp/arch-migrate-baseline`, with this task:

> "Вот Flutter-проект: весь код свалён плоско в `lib/`, данные грузятся прямо в виджете. Приведи его к хорошей, поддерживаемой архитектуре. Опиши, что сделал."

Do not coach it.

- [ ] **Step 3: Record the baseline behavior verbatim**

In `docs/plans/arch-migrate-baseline.md`, document concretely:
- Which layer folders did it create? What names?
- Did it move files? Which, where? Did it keep the project compiling?
- Did it touch `home_page.dart`'s `initState` data-fetch — extract a bloc/cubit, leave it, something else?
- Did it write architecture docs? A marker? A migration ledger / progress file?
- Did it add enforcement (purity tests, strict lint)? Did `flutter analyze` survive?
- What did it skip, hand-wave, or get wrong vs. the spec's intended behavior?

These findings are the input to Task 3 Step 5 — the skill must counter exactly these gaps.

- [ ] **Step 4: Commit**

```bash
git add docs/plans/arch-migrate-baseline.md
git commit -m "docs(plans): baseline behavior for arch-migrate (RED)"
```

---

## Task 3: Write the `arch-migrate-structure` skill

**Files:**
- Create: `skills/arch-migrate-structure/SKILL.md`
- Create: `skills/arch-migrate-structure/references/file-classification.md`
- Create: `skills/arch-migrate-structure/references/ledger-template.md`

- [ ] **Step 1: Write `SKILL.md`**

Frontmatter `description` is triggering-conditions only — no workflow summary (CSO rule, as in `arch-bootstrap`).

````markdown
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
code — the project has its own. Commit.

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
service extraction), and where it will go afterward. Commit.

### 7. Report

Run `flutter analyze` and `flutter test`. Return a summary: layer folders
created, files moved, files left in the ledger, gate status.

## Discipline

- No scope creep: do not reformat, rename, or "clean up" anything that is not
  a file move. Contents of moved files are not edited beyond import paths.
- Never leave the project non-compiling. If a move cascades into trouble,
  revert that move, record the file in the ledger, move on.
- One move = one commit (for review and `git bisect`).
- Tangled files are **not** dragged into a layer folder — they stay in `lib/`
  root where the purity tests do not scan them.

## Result checklist

- [ ] `lib/{app, app_ports, domain, ex_systems, ui}/` exist
- [ ] `docs/architecture/{README,tech,ui,enforcement}.md` — README first line is the marker
- [ ] `test/architecture/` purity tests present, `packageName` set, all green
- [ ] `AGENTS.md` indexes the arch docs; `CLAUDE.md` is `@AGENTS.md`
- [ ] every clean leaf-reachable file moved into its layer
- [ ] `docs/architecture/migration-progress.md` lists every remaining file
- [ ] `flutter analyze` + `flutter test` — no new failures
````

- [ ] **Step 2: Verify the skill loads**

Reload plugins / run `claude --plugin-dir . -p "/help"`; confirm `arch-migrate-structure` appears with no frontmatter error.

- [ ] **Step 3: Write `references/file-classification.md`**

```markdown
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
```

- [ ] **Step 4: Write `references/ledger-template.md`**

```markdown
# Ledger template — docs/architecture/migration-progress.md

The structure worker writes this file into the migrated project. Russian,
project-facing.

---

<!-- ai-dev:migration-ledger v1 -->
# Прогресс миграции архитектуры

Статус структуры: **готова** | в работе
Дата последнего прогона: YYYY-MM-DD

## Разложено по слоям

- `lib/<layer>/<path>` ← бывш. `lib/<old>` — кратко, что за файл.
- …

## Осталось разобрать

Файлы ниже остались в `lib/` (вне папок слоёв) — их нельзя перенести
механически. Каждому нужна работа выделения, потом он переедет в свой слой.

- `lib/<file>` — **грязный**: <причина, напр. «логика загрузки в initState,
  импортирует ex_systems напрямую»>. Нужно: выделить bloc/сервис. Поедет в
  `lib/<layer>/<path>`.
- …

## Чем проект ещё не защищён

Строгий линт (`analysis_options.yaml` эталона) не подключён — он навешивается
позже, по мере выделения архитектурных границ.
```

- [ ] **Step 5: Fold baseline gaps into `SKILL.md`**

Re-read `docs/plans/arch-migrate-baseline.md`. For each gap the baseline agent showed, add a targeted, specific line to `SKILL.md` that prevents it. Examples of likely gaps and counters: baseline renamed layers (`core/data/presentation`) → the skill already fixes layer names, make sure they are unmissable; baseline edited file contents while moving → strengthen the Discipline section; baseline skipped the ledger → make step 6 explicitly required before reporting.

- [ ] **Step 6: Commit**

```bash
git add skills/arch-migrate-structure/
git commit -m "feat(skill): arch-migrate-structure — layer-structure migration worker"
```

---

## Task 4: Write the `arch-migrate` orchestrator skill

**Files:**
- Create: `skills/arch-migrate/SKILL.md`

- [ ] **Step 1: Write `SKILL.md`**

````markdown
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

### 3. Dispatch the structure worker

Launch a sub-agent (general-purpose) whose task is to run the
`arch-migrate-structure` skill on this project. It works in its own context
and returns a summary. Do not do the structure work in your own context.

### 4. Report

Relay the structure worker's summary to the user: layer folders created,
files moved, what is left in `docs/architecture/migration-progress.md` and
therefore needs extraction later.
````

- [ ] **Step 2: Verify the skill loads**

Reload plugins; confirm `arch-migrate` appears with no frontmatter error.

- [ ] **Step 3: Commit**

```bash
git add skills/arch-migrate/SKILL.md
git commit -m "feat(skill): arch-migrate orchestrator"
```

---

## Task 5: GREEN test — run the scenario with the skills

**Files:**
- Modify: `docs/plans/arch-migrate-baseline.md` (append GREEN results)

- [ ] **Step 1: GREEN-test the structure worker**

Fresh fixture copy:
```bash
rm -rf /tmp/arch-migrate-green && cp -r ../arch-migrate-fixture /tmp/arch-migrate-green
```
Dispatch a subagent with the `arch-migrate-structure` skill available, pointed at `/tmp/arch-migrate-green`, task: "Разложи этот Flutter-проект по слоям эталонной архитектуры." Let it run.

- [ ] **Step 2: Check the structure-worker result against the spec**

Verify in `/tmp/arch-migrate-green`:
- `lib/{app,app_ports,domain,ex_systems,ui}/` exist.
- `note.dart` moved into `lib/domain/...`; `notes_repository.dart` into `lib/ex_systems/...`; `note_detail_page.dart` into `lib/ui/...`.
- `home_page.dart` is **still in `lib/` root** (it is dirty: data-fetch in `initState`, imports `ex_systems` directly, cross-screen import) and is listed in `docs/architecture/migration-progress.md`.
- `docs/architecture/{README,tech,ui,enforcement}.md` present; README first line is the marker.
- `test/architecture/` purity tests present with the fixture's `packageName`.
- `AGENTS.md` + `CLAUDE.md` present.
- `flutter analyze` and `flutter test` pass (the purity tests are green).
- No strict `analysis_options.yaml` was added.

Append a pass/fail line per item to `docs/plans/arch-migrate-baseline.md` under a "GREEN — structure worker" heading.

- [ ] **Step 3: Smoke-check the orchestrator's survey + decision**

Dispatch a subagent with the `arch-migrate` skill available, three quick runs:
- empty dir with a bare `flutter create` → expect it says "greenfield, use `arch-bootstrap`".
- `/tmp/arch-migrate-green` (already migrated, marker present, ledger lists `home_page.dart`) → expect it reports the remaining extraction work and that extraction skills do not exist yet.
- a fresh fixture copy → expect it decides to dispatch the structure worker (whether the nested dispatch fully completes is not required here — only that the decision is correct).

Append results under a "GREEN — orchestrator" heading.

- [ ] **Step 4: Commit**

```bash
git add docs/plans/arch-migrate-baseline.md
git commit -m "docs(plans): arch-migrate GREEN test results"
```

---

## Task 6: REFACTOR — close gaps + version bump

- [ ] **Step 1: Fix every GREEN failure**

For each item that failed in Task 5, edit `SKILL.md` / references to address it. Common cause: a step is implied, not stated — make it explicit. If the structure worker moved a dirty file, sharpen `file-classification.md` and the step-5 purity rule.

- [ ] **Step 2: Re-run the GREEN scenario**

Repeat Task 5 Steps 1–3 on fresh copies. Confirm previously-failed items now pass. Iterate until clean.

- [ ] **Step 3: Bump the plugin version**

New skills → per the versioning policy, bump `version` in `.claude-plugin/plugin.json` (patch bump).

- [ ] **Step 4: Commit**

```bash
git add skills/ .claude-plugin/plugin.json
git commit -m "fix(skill): close arch-migrate gaps from GREEN testing; bump version"
```

---

## Task 7: Real-project smoke test (user)

- [ ] **Step 1: Hand off to the user**

The user runs `arch-migrate` on a throwaway copy of a real messy Flutter project and edits the skills in parallel. The subagent scenarios are the fast inner loop; this is the real acceptance gate. Capture any issues as follow-up tasks.

---

## Self-review notes

- **Spec coverage:** Task 3 ↔ the `arch-migrate-structure` worker (steps 1–7, ledger, discipline, no-strict-lint invariant); Task 4 ↔ the `arch-migrate` orchestrator (survey + decision table + dispatch); Tasks 1/2/5/6 ↔ writing-skills TDD on the messy fixture. Extraction workers, orchestrator upgrades, `arch-audit`, and the hook are explicitly out of scope per the spec.
- **Known RED→GREEN dependency:** the exact emphasis wording added in Task 3 Step 5 depends on Task 2's baseline findings — a real dependency, not a placeholder. Structure, file paths, frontmatter, procedure, and reference contents are fully specified.
- **Type/name consistency:** the marker `<!-- ai-dev:arch-contract v1 -->`, the ledger path `docs/architecture/migration-progress.md`, the ledger marker `<!-- ai-dev:migration-ledger v1 -->`, the skill names `arch-migrate` / `arch-migrate-structure`, and the fixture package `arch_migrate_fixture` are used consistently across all tasks.
- **Open follow-up (not this plan):** the эталон `reference-architecture/README.md` folder tree lists `app/bootstrap/` and `app/session/` absent from the skeleton — acknowledged oversight, separate task.
