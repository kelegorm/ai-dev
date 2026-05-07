# Архитектура Flutter-приложения

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

## Техническая архитектура

### DI: get_it и scopes

`get_it` со **scope'ами**. Минимум два: **`unauth`** (стартовый, без
пользовательских данных) и **`auth`** (после успешного логина). В каждом
scope свои регистрации — например, в `auth` появляются `UserProfileService`,
`SyncCoordinator`, авторизованные репозитории.

Переключение — `pushNewScope` / `popScope`. Триггерит **AuthController**, не
виджеты (см. «Авторизация»).

**Блоки регистрируются как фабрики** в `lib/app/di/`:
`registerFactory<XBloc>(() => XBloc(...))`. Зависимости разрешаются внутри
фабрики. Экран делает `BlocProvider(create: (_) => getIt<XBloc>())` и
**не вытаскивает зависимости блока вручную**.

Исключение — **контекстные параметры**, которые экран получил через
навигацию (id, фильтр, таймстемп). Их экран передаёт фабрике как initial
argument: `getIt<XBloc>(param1: id)` или через `registerFactoryParam`.

### Сеть: Dio + interceptors

HTTP — `dio`. Реализации репозиториев из `domain/ports/` живут в
`ex_systems/network/` и принимают `Dio` через конструктор.

Стандартные interceptor'ы:

- **AuthInterceptor** — добавляет токен в заголовки, ловит 401/403, зовёт
  refresh, при успехе ретраит оригинальный запрос.
- **LoggingInterceptor** — отладочный.
- **ErrorMappingInterceptor** — `DioException` → доменные ошибки.

Refresh-логика **не живёт в interceptor'е напрямую** — она в
`AuthController`, interceptor её зовёт. Одна точка авторизации.

### Routing: auto_route с URL-навигацией

`auto_route` с **path-routes с самого начала**. Каждый маршрут — нормальный
URL: `/login`, `/home`, `/journal/:id?from=2026-05-08`. Это даёт:

- Deep-linking работает с первого дня.
- Тестировать можно прямо в браузере (Flutter web), даже до mobile.
- Параметры — через `@PathParam` / `@QueryParam`, не через initial state
  блока.

Конфиг — `lib/app/navigation/app_router.dart` c `@AutoRouterConfig`.
Generated `app_router.gr.dart` рядом.

### Авторизация: scope switch + refresh

Auto_route guards в одиночку **недостаточны**: срабатывают автоматически и
не умеют восстановиться. Если токен просто протух, guard кинет на login,
хотя refresh бы спас.

Правильный поток — через **AuthController** в `domain/shared/services/`
(или `domain/auth/`):

1. Слушает auth state (токен, refresh token, expiry).
2. На истечение / 401 — пробует refresh.
3. Только если refresh упал — переключает scope в `get_it` и зовёт
   `AppNavigator.openLogin()`.

Guards остаются как **декларативный fallback** («без auth scope на этом
маршруте — на login»). Активная логика recovery — в контроллере.

## Стек

- `flutter_bloc` — state management
- `get_it` — dependency injection (со scopes)
- `auto_route` — навигация (code generation, URL-paths)
- `dio` — HTTP-клиент
- `dart_code_linter` — расширенные линты
- `freezed` (опционально) — кодген для sealed states/events и
  immutable-моделей

Заменять с обоснованием.

## Mechanical enforcement

Только тесты и линты — конвенции в README не работают.

1. **Purity-тесты** в `test/architecture/`:
   - `layer_check.dart` — общий движок, allowlist-семантика.
   - По одному тесту на слой (domain, ex_systems, ui). Для `app/` теста нет.
   - В `ui/` — `isolateSiblingSubdirs: true` + `sharedSiblings: {'common',
     'components', 'design_system'}`.

2. **`analysis_options.yaml`**, всё на `error`:
   - `always_use_package_imports`, `avoid_relative_lib_imports`
   - `use_super_parameters`, `unnecessary_null_checks`, `unnecessary_lambdas`
   - `cascade_invocations`, `unawaited_futures`, `avoid_dynamic_calls`
   - `prefer_final_fields` — `warning`

3. **`dart_code_linter`** plugin: `avoid-non-null-assertion: severity: error`.
   CLI exit-code сломан — гейт через grep.

4. **Гейт-команды** — пускаются в CI и локально перед merge'ом. Все три
   зелёные:
   ```
   flutter analyze --no-pub
   flutter test --no-pub
   dart run dart_code_linter:metrics analyze lib | tee /tmp/dcl.out
   ! grep -qE '^(ERROR|WARNING)' /tmp/dcl.out
   ```

## Зафиксированный выбор

| Вопрос              | Решение                                            |
|---------------------|----------------------------------------------------|
| Adapter-слой        | `ex_systems/` (external systems)                   |
| Топ-уровневые порты | `lib/app_ports/`                                   |
| State-классы        | Отдельный `*_state.dart`, sealed                   |
| Event-классы        | Отдельный `*_event.dart`, sealed                   |
| Routing             | `auto_route`, path-routes с первого дня            |

## UI

### Структура экрана

Папка `ui/<screen>/`:

- `<screen>_screen.dart` — корневой виджет, занимает всю area. Обёрнут в
  `SafeArea`. Создаёт свой блок (`BlocProvider(create: (_) => getIt<XBloc>())`)
  или достаёт из контекста, если он уже выше. Прокидывает блок вниз и
  рендерит дерево.
- `bloc/` — bloc/cubit + events + states.
- `widgets/` — экранные виджеты, по одному на файл.
- `<subscreen>/` — отдельная папка для большой локальной части, которая по
  весу почти как экран, но не открывается извне. Не виджет — модальный
  «подэкран» или сложный модальный flow.

### Bloc/Cubit

- Один блок на экран, `ui/<screen>/bloc/`. Файлы: `<screen>_bloc.dart`,
  `<screen>_event.dart`, `<screen>_state.dart`. **Events и states — оба
  sealed.** Кодген `freezed` опционально.
- **Cubit по умолчанию.** Публичные методы → виджеты их зовут. Bloc только
  когда надо строго сериализовать поток UI-событий (типа поиска).
- В Bloc'е — только ивенты. Не делать публичные методы, которые внутри
  закидывают `add(Event)`.
- **Перебор state во вьюшке — строго `switch`**, не `if (state is X)`. Для
  редких случаев (нужен один кейс, не разбор всех) — `if case`.
- **State = только публикуемая часть**, не внутреннее состояние блока.
  Внутренние флаги транзиций, промежуточные результаты — приватные поля
  блока, не утекают наружу.
- Bloc держит **data state**. Виджет держит только **визуальный state**
  (анимации, скролл, контроллеры) — то, что не имеет смысла за пределами
  виджета.
- Подписки — поля, отменяются в `close`. Wiring inline, handler — именованный
  метод.
- **Создаётся через фабрику в `app/di/`** — экран делает
  `BlocProvider(create: (_) => getIt<XBloc>())`, зависимости блока на
  стороне экрана не вытаскиваются. Контекстные параметры из навигации —
  передаются фабрике как initial argument.
- **Sub-блоки для независимых частей.** Если на экране сложный кусок,
  обновляющийся независимо (часто-обновляемый виджет, своя логика загрузки
  и реакций), — у него может быть свой bloc, провайденый ниже по дереву.
  Не злоупотреблять: только когда независимость реальная.

### Modal vs screen vs widget

- Достижимо больше чем из одного места → **экран**. Лежит в `ui/<thing>/`,
  свой блок, открывается через `AppNavigator`.
- Только из одного родителя → **часть родителя**. `ui/<parent>/<thing>/`,
  родитель сам триггерит `showModalBottomSheet`.
- Generic UI-примитив (confirm, snackbar, toast) → отдельный порт
  (`DialogPort`, `SnackbarPort`).

По умолчанию — экран.

### Навигация

```dart
abstract interface class AppNavigator {
  Future<void> openHome();
  Future<Filter?> showFilterPicker(Filter current);
  void back();
}
```

Интерфейс — `lib/app_ports/navigation/`. UI зовёт
`getIt<AppNavigator>().openX()` без `BuildContext`. Возврат значения —
`Future<T?>` сразу в сигнатуре.

UI/blocs **никогда** не зовут `auto_route` напрямую и не пушат экраны
руками. Всё через `AppNavigator`. Реализация — см. техническую
архитектуру.

Исключение — мелкие виджет-локальные popup'ы (`DropdownButton`, локальный
`PopupMenuButton`) и `SnackBar`, которые живут в пределах одного виджета и
не открывают «нечто». Их можно inline.

### Design system

- Живёт в `ui/design_system/` (см. `sharedSiblings` в ui-purity-тесте).
- Готовые компоненты (`AppPrimaryButton`, `AppHeadline`, `AppBodyText`,
  `AppColors`, `AppSpacing`, `AppDimens`) — экраны собираются из них, не из
  голых `ElevatedButton`/`Text`.
- Кастомный виджет → сначала компонент в `design_system/components/`, потом
  его использование на экране.
- Хардкод чисел/цветов/`TextStyle` запрещён — всё через `Spacing`/`Dimens`/
  `Colors`/типографику.

### Локализация (TBD)

Стартовая раскладка, до зрелого решения:

- Абстрактный класс/класс-провайдер строк, доступ через контекст.
- Виджеты дизайн-системы сами подписываются на провайдер локализации из
  контекста и резолвят ключи.
- Generic-виджеты (Button, Headline) принимают **ключ строки**, а не
  итоговый текст. Сам текст резолвится внутри.
- RTL (арабский, иврит) — out of scope.

## Анти-паттерны

- `open<X>Screen(BuildContext)` функции в screen-файлах.
- `RepositoryProvider`/`BlocProvider` вне места создания — инжектить через
  `get_it`.
- Подготовка данных в открывалках/`initState` — это use-case, место в блоке.
- Cross-screen import «только одного виджета» — переносим внутрь экрана или
  в `ui/common/` / `ui/components/`.
- Refresh-логика в interceptor'е напрямую — должна быть в `AuthController`,
  interceptor её зовёт.
- Экран сам вытаскивает зависимости блока из `getIt` и собирает блок
  руками — должна быть фабрика в `app/di/`.
- Обход гейтов «потому что мелочь».
