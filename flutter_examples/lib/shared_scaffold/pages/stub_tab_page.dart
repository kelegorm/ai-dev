import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_examples/shared_scaffold/theme.dart';

/// Self-contained заглушка для tab3/4 — собственный Scaffold с обычным
/// AppBar и крупным текстом по центру.
///
/// [AutomaticKeepAliveClientMixin] — чтобы outer PageView не пересоздавал её
/// при возврате свайпом.
class StubTabPage extends StatefulWidget {
  const StubTabPage({super.key, required this.label});

  final String label;

  @override
  State<StubTabPage> createState() => _StubTabPageState();
}

class _StubTabPageState extends State<StubTabPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: stubAppBarColor,
        foregroundColor: Colors.white,
        title: Text(widget.label),
      ),
      body: Center(
        child: Text(
          widget.label,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// auto_route-обёртки для outer-routes tab3/4.
///
/// Каждая — отдельный `@RoutePage()` поверх общего [StubTabPage]: auto_route
/// получает уникальный тип route-страницы, а реализация переиспользуется.
@RoutePage()
class Tab3Screen extends StatelessWidget {
  const Tab3Screen({super.key});

  @override
  Widget build(BuildContext context) => const StubTabPage(label: 'Tab 3');
}

@RoutePage()
class Tab4Screen extends StatelessWidget {
  const Tab4Screen({super.key});

  @override
  Widget build(BuildContext context) => const StubTabPage(label: 'Tab 4');
}
