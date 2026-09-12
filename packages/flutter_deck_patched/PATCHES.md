# Local flutter_deck patches

This package vendors `flutter_deck` 0.29.0 under its original BSD-3-Clause
license. It is kept local because the published transition API fixes every
`CustomTransitionPage` to GoRouter's 300 ms default, while the reference page
turn needs roughly one second.

Local changes:

- `FlutterDeckTransition.custom` accepts `duration` and `reverseDuration`.
- `FlutterDeckRouter` forwards those values to `CustomTransitionPage`.
- Slide routes are non-opaque so custom page-curl transitions can paint the
  neighbouring paper through their changing silhouette.
- `FlutterDeckApp` mounts its focusable deck subtree after the first layout
  frame, avoiding Flutter 3.47's initial Web view-focus race.
- The presenter client initializes from the router's resolved presentation
  mode, including Web where the constructor mode is null. The reserved
  presenter route starts at slide zero until synchronized, avoiding an invalid
  slide index and blank notes when opening the presenter window.
- Source is formatted with the repository's Dart 3.13.1 formatter.
- One upstream single-line `if` is wrapped in braces to satisfy the workspace
  lint configuration.

Keep the package name and version aligned with upstream so existing workspace
dependencies continue to resolve without changes.
