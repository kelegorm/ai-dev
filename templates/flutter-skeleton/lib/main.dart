import 'package:flutter/widgets.dart';
import 'package:flutter_skeleton/app/app.dart';
import 'package:flutter_skeleton/app/di/app_di.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const App());
}
