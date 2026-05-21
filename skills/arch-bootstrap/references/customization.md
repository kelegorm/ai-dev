# Customization dialog

Ask the user these questions. Each answer customizes the project's
`docs/architecture/README.md` (step 4). Ask them together, accept short
answers, do not over-explain.

## Q1 — App name and one-line purpose

> "Как называется приложение и в одну строку — что оно делает?"

**Changes `README.md`:** the title and the opening paragraph become this
project's name and purpose, replacing the эталон's "это эталонная
архитектура" framing. Example: `# MyNotes — заметочница с офлайн-синком`.

## Q2 — Needs a backend / network?

> "Приложение ходит в сеть / к бэкенду?"

**Changes `README.md`:**
- Yes → keep the `dio` line in the stack section and keep
  `ex_systems/network/` in the folder tree.
- No → still keep `ex_systems/` (storage, device APIs live there), but
  note in the tree that `network/` is unused for now. Do not delete the
  `dio` dependency from the template — leave it; adding network later
  must not require re-bootstrapping.

## Q3 — Needs auth?

> "Есть авторизация пользователя (логин, токены)?"

**Changes `README.md`:**
- Yes → keep both `get_it` scopes (`unauth` / `auth`) in the DI section
  and keep the auth flow described in `tech.md` as live.
- No → keep a single default scope; in the DI section state that only
  `unauth` is used and the `auth` scope is reserved for when auth lands.
  Do not remove the scope mechanism from the template.

## Q4 — Initial feature list

> "Перечисли стартовые фичи / экраны (например: список заметок,
> редактор заметки, настройки)."

**Changes `README.md`:** the "Модули внутри слоёв" section gets a
concrete list. Each feature maps to:
- a `domain/<feature>/` folder (entities, value objects, use cases)
- a `ui/<screen>/` folder with its own local `bloc/`

List the planned `domain/<feature>/` and `ui/<screen>/` pairs explicitly
in `README.md` so the layout is named, not implied. Do not create the
feature folders' contents now — only name them in the doc; the skeleton
folders come from the template.

This same list fills the `{{feature_list}}` placeholder in `AGENTS.md`.
