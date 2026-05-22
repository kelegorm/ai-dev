# Coexisting conflicting gestures on a single widget

## When you need this

You have one widget that must react to several gestures whose recognizers
fight each other. The textbook case: a scrollable, zoomable canvas that also
sits inside a horizontally-swipeable navigation. The user expects to drag the
content vertically, pinch it to zoom, tap items inside it, and swipe sideways
to move to the next screen — all on the same surface, all feeling native.

Flutter's gesture arena is built for *disambiguation*: when two recognizers
both want a pointer, exactly one wins and the rest are dropped. That is the
right model when gestures are mutually exclusive. It is the wrong model here,
because these gestures are not alternatives — they are different *interpreta-
tions of intent* that the app itself can tell apart (one finger moving mostly
vertically is a scroll; two fingers are a zoom; one finger moving mostly
horizontally is navigation). The arena cannot express "let me classify this
myself"; whichever recognizer claims the pointer first wins, and the others
never start.

Reach for this trick when stock composition (`PageView` + `InteractiveViewer`
+ `GestureDetector`) visibly misbehaves: pinch never starts under a `PageView`,
a vertical drag recognizer kills scale, horizontal navigation steals the
scroll, and so on. The fix is to stop tuning the arena and step outside it:
observe raw pointer events and classify intent in your own code.

This example pairs with the [super-page trick](../shared-scaffold/shared-scaffold-pageview.md).
Both were extracted from one prototype and share a seam: the horizontal
gesture, once it runs out of local room, is *forwarded* outward through a pair
of callbacks (`onOverflowDelta` / `onOverflowRelease`). Here the receiver is a
bounded 3-page `PageView` pager (Left ─ Canvas ─ Right); in the super-page
trick it is the shared outer `PageView` carrying the routes. The callback
contract is identical, which is what lets the two tricks be combined in a real
app.

Reference implementation —
`flutter_examples/lib/gesture_coexistence/canvas/canvas_overlay.dart`.

## Solution

Drop the arena entirely for these gestures. Do not use `GestureDetector` /
`InteractiveViewer` — observe raw pointer events through a `Listener` and
classify intent manually.

- **Raw `Listener`** (`HitTestBehavior.translucent`) over the content. It only
  observes `onPointerDown/Move/Up/Cancel`, never joins the arena, and neither
  wins nor loses against anyone.
- **Active-finger counter** — a `Map<int, Offset>` keyed by `pointer` id.
  1 finger → a single-finger gesture, 2 fingers → pinch.
- **Intent classifier** for the single-finger gesture — a pure function
  `classifyPanIntent({start, current}) -> PanIntent`
  (`gestures/pan_intent.dart`). Intent is locked when one axis crosses its
  threshold and does not change until the gesture ends. The classifier is
  biased toward horizontal: a horizontal intent requires a small `dx`
  (threshold 4 px) and only moderate dominance over `dy` (`dx > dy * 0.6`),
  while a vertical intent requires a larger `dy` (threshold 12 px) with strict
  dominance. This matters because the horizontal swipe is navigation and must
  be caught early.
- Routing by `PanIntent`:
  - `horizontal` → forwarded to navigation (the overflow callbacks);
  - `vertical` → the content's own pan (`translateY`);
  - 2 fingers → `pinch` (zoom).
- **The host navigation keeps no drag recognizer of its own** competing with
  the canvas. In this example the horizontal gesture is forwarded straight to
  `auto_route`; in the super-page trick it moves a `PageController` manually
  (`position.jumpTo` / `animateToPage`). Either way the navigation layer never
  enters the arena against the canvas.
- **Inertia (vertical fling)** — `VelocityTracker1D`
  (`gestures/velocity_tracker_1d.dart`, instantaneous velocity from the last
  two move events) + a `FrictionSimulation` on an unbounded
  `AnimationController`. The friction coefficient is kept close to native
  Flutter scroll (~0.135) so the feel matches the system.

### Where the canvas gestures are handled

All canvas gestures live in a **single** entry point — the `Listener` inside
`CanvasOverlay`. Tap is the one exception: it is handled pointwise by a
`GestureDetector` on each `Stripe` (which sits below the same `Listener` and
does not conflict with it, because the translucent `Listener` only observes).

```
PagerShell (@RoutePage shell — bounded 3-page pager: Left ─ Canvas ─ Right)
└─ PagerScope (InheritedWidget — overflow callbacks + isPagerTransitioning)
   └─ Listener (side, translucent)      <- swipes on the Left/Right screens;
      │                                    also owns any in-flight pager snap
      └─ PageView (NeverScrollableScrollPhysics, our PageController)
         ├─ LeftScreen / RightScreen    <- plain Scaffolds, no Listener
         └─ CanvasScreen (route screen) <- the middle page, hosts the canvas
            └─ Scaffold
               ├─ appBar: AppBar
               └─ body: CanvasOverlay   <- ALL canvas gesture handling lives here
                  └─ Listener (translucent)  <- single pointer-event entry point:
                     │                          horizontal swipe, vertical pan,
                     │                          pinch, overflow-forwarding
                     └─ ClipRect
                        └─ Transform     <- scroll offset (translateY)
                           └─ OversizedHitTestBox
                              └─ CanvasContent
                                 └─ Stripe × N  <- each has its own
                                                   GestureDetector.onTap (tap)
```

The horizontal swipe is not consumed by the canvas at all — every horizontal
delta is forwarded, through `PagerScope`, to `PagerShell`, which moves its
bounded `PageView` directly (`jumpTo` during the drag, `animateToPage` to snap)
between the Left / Canvas / Right pages. The canvas widget knows nothing about
navigation. Note the two gesture entry points: the side `Listener` in
`PagerShell` (swipes on the side screens, and ownership of any in-flight pager
snap) and the canvas `Listener` here — the handoff between them is the
[transition-ownership rule](../shared-scaffold/shared-scaffold-pageview.md).

### Vertical-only zoom as layout scaling

Pinch changes **only** the vertical scale of the content. This is intentionally
NOT a `Matrix4` stretch: a matrix Y-scale also stretches text and
border-radii — the picture "smears". Instead `scaleY` is passed into the
content as a layout parameter (`CanvasContent`): heights, paddings and
`fontSize` grow proportionally, while width and radii stay constant — elements
physically become taller rather than being deformed. The matrix is used only
for `translate` (scroll offset).

Pinch is anchored to the midpoint of the two fingers: on start the "world"
Y-coordinate under the midpoint is recorded, and during the move `translateY`
is recomputed so that point stays under the fingers.

### Overflow-forwarding — the seam to navigation

A horizontal gesture is forwarded outward through callbacks
(`onOverflowDelta` during the drag, `onOverflowRelease` with the release
velocity) — the navigation owner decides what to do. The gesture widget knows
nothing about the navigation mechanics.

This is deliberately the same contract the [super-page trick](../shared-scaffold/shared-scaffold-pageview.md)
uses. There the horizontal gesture first moves a local `subState` (0..1) and
only the *excess* past the boundary is forwarded; here there is no local
horizontal state, so the whole horizontal gesture is forwarded. Same two
callbacks, different receiver — which is exactly why a single canvas can be
dropped into either host.

### OversizedHitTestBox

When the content is laid out larger than its parent ("tails" stick out), the
stock `OverflowBox` / `UnconstrainedBox` break hit testing: they lay the child
out larger than the parent but render themselves with `size = parent.biggest`.
`RenderBox.hitTest` checks `size.contains(position)` before delegating to the
child — taps on the part of the content outside the parent bounds never
arrive. Symptom: the content scales/moves correctly but only the part that fit
inside the parent constraints is tappable.

The fix is a custom `RenderProxyBox` (`OversizedHitTestBox`): `performLayout`
lays the child out under `BoxConstraints.tight(childSize)`, and `hitTest`
delegates straight to the child with no `size.contains` check. (In this
trimmed example the canvas is screen-width, so the box is not strictly needed
for overflow today — it is kept because it is part of the trick and becomes
load-bearing the moment the content grows wider than the viewport.)

### PanIntent.consumed — the inert gesture

`PanIntent.consumed` marks a single-finger gesture as inert: its movement is
ignored, and on full release the system still settles to a stable position. It
serves two cases:

- **The pinch tail.** When one of two fingers is lifted (2→1), the remaining
  finger must not be treated as a new pan — otherwise releasing the pinch tail
  would accidentally trigger navigation or start a fling. The survivor is
  marked `consumed`.
- **A gesture started during a pager transition.** If a pointer goes down while
  the host pager is mid-snap, the canvas marks it `consumed` at once: during a
  transition the horizontal swipe belongs to the host's own `Listener` (it
  interrupts the snap via `jumpTo`), so the canvas must not forward overflow in
  parallel. See
  [shared-scaffold-pageview.md](../shared-scaffold/shared-scaffold-pageview.md)
  for the transition-ownership rule — the host reports `isPagerTransitioning()`
  to the canvas through the same scope that carries the overflow callbacks.

## Pitfalls

See [gesture-coexistence-pitfalls.md](gesture-coexistence-pitfalls.md).

## Where to look in the code

- `flutter_examples/lib/gesture_coexistence/canvas/canvas_overlay.dart` —
  `Listener`, finger counter, intent routing, pinch, fling,
  overflow-forwarding.
- `flutter_examples/lib/gesture_coexistence/canvas/canvas_content.dart` —
  layout zoom (scaling of heights/paddings/font).
- `flutter_examples/lib/gesture_coexistence/canvas/oversized_hit_test_box.dart`
  — custom `RenderProxyBox` for hit testing outside the parent.
- `flutter_examples/lib/gesture_coexistence/screens/pager_shell.dart` —
  the host: the bounded 3-page `PageView`, the side `Listener`, pager snapping,
  and transition ownership (`isPagerTransitioning`).
- `flutter_examples/lib/gesture_coexistence/screens/pager_scope.dart` —
  the `InheritedWidget` carrying the overflow callbacks + `isPagerTransitioning`
  down to the canvas.
- `flutter_examples/lib/gesture_coexistence/screens/canvas_screen.dart` —
  the middle page: hosts `CanvasOverlay` and wires it to `PagerScope`.
- `flutter_examples/lib/gesture_coexistence/gestures/pan_intent.dart` —
  `PanIntent`, `classifyPanIntent`.
- `flutter_examples/lib/gesture_coexistence/gestures/velocity_tracker_1d.dart`
  — the 1D velocity tracker.
- `flutter_examples/lib/gesture_coexistence/gestures/gesture_tuning.dart` —
  classifier thresholds, navigation thresholds, fling, pinch (the single
  source of "magic numbers").

Run it with:

```
cd flutter_examples
flutter run -t lib/gesture_coexistence/main.dart
```
