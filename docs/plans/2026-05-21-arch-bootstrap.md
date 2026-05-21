# arch-bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `arch-bootstrap` skill for the `ai-dev` plugin — it lays a greenfield Flutter project out in the reference architecture, writing the project's architecture docs, `AGENTS.md` index, and enforcement code.

**Architecture:** A skill is authored by TDD per `superpowers:writing-skills` — baseline scenario (RED) before writing, scenario re-run (GREEN) after. The reference architecture (`docs/reference-architecture/`) is first split from the former monolithic doc into `docs/reference-architecture/`; `arch-bootstrap` copies those files into a new project's `docs/architecture/`, customizes them, and pulls layer skeleton + enforcement code from the `good_flutter_app` template repo.

**Tech Stack:** Claude Code plugin (skills), Markdown, git, Flutter (`flutter create`), Dart.

---

## Source spec

`docs/specs/2026-05-21-flutter-arch-skills-design.md`. This plan covers **only `arch-bootstrap`**. `arch-migrate`, `arch-audit`, and the hook are deferred to their own brainstorms.

## Assumptions / preconditions

- `kelegorm/good_flutter_app` is in a usable state — it carries the layer skeleton, `test/architecture/` purity tests, and `analysis_options.yaml`. If it is not, bringing it to that state is pre-work outside this plan.
- `good_flutter_app` is sourced by `git clone --depth 1` + stripping `.git` (single source of truth; no vendored snapshot).

## File structure

| File | Responsibility |
|---|---|
| `docs/reference-architecture/README.md` | Эталон spine: style declaration, layers, folder tree, stack, frozen choices |
| `docs/reference-architecture/tech.md` | Эталон: DI, networking, routing/navigation, auth |
| `docs/reference-architecture/ui.md` | Эталон: screen structure, bloc, design system, l10n |
| `docs/reference-architecture/enforcement.md` | Эталон: purity tests, lint, gate commands, anti-patterns |
| `skills/arch-bootstrap/SKILL.md` | The skill: triggers + procedure steps 0–6 |
| `skills/arch-bootstrap/references/agents-md-template.md` | Template for the project's `AGENTS.md` index |
| `skills/arch-bootstrap/references/customization.md` | The mini-dialog: questions for project-specific `README.md` |
| `docs/plans/arch-bootstrap-baseline.md` | Baseline test findings (RED), input to the skill body |

---

## Task 1: Split the эталон into `docs/reference-architecture/`

**Files:**
- Create: `docs/reference-architecture/README.md`, `tech.md`, `ui.md`, `enforcement.md`
- Delete: former monolithic arch doc (done — see commit)
- Modify: `README.md` (repo root), `docs/ai_dev.md` — links to former monolithic arch doc

- [ ] **Step 1: Create the four split files**

Move content from former monolithic arch doc verbatim, by section:

- `README.md` ← intro paragraphs + `## Структура папок` + `## Архитектура` (Слои/направление, Модули, Порты, Контроллеры) + `## Стек` + `## Зафиксированный выбор`. Add a top line: this is the **эталонная** architecture (reference), not a project's.
- `tech.md` ← `## Техническая архитектура` (DI, Сеть, Routing, Авторизация).
- `ui.md` ← `## UI` (Структура экрана, Bloc/Cubit, Modal vs screen, Навигация, Design system, Локализация).
- `enforcement.md` ← `## Mechanical enforcement` + `## Анти-паттерны`.

Add a links block at the top of `README.md` pointing to the other three.

- [ ] **Step 2: Delete former monolithic arch doc and fix inbound links**

`grep -rn "arch[.]md" --include=*.md .` — update every hit. Repo `README.md` and `docs/ai_dev.md` referenced the monolithic arch doc; repointed to `docs/reference-architecture/README.md`.

- [ ] **Step 3: Verify no content lost, no dangling links**

Run:
```bash
grep -rn "arch[.]md" --include=*.md . ; echo "exit: $?"
wc -l docs/reference-architecture/*.md
```
Expected: first grep prints nothing (exit 1). Total line count across the four files ≈ original monolithic arch doc line count (±20 for added headers/links).

- [ ] **Step 4: Commit**

```bash
git add -A docs/ README.md
git commit -m "docs(arch): split reference architecture into docs/reference-architecture/"
```

---

## Task 2: Baseline test — RED

Per `superpowers:writing-skills`: observe what an agent does WITHOUT the skill before writing it.

**Files:**
- Create: `docs/plans/arch-bootstrap-baseline.md`

- [ ] **Step 1: Dispatch a baseline subagent**

Dispatch a general-purpose subagent, WITHOUT mentioning `arch-bootstrap` or the эталон, with this task:

> "Пустая папка. Нужно начать Flutter-приложение (простую заметочницу) с хорошей, поддерживаемой архитектурой. Разложи проект и опиши, что сделал."

Give it a scratch directory. Do not coach it.

- [ ] **Step 2: Record the baseline behavior verbatim**

In `docs/plans/arch-bootstrap-baseline.md`, document concretely:
- Did it create layered folders? Which layers / names?
- Did it write any architecture documentation? `AGENTS.md`?
- Did it set up enforcement (tests asserting structure, strict lint)?
- Did it pick state management / DI / routing? Which?
- What did it skip, hand-wave, or get wrong vs. the эталон?

These findings are the input to Task 4 — the skill must counter exactly these gaps.

- [ ] **Step 3: Commit**

```bash
git add docs/plans/arch-bootstrap-baseline.md
git commit -m "docs(plans): baseline behavior for arch-bootstrap (RED)"
```

---

## Task 3: Write the `arch-bootstrap` skill skeleton

**Files:**
- Create: `skills/arch-bootstrap/SKILL.md`

- [ ] **Step 1: Write frontmatter + procedure**

`SKILL.md` frontmatter — `description` is triggering-conditions only, no workflow summary (CSO rule):

```markdown
---
name: arch-bootstrap
description: Use when starting a new Flutter project, or when asked to set up / lay out / scaffold the architecture of a Flutter app that has no architecture yet.
---
```

Body — a thin procedure, steps 0–6 from the spec. Each step states intent and the deterministic check, not prose padding:

0. **Project exists?** `pubspec.yaml` with `flutter:` + `lib/` present? No → `flutter create` (do NOT document how — the agent knows). Yes → skip.
1. **Marker check.** `docs/architecture/` has a file carrying the `ai-dev arch contract` marker? Yes → already bootstrapped, stop. No → continue.
2. **Scaffold from template.** `git clone --depth 1 https://github.com/kelegorm/good_flutter_app`, copy the layer skeleton + `test/architecture/` + `analysis_options.yaml`, remove the clone's `.git`.
3. **Customization dialog.** Follow `references/customization.md`.
4. **Generate project arch docs.** Copy `${CLAUDE_PLUGIN_ROOT}/docs/reference-architecture/{README,tech,ui,enforcement}.md` into the project's `docs/architecture/`. Customize `README.md` per the dialog answers. Stamp `README.md` with the marker. Ask whether to create `docs/architecture/decisions/` (ADR) — if yes, add it with an empty `INDEX.md`.
5. **Generate `AGENTS.md`** from `references/agents-md-template.md`, linking every arch doc + `decisions/INDEX.md` + the gate commands.
6. **Verify.** Run the gate commands (`flutter analyze`, `flutter test`); report.

- [ ] **Step 2: Verify the skill loads**

Run: `claude --plugin-dir . -p "/help"` or reload plugins; confirm `arch-bootstrap` appears with no frontmatter error.

- [ ] **Step 3: Commit**

```bash
git add skills/arch-bootstrap/SKILL.md
git commit -m "feat(skill): arch-bootstrap skeleton"
```

---

## Task 4: Write the reference files

**Files:**
- Create: `skills/arch-bootstrap/references/agents-md-template.md`, `skills/arch-bootstrap/references/customization.md`

- [ ] **Step 1: Write `customization.md`**

The mini-dialog. Questions whose answers make the project `README.md` project-specific: app name & one-line purpose; needs network/backend?; needs auth (and therefore the `unauth`/`auth` get_it scopes)?; initial feature list (each becomes a `domain/<feature>/` + `ui/<screen>/`). Each question states how the answer changes `README.md`.

- [ ] **Step 2: Write `agents-md-template.md`**

A project `AGENTS.md` template: gate commands block (from `enforcement.md`), a "before touching code, read `docs/architecture/`" rule, and a links section to every arch doc + `decisions/INDEX.md`. Use `{{placeholders}}` for project name and the feature list.

- [ ] **Step 3: Fold baseline gaps into `SKILL.md`**

Re-read `docs/plans/arch-bootstrap-baseline.md`. For each gap the baseline agent showed, add a targeted line to `SKILL.md` that prevents it (e.g. baseline skipped enforcement → make step 6 explicit that the gate must run and pass before declaring done).

- [ ] **Step 4: Commit**

```bash
git add skills/arch-bootstrap/references/ skills/arch-bootstrap/SKILL.md
git commit -m "feat(skill): arch-bootstrap reference files + baseline-informed steps"
```

---

## Task 5: GREEN test — run the scenario with the skill

**Files:**
- Modify: `docs/plans/arch-bootstrap-baseline.md` (append GREEN results)

- [ ] **Step 1: Dispatch a subagent WITH the skill**

Same task as Task 2 Step 1, but in a fresh scratch directory and with the `arch-bootstrap` skill available. Let it run.

- [ ] **Step 2: Check compliance against the spec**

Verify the result has: layered folders matching the эталон; `docs/architecture/` with the four docs + marker; `AGENTS.md` indexing them; `test/architecture/` purity tests present; gate commands run. Append pass/fail per item to the baseline doc.

- [ ] **Step 3: Commit**

```bash
git add docs/plans/arch-bootstrap-baseline.md
git commit -m "docs(plans): arch-bootstrap GREEN test results"
```

---

## Task 6: REFACTOR — close gaps

- [ ] **Step 1: Fix every GREEN failure**

For each item that failed in Task 5 Step 2, edit `SKILL.md` / references to address it. Common cause: a step is implied, not stated — make it explicit.

- [ ] **Step 2: Re-run the GREEN scenario**

Repeat Task 5 Step 1 in a new scratch dir. Confirm previously-failed items now pass. Iterate until clean.

- [ ] **Step 3: Commit**

```bash
git add skills/arch-bootstrap/
git commit -m "fix(skill): close arch-bootstrap gaps from GREEN testing"
```

---

## Task 7: Real-project smoke test (user)

- [ ] **Step 1: Hand off to the user**

The user runs `arch-bootstrap` on a throwaway real project (`flutter create` from scratch) and edits in parallel. Capture any issues as follow-up tasks. This is the real acceptance gate; the subagent scenarios are the fast inner loop.

---

## Self-review notes

- **Spec coverage:** Task 1 ↔ эталон reorg; Tasks 3–4 ↔ `arch-bootstrap` steps 0–6, doc set, marker, customization; Tasks 2/5/6 ↔ writing-skills TDD. `arch-migrate`/`arch-audit`/hook are explicitly out of scope per spec.
- **Known dependency:** the exact wording of the `SKILL.md` body emphasis (Task 4 Step 3) depends on Task 2's baseline findings — this is a real RED→GREEN dependency, not a placeholder. Structure, file paths, frontmatter, and procedure are fully specified.
- The `good_flutter_app` sourcing decision (clone-and-strip) is locked in Task 3 Step 1.
