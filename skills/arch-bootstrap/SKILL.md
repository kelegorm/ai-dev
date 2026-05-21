---
name: arch-bootstrap
description: Use when starting a new Flutter project, or when asked to set up / lay out / scaffold the architecture of a Flutter app that has no architecture yet.
---

# arch-bootstrap

Lays a greenfield Flutter project out in the reference architecture: layer skeleton, project arch docs, `AGENTS.md`, working enforcement.

This skill is **prescriptive**. An unguided agent builds a reasonable but *different* architecture (Riverpod, `go_router`, `core/data/presentation`). Do not improvise — follow the steps and copy from the named sources. The folder names, stack, purity tests, and lint config are **fixed**, not suggestions.

**Fixed stack — do not substitute.** `flutter_bloc` (state) · `get_it` with scopes (DI) · `auto_route`, path-routes (navigation) · `dio` (HTTP). Not Riverpod, not `go_router`.

**Fixed layers — do not rename.** `lib/{app, app_ports, domain, ex_systems, ui}/`. Not `core/data/presentation`.

## Procedure

Run steps 0–6 in order. Do not skip the verify step.

### 0. Project exists?

`pubspec.yaml` with a `flutter:` section AND a `lib/` directory present?
- No → run `flutter create` (you know how — do not document it here).
- Yes → skip to step 1.

### 1. Marker check

Does `docs/architecture/` contain a file whose **first line** is exactly:

```
<!-- ai-dev:arch-contract v1 -->
```

- Yes → project is already bootstrapped. **STOP. Do not overwrite anything.**
- No → continue.

### 2. Scaffold from template

The template `kelegorm/good_flutter_app` is the **single source** of the layer skeleton, purity tests, and lint config. Do not invent any of them.

```bash
git clone --depth 1 https://github.com/kelegorm/good_flutter_app /tmp/gfa-template
```

From the clone, copy into the project:
- the layer skeleton `lib/{app, app_ports, domain, ex_systems, ui}/`
- `test/architecture/`
- `analysis_options.yaml`

Then delete the clone's `.git` (and `/tmp/gfa-template` once copied).

### 3. Customization dialog

Run the mini-dialog in `references/customization.md`. Record the answers — they fill in the project `README.md` in step 4.

### 4. Generate project arch docs

Target: the project's `docs/architecture/`.

- Copy **verbatim** from `${CLAUDE_PLUGIN_ROOT}/docs/reference-architecture/`: `tech.md`, `ui.md`, `enforcement.md`.
- Produce the project's `docs/architecture/README.md` from the эталон `README.md`: drop the "это эталонная архитектура" framing, turn it into *this* project's own architecture map, and fill in project name/purpose and the step-3 answers (feature list, whether the `auth` scope is used). Its **first line must be** `<!-- ai-dev:arch-contract v1 -->`.
- Ask the user whether to create `docs/architecture/decisions/` (ADR folder). If yes: create it with an `INDEX.md` that has a one-line explanation of what ADRs are plus an empty list.

### 5. Generate `AGENTS.md`

Generate `AGENTS.md` in the project root from `references/agents-md-template.md` (fill the `{{placeholders}}`).
Also create `CLAUDE.md` containing exactly one line: `@AGENTS.md`.
`AGENTS.md` is the main agent file — do not put rules in a standalone `CLAUDE.md`.

### 6. Verify

Run the gate commands from the project's `enforcement.md` (`flutter analyze`, `flutter test`, and the `dart_code_linter` grep gate). Report the results. **Do not declare the bootstrap done until they pass.**

## Result checklist

- [ ] `lib/{app, app_ports, domain, ex_systems, ui}/` present, from the template
- [ ] `test/architecture/` purity tests + `analysis_options.yaml` present, from the template
- [ ] `docs/architecture/{README,tech,ui,enforcement}.md` — README first line is the marker
- [ ] `AGENTS.md` indexing every arch doc; `CLAUDE.md` is `@AGENTS.md`
- [ ] gate commands run and pass
