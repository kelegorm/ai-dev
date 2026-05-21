import 'package:flutter/material.dart';

/// Body text. Use for descriptive or supporting content.
class AppBodyText extends StatelessWidget {
  const AppBodyText(this.text, {super.key, this.textAlign});

  final String text;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium,
      textAlign: textAlign,
    );
  }
}
