# arch-bootstrap — baseline (RED)

Что делает агент **без** скилла `arch-bootstrap`, получив задачу
«пустая папка, начни Flutter-заметочницу с хорошей архитектурой».
Дата: 2026-05-21. Модель: sonnet.

## Вывод одной строкой

Агент строит **разумную, но другую** архитектуру. Без скилла он делает
хороший проект — но не по эталону. Значит скилл должен быть
**предписывающим**: не «сделай хорошо», а «сделай именно так».

## Что агент сделал хорошо (само, без скилла)

- Разбил на слои с односторонними зависимостями.
- Написал arch-док (`docs/architecture/overview.md`) с графом слоёв.
- Настроил механический enforcement: grep-тест границ слоёв в
  `test/architecture/`, строгий `analysis_options.yaml`.
- Завёл agent-файл с правилами и командами.

Вывод: базовую *идею* layered + enforcement объяснять не надо. Надо
навязать **конкретику эталона**.

## Расхождения с эталоном (это и чинит скилл)

| Аспект | Сделал сам | Эталон требует |
|---|---|---|
| State management | Riverpod 2 | `flutter_bloc` |
| DI | Riverpod-провайдеры | `get_it` со scopes (`unauth`/`auth`) |
| Навигация | `go_router` | `auto_route`, path-routes с первого дня |
| Слои | `core/ domain/ data/ presentation/` | `app/ app_ports/ domain/ ex_systems/ ui/` |
| Порт-слой | нет | `app_ports/` (cross-cutting), `domain/ports/` (бизнес) |
| Навигация в коде | экраны зовут роутер напрямую | только через `AppNavigator`-порт |
| Разбивка `domain/` | по типам (`entities/ repositories/ usecases/`) | по фичам (`domain/<feature>/` + `domain/shared/`) |
| Разбивка UI | `presentation/<screen>/` | `ui/<screen>/` со своим `bloc/` |
| Agent-файл | `CLAUDE.md` (а `AGENTS.md` намеренно НЕ создал) | `AGENTS.md` главный, `CLAUDE.md` → `@AGENTS.md` |
| Arch-доки | один `overview.md` | набор: `README/tech/ui/enforcement` |
| Маркер | нет | штамп `ai-dev arch contract` в `README.md` |
| Хранилище | Drift (выбрал сам) | реализации в `ex_systems/`, HTTP — `dio` |

## Следствия для скилла (вход в Task 4, шаг 3)

Скилл `arch-bootstrap` обязан явно:

1. **Навязать стек:** `flutter_bloc` + `get_it` (scopes) + `auto_route` +
   `dio`. Не оставлять выбор агенту — он выберет Riverpod/go_router.
2. **Навязать имена слоёв:** `app/ app_ports/ domain/ ex_systems/ ui/`.
   Агент по умолчанию назовёт `core/data/presentation`.
3. **Потребовать порт-слой** и навигацию только через `AppNavigator` —
   агент сам его не заводит.
4. **Потребовать feature-разбивку** `domain/<feature>/` и `ui/<screen>/`
   с локальным `bloc/` — агент режет по техническим типам.
5. **Потребовать `AGENTS.md`** как главный файл (+ `CLAUDE.md` →
   `@AGENTS.md`) — агент сам предпочитает `CLAUDE.md`.
6. **Потребовать набор арх-доков** (4 файла) и **штамп-маркер** — агент
   сам пишет один общий файл и маркер не ставит.

Поскольку агент и сам делает enforcement и слои, скилл не объясняет
«зачем архитектура» — он коротко и жёстко фиксирует **какую именно** и
опирается на копирование из шаблона `good_flutter_app`, чтобы стек и
имена не дрейфовали.
