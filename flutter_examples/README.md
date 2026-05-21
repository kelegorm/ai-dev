# flutter_examples

Runnable examples of UI tricks from the `ai-dev` repository. Each example is a
standalone mini-app with its own `main.dart`, illustrating one article from
[`docs/flutter-tricks/`](../docs/flutter-tricks/). The package is not published
(`publish_to: none`) and exists purely for demonstration and tests.

There are two examples: **gesture coexistence** (`lib/gesture_coexistence/`) and
**shared scaffold** (`lib/shared_scaffold/`). See
[`docs/flutter-tricks/`](../docs/flutter-tricks/) for what each one demonstrates.

## Running the examples

Each example has its own entry point. Pick one with `-t`:

```sh
# Gesture coexistence
flutter run -t lib/gesture_coexistence/main.dart

# Shared scaffold
flutter run -t lib/shared_scaffold/main.dart
```

Install dependencies before the first run:

```sh
flutter pub get
```

Both examples drive navigation through `auto_route`, so the generated
`*.gr.dart` files are already committed. If you change the routes, regenerate
them:

```sh
dart run build_runner build --delete-conflicting-outputs
```

## Tests

Widget and golden tests live in `test/`:

```sh
flutter test

# Regenerate reference screenshots after intentional UI changes
flutter test --update-goldens
```
