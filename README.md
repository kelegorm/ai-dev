# ai-dev

Личная коллекция принципов и инструментов для разработки через AI-агентов.
Одновременно (а) человекочитаемые доки, (б) Claude Code плагин.

## Установка как плагин

```
/plugin install github:kelegorm/ai-dev
```

Скиллы будут вызываться как `/ai-dev:<skill-name>`.

Локальная разработка плагина:

```bash
claude --plugin-dir /path/to/ai-dev
/reload-plugins
```

## Зависимости

Доки и (будущие) скиллы предполагают, что в Claude Code сессии установлены:

- **`compound-engineering`** — обязательно. `ai_dev.md` ссылается на
  `ce-strategy`, `ce-brainstorm`, `ce-plan`, `ce-doc-review` как ключевые
  шаги процесса. Без них всё работает, но руками и хуже.
- **`superpowers`** — опционально. Некоторые практики (`writing-plans`,
  `subagent-driven-development`, `using-git-worktrees`) пересекаются с тем,
  что описано здесь. Если стоит — пригодится; если нет — доки
  самодостаточны.

Если плагины ещё не установлены: `/plugin marketplace add anthropic-marketplace`
(или подходящий маркетплейс), затем `/plugin install compound-engineering`.

## Что внутри

- [`docs/ai_dev.md`](docs/ai_dev.md) — общая философия: документация в
  проекте, roadmap, процесс CE, оркестратор vs subagent, enforcement,
  rewrite vs refactor.
- [`docs/orchestrator.md`](docs/orchestrator.md) — заготовка системного
  промпта для оркестратор-сессии: брифинг саба, проверка результата,
  типичные ошибки и реакция.
- [`docs/reference-architecture/`](docs/reference-architecture/README.md) — конкретная Flutter-архитектура:
  layered + ports & adapters, направления зависимостей, mechanical
  enforcement, UI/Bloc/Navigation/DesignSystem конвенции.
- `skills/` — рабочие скиллы. Пока пусто; наполняется по мере того, как
  одна и та же процедура повторяется в третий раз.

## Связанные репозитории

- [`kelegorm/good_flutter_app`](https://github.com/kelegorm/good_flutter_app)
  — литературный пример архитектуры из [`docs/reference-architecture/`](docs/reference-architecture/README.md) в
  работающем виде: шаблонный Flutter-проект со всеми слоями, purity-тестами,
  strict lint и `flutter_bloc` + `auto_route`. Использовать как референс
  при бутстрапе нового проекта.

## Структура

```
ai-dev/
├── .claude-plugin/
│   └── plugin.json           # манифест Claude Code плагина
├── docs/                      # человекочитаемые принципы и шаблоны
│   ├── ai_dev.md
│   ├── orchestrator.md
│   └── reference-architecture/
├── skills/                    # исполняемые скиллы (skills/<name>/SKILL.md)
└── README.md
```

## Принципы наполнения

- **Доки меняются медленно.** Это контракт того, как мы работаем.
- **Скиллы пишутся когда практика устаканилась.** Третий раз руками — повод
  выносить.
- **Скилл = одна процедура с явным acceptance criteria.** Не «помощник»,
  а проверяемая единица работы.

## Лицензия

MIT.
