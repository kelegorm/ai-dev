import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_examples/shared_scaffold/theme.dart';

/// AppBar для unified-режима super-page (tab1 ↔ tab2).
///
/// Слушает [subState] (0..1) и в каждом тике перерисовывает фон через
/// `Color.lerp` и положение индикатора-слайдера через `Alignment` — индикатор
/// едет за пальцем дробно. SubState шарится между AppBar и swipe-логикой
/// super-page, что даёт идеальную синхронность.
class UnifiedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const UnifiedAppBar({super.key, required this.subState});

  final ValueListenable<double> subState;

  static const double _indicatorWidth = 56;
  static const double _indicatorHeight = 6;
  static const double _trackWidth = 140;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: subState,
      builder: (context, _) {
        final value = subState.value.clamp(0.0, 1.0);
        final backgroundColor = Color.lerp(tab1Accent, tab2Accent, value)!;
        final alignmentX = -1 + value * 2;
        return AppBar(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: SizedBox(
            width: _trackWidth,
            height: _indicatorHeight + 12,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: _indicatorHeight,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(_indicatorHeight / 2),
                  ),
                ),
                Align(
                  alignment: Alignment(alignmentX, 0),
                  child: Container(
                    width: _indicatorWidth,
                    height: _indicatorHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(_indicatorHeight / 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
