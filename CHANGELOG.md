# Spotlight Guide Changelog

This file records the current component contract for maintainers.

## 0.1.4

- Replaced `SpotlightGuideStepItem.targetPadding` and `targetRadius` with
  `targetDecoration`, which owns target hole padding, shape, and optional paint
  layers.
- Added shape-aware target hole decoration APIs:
  `SpotlightGuideTargetDecoration`, `SpotlightGuideTargetShape`,
  `SpotlightGuideRoundedRectTargetShape`, `SpotlightGuideOvalTargetShape`,
  `SpotlightGuideTargetLayer`, `SpotlightGuideTargetRingLayer`,
  `SpotlightGuideTargetDashedOutlineLayer`,
  `SpotlightGuideTargetGlowLayer`, and `SpotlightGuideTargetShadowLayer`.
- Added an example target decoration scenario showing layered rounded rings and
  reusable glow and dashed outline effects.

## 0.1.3

- Treated hint `margin` as the highest-priority visual boundary, so built-in
  bubble hints can no longer translate outside the resolved safe hint rect while
  aligning their anchors.
- Improved `SpotlightGuideTriangleAnchor.tipArcAngle` rendering by using a
  rounded conic tip instead of the previous shallow quadratic approximation.

## 0.1.2

- Added `SpotlightGuidePortal.blockInteractionDuringPreparation`, which blocks
  page interaction during step preparation by default while keeping the existing
  delayed hint presentation after route transitions and reveal scrolling settle.
- When preparation blocking is disabled, reveal scrolling now stays pass-through
  until the visible guide overlay is ready.
- Reduced unnecessary preparation frame waits when no reveal hooks or scrolling
  actually change layout, so first-screen mounted targets can present faster.
- Kept missing-target wait states pass-through after preparation, so an
  unavailable target does not leave an empty blocking barrier on screen.

## 0.1.1

Documentation-only patch release.

- Changed README preview GIF links to versioned GitHub raw URLs so pub.dev can
  render them correctly.

## 0.1.0

Initial standalone Flutter package release.

- Added semantic `SpotlightGuidePlacement.start` and
  `SpotlightGuidePlacement.end` while keeping physical `left` and `right`.
- Expanded the example app and README previews with horizontal auto-placement,
  no-anchor custom style, and automatic scroll/lazy-target GIFs.

## Current Contract

- `SpotlightGuidePortal` owns the overlay host and may be created with static
  `steps` or with no steps for fully runtime-driven guides.
- `SpotlightGuidePortalController` is the command surface:
  `showPortal`, `showSteps`, `next`, `previous`, `goTo`, `reset`, `hide`, and
  `finish`.
- `showSteps` supplies a runtime sequence that takes priority until another
  runtime sequence replaces it or `showPortal` switches back to portal steps.
- `hide` closes without `onFinish`; `finish` closes and reports completion.
- `controller.index`, `controller.total`, `controller.isFirst`,
  `controller.isLast`, and the same values on `SpotlightGuideStepContext`
  reflect the active sequence after dynamic step and target availability
  changes.
- `SpotlightGuidePortal.onStateChanged` reports visibility, progress, active
  step count, and target availability changes.
- `SpotlightGuideMissingTargetBehavior.wait` keeps late targets alive;
  `skip` removes unavailable API-driven targets from the active sequence.
  Item-level values override the portal default.
- `SpotlightGuideTarget` only registers target geometry. Step selection,
  server response interpretation, and business decisions stay outside targets.
- Repeated `SpotlightGuideTarget.id` values are group semantics. All mounted
  instances are highlighted, placement uses the group union, and repeated
  `anchorTargetId` values resolve as an anchor group rather than first/last
  mount order. Use `SpotlightGuideTarget.anchorId` plus
  `SpotlightGuideStepItem.anchorTargetId` when one instance in that group should
  drive the bubble anchor.
- Public configuration lives in `src/api/`. `SpotlightGuidePortal` and its
  private State stay together in `src/api/portal.dart` to follow common Flutter
  widget style. Runtime collaborators live in `src/runtime/`.
- Target lookup and geometry resolution live in `runtime/target_resolver.dart`.
  Step-source selection lives in `runtime/step_source.dart`. Missing-target
  decisions live in `runtime/missing_target_policy.dart`. Reveal scroll
  decisions live in `runtime/reveal_scroll_strategy.dart`.
- Target hole visuals live on `SpotlightGuideStepItem.targetDecoration`.
  `padding` expands the target used for placement and barrier cutouts, `shape`
  builds the hole path, and `layers` paint around that path after the barrier
  and before hints.
- Reveal hooks run before drawing: portal-level preparation, step-level reveal,
  item-level reveal, then default reveal scrolling. Default reveal uses
  `SpotlightGuideRevealScrollPolicy.onlyIfNeeded`; set `always` to force
  realignment.
- `SpotlightGuideRevealOptions.scrollTargetPolicy` controls which area drives
  reveal scrolling: highlighted area, anchor target, or the default large-group
  anchor fallback.
- For `targetIds` with `anchorTargetId`, default reveal prioritizes the full
  highlighted group only when it can fit in the viewport; otherwise the anchor
  target controls whether scrolling is needed.
- Same-step auto scroll is a viewing aid. It does not advance the controller
  index and it keeps later lazy/offscreen hints hidden until their targets can
  be visually connected.
- Barrier holes are de-duplicated and merged before painting. Target
  pass-through uses only the unpadded target rect. Oversized visual holes are
  clipped to the visible overlay so rounded corners stay on screen.
- The overlay wrapper must stay transparent for target pass-through to work.
- Overlay hides requested during Flutter's build phase are deferred safely.

## Verification

Code changes in this component should pass:

```sh
dart format lib/spotlight_guide.dart lib/src test/spotlight_guide
flutter analyze --no-pub lib/spotlight_guide.dart lib/src test/spotlight_guide
flutter test --no-pub test/spotlight_guide
git diff --check
```
