import 'package:flutter/material.dart';
import 'package:flutter_examples/gesture_coexistence/canvas/canvas_theme.dart';
import 'package:flutter_examples/gesture_coexistence/canvas/stripe.dart';

/// Статичное содержимое полотна: серый фон + столбец нумерованных полосок.
///
/// Layout-zoom: высоты/отступы/шрифт растут пропорционально [scaleY],
/// ширина и border-radius не меняются — полоски физически увеличиваются,
/// а не stretch'атся. Gesture-логика и трансформации живут в `CanvasOverlay`.
class CanvasContent extends StatelessWidget {
  const CanvasContent({
    super.key,
    required this.canvasWidth,
    required this.scaleY,
    required this.onStripeTap,
  });

  final double canvasWidth;
  final double scaleY;
  final ValueChanged<int>? onStripeTap;

  @override
  Widget build(BuildContext context) {
    final stripeWidth = (canvasWidth - stripeHorizontalPadding * 2).clamp(
      48.0,
      double.infinity,
    );
    final scaledHeight = stripeHeight * scaleY;
    final scaledGap = stripeGap * scaleY;
    final scaledPadding = canvasVerticalPadding * scaleY;
    final scaledFontSize = stripeFontSize * scaleY;
    final rowHeight = scaledHeight + scaledGap;
    final totalHeight = scaledPadding * 2 + stripeCount * rowHeight;

    final children = <Widget>[
      Positioned.fill(child: ColoredBox(color: canvasBackground)),
    ];
    for (var row = 0; row < stripeCount; row++) {
      final topY = scaledPadding + row * rowHeight;
      final number = row + 1;
      children.add(
        Positioned(
          left: stripeHorizontalPadding,
          top: topY,
          width: stripeWidth,
          height: scaledHeight,
          child: Stripe(
            number: number,
            fontSize: scaledFontSize,
            onTap: onStripeTap == null ? null : () => onStripeTap!(number),
          ),
        ),
      );
    }

    return SizedBox(
      width: canvasWidth,
      height: totalHeight,
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }
}
