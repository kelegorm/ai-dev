import 'package:flutter/material.dart';

/// Primary action button. Use for the single most important action on a screen.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: onPressed, child: child);
  }
}
