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
