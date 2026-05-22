# arch-analyze Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `arch-analyze` skill for the `ai-dev` plugin — a read-only "front door" that surveys any Flutter project, runs light signal-probes, classifies the project's architectural state, and reports a verdict + recommendation.

**Architecture:** A skill authored by TDD per `superpowers:writing-skills` — a baseline scenario (RED) before writing, the scenario re-run (GREEN) after. `arch-analyze` is read-only: it surveys, probes (greps + a few sample files), classifies into one of five states, and reports to chat. It writes nothing, dispatches nothing, fixes nothing. Tested on two fixtures: the existing flat-messy `arch-migrate-fixture` and a new hand-layered `arch-analyze-fixture`.

**Tech Stack:** Claude Code plugin (skills), Markdown, git, Flutter, Dart.

---

## Source spec

`docs/specs/2026-05-22-arch-analyze-design.md`. Family context: `docs/specs/2026-05-21-flutter-arch-skills-design.md`. This plan covers **only** `arch-analyze`. `arch-audit`, the extraction workers, and the hook are deferred to their own iterations.

## Assumptions / preconditions

- Flutter is installed; `flutter`, `dart`, `git` on PATH.
- The flat-messy fixture `../arch-migrate-fixture/` exists (built in the arch-migrate iteration — a flat Flutter project, all files in `lib/` root). If it is missing, rebuild it per `docs/plans/2026-05-22-arch-migrate.md` Task 1.
- The marker string used family-wide is `<!-- ai-dev:arch-contract v1 -->`; the migration ledger lives at `docs/architecture/migration-progress.md`.

## File structure

| File | Responsibility |
|---|---|
| `skills/arch-analyze/SKILL.md` | The skill: survey → probe → classify → report |
| `skills/arch-analyze/references/signal-probes.md` | The probe checklist — grep patterns and what to sample |
| `docs/plans/arch-analyze-baseline.md` | Baseline test findings (RED) — input to Task 3 |
| `../arch-analyze-fixture/` | A hand-layered, unmarked Flutter project — test input. Lives **outside** the plugin repo, not committed. |

Reused as-is: `../arch-migrate-fixture/` (flat-messy fixture).

---

## Task 1: Build the hand-layered fixture

A small Flutter project laid out in layers **by hand**, with no `ai-dev` marker — the state that motivated this skill (arch-migrate Task 7). Deliberately carries detectable signals: a `ChangeNotifier` controller, a domain model with `fromJson` (entity/data mixing), ad-hoc `Navigator.push`, and layer names that deviate from the эталон (`data/` instead of `ex_systems/`, no `app/`/`app_ports/`).

**Files:**
- Create: `../arch-analyze-fixture/` (sibling of the plugin repo)

- [ ] **Step 1: Scaffold a Flutter project**

```bash
cd /Users/dmitry/Work/my_own && flutter create --org com.example arch_analyze_fixture && mv arch_analyze_fixture arch-analyze-fixture
```

(`flutter create` rejects a hyphenated name — create with an underscore, rename the directory. The Dart package stays `arch_analyze_fixture`.)

- [ ] **Step 2: Replace `lib/` with the hand-layered file set**

Delete the generated `lib/main.dart` and `test/widget_test.dart`. Create exactly these files under `../arch-analyze-fixture/lib/`:

`lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'ui/home_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(home: HomeScreen());
}
```

`lib/domain/note.dart`:
```dart
class Note {
  Note(this.id, this.title);

  factory Note.fromJson(Map<String, dynamic> json) =>
      Note(json['id'] as String, json['title'] as String);

  final String id;
  final String title;
}
```

`lib/data/notes_api.dart`:
```dart
import '../domain/note.dart';

class NotesApi {
  List<Note> load() => <Note>[
        Note('1', 'first note'),
        Note('2', 'second note'),
      ];
}
```

`lib/ui/notes_controller.dart`:
```dart
import 'package:flutter/foundation.dart';

import '../data/notes_api.dart';
import '../domain/note.dart';

class NotesController extends ChangeNotifier {
  NotesController(this._api);

  final NotesApi _api;
  List<Note> notes = <Note>[];

  void load() {
    notes = _api.load();
    notifyListeners();
  }
}
```

`lib/ui/home_screen.dart`:
```dart
import 'package:flutter/material.dart';

import '../domain/note.dart';
import 'note_detail_screen.dart';
import 'notes_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotesController _controller = NotesController(NotesApi());

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: ListView(
        children: _controller.notes
            .map((Note n) => ListTile(
                  title: Text(n.title),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => NoteDetailScreen(note: n),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
```

`lib/ui/note_detail_screen.dart`:
```dart
import 'package:flutter/material.dart';

import '../domain/note.dart';

class NoteDetailScreen extends StatelessWidget {
  const NoteDetailScreen({super.key, required this.note});

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

The set is exactly six files: `main.dart`, `domain/note.dart`, `data/notes_api.dart`, `ui/notes_controller.dart`, `ui/home_screen.dart`, `ui/note_detail_screen.dart`.

- [ ] **Step 3: Add a hand-written project architecture doc**

Create `../arch-analyze-fixture/docs/architecture.md`:
```markdown
# Архитектура

Проект разложен по слоям: `domain/` (модели), `data/` (доступ к данным),
`ui/` (экраны и контроллеры). Состояние экранов — через `ChangeNotifier`.
```

This is the project's **own** doc — it has no `ai-dev` marker.

- [ ] **Step 4: Verify it compiles**

```bash
cd /Users/dmitry/Work/my_own/arch-analyze-fixture && flutter pub get && flutter analyze
```
Expected: `flutter analyze` reports "No issues found!".

- [ ] **Step 5: Commit the fixture as its own git repo**

```bash
cd /Users/dmitry/Work/my_own/arch-analyze-fixture && git init -q && git add -A && git commit -q -m "hand-layered fixture: domain/data/ui, ChangeNotifier, no ai-dev marker"
```

No commit in the plugin repo — the fixture lives outside it.

---

## Task 2: Baseline test — RED

Per `superpowers:writing-skills`: observe what an agent does WITHOUT the skill before writing it.

**Files:**
- Create: `docs/plans/arch-analyze-baseline.md`

- [ ] **Step 1: Take a fresh copy of the flat-messy fixture**

```bash
rm -rf /tmp/arch-analyze-baseline && cp -r /Users/dmitry/Work/my_own/arch-migrate-fixture /tmp/arch-analyze-baseline && rm -rf /tmp/arch-analyze-baseline/.git
```

- [ ] **Step 2: Dispatch a baseline subagent**

Dispatch a general-purpose subagent, WITHOUT mentioning `arch-analyze`, the `ai-dev` family, the эталон, or the marker, pointing it at `/tmp/arch-analyze-baseline`, with this task:

> "Проверь архитектуру этого Flutter-проекта — всё ли с ней хорошо? Опиши, что нашёл."

Do not coach it.

- [ ] **Step 3: Record the baseline behavior verbatim**

In `docs/plans/arch-analyze-baseline.md`, document concretely:
- Did it give a clear verdict on the project's state, or just loose observations?
- Did it classify the project into any defined category?
- Did it check for layer folders, a presentation pattern, navigation style, entity mixing — and how consistently?
- Did it know anything about the `ai-dev` skill family, the marker, or recommend a specific next skill?
- Did it modify any files, or stay read-only?
- What did it skip, hand-wave, or get wrong vs. the spec's intended behavior?

These findings are the input to Task 3 Step 4 — the skill must counter exactly these gaps.

- [ ] **Step 4: Commit**

```bash
git add docs/plans/arch-analyze-baseline.md
git commit -m "docs(plans): baseline behavior for arch-analyze (RED)"
```

---

## Task 3: Write the `arch-analyze` skill

**Files:**
- Create: `skills/arch-analyze/SKILL.md`
- Create: `skills/arch-analyze/references/signal-probes.md`

- [ ] **Step 1: Write `SKILL.md`**

Frontmatter `description` is triggering-conditions only — no workflow summary (CSO rule, as in `arch-bootstrap`).

````markdown
---
name: arch-analyze
description: Use when asked to check, assess, or review the architecture of a Flutter project — "is the architecture OK", "what state is this project in", "look at this project's architecture".
---

# arch-analyze

You assess an existing Flutter project's architecture and recommend what to
do next. You are **read-only**: you survey, probe, and report to chat. You
do not edit or move files, you do not write a report file, you do not launch
other skills.

## Procedure

### 1. Survey

Gather, without changing anything:
- Does `pubspec.yaml` have a `flutter:` section?
- Is `lib/` empty, **flat** (`.dart` files directly in `lib/`, no layer
  subfolders), or **laid out** (subfolders that look like layers)?
- The top-level folder names under `lib/`.
- Is `test/architecture/` present (purity tests)?
- Is the first line of `docs/architecture/README.md` exactly
  `<!-- ai-dev:arch-contract v1 -->`?
- Is `docs/architecture/migration-progress.md` present? If so, read it.
- Is there any hand-written architecture doc (`docs/architecture.md`,
  `docs/architecture/`, `ARCHITECTURE.md`)?

### 2. Signal probes

Run the probes in `references/signal-probes.md`. These are cheap — greps
plus reading a few sample files — **not** a full scan. They cover: the
presentation pattern, layer/entity mixing, navigation, layers & dependency
direction, and basic smells. Form a one-line verdict for each probe.

### 3. Classify the state

Place the project in exactly one state:

| State | How to tell |
|---|---|
| greenfield | `lib/` empty, or only the generated `main.dart` counter template |
| flat | real code, but `lib/` has no layer subfolders |
| layered, no marker | `lib/` has layer-like subfolders, but no `ai-dev` marker |
| ai-dev, migration in progress | marker present AND `migration-progress.md` lists unfinished files |
| ai-dev, settled | marker present AND (no ledger, or ledger lists nothing remaining) |

### 4. Report

Report to the user **in chat only — write no file**:
- The state.
- The signal-probe verdicts (one line each).
- The recommendation for the state:

| State | Recommendation |
|---|---|
| greenfield | New project → use `arch-bootstrap`. |
| flat | Real code, no layers → use `arch-migrate`. |
| layered, no marker | Give the probe verdicts. The project has an architecture; `ai-dev` does not manage it (no marker). If the layout deviates from the эталон (`docs/reference-architecture/` — e.g. layer names like `data/` vs `ex_systems/`), name the deviations. State plainly: bringing a hand-architected project to the эталон is **not** covered by any skill yet — it is manual or future work. |
| ai-dev, migration in progress | Migration is underway; name the unfinished files from the ledger; `arch-migrate` continues it, extraction comes later. |
| ai-dev, settled | The project is `ai-dev`-managed. For a drift check, use `arch-audit` — and say plainly that `arch-audit` is not built yet. |

## Do not

- Write any file (the report is chat-only).
- Launch or dispatch another skill — you recommend, you do not run.
- Edit or move code, or "fix" anything.
- Do a deep drift analysis — that is `arch-audit`'s job.
````

- [ ] **Step 2: Verify the skill loads**

Reload plugins / run `claude --plugin-dir . -p "/help"`; confirm `arch-analyze` appears with no frontmatter error.

- [ ] **Step 3: Write `references/signal-probes.md`**

```markdown
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

- `flutter analyze` — clean or not (read-only, safe to run).
- Data preparation inside `initState` / `build` (a repository or API call
  in `initState`) → logic in the widget.
- Very large widget files — `find lib -name '*.dart' | xargs wc -l` and
  flag anything over ~400 lines.
Verdict: notable smells, or none.
```

- [ ] **Step 4: Fold the baseline findings**

Re-read `docs/plans/arch-analyze-baseline.md`. For each gap the baseline agent showed, confirm `SKILL.md` unmissably counters it. Likely gaps and their counters: the baseline gave loose observations with no verdict → the state classification (step 3) forces a verdict; the baseline knew nothing of the `ai-dev` family → the recommendation table names the exact next skill; the baseline probed inconsistently → `signal-probes.md` fixes the probe set. If any counter is only implied, add a short explicit line. Do not pad.

- [ ] **Step 5: Commit**

```bash
git add skills/arch-analyze/
git commit -m "feat(skill): arch-analyze — read-only architecture front door"
```

---

## Task 4: GREEN test — run the scenario with the skill

**Files:**
- Modify: `docs/plans/arch-analyze-baseline.md` (append GREEN results)

- [ ] **Step 1: GREEN-test on the flat-messy fixture**

```bash
rm -rf /tmp/arch-analyze-green-flat && cp -r /Users/dmitry/Work/my_own/arch-migrate-fixture /tmp/arch-analyze-green-flat
```
Dispatch a subagent that follows the `arch-analyze` skill (paste the `SKILL.md` content into the prompt; tell it `references/signal-probes.md` is at `/Users/dmitry/Work/my_own/ai-dev/skills/arch-analyze/references/signal-probes.md` and the эталон is at `/Users/dmitry/Work/my_own/ai-dev/docs/reference-architecture/`), pointed at `/tmp/arch-analyze-green-flat`, task: "Проверь архитектуру этого проекта."

Verify the report: state classified as **flat**; recommendation is **use `arch-migrate`**; probe verdicts mention no pattern / logic in widget, ad-hoc `Navigator.push`, no layers. Confirm the subagent changed **no files** and wrote **no report file**.

- [ ] **Step 2: GREEN-test on the hand-layered fixture**

```bash
rm -rf /tmp/arch-analyze-green-layered && cp -r /Users/dmitry/Work/my_own/arch-analyze-fixture /tmp/arch-analyze-green-layered
```
Dispatch a subagent the same way, pointed at `/tmp/arch-analyze-green-layered`, task: "Проверь архитектуру этого проекта, всё ли хорошо?"

Verify the report: state is **layered, no marker**; probe verdicts catch the `ChangeNotifier` controller pattern, the `fromJson` in the domain model (entity/data mixing), ad-hoc `Navigator.push`, and layer names deviating from the эталон (`data/` vs `ex_systems/`, no `app/`/`app_ports/`); the recommendation says `ai-dev` does not manage it and that bringing a hand-layered project to the эталон is not covered by a skill yet. No files changed.

- [ ] **Step 3: GREEN-test the marked state**

```bash
rm -rf /tmp/arch-analyze-green-marked && cp -r /Users/dmitry/Work/my_own/arch-analyze-fixture /tmp/arch-analyze-green-marked
mkdir -p /tmp/arch-analyze-green-marked/docs/architecture
printf '%s\n' '<!-- ai-dev:arch-contract v1 -->' '# Архитектура проекта' > /tmp/arch-analyze-green-marked/docs/architecture/README.md
```
Dispatch a subagent the same way, pointed at `/tmp/arch-analyze-green-marked`, task: "Проверь архитектуру этого проекта."

Verify: state is **ai-dev, settled** (marker present, no ledger); recommendation is **use `arch-audit`**, with the note that `arch-audit` is not built yet. No files changed.

- [ ] **Step 4: Record results and commit**

Append a "GREEN" section to `docs/plans/arch-analyze-baseline.md` — pass/fail per check across the three runs.

```bash
git add docs/plans/arch-analyze-baseline.md
git commit -m "docs(plans): arch-analyze GREEN test results"
```

---

## Task 5: REFACTOR — close gaps + version bump

- [ ] **Step 1: Fix every GREEN failure**

For each check that failed in Task 4, edit `SKILL.md` / `signal-probes.md` to address it. Common cause: a step is implied, not stated — make it explicit. If a probe verdict was missed, sharpen that probe's grep pattern or sample instruction.

- [ ] **Step 2: Re-run the GREEN scenario**

Repeat Task 4 Steps 1–3 on fresh copies. Confirm previously-failed checks now pass. Iterate until clean.

- [ ] **Step 3: Bump the plugin version**

Per the versioning policy, a new skill → bump `version` in `.claude-plugin/plugin.json` (patch bump).

- [ ] **Step 4: Commit**

```bash
git add skills/ .claude-plugin/plugin.json
git commit -m "fix(skill): close arch-analyze gaps from GREEN testing; bump version"
```

---

## Task 6: Real-project smoke test (user)

- [ ] **Step 1: Hand off to the user**

The user runs `arch-analyze` on a real project (including the hand-layered one that motivated this skill). The subagent fixture scenarios are the fast inner loop; this is the real acceptance gate. Capture any issues as follow-up tasks.

---

## Self-review notes

- **Spec coverage:** Task 3 ↔ the skill (survey, signal probes, five-state classification, chat-only report, the "do not" list); Task 3 Step 3 ↔ the `references/signal-probes.md` probe set from the spec's step 2; Tasks 1/2/4/5 ↔ writing-skills TDD. The `arch-audit` boundary is reflected in the "ai-dev, settled" recommendation (defer to `arch-audit`). `arch-audit`, extraction workers, and the hook are out of scope per the spec.
- **Known RED→GREEN dependency:** the exact emphasis wording added in Task 3 Step 4 depends on Task 2's baseline findings — a real dependency, not a placeholder. Structure, file paths, frontmatter, procedure, and reference contents are fully specified.
- **Type/name consistency:** the skill name `arch-analyze`, the marker `<!-- ai-dev:arch-contract v1 -->`, the ledger path `docs/architecture/migration-progress.md`, the five state names (greenfield / flat / layered, no marker / ai-dev, migration in progress / ai-dev, settled), and the fixture package `arch_analyze_fixture` are used consistently across all tasks.
- **Read-only invariant:** every GREEN check (Task 4) explicitly verifies the subagent changed no files and wrote no report file — the skill's core safety property.
