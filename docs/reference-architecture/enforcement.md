# Mechanical enforcement

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
