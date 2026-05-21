# `AGENTS.md` template

Generate the project root `AGENTS.md` from the template below. Replace
every `{{placeholder}}`. `CLAUDE.md` is a separate one-line file
containing exactly `@AGENTS.md` — do not duplicate this content there.

---

```markdown
# {{project_name}} — agent guide

{{project_purpose}}

## Before touching code

Read `docs/architecture/` first. The architecture is fixed and
mechanically enforced — code that breaks a layer boundary or a lint
will fail the gate below.

## Architecture docs

- [docs/architecture/README.md](docs/architecture/README.md) — architecture map: layers, dependency direction, folder tree, stack
- [docs/architecture/tech.md](docs/architecture/tech.md) — DI & scopes, networking, routing/navigation, auth
- [docs/architecture/ui.md](docs/architecture/ui.md) — screen structure, bloc/cubit, design system, localization
- [docs/architecture/enforcement.md](docs/architecture/enforcement.md) — purity tests, lint config, gate commands, anti-patterns
- [docs/architecture/decisions/INDEX.md](docs/architecture/decisions/INDEX.md) — architecture decision records

## Features

{{feature_list}}

## Gate — must pass before merge

Run all of these; all must be green:

\`\`\`
flutter analyze --no-pub
flutter test --no-pub
dart run dart_code_linter:metrics analyze lib | tee /tmp/dcl.out
! grep -qE '^(ERROR|WARNING)' /tmp/dcl.out
\`\`\`
```

---

## Filling the placeholders

- `{{project_name}}` / `{{project_purpose}}` — from customization Q1.
- `{{feature_list}}` — from customization Q4: a bullet per feature, each
  naming its `domain/<feature>/` and `ui/<screen>/` pair. Example:

  ```
  - Notes list — `domain/notes/` + `ui/notes_list/`
  - Note editor — `domain/notes/` + `ui/note_editor/`
  ```

- If the user declined the ADR folder in step 4, drop the
  `decisions/INDEX.md` line from the docs list.
- The gate block is copied verbatim from
  `docs/architecture/enforcement.md`. If `enforcement.md` ever changes
  its commands, take them from there — that file is the source.
