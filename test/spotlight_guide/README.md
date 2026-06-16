# Spotlight Guide Tests

Run all guide tests:

```sh
flutter test --no-pub test/spotlight_guide
```

Run static checks:

```sh
flutter analyze --no-pub lib/spotlight_guide.dart lib/src test/spotlight_guide
```

## Test Files

```text
spotlight_guide_targets_test.dart
  Target registration, multiple hints in a step, targetIds, duplicate ids,
  duplicate anchor groups, anchorId selection and rebuild fallback, targetKey,
  late target appearance, portal enabled toggle, per-target enabled toggle,
  target removal rebuild/notification, missing targetIds member, missing target
  wait/skip behavior, unknown anchorTargetId fallback, no-target whole-child
  highlight.

spotlight_guide_layout_test.dart
  Placement, auto placement by full-overlay directional space, RTL anchor
  semantics, directional margin, min/max constraints, infinity width and height
  expansion, negative center anchor offset, bottom-edge auto flip, target
  padding, decoration anchor safe area, anchor connection range handling, stale
  measurement reset.

spotlight_guide_pointer_test.dart
  Visual pointer alignment for every side, semantic start/end placement in RTL,
  pointer paint layer ordering, pointer anchor-mode behavior, pointer-to-target
  start/end semantics, pointer-center bubble anchoring, top-placed pointer
  below the bubble, and direct arrow anchoring when no pointer is supplied.

spotlight_guide_hint_test.dart
  Built-in bubble sizing and arrow-side padding, bubble hint border/arrow-tip
  inheritance from the guide context, border override precedence, path anchor
  direction exposure, bubble child tap hit testing, proxy decoration, and path
  anchor connection geometry.

spotlight_guide_barrier_test.dart
  Barrier style inheritance and overrides, spotlight-hole de-duplication,
  overlapping/nested hole union, oversized hole clipping, barrier absorbing
  target taps by default, allowTargetInteraction pass-through, and pass-through
  covering only the target rect and not its padding.

spotlight_guide_target_decoration_test.dart
  Target decoration shape cutting, target paint context shape resolution,
  glow layer clearing, and outside-only layered ring painting.

spotlight_guide_auto_scroll_test.dart
  Zero interval, three-item index sequencing, finish/next/reset cancellation,
  single-item and disabled auto scroll, onAutoScrollItemChanged deduplication,
  onlyWhenNeeded false, horizontal axis, partially visible later targets, lazy
  target with onReveal, reset callback restart. Uses [kAutoScrollTestInterval],
  [pumpGuideFrames], and [pumpAutoScrollInterval] for stable timer-driven pumps.

spotlight_guide_reveal_test.dart
  Default ensureVisible, only-if-needed reveal, always reveal, configurable
  reveal scroll target policy, large target group anchor-priority reveal,
  anchorId reveal for repeated target groups, targetKey reveal, all fixed
  placements, vertical and horizontal same-step auto scroll, deferred later-item
  onReveal at auto-scroll turn, lazy later targets hiding outgoing hints while
  they are revealed, offscreen same-step hints staying hidden until their target
  is visible, a same-step target taller than the viewport still revealing its
  hint once it overlaps the viewport, default reveal presentation hiding hints
  during animated/lazy reveal, live reveal presentation tracking animated target
  geometry, lazy list reveal, manual item reveal with default reveal disabled,
  disabled reveal, item reveal options inherited from the step, onStepWillShow
  ordering, disabled auto scroll up-front reveal, edge-flush no-auto-scroll
  regression, async item reveal cancellation, same-step auto scroll transition
  hiding while animated reveal runs,
  same-step one-hint-at-a-time focus during auto scroll,
  onAutoScrollItemChanged context fields, targetIds item during auto scroll,
  all-visible multi-hint without callbacks.

spotlight_guide_controller_test.dart
  next/previous/goTo/finish/hide/reset behavior, showPortal/showSteps,
  runtime-only portals, previous clamping on the first step, goTo clamping
  out-of-range indices, auto-start without a controller, finish from a hint
  button, unmount during auto-start preparation, pending commands replayed
  after attach, idle finish, disabling the portal, clearing steps, barrier tap
  with an external controller, barrier tap driving the internal controller,
  barrier dismiss disabled/onComplete/anytime behavior, dynamic step and item
  updates, dynamic metadata rebuilds, parent rebuilds of portal-owned steps,
  state callback coverage, async onStepWillShow, error reporting, controller
  replacement.

spotlight_guide_hot_reload_test.dart
  Hot-reload-like parent rebuild behavior while a guide is visible: active
  index preservation, first-step property changes, no duplicate final step
  after Next, auto-start/internal-controller rebuilds, runtime steps staying
  separate from portal steps, in-flight preparation cancellation, reassemble
  and parent-rebuild ordering, current item layout changes, pointer swaps,
  target geometry/id changes, barrier changes, RTL rebuilds, step-list shrink,
  and missing-target behavior changes.

spotlight_guide_test_helpers.dart
  Shared app shell, target builders, grouped target reveal fixtures, scroll
  fixtures, hint builders, case classes, and pump helper.
```

## Regression Map

- Changing `SpotlightGuideStepItem`, `targetId`, `targetIds`, or `targetKey`: run targets and reveal tests.
- Changing placement or constraints: run layout tests.
- Changing pointer or arrow anchor math: run pointer and layout tests.
- Changing built-in hint widgets, the bubble decoration, or the connected arrow painter: run hint and pointer tests.
- Changing target decoration rings, glow, shadow, dashed outlines, or shapes: run target decoration and barrier tests.
- Changing barrier color, blur, hole clipping, or target pass-through: run barrier tests.
- Changing reveal, scroll, lazy-list handling, or same-step multi-item behavior: run reveal and auto-scroll tests.
- Changing controller behavior: run controller tests.
- Changing hot-reload-like rebuild, runtime step source, active index, or
  visible-step update behavior: run hot reload and controller tests.

The full folder currently contains focused widget tests split by feature area.

Before changing guide code, also read:

```text
CONTRIBUTING.md
```
