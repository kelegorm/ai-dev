# Pitfalls — coexisting conflicting gestures

Companion to [gesture-coexistence.md](gesture-coexistence.md).

- **Gesture arena.** With a parent `PageView`, its `HorizontalDragRecognizer`
  wins the arena before anyone sees the second finger — pinch never starts. A
  `ScaleGestureRecognizer` next to a `VerticalDragGestureRecognizer` — drag
  wins the single-finger arena, scale never activates. Conclusion: for
  overlapping gestures the arena must be bypassed, not tuned.
- **`InteractiveViewer` is not an option.** `panEnabled: false` does not hand
  the pan to the parent, it simply disables it; there is no "magic handoff
  flag". `PanAxis.vertical` helps partially, but `InteractiveViewer` still
  pulls scale into the arena. Final answer — without it.
- **A pointer-count gate that switches `PageView.physics`** is a rejected
  research approach. Switching physics on the fly is brittle, and resetting the
  gate at `pointerCount == 1` breaks on the pinch tail. Final answer: the host
  navigation has no drag recognizer competing with the canvas, and the
  horizontal gesture is forwarded out by hand.
- **`Matrix4` Y-scale instead of layout zoom** — stretches text and radii.
- **`OverflowBox` / `UnconstrainedBox`** — `size = parent.biggest`, hit testing
  drops taps outside the parent (see `OversizedHitTestBox`).
- **`VelocityTracker1D` with no `dt == 0` guard** — several move events sharing
  one timestamp produce a division by zero; recompute velocity only when `dt`
  is positive.
- **The 2→1 pinch tail** — the remaining finger must be moved to `consumed`,
  otherwise a stray navigation or fling occurs.
- **A handoff guard that reads the *animating* page.** The host hands gestures
  to the canvas by `pageController.page.round() == <canvas page>`. But `page`
  is fractional and animating during a snap, so `round()` flips mid-animation
  and the host's own `Listener` steps aside before the snap finishes. A
  re-touch then reaches only the canvas, which forwards overflow but does not
  own the host `PageController`, so the snap plays out ignoring the finger and
  chained swipes are dropped. Gate the handoff on the pager being idle
  (`position.isScrollingNotifier`); while it animates the host `Listener` keeps
  ownership (a re-touch interrupts via `jumpTo`) and the canvas marks the
  gesture `consumed` so it does not forward overflow in parallel. With the
  canvas in the *middle* of the pager this is sharper than at an edge — every
  cross-pager journey passes through the canvas seam.
- **A `page`/position read before the first layout** — guard with `?? 0.0`
  and `hasClients` everywhere a controller is touched.
