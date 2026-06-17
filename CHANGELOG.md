# Spotlight Guide Changelog

This file records the current component contract for maintainers.

## 0.2.1

- Refined default reveal scrolling so the first reveal can scroll before
  painting the overlay, while later in-flow reveal transitions keep the dim
  barrier visible and only hide hints/holes until targets settle.
- Unified reveal scroll timing around Flutter's `duration` plus `curve`
  convention, with `320ms` and `Curves.easeOutCubic` defaults shared by
  `SpotlightGuideRevealOptions`, `ensureVisible`, `scrollToOffset`, and
  `scrollToIndex`.
- Added `SpotlightGuideBarrierReveal` for apps that want a visible dim barrier
  during every reveal preparation phase.
- Expanded reveal strategy docs and tests for interaction blocking,
  lazy-target helpers, and same-step scroll transitions.

## 0.2.0

- Moved pointer configuration to `SpotlightGuideStepItem.pointer` so reveal
  scrolling, auto placement, and safe-area layout can reserve pointer geometry
  before `hintBuilder` runs.
- Removed hint-level pointer parameters from `SpotlightGuideBubbleHint` and
  `SpotlightGuideTextHint`; built-in hints now read the item pointer from
  `SpotlightGuideStepContext.pointer`.
- Added render-level paint readiness support for custom async hint visuals via
  `SpotlightGuidePaintGate`, keeping target holes and hints hidden together
  until the rendered hint subtree is ready.

## 0.1.6

- Stabilized visible guides across Flutter hot reload/reassemble and parent
  rebuilds, including in-flight step preparation, so stale async preparation can
  no longer hide or corrupt the newer visible step.
- Reworked built-in bubble and pointer layout to resolve in the render layout
  pass, removing delayed measurement frames that could make hints flicker or
  jump after hot reload, pointer changes, or reveal scrolling.
- Changed the default missing-target behavior to `skip`, so steps whose targets
  are not mounted and have no reveal callback are removed from the active
  sequence automatically. Use `wait` when a target is intentionally expected to
  appear later.
- Clarified pointer semantics for `gap`, `targetGap`, `visualOffset`,
  `bubbleSide`, and `anchorMode`, and expanded pointer examples around
  target, pointer, and bubble anchor relationships.
- Hardened target decoration, reveal scrolling helpers, and bubble decoration
  inputs against invalid numeric values.
- Expanded focused tests for hot reload, pointer layout, missing target
  filtering, direction semantics, and target decoration edge cases.

## 0.1.5

- Added `SpotlightGuideTextHint`, a ready-to-use title/message/progress/action
  hint for simple onboarding flows.
- Added `SpotlightGuideTapPointer`, a built-in pointer widget for lightweight
  tap cues without requiring an image asset.
- Reordered the example app from simple usage toward advanced scenarios and
  added a dedicated pointer hint scenario.
- Expanded README visuals so core feature sections include direct GIF previews.
- Updated documentation for built-in hint types, pointer usage, and the
  recommended example flow.
- Stabilized first visible hint frames after reveal scrolling, including
  pointer/bubble layouts, so complex hints no longer expose a delayed layout
  jump while their anchor position settles.
- Improved reveal preparation to wait for target geometry to settle after
  scroll work, including nested scrollable animation checks.

## 0.1.4

- Replaced `SpotlightGuideStepItem.targetPadding` and `targetRadius` with
  `targetDecoration`, which owns target hole padding, shape, and optional paint
  layers.
- Added shape-aware target hole decoration APIs:
  `SpotlightGuideTargetDecoration`, `SpotlightGuideTargetShape`,
  `SpotlightGuideRoundedRectShape`, `SpotlightGuideOvalShape`,
  `SpotlightGuideTargetLayer`, `SpotlightGuideTargetRingLayer`,
  `SpotlightGuideTargetOutlineLayer`,
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

- Added `SpotlightGuidePortal.blockDuringPreparation`, which blocks
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
- `SpotlightGuideMissingTargetBehavior.skip` is the portal default and removes
  unavailable targets from the active sequence. `wait` keeps late targets alive.
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
- `SpotlightGuideRevealOptions.targetPolicy` controls which area drives
  reveal scrolling: highlighted area, anchor target, or the default large-group
  anchor fallback.
- For `targetIds` with `anchorTargetId`, default reveal prioritizes the full
  highlighted group only when it can fit in the viewport; otherwise the anchor
  target controls whether scrolling is needed.
- Same-step scroll is a viewing aid. It does not advance the controller
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
