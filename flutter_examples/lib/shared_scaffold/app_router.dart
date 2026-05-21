import 'package:auto_route/auto_route.dart';
import 'package:flutter_examples/shared_scaffold/pages/stub_tab_page.dart';
import 'package:flutter_examples/shared_scaffold/pages/super_page.dart';
import 'package:flutter_examples/shared_scaffold/root_shell.dart';

part 'app_router.gr.dart';

/// Роутер примера shared-scaffold.
///
/// Один shell-route ([RootShellRoute]) с 3 outer-children: [SuperPageRoute]
/// (tab1/2 super-page), [Tab3Route], [Tab4Route]. Shell внутри строит
/// `AutoTabsRouter.builder` — tabsRouter управляет только `activeIndex`, а
/// layout (наш PageView + наш PageController) собирается в builder-колбеке.
///
/// `replaceInRouteName: 'Screen,Route'` — route-классы генерируются с
/// суффиксом `Route`, а widget-классы (`SuperPageScreen` и т.п.) сохраняют
/// суффикс `Screen`.
///
/// `generateForDir` ограничивает скан `@RoutePage` каталогом примера, чтобы
/// route-классы второго примера не попали в этот `.gr.dart`.
@AutoRouterConfig(
  replaceInRouteName: 'Screen,Route',
  generateForDir: ['lib/shared_scaffold'],
)
class SharedScaffoldRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      path: '/',
      page: RootShellRoute.page,
      initial: true,
      children: [
        AutoRoute(path: 'tab12', page: SuperPageRoute.page, initial: true),
        AutoRoute(path: 'tab3', page: Tab3Route.page),
        AutoRoute(path: 'tab4', page: Tab4Route.page),
      ],
    ),
  ];
}
