# Flutter 3.44 + официальные agent-скиллы — находки

Дата: 2026-05-21. Источник: блог-пост «What's new in Flutter 3.44»
(https://blog.flutter.dev/whats-new-in-flutter-3-44-b0cc1ad3c527) и разбор
официальных репозиториев `flutter/skills` и `dart-lang/skills`.

Статус: разведка. Конкретные правки в скиллах ещё не сделаны — см. «Что делать».

## 1. Что в Flutter 3.44 касается нас

### Заморозка Material и Cupertino — стратегически важно
Библиотеки Material и Cupertino **заморожены** в 3.44. Дальше они переезжают в
отдельные пакеты `material_ui` / `cupertino_ui`, а версии внутри фреймворка
будут deprecated уже в следующем stable. Любые наши советы и примеры, опирающиеся
на Material, скоро придётся переориентировать на пакеты. Нужно хотя бы пометить
направление в арх-документации, чтобы не плодить устаревающие рекомендации.

### Flutter официально выпустил agent-скиллы
Команда Flutter и команда Dart теперь поставляют собственные task-oriented
скиллы для кодинг-агентов + MCP-сервер для agentic hot reload. Это прямой сосед
того, что делаем мы. Подробный разбор — раздел 2.

### Для gesture-coexistence
`CupertinoSheetRoute` получил `scrollableBuilder` (старые `builder`/`pageBuilder`
deprecated) — для кастомных drag-регионов и бесшовной интеграции скролла с
перетаскиванием шита. Это ровно тема `docs/flutter-tricks/gesture-coexistence` —
потенциально достойно упоминания в `gesture-coexistence-pitfalls`.

### Для скелета (arch-bootstrap)
- **SwiftPM стал дефолтом** вместо CocoaPods (iOS/macOS). Миграция автоматическая.
- **AGP 9.0** со встроенным Kotlin (KGP больше не требуется); авторам плагинов
  нужно прописать min Flutter 3.44 в `pubspec.yaml`.
Если в `templates/flutter-skeleton/` зашиты iOS/Android-конфиги — сверить с
новыми дефолтами.

### Можно проигнорировать
`CarouselView` infinite scroll, `ReorderableListView.onReorderItem`, HCPP,
Impeller, Windowing API, embedded — к текущему контенту не относится.

## 2. Официальные agent-скиллы — разбор

Репозитории (оба от команд Flutter/Dart, скиллы сгенерированы Gemini, апрель 2026):
- `flutter/skills` — 10 скиллов по Flutter-разработке + 3 бандл-скилла.
- `dart-lang/skills` — 9 скиллов по Dart (тесты, CLI, анализ).
- `flutter/skills/tool/dart_skills_lint/` — бандл стиль/тест-скиллов + линтер
  SKILL.md-файлов.
- Документация: https://docs.flutter.dev/ai/agent-skills

### Главный вывод: КОНФЛИКТ по архитектуре
Официальный скилл `flutter-apply-architecture-best-practices` предписывает
**другую** архитектуру, чем наш `arch-bootstrap`:

| Ось | Официальный скилл | Наш эталон |
|---|---|---|
| State | MVVM, `ChangeNotifier` + `ListenableBuilder` | `flutter_bloc` |
| Слои | `lib/{data, domain, ui}/` | `lib/{app, app_ports, domain, ex_systems, ui}/` |
| Навигация | `go_router`, `context.go()` прямо из виджета | `auto_route` за портом `AppNavigator` |
| HTTP | `http` | `dio` |
| DI | «`provider` или `get_it`», опционально | `get_it` со scopes, фикс |
| domain-слой | опциональный | обязательный |
| Enforcement | нет | purity-тесты, линт, маркер-контракт |

Совпадение только на абстрактном принципе строгой слоистости. Каждое конкретное
предписание расходится. Официальный скилл — это канонический вид того дефолта
(`core/data/presentation`), который `arch-bootstrap` и создан перебивать.

**Риск:** триггеры пересекаются. Официальный скилл триггерится на «structuring a
new project», наш `arch-bootstrap` — на «starting a new Flutter project». У
пользователя с обоими плагинами агент видит два конкурирующих арх-скилла.

### Что переиспользовать / упомянуть в своих скиллах

Идеи переносим, файлы — нет: всё на английском, наш вывод на русском (не мешать
языки в одном файле). Дубли уже есть в окружении (`test-driven-development`,
`grill-me` ≈ superpowers) — не импортировать.

Топ-кандидаты:
1. **`definition-of-done`** (`dart_skills_lint/.agents/skills/`) — лучший шаблон
   для completion-gate; ложится на будущие `arch-audit` и хук. Совпадает с
   дисциплиной analyze/test в `kel-dart-formatting`.
2. **`grill-with-docs` → формат ADR** (`flutter/skills/.agents/.../reidbaker-agent/`)
   — критерии «когда заводить ADR» и `ADR-FORMAT.md`. У нас `arch-bootstrap` шаг 4
   предлагает `decisions/INDEX.md`, но критерии расплывчаты — взять их формализм.
3. **`dart-doc-validation`** — шаг `dart doc -o $(mktemp -d)` + линт
   `comment_references` как верификация для doc-комментов; у `kel-dart-formatting`
   шага верификации сейчас нет. Синтаксис кросс-ссылок `[Identifier]` совпадает.
4. **`dart-resolve-package-conflicts`** — приём «удалять из `pubspec.lock` только
   конфликтующий блок, не весь файл». Полезно на фиксированном стеке.
5. **`flutter-setup-localization`** — чистейшее совпадение со стеком; `ui.md` может
   ссылаться вместо повторного документирования ARB.
6. **`flutter-build-responsive-layout` + `flutter-fix-layout-issues`** —
   качественные UI-техники, нейтральные к архитектуре. Спутники для
   `docs/flutter-tricks/`.
7. **`flutter-add-widget-test`** — закрывает наш пробел по поведенческим тестам
   (у нас только purity-тесты).
8. Нативная настройка deep links из `flutter-setup-declarative-routing` —
   package-agnostic, применима и к `auto_route`.
9. Структурные правила `natural-writing` (без rule-of-three, sentence-case
   заголовки) — для генерируемых нами доков. Список английских слов — мимо.

### Длина строки — латентная неоднозначность
`kel-dart-formatting` не фиксирует `page_width`. Официальные скиллы предполагают
80 колонок, а `analysis_options.yaml` репозитория `dart_skills_lint` ставит
`page_width: 100`. Экосистема сама непоследовательна. **Стоит явно зафиксировать
`page_width`** в `kel-dart-formatting`.

### `dart_skills_lint` как инструмент
Это линтер **SKILL.md-файлов** (frontmatter, структура, ссылки), не Dart-кода.
Полезен для **нашего CI самого плагина** `ai-dev` (проверять свои скиллы), не для
user-facing enforcement Flutter-приложений.

## 3. Как поставить / где брать

Официальные скиллы ставятся CLI-утилитой `skills` (через npm/npx, нужен Node.js):

```
npx skills add flutter/skills --skill '*' --agent universal
npx skills add dart-lang/skills --skill '*' --agent universal
```

`--agent universal` кладёт их в стандартную папку `.agents/skills/`. Можно
ставить выборочно, указав имя скилла вместо `'*'`.

Репозитории:
- https://github.com/flutter/skills
- https://github.com/dart-lang/skills
- Документация: https://docs.flutter.dev/ai/agent-skills

## 4. Что делать (follow-up, не сделано)

- [ ] `arch-bootstrap`: добавить явную заметку, что официальный
      `flutter-apply-architecture-best-practices` существует и сознательно НЕ
      используется — чтобы у агента с обоими плагинами приоритет был однозначен.
- [ ] `tech.md`: назвать `go_router` и `http` как сознательно отвергнутые
      альтернативы (рядом с `auto_route`/`dio`).
- [ ] `arch-migrate`/`arch-audit` (когда будут): считать MVVM + `data/domain/ui`
      известной легаси-раскладкой, от которой мигрируют и которую детектят как дрейф.
- [ ] Сверить `templates/flutter-skeleton/` iOS/Android-конфиги с дефолтами 3.44
      (SwiftPM, AGP 9.0).
- [ ] `kel-dart-formatting`: явно зафиксировать `page_width`; добавить шаг
      верификации doc-комментов через `dart doc`; перенести приёмы по
      multi-line-строкам.
- [ ] Решить про заморозку Material/Cupertino — пометка в арх-документации.
- [ ] Рассмотреть `dart_skills_lint` в CI самого плагина `ai-dev`.
- [ ] `gesture-coexistence-pitfalls`: упомянуть `CupertinoSheetRoute.scrollableBuilder`.
