# Эталонная архитектура Flutter-проектов

Это **эталонная (reference)** архитектура для Flutter-проектов — не архитектура какого-то конкретного проекта, а канонический образец, которому следуют все наши Flutter-приложения.

Разделы:
- [tech.md](tech.md) — DI, сеть, routing, авторизация
- [ui.md](ui.md) — структура экрана, Bloc/Cubit, навигация, design system, локализация
- [enforcement.md](enforcement.md) — mechanical enforcement и анти-паттерны

---

Литературный пример этой архитектуры в работающем коде —
[`kelegorm/good_flutter_app`](https://github.com/kelegorm/good_flutter_app).
Шаблонный проект со всем, что описано ниже: слоями `lib/{app, domain,
ex_systems, ui}/`, `flutter_bloc` + `auto_route`, strict lint,
per-layer purity-тесты. Использовать как справочник при бутстрапе нового
проекта.

Подход держится на нескольких устоявшихся идеях. **Layered architecture** —
код разделён на слои с односторонним направлением зависимостей. **Ports &
Adapters (Hexagonal)** — UI и бизнес-логика работают через интерфейсы;
реализации скрыты за ними и подменяемы. **Composition root** — единственное
место, где интерфейсы связываются с конкретными реализациями. **Dependency
Injection** — связи объектов получаются извне, а не создаются внутри.
**Cross-cutting concerns** (навигация, логирование, аутентификация,
аналитика) выделены в отдельный слой портов, чтобы не размазываться по
бизнес-логике. **Mechanical enforcement** — архитектурные границы
проверяются автотестами и линтерами, а не словами в README.

## Структура папок

```
lib/
  app/                # composition root: bootstrap, DI, router impl, session
    bootstrap/
    di/               # фабрики блоков и регистрации get_it
    navigation/       # реализация AppNavigator поверх auto_route
    session/          # SessionController и подобный glue к app_ports/
  app_ports/          # cross-cutting concerns: navigation, logging, analytics,
                      # auth, feature flags. Бизнес-порты — в domain/ports/.
    navigation/       # AppNavigator (interface)
  domain/             # чистый Dart, никаких Flutter/JSON/transport.
                      # Содержит и domain-логику, и app-уровневую (use cases).
    ports/            # репозитории/сервисы (interface)
    <feature>/        # entities, value objects, business logic, use cases
    shared/           # межфичные сервисы/контроллеры на domain/ports/
                      # (AuthController, SyncCoordinator). Если контроллер
                      # дёргает app_ports/ (navigation, analytics) — он не
                      # domain, его место в app/.
  ex_systems/         # реализации портов (external systems)
    network/          # Dio + interceptors + repository impls
    storage/          # secure storage, prefs, БД
    <subsystem>/
  ui/                 # экраны и виджеты
    common/           # shared utilities (sharedSiblings)
    components/       # переиспользуемые виджеты (sharedSiblings)
    design_system/    # AppColors/Spacing/Theme/Buttons (sharedSiblings)
    <screen>/
      bloc/             # <screen>_bloc.dart + _event.dart + _state.dart (sealed)
      widgets/          # экранные виджеты в отдельных файлах
      <subscreen>/      # большая локальная модалка/часть, не виджет

test/
  architecture/       # тесты на проверку архитектурных и межмодульных границ
  domain/             # тесты бизнес-логики
  ex_systems/
  ui/

docs/                 # документация проекта (раскладка — см. ai_dev.md)
```

## Архитектура

### Слои и направление зависимостей

```
app/  →  ui/  →  domain/
      \         ↑
       ex_systems/
                ↑
       app_ports/  (interfaces only)
```

Кто что импортирует и что **никогда** не должен:

| Слой | Импортирует | Никогда |
|---|---|---|
| `app/` | всё (composition root) | — |
| `ui/` | `domain/`, `app_ports/`, flutter, design_system | `ex_systems/`, `app/` |
| `domain/` | dart + микро-allowlist | flutter, json, transport, другие слои |
| `ex_systems/` | `domain/`, `app_ports/`, transport-пакеты | `ui/`, `app/` |
| `app_ports/` | `domain/` (для типов) | flutter, реализации, другие слои |

`app/` — единственное место, где `ui/` и `ex_systems/` встречаются (через
DI). Между собой эти слои друг друга не видят.

### Модули внутри слоёв

В `domain/` модуль = **фича** (`domain/<feature>/`): свои entities, value
objects, use cases. Фичи изолированы — чтобы общаться, идут через события
или явные публичные API. Cross-feature логика — в `domain/shared/`.

В `ui/` модуль = **экран** (`ui/<screen>/`): свой bloc, виджеты, локальные
подэкраны. Экраны изолированы (см. cross-screen-isolation в purity-тесте).
Cross-screen — в `ui/common/`, `ui/components/`, `ui/design_system/`.

Параллель: **фича в domain ↔ экран в ui** — единицы изоляции. Связь между
ними проходит через bloc в ui, который зовёт доменные порты.

### Порты — два уровня

- `lib/app_ports/` — **cross-cutting concerns**: navigation, logging,
  analytics, auth, feature flags. То, что нужно UI, но не бизнес-логика.
- `lib/domain/ports/` — **бизнес-порты**: репозитории и доменные сервисы
  (`AuthRepository`, `JournalRepository`, `LessonRepository`).

Реализации обоих — в `ex_systems/`. Исключение — реализации, требующие
app-state (`GlobalKey<NavigatorState>`, корневой router): они живут в `app/`
рядом с этим состоянием.

### Куда класть контроллеры и state holder'ы

Тест: с какими портами работает.

- Только с `domain/ports/` → `domain/shared/` или `domain/<feature>/`. Это
  всё ещё бизнес-логика. Примеры: `AuthController` (хранит auth state, зовёт
  `AuthRepository`), `SyncCoordinator` (синхронит между доменными портами).
- Лезет в `app_ports/` (navigation, analytics, push) → `app/<thing>/`. Это
  уже не domain, а glue между бизнес-логикой и cross-cutting. Пример:
  `SessionController` (ловит изменение auth state и зовёт `AppNavigator`).

## Стек

- `flutter_bloc` — state management
- `get_it` — dependency injection (со scopes)
- `auto_route` — навигация (code generation, URL-paths)
- `dio` — HTTP-клиент
- `dart_code_linter` — расширенные линты
- `freezed` (опционально) — кодген для sealed states/events и
  immutable-моделей

Заменять с обоснованием.

## Зафиксированный выбор

| Вопрос              | Решение                                            |
|---------------------|----------------------------------------------------|
| Adapter-слой        | `ex_systems/` (external systems)                   |
| Топ-уровневые порты | `lib/app_ports/`                                   |
| State-классы        | Отдельный `*_state.dart`, sealed                   |
| Event-классы        | Отдельный `*_event.dart`, sealed                   |
| Routing             | `auto_route`, path-routes с первого дня            |
