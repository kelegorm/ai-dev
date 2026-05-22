# Ledger template — docs/architecture/migration-progress.md

The structure worker writes this file into the migrated project. Russian,
project-facing.

---

<!-- ai-dev:migration-ledger v1 -->
# Прогресс миграции архитектуры

Статус структуры: **готова** | в работе
Дата последнего прогона: YYYY-MM-DD

## Разложено по слоям

- `lib/<layer>/<path>` ← бывш. `lib/<old>` — кратко, что за файл.
- …

## Осталось разобрать

Файлы ниже остались в `lib/` (вне папок слоёв) — их нельзя перенести
механически. Каждому нужна работа выделения, потом он переедет в свой слой.

- `lib/<file>` — **грязный**: <причина, напр. «логика загрузки в initState,
  импортирует ex_systems напрямую»>. Нужно: выделить bloc/сервис. Поедет в
  `lib/<layer>/<path>`.
- …

## Чем проект ещё не защищён

Строгий линт (`analysis_options.yaml` эталона) не подключён — он навешивается
позже, по мере выделения архитектурных границ.
