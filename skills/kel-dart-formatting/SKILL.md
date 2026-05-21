---
name: kel-dart-formatting
description: Use when writing or editing Dart code in kel's projects — formatting style, doc-comments, naming, file organization, imports. Triggers on creating or modifying any .dart file under kel's repos.
---

# Kel Dart Formatting

Conventions for writing Dart code in kel's style. Apply when creating or editing any `.dart` file. Run `dart format` after edits.

**Главное правило применения.** Если код не нарушает ни одного пункта этого скилла — не трогай его. Лучше оставить как есть, чем переписывать ради «улучшения». Скилл фиксирует минимально-необходимые требования; всё, что им удовлетворяет, считается приемлемым, даже если можно было бы написать чуть иначе. Менять стилистику без нарушения правила — шум, который засоряет diff и затрудняет ревью.

## Imports

- Absolute imports with package name: `package:my_pkg/path.dart`. No relative imports (`../foo.dart`).
- **No doc-comment before imports.** `dart doc` doesn't pick up file-level comments — они не привязаны к декларации. Put descriptions on the relevant class / function instead.

```dart
// ❌ Плохо — относительный путь
import '../expert/line.dart';

// ❌ Плохо — doc-comment перед импортами не парсится `dart doc`
/// Кодек линии в lineId.
import 'package:luna_rethink/expert/line.dart';

// ✅ Хорошо
import 'package:luna_rethink/expert/line.dart';

/// Кодек линии в `lineId`. ← привязан к функции ниже
int encodeLine(Line line) { ... }
```

## Doc-comments

- Use `///` for any doc-comment, never `//`.
- Document a public symbol **only когда имя + сигнатура не передают всё сами**. Если значение очевидно из имени и типов — doc-comment не нужен. Не добавляй текст ради формальности; это шум, в котором тонет настоящий сигнал.
- Если doc-comment всё-таки уместен, он должен сообщать **скрытое**: невыводимое из сигнатуры поведение, инвариант, ошибку, нетривиальное условие. Если получается только «делает то же, что говорит имя» — удаляй комментарий.
- First sentence — a verb in **third person**, describing what the function does in general:
  - Function: «Сворачивает...», «Проверяет...», «Возвращает...» (not «Свернуть»).
  - Boolean-returning: lead with verb («Проверяет линию на соответствие правилам Tango»), describe `true`-condition in the next paragraph («Возвращает `true`, если...»).
  - Class / variable: **конкретная именная группа**. «Тупик: линейных форсимых ходов больше нет», «Противоречие в линии», «Минимальный `lineId` в классе эквивалентности». **Не** filler-существительные ради формы: «Состояние, в котором...», «Вариант, при котором...» — это пустая обёртка вокруг сказуемого, ничего не добавляет, лучше переписать через предметное существительное.
- First sentence on its own line, then blank line, then details.
- Cross-references: `[TypeName]` и `[functionName]`. No `@param`, `@return`, `@throws` tags — use prose.

```dart
// ❌ Плохо — комментарий повторяет сигнатуру
/// Создаёт пустую доску.
factory Board.empty() => ...;

// ✅ Хорошо — без комментария, имя самодостаточно
factory Board.empty() => ...;


// ❌ Плохо — первое предложение начинается с существительного
/// Содержимое клетки в строке row, колонке col.
Cell getCellAt({required int row, required int col}) => ...;

// ✅ Хорошо — комментарий вообще не нужен, сигнатура говорит всё
Cell getCellAt({required int row, required int col}) => ...;


// ❌ Плохо — filler-существительное «Состояние»
/// Состояние, в котором линейные форсимые ходы исчерпались, а доска не заполнилась.
class StuckBoardResult ...

// ✅ Хорошо — конкретное предметное существительное
/// Тупик: линейных форсимых ходов больше нет, доска не заполнена.
class StuckBoardResult ...


// ❌ Плохо — для bool-функции лидирующее «Возвращает `true`, если...»,
//          скилл хочет глагол-описание первым
/// Возвращает `true`, если линия не нарушает правил.
bool isLineValid(Line line) { ... }

// ✅ Хорошо — глагол-описание + отдельный абзац про `true`
/// Проверяет линию на соответствие правилам Tango.
///
/// Возвращает `true`, если ни одно правило не нарушено.
bool isLineValid(Line line) { ... }
```

## Naming

- **Функции с побочным эффектом или преобразованием:** глаголы в третьем лице. `encodeLine`, `solveLine`, `iterateForcedLines`. **Избегай имён-существительных** типа `canonical()`, `signature()` — функция должна читаться как действие.
- **Функции, возвращающие значение без побочного эффекта,** — префикс `getX`: `getCanonicalId(id)`, `getSymmetriesOf(id)`, `getForcedLineIds()`. Это правило распространяется **и на индексные аксессоры**: `getRow(int i)`, `getColumn(int j)`, `getCellAt({row, col})` — а не `row(i)`, `column(j)`, `cellAt(...)`. Никаких исключений, даже когда короткое имя «звучит нормально». (Конвенция конфликтует с Effective Dart's "AVOID get prefix" — стиль kel перебивает.)
- **Булевы предикаты** — префикс `is` / `has` / `can`: `isLineValid(line)`, `isBoardValid(board)`, `isFilled(board)`, `hasForcedMove(...)`, `canApply(...)`. **Не** `validateLine`, `checkBoard`, `verifyX` — это глаголы-команды, для предикатов не подходят.
- **Классы** — существительные. Для sealed-result сабкласов используй **конкретные** имена, избегающие коллизий и расширяющие смысл: `ForcedLineResult` (не `Forced`), `SolvedBoardResult` (не `Solved`).
- **Файлы** — имя следует за главной сущностью или функцией внутри: `line_codec.dart` (не `codec.dart`), `solve_board.dart`, `is_line_valid.dart`, `generate_forced_lines.dart`. Если функция-якорь переименована — файл переименовывается следом.

```dart
// ❌ Плохо — имя-существительное у функции
int canonical(int id) { ... }

// ✅ Хорошо — get-префикс для value-возвращающей функции
int getCanonicalId(int id) { ... }


// ❌ Плохо — глагол-команда `validate` для bool-предиката
bool validateLine(Line line) { ... }
bool checkBoard(Board board) { ... }

// ✅ Хорошо — is-префикс
bool isLineValid(Line line) { ... }
bool isBoardValid(Board board) { ... }


// ❌ Плохо — индексный аксессор без префикса
Line row(int i) => ...;
Cell cellAt({required int row, required int col}) => ...;

// ✅ Хорошо — getX и для индексных аксессоров
Line getRow(int i) => ...;
Cell getCellAt({required int row, required int col}) => ...;


// ❌ Плохо — sealed-сабклассы с короткими именами, конфликтуют с другими
class Forced extends SolveResult { ... }
class Stuck extends SolveResult { ... }

// ✅ Хорошо — конкретные имена с суффиксом
class ForcedLineResult extends SolveResult { ... }
class StuckBoardResult extends BoardSolveResult { ... }
```

## File organization

- **Most important entity first** — the public entry-point function or the main class. Глаз читателя должен попасть на неё сразу.
- Helpers, return types, and constants below, in decreasing order of importance to an external reader.
- Private helpers (prefixed `_`) at the bottom of the file.

```dart
// ❌ Плохо — главная функция в самом низу, сначала вспомогательные типы
sealed class BoardSolveResult { ... }
class SolvedBoardResult extends BoardSolveResult { ... }
class StuckBoardResult extends BoardSolveResult { ... }
const int defaultMaxDepth = 3;
BoardSolveResult solveBoard(Board board) { ... } // главное

// ✅ Хорошо — главная функция первой, типы и константы ниже
BoardSolveResult solveBoard(Board board) { ... }
sealed class BoardSolveResult { ... }
class SolvedBoardResult extends BoardSolveResult { ... }
class StuckBoardResult extends BoardSolveResult { ... }
const int defaultMaxDepth = 3;
bool _isFilled(Board board) { ... } // приватный — в самом низу
```

## Parameters

- For functions with multiple parameters of similar types (especially indexes like `row`, `col`), use **named required**: `getCellAt({required int row, required int col})`. Disambiguates call site, prevents argument-order bugs.

```dart
// ❌ Плохо — позиционные индексы, легко перепутать
Cell getCellAt(int row, int col) => _cells[row][col];
board.getCellAt(2, 3); // что есть что?

// ✅ Хорошо — именованные required
Cell getCellAt({required int row, required int col}) => _cells[row][col];
board.getCellAt(row: 2, col: 3);
```

## What NOT to write in code

- No emoji.
- No diary-style comments («раньше так, теперь сяк», «added for issue #123»).
- No comments that just restate what the signature or code already shows.
- No top-of-file headers describing the file as a whole.

## Перед началом и после правок

**До любых правок:** запусти `dart analyze` и зафиксируй текущий список варнингов и ошибок. Это **базовый уровень** — то, что уже было, не считается твоим долгом и не должно правиться в этом проходе. Цель — не добавлять новых.

**После правок:** прогон `dart analyze` ещё раз и сравнение с базовым уровнем. Новых варнингов и ошибок быть не должно. Если появились — это регрессия твоих правок; чини, пока список не сравняется с базой.

Тесты (`dart test`) тоже должны пройти полностью; число тестов не должно уменьшиться. Если что-то падает — не коммить, не отчитывайся как готовое.
