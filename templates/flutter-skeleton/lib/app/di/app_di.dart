import 'package:flutter_skeleton/app/navigation/app_router.dart';
import 'package:flutter_skeleton/app/navigation/auto_route_app_navigator.dart';
import 'package:flutter_skeleton/app_ports/navigation/app_navigator.dart';
import 'package:get_it/get_it.dart';

/// Composition root. Registers everything the skeleton needs: the router
/// and the [AppNavigator] implementation built on top of it.
///
/// Calling this multiple times is safe — subsequent calls are ignored.
///
/// As features arrive, register their domain services, `ex_systems/`
/// adapters and screen-bloc factories here.
void configureDependencies() {
  final getIt = GetIt.instance;
  if (getIt.isRegistered<AppRouter>()) return;

  getIt
    ..registerLazySingleton<AppRouter>(AppRouter.new)
    ..registerLazySingleton<AppNavigator>(
      () => AutoRouteAppNavigator(getIt<AppRouter>()),
    );
}
