# Super-page: a shared Scaffold/AppBar for adjacent tabs

## When you need this

You have a bottom navigation with N items, but a couple of adjacent items are
not really separate destinations — they are two faces of the *same* place. The
classic example: a "Feed" and a "For you" tab that share one AppBar, one
search field, one set of actions; the user swipes between them and only a small
indicator moves. The remaining bottom-nav items are ordinary, fully separate
screens.

The naive implementation gives each tab its own `Scaffold` and `AppBar`. On a
swipe the two AppBars cross-fade or get swapped by an `AnimatedSwitcher`, and
the result flickers: the title jumps, the background color pops, actions blink.
Nesting a `PageView` inside the page to carry the two tabs then collides with
whatever horizontal-drag mechanism moves you between the *outer* destinations.

The fix is a **super-page**: several bottom-nav items map onto a single route
that owns one `Scaffold` and one `AppBar`. Switching between the merged tabs is
an internal continuous value (`subState`, 0..1), not a route change, so the
AppBar can interpolate smoothly instead of being swapped. The super-page still
slides as a whole — AppBar included — when you navigate to a genuinely
different destination.

Reach for this when two or more bottom-nav tabs must look and feel like one
surface while neighbouring tabs stay independent, and when you have already
seen the two-Scaffold flicker and want it gone.

This example pairs with the [gesture-coexistence trick](../gesture-coexistence/gesture-coexistence.md).
Both came out of one prototype and share a seam: when the internal `subState`
saturates and the finger keeps going, the *excess* is forwarded outward through
a pair of callbacks (`onOverflowDelta` / `onOverflowRelease`). Here that
overflow drives the outer `PageView`; in the gesture example the very same
contract drives `auto_route`. The shared contract is what lets a complex
gesture surface and a super-page host be combined in a real app.

Reference implementation —
`flutter_examples/lib/shared_scaffold/root_shell.dart`,
`pages/super_page.dart`, `widgets/unified_app_bar.dart`.

## Solution

The N BottomNav items map onto a **smaller** number of routes. In this example
4 items → 3 routes: items Tab1 and Tab2 lead to one super-page (outer-route 0),
where switching is a subState; Tab3-4 → outer-routes 1-2.

- **The super-page = one Scaffold + one AppBar.** tab1 and tab2 are values of
  the internal `subState` 0..1, not separate outer routes. The AppBar
  (background via `Color.lerp`, indicator via `Alignment`) is subscribed to
  that same `subState` and moves fractionally with the finger.
- **`SubStateController`** (`gestures/sub_state_controller.dart`) — one
  `ValueNotifier<double>` + **one** `AnimationController`. Both the post-swipe
  snap and the BottomNav-tap animation go through this single controller.
  `setRaw` (immediate, for drag) stops the current animation; `animateTo` (for
  snap/tap) animates. Two separate controllers driving one value raced: one
  controller's tick overwrote the other's and the value jittered.
- **The outer `PageView`** drives the real transitions between routes. On a
  tab2→tab3 swipe the super-page slides **as a whole** (together with its
  AppBar and content) — a real horizontal slide through the `PageView`, not a
  fade and not an `AnimatedSwitcher` swapping AppBars.
- **Overflow-forwarding.** When `subState` saturates (hits 0 or 1) and the
  finger keeps going, the gesture excess is forwarded into outer navigation via
  callbacks (`onOverflowDelta` during the drag → `PageController.position
  .jumpTo`; `onOverflowRelease` with velocity → snaps the outer `PageView` to
  the nearest page).

### The tab content is a plain vertical scroll

Inside each merged tab the content is an ordinary vertical `ListView`. The
super-page trick is about a *shared shell*, not about gestures — there is no
pinch and no zoom here. The only custom gesture is the horizontal swipe that
moves `subState`; it is caught by a translucent raw `Listener` that merely
observes, so the vertical `ListView` underneath keeps scrolling on its own. If
you also need a zoomable / multi-gesture canvas inside a tab, that is the
separate [gesture-coexistence trick](../gesture-coexistence/gesture-coexistence.md),
and it plugs in through the same overflow callbacks described below.

### Widget tree and where gestures are handled

Gesture handling lives in **two** places, not one. The tree below marks both
`Listener`s, the route screen and the main widgets.

```
RootShell (StatefulWidget, owns PageController + SubStateController)
└─ SharedScaffoldScope (InheritedWidget — shared deps for route pages)
   └─ AutoTabsRouter.builder              <- route-state only (activeIndex)
      └─ Scaffold
         ├─ body: Listener (outer, translucent)   <- GESTURE POINT #1:
         │  │                                        horizontal swipes on
         │  │                                        tab3/4 (idle on outer 0)
         │  └─ PageView (NeverScrollableScrollPhysics, our PageController)
         │     ├─ SuperPage (route screen)
         │     │  └─ Scaffold
         │     │     ├─ appBar: UnifiedAppBar
         │     │     └─ body: SubStatePager
         │     │        └─ Listener (translucent)  <- GESTURE POINT #2:
         │     │           └─ Row(tab1, tab2)         horizontal subState swipe
         │     │              └─ ListView × 2         (vertical scroll is the
         │     │                                       ListView's own)
         │     └─ Tab3 / Tab4 → plain Scaffolds
         │                      (no Listener; outer Listener handles their
         │                       horizontal swipes)
         └─ bottomNavigationBar: BottomNavigationBar (4 items → onTap → routes)
```

Why two points, and why it is deliberate:

- **Point #2 — the `Listener` inside `SubStatePager`** (route screen
  `SuperPage`). The super-page owns the horizontal subState swipe and the
  overflow-forwarding, so it owns its own `Listener`. In this trimmed example
  it handles only the horizontal swipe; in a full app this is exactly where a
  multi-gesture canvas would live — see
  [gesture-coexistence.md](../gesture-coexistence/gesture-coexistence.md).
- **Point #1 — the outer `Listener` in `RootShell`**, wrapping the `PageView`.
  The stub pages tab3/4 have no super-page surface, and the outer `PageView`
  keeps `NeverScrollableScrollPhysics` (so it cannot conflict with point #2).
  They need only a horizontal swipe, so a lightweight outer `Listener` handles
  it manually. It is idle while the outer page is 0 (the super-page), so the
  two `Listener`s never overlap.

`currentIndex` of the BottomNav is computed from the outer position and the
subState: outer 0 + subState < 0.5 → item 0, outer 0 + subState ≥ 0.5 → item 1,
otherwise outer + 1.

## Compatibility with auto_route

- Use **`AutoTabsRouter.builder`**, NOT `AutoTabsRouter.pageView`. `.pageView`
  hides its own `PageController` inside — there is no access to the fractional
  `page` for the AppBar indicator or the overflow logic. `.builder` exposes
  only the route state (`tabsRouter.activeIndex`), and the layout (our own
  `PageView` + our `PageController`) is assembled in the builder callback.
- The route ↔ layout sync is two-way: a swipe moves our `PageController` →
  when the fractional position reaches an integer, `tabsRouter.setActiveIndex`
  is called; a programmatic switch (deep-link, tap) goes through a `tabsRouter`
  listener → `pageController.animateToPage`.
- auto_route constructs the route pages itself, so live dependencies cannot be
  passed to them through the constructor. Shared dependencies
  (`SubStateController`, overflow callbacks) are placed in an `InheritedWidget`
  above `AutoTabsRouter` (`SharedScaffoldScope`); a route page reads them from
  `context`.

## Pitfalls

See [shared-scaffold-pageview-pitfalls.md](shared-scaffold-pageview-pitfalls.md).

## Where to look in the code

- `flutter_examples/lib/shared_scaffold/root_shell.dart` —
  `AutoTabsRouter.builder`, our own `PageView`/`PageController`, route↔layout
  sync, the outer `Listener`, overflow callbacks, BottomNav mapping.
- `flutter_examples/lib/shared_scaffold/pages/super_page.dart` — the
  super-page: one Scaffold + `UnifiedAppBar` + content.
- `flutter_examples/lib/shared_scaffold/widgets/sub_state_pager.dart` — the
  horizontal subState swipe + overflow-forwarding; the simplified stand-in for
  a full multi-gesture canvas.
- `flutter_examples/lib/shared_scaffold/widgets/tab_list.dart` — the plain
  vertical `ListView` content of a tab.
- `flutter_examples/lib/shared_scaffold/widgets/unified_app_bar.dart` — the
  AppBar subscribed to `subState` (background + indicator move fractionally).
- `flutter_examples/lib/shared_scaffold/gestures/sub_state_controller.dart` —
  the single notifier + animation controller for subState.
- `flutter_examples/lib/shared_scaffold/shared_scaffold_scope.dart` — the
  `InheritedWidget` that passes shared dependencies into route pages.
- `flutter_examples/lib/shared_scaffold/app_router.dart` — the auto_route
  configuration (one shell-route with 3 outer children).
- `flutter_examples/lib/shared_scaffold/pages/stub_tab_page.dart` — the stub
  pages tab3/4.

Run it with:

```
cd flutter_examples
flutter run -t lib/shared_scaffold/main.dart
```
