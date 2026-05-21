import 'package:flutter/material.dart';
import 'package:flutter_examples/shared_scaffold/theme.dart';

/// Обычный вертикальный список карточек — содержимое одной вкладки super-page.
///
/// Намеренно простой `ListView`: приём этого примера — общий Scaffold/AppBar,
/// а не жесты, поэтому скролл здесь классический, без pinch/zoom.
class TabList extends StatelessWidget {
  const TabList({super.key, required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tabItemCount,
      itemBuilder: (context, index) {
        return Card(
          color: accent.withValues(alpha: 0.15),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              child: Text('${index + 1}'),
            ),
            title: Text('$label · item ${index + 1}'),
            subtitle: const Text('Plain vertical scroll, no zoom.'),
          ),
        );
      },
    );
  }
}
