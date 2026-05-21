import 'package:flutter/material.dart';
import 'package:flutter_skeleton/ui/design_system/app_colors.dart';

/// Factory for application [ThemeData] instances.
abstract final class AppTheme {
  static ThemeData light() => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.seed),
    useMaterial3: true,
  );
}
