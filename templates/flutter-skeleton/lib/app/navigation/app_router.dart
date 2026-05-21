import 'package:auto_route/auto_route.dart';
import 'package:flutter_skeleton/ui/home/home_screen.dart';

part 'app_router.gr.dart';

/// Canonical URL paths for every route. Path-routes from day one so
/// deep-linking and Flutter-web testing work immediately.
class AppRoutePaths {
  const AppRoutePaths._();

  static const home = '/home';
}

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  AppRouter();

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: HomeRoute.page,
      path: AppRoutePaths.home,
      initial: true,
    ),
    RedirectRoute(path: '*', redirectTo: AppRoutePaths.home),
  ];
}
