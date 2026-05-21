import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Render-box, который layout'ит child под фиксированный [childSize]
/// (как правило — больший, чем parent constraints), при этом hit-test
/// пропускает напрямую в child без bounds-check'а собственного размера.
///
/// Решает классическую ловушку `OverflowBox` / `UnconstrainedBox`: у них
/// `size = parent.biggest`, и hit-test для overflow-области (части child'а,
/// выходящей за parent) не срабатывает, потому что точка попадает вне
/// `size` самого box'а. Здесь [hitTest] делегирует child'у напрямую, так
/// что tap по «вынесенной» части полотна корректно доходит до полосок.
class OversizedHitTestBox extends SingleChildRenderObjectWidget {
  const OversizedHitTestBox({
    super.key,
    required this.childSize,
    required Widget super.child,
  });

  /// Фиксированный размер, под который layout'ится child.
  final Size childSize;

  @override
  RenderOversizedHitTestBox createRenderObject(BuildContext context) {
    return RenderOversizedHitTestBox(childSize: childSize);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderOversizedHitTestBox renderObject,
  ) {
    renderObject.childSize = childSize;
  }
}

/// Render-object для [OversizedHitTestBox].
class RenderOversizedHitTestBox extends RenderProxyBox {
  RenderOversizedHitTestBox({required Size childSize}) : _childSize = childSize;

  Size _childSize;
  set childSize(Size value) {
    if (value == _childSize) return;
    _childSize = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    child?.layout(BoxConstraints.tight(_childSize));
    size = constraints.biggest;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (child != null && child!.hitTest(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
