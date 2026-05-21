import 'package:flutter/material.dart';
import 'package:flutter_examples/gesture_coexistence/canvas/canvas_theme.dart';

/// Одна нумерованная полоска на полотне.
///
/// Tap по полоске обрабатывается собственным [GestureDetector] — он живёт
/// ниже translucent-`Listener`'а полотна и с ним не конфликтует.
class Stripe extends StatelessWidget {
  const Stripe({
    super.key,
    required this.number,
    required this.fontSize,
    this.onTap,
  });

  final int number;
  final double fontSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: stripeAccent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
