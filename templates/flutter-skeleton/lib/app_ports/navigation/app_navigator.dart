/// Cross-cutting navigation port.
///
/// UI and blocs depend on this interface, never on `auto_route` directly.
/// The implementation lives in `app/navigation/` because it needs the
/// app-level router state.
abstract interface class AppNavigator {
  Future<void> openHome();
  void back();
}
