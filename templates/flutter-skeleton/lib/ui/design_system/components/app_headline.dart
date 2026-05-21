import 'package:flutter/material.dart';

/// Headline text. Use for primary titles and screen headers.
class AppHeadline extends StatelessWidget {
  const AppHeadline(this.text, {super.key, this.textAlign});

  final String text;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineMedium,
      textAlign: textAlign,
    );
  }
}
