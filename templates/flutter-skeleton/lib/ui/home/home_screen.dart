import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_skeleton/ui/design_system/components/app_headline.dart';

/// Placeholder screen — the single screen the skeleton ships with.
///
/// Replace its body with a real screen, and add the matching bloc under
/// `bloc/` plus a factory in `app/di/` when the first feature lands.
@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: AppHeadline('flutter_skeleton'),
        ),
      ),
    );
  }
}
