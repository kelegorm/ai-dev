import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_examples/gesture_coexistence/canvas/canvas_overlay.dart';
import 'package:flutter_examples/gesture_coexistence/screens/pager_scope.dart';

/// Центральный экран примера — полотно с четырьмя сосуществующими жестами.
///
/// Хостит [CanvasOverlay] и замыкает шов «жесты ↔ навигация»: горизонтальные
/// overflow-колбеки полотна форвардятся в bounded-пейджер хоста ([PagerShell])
/// через [PagerScope]. Свайп переключает активный таб пейджера, а не плодит
/// push-стек; на краях пейджер упирается.
///
/// Полотно ничего не знает о навигации — оно лишь форвардит горизонтальный
/// жест через контракт `onOverflowDelta` / `onOverflowRelease`. Здесь
/// приёмник — [PagerScope] хоста; в приёме super-page тот же контракт
/// форвардит overflow в общий outer `PageView`.
@RoutePage()
class CanvasScreen extends StatefulWidget {
  const CanvasScreen({super.key});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  void _onOverflowDelta(double dxPixels) {
    PagerScope.of(context).onOverflowDelta(dxPixels);
  }

  void _onOverflowRelease(double velocityDxPerSec) {
    PagerScope.of(context).onOverflowRelease(velocityDxPerSec);
  }

  void _onStripeTap(int number) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Stripe #$number',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text('Tap on a stripe on the canvas.'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF455A64),
        foregroundColor: Colors.white,
        title: const Text('Canvas'),
      ),
      body: CanvasOverlay(
        onOverflowDelta: _onOverflowDelta,
        onOverflowRelease: _onOverflowRelease,
        isPagerTransitioning: PagerScope.of(context).isPagerTransitioning,
        onStripeTap: _onStripeTap,
      ),
    );
  }
}
