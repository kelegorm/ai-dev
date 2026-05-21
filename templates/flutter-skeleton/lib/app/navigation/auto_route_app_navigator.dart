import 'package:flutter_skeleton/app/navigation/app_router.dart';
import 'package:flutter_skeleton/app_ports/navigation/app_navigator.dart';

/// `auto_route`-backed implementation of [AppNavigator].
///
/// Lives in `app/` (not `ex_systems/`) because it wraps the root router,
/// which is app-level state.
class AutoRouteAppNavigator implements AppNavigator {
  AutoRouteAppNavigator(this._router);

  final AppRouter _router;

  @override
  Future<void> openHome() => _router.replace(const HomeRoute());

  @override
  void back() {
    if (_router.canPop()) {
      _router.pop();
    }
  }
}
