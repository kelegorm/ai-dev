import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

/// Пустой экран-сосед слева/справа от канваса — крайняя страница
/// bounded-пейджера ([PagerShell]).
///
/// Существует только чтобы показать стыковку кастомного горизонтального
/// жеста на канвасе с auto_route: свайп переключает активный таб пейджера.
///
/// Никакого собственного swipe-back здесь нет — это полноценная страница
/// пейджера. Свайп назад к канвасу ловит root-level `Listener` хоста и
/// двигает общий `PageController`.
class SideScreen extends StatelessWidget {
  const SideScreen({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Text(label),
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text('Swipe horizontally to go back to the canvas.'),
          ],
        ),
      ),
    );
  }
}

/// auto_route-обёртка для левого экрана-соседа.
@RoutePage()
class LeftScreen extends StatelessWidget {
  const LeftScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const SideScreen(label: 'Left screen', color: Color(0xFF7E57C2));
}

/// auto_route-обёртка для правого экрана-соседа.
@RoutePage()
class RightScreen extends StatelessWidget {
  const RightScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const SideScreen(label: 'Right screen', color: Color(0xFF26A69A));
}
