import 'package:auto_route/auto_route.dart';
import 'package:flutter_examples/gesture_coexistence/screens/canvas_screen.dart';
import 'package:flutter_examples/gesture_coexistence/screens/pager_shell.dart';
import 'package:flutter_examples/gesture_coexistence/screens/side_screen.dart';

part 'app_router.gr.dart';

/// Роутер примера gesture-coexistence.
///
/// Один shell-route ([PagerShellRoute]) с 3 tab-children: [LeftRoute],
/// [CanvasRoute] (центр, initial) и [RightRoute]. Shell внутри строит
/// `AutoTabsRouter.builder` — tabsRouter управляет только `activeIndex`, а
/// layout (наш `PageView` + наш `PageController`) собирается в builder-
/// колбеке.
///
/// Это **bounded 3-страничный пейджер**: горизонтальный overflow с канваса
/// двигает `PageController` и синхронит `tabsRouter.setActiveIndex`, а не
/// плодит push-стек. На краях свайп упирается — листать дальше нечего.
///
/// `replaceInRouteName: 'Screen,Route'` — route-классы генерируются с
/// суффиксом `Route` (`CanvasRoute`, `LeftRoute`, `RightRoute`), а widget-
/// классы сохраняют суффикс `Screen`.
///
/// `generateForDir` ограничивает скан `@RoutePage` каталогом примера, чтобы
/// route-классы второго примера не попали в этот `.gr.dart`.
@AutoRouterConfig(
  replaceInRouteName: 'Screen,Route',
  generateForDir: ['lib/gesture_coexistence'],
)
class GestureCoexistenceRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      path: '/',
      page: PagerShellRoute.page,
      initial: true,
      children: [
        AutoRoute(path: 'left', page: LeftRoute.page),
        AutoRoute(path: 'canvas', page: CanvasRoute.page, initial: true),
        AutoRoute(path: 'right', page: RightRoute.page),
      ],
    ),
  ];
}
