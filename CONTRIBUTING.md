# Contributing To Spotlight Guide

Read this file before changing Spotlight Guide code. It is the maintainer entry point and maps code changes to required docs and tests.

## File Map

```text
spotlight_guide.dart
  Public export used by product code.

spotlight_guide/spotlight_guide.dart
  Library entry that owns imports and part declarations.

spotlight_guide/src/api/models.dart
  Public configuration models, enums, callbacks, reveal options, step context.

spotlight_guide/src/api/portal.dart
  Public SpotlightGuidePortal widget, configuration fields, private State,
  overlay host, guide orchestration, reveal pipeline, same-step auto scroll,
  and overlay rendering. Keep the widget and its State together unless there is
  a strong Flutter-specific reason to split them.

spotlight_guide/src/api/target.dart
  SpotlightGuideTarget registration and target scope.

spotlight_guide/src/api/controller.dart
  SpotlightGuidePortalController and pending command handling.

spotlight_guide/src/runtime/step_source.dart
  Active step source: portal-owned steps or controller-provided runtime steps.

spotlight_guide/src/runtime/target_resolver.dart
  Target id/key/group lookup and overlay geometry resolution.

spotlight_guide/src/runtime/missing_target_policy.dart
  Missing-target wait/skip strategy for portal defaults and item overrides.

spotlight_guide/src/runtime/reveal_scroll_strategy.dart
  Reveal scroll decision strategy: when to scroll, which target context drives
  scroll, and how large target groups relate to anchor targets.

spotlight_guide/src/runtime/geometry.dart
  Internal target, overlay item, and hole geometry value objects.

spotlight_guide/src/hints/
  Built-in reusable hint UI: bubble, pointer bubble hint, bubble decoration.

spotlight_guide/src/layout/
  Hint measurement, placement selection, constraints, arrow safe-area layout.

spotlight_guide/src/painting/
  Barrier painter and connected bubble-arrow path painter. Barrier holes are
  unioned before subtraction, so nested or overlapping targets remain one clear
  highlighted area.

spotlight_guide/src/utils/collections.dart
  Equality helpers and Rect padding extension.
```

## Documentation Map

```text
README.md
  User-facing overview and common usage.

CHANGELOG.md
  Internal iteration record and regression history.

CONTRIBUTING.md
  This maintainer guide, invariants, change rules, and required verification.

doc/reference.md
  API relationships and built-in hint catalog.

doc/examples.md
  Copyable product integration examples.

doc/troubleshooting.md
  Symptom-based debugging guide.

test/spotlight_guide/README.md
  Test grouping and regression map.

test/spotlight_guide/spotlight_guide_hint_test.dart
  Built-in bubble/decoration rendering, hole de-duplication, and overlapping
  hole union coverage.
```

## Maintainer Rules

- Prefer official Flutter style first. Keep a public `StatefulWidget` and its
  private `State` in the same file when that is the common readable shape, and
  split files only when the split gives a clear maintenance benefit.
- Before changing code, classify the change. Page-only integration can stay in
  the page. Component behavior changes need an abstraction review: decide
  whether the rule belongs in a strategy, resolver, source, policy, value
  object, or plain widget method.
- Use design patterns as small tools, not ceremony. Strategy-like classes are
  useful for step source selection, target resolution, and missing-target
  decisions because those rules vary independently. Reveal scroll behavior also
  lives in a strategy because product experience rules change independently of
  overlay rendering. Do not introduce a pattern if a plain widget method is
  clearer.
- Ask whether the next change should be easy. If a behavior is likely to be
  tuned again, give it a named owner now instead of adding conditional branches
  to `SpotlightGuidePortal` state.
- Keep public API simple for product code. Runtime details may be composed
  internally, but callers should usually set portal defaults, define steps, and
  use controller or guide-context commands.
- Business decisions stay outside the component. The component can reveal,
  filter unavailable targets, and report state; product pages decide which
  server response, tab, list index, or feature flag matters.
- Dynamic behavior must notify and rebuild. Any change that affects active
  `index`, `total`, `isFirst`, `isLast`, resolved target count, or visible hint
  content must sync the controller, rebuild the overlay, and notify
  `onStateChanged`.
- Update tests and docs with behavior changes. Treat this component as a
  reusable feature, not a one-page patch.

## Core Invariants

- `SpotlightGuideTarget` only registers mounted targets. It must not own scroll, tab switching, data loading, or business logic.
- Runtime guide steps belong to `SpotlightGuidePortalController.showSteps` and
  the portal step source. Targets still only register geometry and must not
  decide which API-driven steps should be shown.
- Missing target handling is controlled by `SpotlightGuideMissingTargetBehavior`.
  Keep `wait` for late-mounted targets; use `skip` for optional API-driven
  targets so an absent id cannot leave the guide blank.
- With `skip`, unresolved steps without a reveal path are removed from the
  active sequence. Controller and guide-context `index`, `total`, `isFirst`, and
  `isLast` must reflect that filtered sequence, including when future targets
  are removed while the current hint is visible.
- `SpotlightGuideStep.onReveal` prepares page-level state before item reveal.
- `SpotlightGuideStepItem.onReveal` prepares item-specific state before default `Scrollable.ensureVisible`.
- `targetId`, `targetIds`, and `targetKey` must all work with reveal and geometry.
- Repeated target ids are target-group semantics. Highlight every mounted
  instance, use the union rect for placement, and never silently choose the
  first or last mounted target. If `anchorTargetId` resolves to repeated
  targets, use that id's union rect as the anchor group. Product code that
  needs one precise instance inside a repeated group should set
  `SpotlightGuideTarget.anchorId` on that instance and point
  `anchorTargetId` at it, so dynamic target registration still drives rebuilds
  and `onStateChanged`.
- Reveal scrolling has two public decisions: `scrollPolicy` says when to scroll,
  and `scrollTargetPolicy` says which area drives the decision. Keep those
  dimensions separate when adding new behavior.
- For `targetIds` with `anchorTargetId`, the default
  `scrollTargetPolicy` should keep the whole group visible only when that group
  can fit in the viewport. If the group is too large, anchor visibility is the
  priority.
- `SpotlightGuidePlacement.verticalAuto` is the default. `auto` may choose any side based on target and hint relative position.
- `SpotlightGuideAnchorPosition.start/end` are semantic and must respect RTL.
- The indicator tip position is the visual anchor. Arrow safe-area logic may shift or expand the bubble body, but it must not move the target anchor.
- Bubble arrows are painted as one continuous path with the bubble body. Avoid drawing a separate triangle widget for the common bubble implementation.
- `SpotlightGuidePortal.barrier` owns shared background atmosphere such as dim
  color and blur. `SpotlightGuideStep.barrier` may partially override it.
  Target hole padding, shape, and paint layers stay on
  `SpotlightGuideStepItem.targetDecoration`.
- Visual target holes must be clipped to the visible overlay before painting so
  oversized or edge-aligned targets keep rounded corners on screen. Do not use
  the clipped hole rect for placement, reveal scrolling, or pass-through
  interaction; those keep using resolved target geometry.
- The barrier absorbs taps everywhere except the unpadded target rect of an item
  with `allowTargetInteraction`, which passes through to the page so the user
  can press the real highlighted widget. The padding band from
  `targetDecoration.padding` stays absorbed. `onBarrierTap` receives the active
  controller and only adds a reaction; it must not stop the barrier from
  absorbing elsewhere.
- The overlay wrapper `Material` must stay `MaterialType.transparency`. A default `Material` (canvas/card/button) absorbs pointer events and would silently block `allowTargetInteraction` pass-through even though `_SpotlightBarrierRegion` punches the hole.
- The overlay must be hidden through `_hideOverlay`, never with a direct `OverlayPortalController.hide` from the build phase. Hiding during `didUpdateWidget` is deferred to the end of the frame.
- Controller replacement should absorb the previous controller state. Hot-reload-like rebuilds should not reset active guide state.
- If the guide is preparing and `finish` is called, pending async work must not show the hint later.

## Reveal Pipeline

When a step is shown:

1. `SpotlightGuidePortal.onStepWillShow`
2. `SpotlightGuideStep.onReveal`
3. `SpotlightGuideStepItem.onReveal` for the first item, or for every item when same-step auto scroll is disabled. Later items in an auto-scroll step defer their `onReveal` to step 6.
4. Default reveal scrolling for the first item, or for every item when same-step auto scroll is disabled. The default `SpotlightGuideRevealScrollPolicy.onlyIfNeeded` calls `Scrollable.ensureVisible` only when a mounted target is outside the padded visible viewport. `always` restores unconditional alignment. The overlay is shown before this reveal pass so animated scrolling is visible. While a non-zero reveal duration runs, the portal schedules per-frame `setState` rebuilds until scroll positions settle.
5. Overlay show
6. Same-step auto scroll optionally visits later hidden items after `autoScrollOptions.interval`, running each deferred `onReveal` then `ensureVisible`. A later item that is not mounted yet still qualifies when it has an `onReveal` hook. `onAutoScrollItemChanged` fires when the sequentially focused `itemIndex` changes (`0` first, then each later item as auto scroll advances).

The auto-scroll aid does not advance the controller index. It only moves scrollables so hidden hints can be seen. A same-step auto-scroll overlay renders each item whose target resolves and overlaps the viewport, then skips unresolved or entirely off-screen items until auto scroll brings any part of them into view. When a later item is still hidden, only the highest renderable `itemIndex` is painted so two hints never overlap during a scroll transition. The skip uses viewport overlap, not full containment, so a target larger than the viewport still shows its hint. This prevents a hint from being clamped onto the screen while its target is elsewhere. `SpotlightGuideStepContext.itemTotal` reports the full step item count regardless of how many items currently render.

## Change Matrix

| Change Type | Code Area | Required Docs | Required Tests |
| --- | --- | --- | --- |
| New public parameter, enum, callback, or default value | `src/api/models.dart`, `src/api/portal.dart` | `doc/reference.md`, `README.md` when user-facing, `CHANGELOG.md` | Closest focused test file plus helper updates if needed |
| Target registration, `targetId`, `targetIds`, `anchorTargetId`, `targetKey` | `src/api/target.dart`, `src/runtime/target_resolver.dart`, `src/runtime/geometry.dart` | `doc/reference.md`, `doc/troubleshooting.md` if behavior affects missing targets | `spotlight_guide_targets_test.dart`, reveal tests if scroll is involved |
| Missing target wait/skip behavior | `src/runtime/missing_target_policy.dart`, `src/api/models.dart`, `src/api/portal.dart` | `doc/reference.md`, `doc/troubleshooting.md`, `doc/examples.md` for API-driven guides | `spotlight_guide_targets_test.dart`, `spotlight_guide_controller_test.dart` when active step metadata changes |
| Step, controller, next/previous/goTo/finish/hide/reset, dynamic steps/items, `onBarrierTap` | `src/api/controller.dart`, `src/api/portal.dart`, `src/runtime/step_source.dart` | `CONTRIBUTING.md`, `CHANGELOG.md`, `doc/reference.md` and `README.md` when user-facing | `spotlight_guide_controller_test.dart` |
| `SpotlightGuideBarrierStyle`, blur, color, hole pass-through, barrier hit testing | `src/api/models.dart`, `src/layout/overlay_layout.dart`, `src/painting/barrier_painter.dart` | `doc/reference.md`, `doc/troubleshooting.md`, `README.md`, `CHANGELOG.md` | `spotlight_guide_barrier_test.dart` |
| Reveal, scroll, lazy list, same-step auto scroll | `src/api/portal.dart`, `src/api/models.dart`, `src/runtime/reveal_scroll_strategy.dart` | `doc/reference.md`, `doc/troubleshooting.md`, `doc/examples.md` for integration changes, `CHANGELOG.md` | `spotlight_guide_reveal_test.dart`, `spotlight_guide_auto_scroll_test.dart` |
| Placement, constraints, margin, min/max size, RTL anchor semantics | `src/layout/overlay_layout.dart`, `src/api/models.dart` | `doc/reference.md`, `doc/troubleshooting.md` for known symptoms | `spotlight_guide_layout_test.dart` |
| Arrow safe area, indicator size, indicator tip, connected path, barrier holes | `src/layout/overlay_layout.dart`, `src/painting/`, `src/hints/` | `doc/reference.md`, `doc/troubleshooting.md` if hint-facing | `spotlight_guide_layout_test.dart`, pointer tests if pointer alignment can move |
| Pointer widget, `SpotlightGuideBubbleHint`, `SpotlightGuideHintPointer`, pointer alignment | `src/hints/bubble_hint.dart` | `doc/reference.md`, `doc/examples.md` if usage changes | `spotlight_guide_pointer_test.dart` |
| Built-in hint type added, renamed, or behavior changed | `src/hints/` | `doc/reference.md`, `README.md`, `doc/examples.md`, `CHANGELOG.md` | `spotlight_guide_hint_test.dart`, plus pointer/layout tests when alignment can move |
| Target decoration shape, ring, glow, shadow, or dashed layer behavior | `src/api/target_decoration.dart`, `src/painting/barrier_painter.dart` | `doc/reference.md`, `doc/troubleshooting.md` if symptoms change | `spotlight_guide_target_decoration_test.dart` |
| Low-level bubble decoration or painter behavior | `src/hints/bubble_decoration.dart`, `src/painting/` | `doc/reference.md`, `doc/troubleshooting.md` if symptoms change | Layout/pointer tests that inspect geometry |
| Test helper or fixture behavior | `test/spotlight_guide/spotlight_guide_test_helpers.dart` | `test/spotlight_guide/README.md` if fixture responsibilities change | Run all `test/spotlight_guide` |
| Directory structure or file ownership | `spotlight_guide.dart`, `src/**`, tests | `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `test/spotlight_guide/README.md` | Full analyze and full guide tests |

## New Feature Rule

For a new feature, add or update all of these when applicable:

- Public API docs in `doc/reference.md`.
- At least one copyable usage in `doc/examples.md` if product integration would otherwise be unclear.
- A troubleshooting entry if the feature can fail visually or asynchronously.
- A changelog bullet with the maintenance context.
- A focused test in the matching test file.
- A test-file header comment if the new scenario changes that file's responsibility.

## Bug Fix Rule

For a bug fix, add or update:

- A regression test that fails without the fix.
- `doc/troubleshooting.md` if the bug maps to a symptom product developers may see.
- `CHANGELOG.md` under regression history if the bug is likely to recur.

## Required Final Verification

For code changes:

```sh
dart format lib/spotlight_guide.dart lib/src test/spotlight_guide
flutter analyze --no-pub lib/spotlight_guide.dart lib/src test/spotlight_guide
flutter test --no-pub test/spotlight_guide
git diff --check
```

For documentation-only changes:

```sh
git diff --check
```
