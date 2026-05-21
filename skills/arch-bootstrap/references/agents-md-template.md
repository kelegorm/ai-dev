# `AGENTS.md` template

Generate the project root `AGENTS.md` from the template below. Replace
every `{{placeholder}}`. `CLAUDE.md` is a separate one-line file
containing exactly `@AGENTS.md` — do not duplicate this content there.

---

```markdown
# {{project_name}} — гид для агентов

{{project_purpose}}

## Перед тем как трогать код

Сначала прочитай `docs/architecture/`. Архитектура зафиксирована и
проверяется механически — код, нарушающий границу слоя или линт,
завалит гейт ниже.

## Документы архитектуры

- [docs/architecture/README.md](docs/architecture/README.md) — карта архитектуры: слои, направление зависимостей, дерево папок, стек
- [docs/architecture/tech.md](docs/architecture/tech.md) — DI и scopes, сеть, routing/навигация, авторизация
- [docs/architecture/ui.md](docs/architecture/ui.md) — структура экрана, bloc/cubit, design system, локализация
- [docs/architecture/enforcement.md](docs/architecture/enforcement.md) — purity-тесты, конфиг линта, гейт-команды, анти-паттерны
- [docs/architecture/decisions/INDEX.md](docs/architecture/decisions/INDEX.md) — architecture decision records (ADR)

## Фичи

{{feature_list}}

## Гейт — должен проходить до merge

Запусти все команды; все должны быть зелёными:

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
