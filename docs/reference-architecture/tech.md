# Техническая архитектура

## DI: get_it и scopes

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

## Сеть: Dio + interceptors

HTTP — `dio`. Реализации репозиториев из `domain/ports/` живут в
`ex_systems/network/` и принимают `Dio` через конструктор.

Стандартные interceptor'ы:

- **AuthInterceptor** — добавляет токен в заголовки, ловит 401/403, зовёт
  refresh, при успехе ретраит оригинальный запрос.
- **LoggingInterceptor** — отладочный.
- **ErrorMappingInterceptor** — `DioException` → доменные ошибки.

Refresh-логика **не живёт в interceptor'е напрямую** — она в
`AuthController`, interceptor её зовёт. Одна точка авторизации.

## Routing: auto_route с URL-навигацией

`auto_route` с **path-routes с самого начала**. Каждый маршрут — нормальный
URL: `/login`, `/home`, `/journal/:id?from=2026-05-08`. Это даёт:

- Deep-linking работает с первого дня.
- Тестировать можно прямо в браузере (Flutter web), даже до mobile.
- Параметры — через `@PathParam` / `@QueryParam`, не через initial state
  блока.

Конфиг — `lib/app/navigation/app_router.dart` c `@AutoRouterConfig`.
Generated `app_router.gr.dart` рядом.

## Авторизация: scope switch + refresh

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
