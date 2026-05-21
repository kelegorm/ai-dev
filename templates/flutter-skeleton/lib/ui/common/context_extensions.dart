import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

extension GetItContext on BuildContext {
  T get<T extends Object>() => GetIt.instance.get<T>();
}
