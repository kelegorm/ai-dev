# Wizard-архитектура: разбор pattern из avoska_mobile

Дата: 2026-05-08
Reference: https://github.com/AlchemistDark/avoska_mobile/tree/develop/lib/presentation/ui/3_cart
Branch на момент исследования: `develop`

## Зачем этот документ

В `wm_prototype` wizard настройки протокола (`lib/ui/protocol_wizard/`) разъехался: AppBar title живёт в shell-экране через listener на nested StackRouter, а body шагов — в отдельных child-screens. После live-smoke стало очевидно, что архитектура хрупкая (title и контент вычисляются разными «драйверами»). Перед рефакторингом стоит подсмотреть, как делают «4-шаговый wizard с накоплением state» в публичном Flutter-проекте, который уже использует знакомый стек: **flutter_bloc + auto_route + sealed states**.

Avoska — public B2C grocery-app, и `placing_order` (оформление заказа) — каноничный wizard на 4 шага: **детали → дата/время → оплата → подтверждение**. Стек совпадает с нашим.

---

## Структура папки `lib/presentation/ui/3_cart/`

```
3_cart/
├── placing_order_screen.dart            (1.8K) — entry-point @RoutePage, BlocProvider + switch по state
├── placing_order_logic.dart             (8.7K) — PlacingOrderCubit (extends Emit<PlacingOrderState>), вся бизнес-логика
├── placing_order_state.dart             (6.5K) — sealed PlacingOrderState + Step{1,2,3,4}State + DTO Step{1,2,3}Input
├── placing_order_step1_screen.dart      (3.4K) — экран шага 1 (комментарий + адрес)
├── placing_order_step2_screen.dart      (11K)  — экран шага 2 (дата/слот доставки)
├── placing_order_step3_screen.dart      (12K)  — экран шага 3 (оплата + промокод)
├── placing_order_step4_screen.dart      (8.7K) — экран шага 4 (подтверждение + submit)
├── placing_order_progress_widget.dart   (4.3K) — индикатор прогресса (4 кружка + соединительные линии)
├── prev_next_buttons_panel.dart         (1.1K) — переиспользуемая нижняя панель «Назад/Далее»
├── address_blocks_widgets.dart          (5.2K) — UI-блоки адреса по 3 типам (apartment/private home/pickup)
├── widgets.dart                         (2.9K) — мелкие UI-helpers
└── warning_widget.dart                  (1.1K) — UI-helper
```

12 файлов на feature, всё в одной папке (без подкаталогов screens/cubit/widgets). Cubit лежит рядом со screens — автор сам пишет в TODO «переименовать в cubit и выкинуть в папку с кубитами», т.е. знает про канон, но локальная co-location выиграла.

---

## State management: sealed-класс под Cubit

`PlacingOrderState` — `sealed` иерархия (Dart 3):

```dart
sealed class PlacingOrderState {}

class PlacingOrderNoInitState extends PlacingOrderState {}

final class PlacingOrderStep1State extends PlacingOrderState {
  final OrderAddress address;
  final DeliveryMethod deliveryMethod;
  final String comment;
  // ...
  PlacingOrderStep2State toStep2({required Step1Input input1, ...}) { ... }
}

final class PlacingOrderStep2State extends PlacingOrderState {
  final OrderAddress address;
  final DeliveryMethod deliveryMethod;
  final Step1Input input1;          // <-- данные предыдущего шага
  final Future<AllTimeSlots> intervals;
  final TimeSlot? selectedSlot;
  final DeliveryDay? selectedData;
  // ...
  PlacingOrderStep3State toStep3({required Step2Input input2}) { ... }
}

final class PlacingOrderStep3State extends PlacingOrderState {
  final ...;
  final Step1Input input1;
  final Step2Input input2;
  // ...
  PlacingOrderStep4State toStep4({required Step3Input input3, required OrderCalculation orderCalcs}) { ... }
}

final class PlacingOrderStep4State extends PlacingOrderState {
  final Step1Input input1;
  final Step2Input input2;
  final Step3Input input3;
  final OrderCalculation orderCalcs;
}
```

Ключевые наблюдения:

1. **State — это и есть «текущий шаг».** Какой именно подкласс активен — таково и место в wizard. Никакого отдельного `currentStep: int`.
2. **Каждый StepNState содержит данные ВСЕХ предыдущих шагов** (`input1`, `input2`, ...). Это accumulator: state монотонно «толстеет».
3. **Переходы — методы на самом state**: `step1.toStep2(...)`, `step2.toStep3(...)`. Cubit не знает, как собирать новый state — он делегирует это самому state. State immutable (`final` поля), переход = новый объект.
4. **Step{N}Input — отдельные DTO** для данных, которые юзер ввёл на конкретном шаге (`Step1Input { String comment }`, `Step2Input { DeliveryDay selectedDate; TimeSlot timeSlot }`, ...). Они не часть state, а аргумент перехода. Это даёт чистую сигнатуру `runStepN(StepNInput)`.

---

## Cubit: тонкий driver состояний

`PlacingOrderCubit extends Emit<PlacingOrderState>` (avoska использует свою тонкую обёртку над Cubit). Публичный API:

```dart
class PlacingOrderCubit extends Emit<PlacingOrderState> with ... {
  PlacingOrderCubit(...) : super(PlacingOrderNoInitState()) {
    emit(_makeStep1(storeContext));         // инициализация step1 в конструкторе
    _intervals = _loadIntervals();           // фоновая загрузка справочников
  }

  void runStep2(Step1Input info) { ... }     // step1 -> step2
  void newStep2({...}) { ... }                // обновление полей внутри step2 (выбор даты/слота)
  void runStep3(Step2Input step2input) { ... }
  Future<void> checkOrderAndRun4(PlacingOrderStep3State step3, Step3Input step3input) async { ... } // делает API-вызов orderCalculator перед переходом
  void goBack() { ... }                       // pattern-match: возвращается на предыдущий step, сохраняя уже введённые данные
  Future<void> placeOrder() async { ... }    // финальный submit
}
```

Каждый transition-метод делает `if (state case PlacingOrderStepNState step) { _setState(step.toStepNPlus1(...)) }` — т.е. сначала проверяет, что мы реально на ожидаемом шаге (защита от race condition), потом просит сам state сгенерить следующий.

**`goBack()` — отдельный switch:**

```dart
void goBack() {
  final newState = switch (state) {
    PlacingOrderNoInitState() => state,
    PlacingOrderStep1State() => state,                            // step1: уже первый
    PlacingOrderStep2State step2 => PlacingOrderStep1State(
        address: step2.address,
        deliveryMethod: step2.deliveryMethod,
        comment: step2.input1.comment,                             // сохраняем, что юзер ввёл
      ),
    PlacingOrderStep3State step3 => PlacingOrderStep2State(...),
    PlacingOrderStep4State step4 => PlacingOrderStep3State(...),
  };
  _setState(newState);
}
```

Назад идёт не «выкидывая» данные, а конструируя предыдущий state с сохранением всего, что было собрано. Это критично: юзер вернулся на step2, поправил адрес, идёт обратно на step3 — данные step3 могут быть утеряны (это сознательное решение: backward = «отмена»; данные шагов после текущего не сохраняются), но `input1` остаётся с ним.

---

## Navigation pattern: ОДИН route, разные screens по state

`placing_order_screen.dart` целиком:

```dart
@RoutePage()
class PlacingOrderPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<PlacingOrderCubit>(
      create: (ctx) => ctx.get<PlacingOrderCubit>(),
      child: BlocBuilder<PlacingOrderCubit, PlacingOrderState>(
        builder: (context, snapshot) {
          final logic = context.read<PlacingOrderCubit>();
          return switch (snapshot) {
            PlacingOrderStep1State step1 => PlacingOrderStep1Screen(state: step1, logic: logic),
            PlacingOrderStep2State step2 => PlacingOrderStep2Screen(state: step2, logic: logic),
            PlacingOrderStep3State step3 => PlacingOrderStep3Screen(state: step3, logic: logic),
            PlacingOrderStep4State step4 => PlacingOrderStep4Screen(state: step4, logic: logic),
            PlacingOrderNoInitState() => SizedBox(),
          };
        },
      ),
    );
  }
}
```

**Это не auto_route nested-stack.** Это ОДИН `@RoutePage()` (для auto_route), внутри которого `BlocBuilder` свапает widget tree по типу state. Никакого `Navigator.push` между шагами не происходит — каждый «шаг» это просто другой Widget в том же месте дерева.

Что это даёт:

- **Никакого back-stack от Navigator** — система Android-back и `Navigator.of(context).pop()` будут выкидывать юзера ИЗ всего wizard'а целиком. На step1 кнопка «Назад» делает `Navigator.of(context).pop()` (выход из wizard), на step2-4 — `logic.goBack()` (откат state).
- **Простая глубокая ссылка/restart**: deep-link на `/placing_order` всегда стартует с шага 1 (через initial state в конструкторе cubit'а).
- **Cubit живёт ровно столько, сколько wizard** — он создаётся в `BlocProvider`, привязан к route, на выходе из route уничтожается вместе со всем накопленным state.

### AppBar title

Title ВО ВСЕХ четырёх шагах одинаковый: `AvoskaAppBar(title: AppStrings.cart.placingOrderHeader)`. Что РАЗЛИЧАЕТСЯ от шага к шагу — `PlacingOrderProgressWidget(currentStep: N)` в body. Т.е. avoska сознательно не варьирует title — вместо этого показывает прогресс-бар «1/2/3/4 кружок» с подписями (Детали / Дата и время / Оплата / Подтверждение).

**Каждый ScreenN имеет свой Scaffold + AppBar** — никаких общих shell-listener'ов. Это и есть «экраны полноценные», которое хочет юзер wm_prototype.

```dart
// placing_order_step1_screen.dart
return Scaffold(
  appBar: AvoskaAppBar(title: AppStrings.cart.placingOrderHeader),
  body: SafeArea(
    child: Column(
      children: [
        PlacingOrderProgressWidget(currentStep: 1),
        // ...
        PrevNextButtonsPanel(
          onBackPressed: () => Navigator.of(context).pop(),     // выход из wizard
          onNextPressed: _onNextPressed,
          nextEnabled: true,
        ),
      ],
    ),
  ),
);
```

```dart
// placing_order_step2_screen.dart, step3, step4 — то же самое, но
PrevNextButtonsPanel(
  onBackPressed: () => logic.goBack(),                          // откат на предыдущий step
  onNextPressed: _onNextPressed,
  nextEnabled: isValid,                                         // <-- per-step валидация
);
```

---

## Control flow (data aggregation)

```
+-------------------------------------------------------------+
|  PlacingOrderCubit (живёт пока есть PlacingOrderPage route)  |
|                                                              |
|  state: PlacingOrderState (sealed)                           |
|                                                              |
|   NoInit ── ctor ──► Step1 ── runStep2(Step1Input) ──► Step2 |
|                  ◄── goBack() ─── ◄── Step1State              |
|                                                              |
|   Step2 ── runStep3(Step2Input) ──► Step3                    |
|         ◄── goBack() ─── (новый Step1State из step2 полей)   |
|                                                              |
|   Step3 ── checkOrderAndRun4 (await orderCalculator) ──►Step4|
|         ◄── goBack() ─── (новый Step2State из step3 полей)   |
|                                                              |
|   Step4 ── placeOrder() ──► API submit ──► snackbar+pop      |
|         ◄── goBack() ─── (новый Step3State из step4 полей)   |
|                                                              |
+-------------------------------------------------------------+
                               │
                               │ BlocBuilder switch (snapshot)
                               ▼
                +-------------------------------+
                | PlacingOrderPage (одно дерево)|
                | swap widget по типу state     |
                +-------------------------------+
                               │
        ┌────────────┬─────────┴────────┬──────────────┐
        ▼            ▼                  ▼              ▼
   Step1Screen   Step2Screen        Step3Screen    Step4Screen
   (Scaffold +  (Scaffold +        (Scaffold +    (Scaffold +
    AppBar +     AppBar +           AppBar +       AppBar +
    Progress +   Progress +         Progress +     Progress +
    body +       body +             body +         body +
    PrevNext)    PrevNext)          PrevNext)      PrevNext)
```

Финальная агрегация в `placeOrder()`:

```dart
if (state case PlacingOrderStep4State step4) {
  OrderRequest order = OrderRequest(
    itemIds: cartItems.map((i) => i.id).toList(),
    comment: step4.input1.comment,                        // из step1
    deliveryMethod: authedStoreContext.deliveryMethod,
    paymentMethod: step4.input3.paymentMethod,            // из step3
    promoCodeTitle: step4.input3.promoCode,
    timeSlotId: step4.input2.timeSlot.id,                 // из step2
    orderDate: step4.input2.selectedDate.date,
    changeFrom: step4.input3.amountToPrepareForChange,
  );
  await ordersRepository.createOrder(...);
}
```

Step4State имеет `input1`, `input2`, `input3`, `orderCalcs` — все данные wizard'а доступны разом, без походов в shared store.

---

## Validation

Per-step, в самом screen-widget'е (внутри `_onNextPressed` или через локальный flag `isValid`):

```dart
// step2: _onNextPressed
void _onNextPressed() {
  if (state.selectedSlot != null && state.selectedData != null) {
    logic.runStep3(Step2Input(timeSlot: state.selectedSlot!, selectedDate: state.selectedData!));
  }
}

// step3: nextEnabled: isValid (флаг считается локально по полям формы)
PrevNextButtonsPanel(
  onBackPressed: () => widget.logic.goBack(),
  onNextPressed: _onNextPressed,
  nextEnabled: isValid,
);
```

Cubit в transition-методах **не валидирует** — он доверяет, что widget пропустит только валидные данные. Это сознательная эрозия инвариантов в пользу простоты — всё, что нужно, экран знает локально.

---

## Сильные стороны pattern'а

1. **Одно место правды для wizard-state.** Cubit + sealed PlacingOrderState — невозможно «сломать» переход (нельзя оказаться в Step3State без `input1` и `input2`, типы это запрещают).
2. **Экраны полноценные** (Scaffold + AppBar внутри каждого), но при этом нет дублирования: progress-widget и prev-next-panel вынесены.
3. **Один auto_route — никаких nested-stack/title-listener.** AppBar title не путешествует через navigation events.
4. **`goBack()` сохраняет накопленные данные.** Юзер вернулся на step1 → видит уже введённый comment.
5. **Async-side-effects на переходе.** `checkOrderAndRun4` await'ит API перед сменой state — UI просто видит «всё ещё step3» пока не пришёл ответ. Loader накручивается на уровне button-handler (`showFullScreenLoader`).
6. **Cubit умирает вместе с route.** Никакого глобального state, никаких leak'ов недоделанного wizard'а.

---

## Adoption notes для wm_prototype

Текущий стек wm_prototype:
- `flutter_bloc` ✓ совпадает
- `auto_route` ✓ совпадает (включая nested router в `protocol_wizard_shell_screen.dart`)
- `drift` для БД (а не REST как в avoska)
- Существующая реализация в `lib/ui/protocol_wizard/` со shell-screen + dynamic title через listener

### Что переиспользовать 1:1

- **Sealed state-иерархия** `ProtocolWizardState` с подклассами на каждый шаг (`StepDayRoutineState`, `StepStartLaunchState`, `StepEditorState`, `StepSubEditorState`, ...). Базируется на нашем правиле «не использовать freezed/codegen для моделей» — sealed/final + ручной код идеально подходит.
- **`StepNInput` DTO** для данных юзера на шаге, отдельно от state.
- **Transition-методы на самом state** (`step1.toStep2(input1: ...)`).
- **Один `@RoutePage()` для всего wizard'а** + `BlocBuilder` со `switch (state)` вместо nested StackRouter. Это **главное архитектурное упрощение** — оно решает корневую проблему (title и body живут в разных flows).
- **Свой Scaffold+AppBar в каждом screen**. Никакого shell-listener.
- **Переиспользуемый `WizardProgressWidget`** + `PrevNextButtonsPanel` вместо динамического title в AppBar.
- **`goBack()` через `switch (state)`** с реконструкцией предыдущего шага из накопленных полей.

### Что адаптировать

- **Финальный submit идёт в drift, не в REST.** В `placeOrder()` (наш аналог — `saveProtocol()`) `Step4State` (или последний step) даёт нам `Step1Input + Step2Input + ... + StepNInput` — мапим в drift companion'ы и пишем транзакцией. Логика та же, target другой.
- **Async-side-effects на переходе** — у нас вместо `orderCalculator.calculateOrder` могут быть pre-validation запросы к drift или вычисления preview протокола. Тот же pattern: `await` внутри transition-метода cubit'а, UI крутит loader на уровне `_onNextPressed`.
- **Initial state** — у avoska `_makeStep1(storeContext)` собирает step1 из глобального контекста (адрес, способ доставки). У нас аналог — взять текущий draft протокола из drift или передать `initialDraft` через route-args. Конструктор cubit'а — правильное место для этого.

### Что **НЕ подойдёт** или потребует переосмысления

- **Avoska не использует nested auto_route внутри wizard'а** — наш текущий `protocol_wizard_shell_screen.dart` с nested StackRouter надо **снести целиком**. Это противоречит архитектурной интуиции «sub-routes для шагов», но как раз это и есть источник проблемы (title-driver вне body-driver). Принципиальный шаг — переписать `lib/ui/protocol_wizard/` на single-route + state-driven swap.
- **Deep-link на конкретный шаг** не поддерживается из коробки (всё всегда стартует с step1). Если у нас есть требование «открыть wizard сразу на шаге N для редактирования» — придётся либо передавать `initialStep` в route-args и инициализировать cubit нужным state, либо сохранять nested-маршруты как опцию. Текущий wm_prototype, кажется, deep-link на шаг не использует — стоит явно подтвердить.
- **Lossy goBack по дальним шагам.** Если юзер был на step4, нажал «назад» на step3, потом снова «назад» на step2, потом «вперёд» — данные step3 утеряны. Для длинного wizard'а лечения это может быть болью; стоит решить на стадии планирования: либо сохранять future-step inputs в отдельном `Map<int, dynamic>` в state, либо принять lossy-семантику как у avoska (она проще).
- **Cubit с большим набором transition-методов** разрастётся, если шагов много. У avoska 4 шага = 4 транзишена + `goBack` + `placeOrder`. У нас может быть больше (day_routine, start_and_launch, editor, sub_editor — уже 4+ только из имён файлов). Если шагов > 6-7, стоит подумать про generic step-machine, но как baseline avoska-pattern масштабируется ок.
- **Валидация per-step локально в widget** — приемлемо для маленьких форм, но у нас формы протокола могут быть сложнее (drift constraints, cross-step deps). Возможно, стоит вынести validator-функции в отдельные классы и вызывать их и из cubit (в transition guard), и из widget (для `nextEnabled`).

### Mini-roadmap рефакторинга (на будущее, не делать сейчас)

1. Снести `protocol_wizard_shell_screen.dart` и nested router.
2. Создать `protocol_wizard_state.dart` (sealed) + `protocol_wizard_cubit.dart`.
3. Создать `protocol_wizard_page.dart` (один `@RoutePage`) с `BlocProvider` + `BlocBuilder` + `switch`.
4. Каждый существующий step-screen обернуть в свой `Scaffold` + `AppBar` (если ещё нет) и принимать `(state: StepNState, logic: ProtocolWizardCubit)` в конструкторе.
5. Добавить `WizardProgressWidget` + переиспользуемый `PrevNextButtonsPanel`.
6. Финальный submit пишет в drift одной транзакцией из последнего step state.

---

## Ссылки на исходники (для копи-паста при имплементации)

- Entry-page (15 строк): https://github.com/AlchemistDark/avoska_mobile/blob/develop/lib/presentation/ui/3_cart/placing_order_screen.dart
- Cubit: https://github.com/AlchemistDark/avoska_mobile/blob/develop/lib/presentation/ui/3_cart/placing_order_logic.dart
- Sealed state + Step{N}Input DTO: https://github.com/AlchemistDark/avoska_mobile/blob/develop/lib/presentation/ui/3_cart/placing_order_state.dart
- Step1 (минимальный пример): https://github.com/AlchemistDark/avoska_mobile/blob/develop/lib/presentation/ui/3_cart/placing_order_step1_screen.dart
- Progress-widget: https://github.com/AlchemistDark/avoska_mobile/blob/develop/lib/presentation/ui/3_cart/placing_order_progress_widget.dart
- Prev/Next-panel: https://github.com/AlchemistDark/avoska_mobile/blob/develop/lib/presentation/ui/3_cart/prev_next_buttons_panel.dart
