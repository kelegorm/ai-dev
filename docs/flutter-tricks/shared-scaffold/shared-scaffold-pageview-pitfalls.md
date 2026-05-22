# Pitfalls — super-page with a shared Scaffold/AppBar

Companion to [shared-scaffold-pageview.md](shared-scaffold-pageview.md).

- **Two animators on one value.** A snap controller and a nav controller both
  animating one subState compete — the value jitters. Use one
  `AnimationController` + `ValueNotifier` (`SubStateController`).
- **`AutoTabsRouter.pageView`** hides its `PageController` — the fractional
  `page` is unavailable and there is nothing to build the indicator or overflow
  on. Use `.builder` only.
- **A Scaffold inside a `PageView` page** is fine (the super-page and the stubs
  each have their own Scaffold), but the AppBar must not be "swapped" via
  `AnimatedSwitcher` on a gesture tick — that is exactly the flicker. The
  AppBar slides together with its page inside the outer `PageView`.
- **An overlay page in a `Stack` above the Scaffold** (transparent slots in the
  `PageView` + a separate overlay) is a rejected research approach: the overlay
  and the `PageView` desync, and it needs extra `IgnorePointer` / `Opacity`.
  Final answer: the super-page is an ordinary `PageView` page.
- **The `PageView` rebuilding on every gesture tick.** The `PageView` and its
  children are built once; a drag moves the `PageController` directly via
  `jumpTo`. For the outer position there is a separate `ValueNotifier`, so a
  `ValueListenableBuilder` rebuilds only the BottomNav pointwise, not the whole
  shell.
- **`addListener` without `removeListener`** on `PageController` / `tabsRouter`
  — a leak; remove it in `dispose`.
- **An interrupted outer gesture (pointer cancel)** — the snap to an integer
  page must take the same path as on pointer up, otherwise the `PageView`
  sticks on a fractional position.
- **A handoff guard that reads the *animating* page.** The outer `Listener`
  hands gestures to the super-page by `pageController.page.round() == 0`. But
  `page` is fractional and animating during a snap — `round()` flips to 0
  halfway through a transition still travelling *toward* the super-page,
  disabling the outer `Listener` mid-animation. The super-page's `SubStatePager`
  can move `subState` but not the outer `PageController`, so the snap finishes
  ignoring the finger and chained swipes are dropped until the page settles
  exactly. Gate the handoff on the outer `PageView` being idle
  (`position.isScrollingNotifier`); while it animates, the outer `Listener`
  keeps ownership (a re-touch interrupts via `jumpTo`) and `SubStatePager` marks
  the gesture inert so it does not drive `subState` in parallel.
- **A stub page without `AutomaticKeepAliveClientMixin`** — it is recreated
  when swiped back to (scroll position is lost).
