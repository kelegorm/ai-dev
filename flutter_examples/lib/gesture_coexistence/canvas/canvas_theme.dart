import 'package:flutter/material.dart';

/// Серый фон полотна.
const Color canvasBackground = Color(0xFFE8E8EA);

/// Акцентный цвет полосок на полотне.
const Color stripeAccent = Color(0xFF64B5F6);

/// Количество нумерованных полосок на полотне.
const int stripeCount = 24;

/// Высота одной полоски при scaleY = 1.
const double stripeHeight = 56.0;

/// Вертикальный gap между полосками.
const double stripeGap = 12.0;

/// Горизонтальный padding полоски от края полотна.
const double stripeHorizontalPadding = 24.0;

/// Минимальный масштаб (нижняя граница из темы; эффективный минимум также не
/// даёт content'у стать меньше viewport'а).
const double minCanvasScale = 0.8;

/// Максимальный масштаб.
const double maxCanvasScale = 2.0;

/// Вертикальный padding полотна (сверху и снизу) при scaleY = 1.
const double canvasVerticalPadding = 24.0;

/// Базовая высота content'а полотна при scaleY = 1.
const double canvasContentHeight =
    canvasVerticalPadding * 2 + stripeCount * (stripeHeight + stripeGap);

/// Базовый размер шрифта цифры на полоске при scaleY = 1.
const double stripeFontSize = 22.0;
