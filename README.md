# Spotlight Guide

`SpotlightGuidePortal` is a reusable onboarding overlay for highlighting one or more widgets on a page. It supports target holes, custom hint UI, connected bubble arrows, pointer images, RTL-aware anchor positions and semantic placement, automatic placement, reveal scrolling, lazy-list preparation, and multiple hints in the same step.

## Preview

| Basic flow | Same-step auto scroll | Barrier dismiss |
| --- | --- | --- |
| ![Basic spotlight guide flow](https://raw.githubusercontent.com/ModWU/spolight_guide/v0.1.1/doc/images/readme/basic_flow.gif) | ![Same-step automatic scroll](https://raw.githubusercontent.com/ModWU/spolight_guide/v0.1.1/doc/images/readme/same_step_scroll.gif) | ![Barrier tap dismiss modes](https://raw.githubusercontent.com/ModWU/spolight_guide/v0.1.1/doc/images/readme/barrier_dismiss.gif) |
| Custom anchors and groups | Lazy target reveal | Horizontal auto |
| ![Custom anchors and repeated target groups](https://raw.githubusercontent.com/ModWU/spolight_guide/v0.1.1/doc/images/readme/custom_anchors.gif) | ![Lazy target reveal scroll](https://raw.githubusercontent.com/ModWU/spolight_guide/v0.1.1/doc/images/readme/lazy_target_reveal.gif) | ![Horizontal auto placement choosing left and right arrows](https://raw.githubusercontent.com/ModWU/spolight_guide/v0.1.1/doc/images/readme/horizontal_auto.gif) |

## Highlights

- Static or runtime guide steps through `SpotlightGuidePortalController`.
- Multiple hints in one step, including sequential same-step auto scroll.
- Dynamic API-driven steps with skip/wait behavior for missing targets.
- Lazy-list targets using `onReveal` before measurement.
- Repeated target ids highlighted as a group, with optional `anchorId`.
- Custom target anchor positions, interactive bubble arrows, barrier style, and hints.

## Public Entry

Import the public entry:

```dart
import 'package:spotlight_guide/spotlight_guide.dart';
```

The implementation lives here:

```text
lib/spotlight_guide.dart
lib/src/api/
lib/src/runtime/
lib/src/hints/
lib/src/layout/
lib/src/painting/
lib/src/utils/
```

Runtime files are small collaborators rather than page code. For example,
`runtime/reveal_scroll_strategy.dart` owns reveal scroll decisions, while
`api/portal.dart` keeps the Flutter widget and State orchestration together.

## Documents

```text
README.md
  Overview and common usage.

CONTRIBUTING.md
  Maintainer rules, architecture map, invariants, and required verification.

CHANGELOG.md
  Current component contract and maintenance notes.

doc/reference.md
  Public parameter relationships and built-in hint types.

doc/examples.md
  Copyable examples for saving-page style, lazy lists, and same-step targets.

doc/troubleshooting.md
  Symptom-based debugging guide.
```

Before changing code in this component, read `CONTRIBUTING.md` first.

## Example App

The example app is a scenario playground. The entry stays small in
`example/lib/main.dart`, while each usage pattern lives in its own file:

```text
example/lib/src/scenarios/basic_steps_scenario.dart
example/lib/src/scenarios/same_step_hints_scenario.dart
example/lib/src/scenarios/same_step_auto_scroll_scenario.dart
example/lib/src/scenarios/lazy_target_reveal_scenario.dart
example/lib/src/scenarios/dynamic_steps_scenario.dart
example/lib/src/scenarios/side_anchor_scenario.dart
example/lib/src/scenarios/large_group_anchor_scenario.dart
example/lib/src/scenarios/custom_anchor_scenario.dart
example/lib/src/scenarios/controller_usage_scenario.dart
```

Run it with:

```sh
cd example
flutter run -d ios
```

## Basic Usage

```dart
SpotlightGuidePortal(
  enabled: shouldShowGuide,
  steps: <SpotlightGuideStep>[
    SpotlightGuideStep.item(
      SpotlightGuideStepItem(
        targetId: 'more-button',
        hintBuilder: (BuildContext context, SpotlightGuideStepContext guide) {
          return SpotlightGuideBubbleHint(
            guide: guide,
            child: TextButton(
              onPressed: guide.next,
              child: const Text('Got it'),
            ),
          );
        },
      ),
    ),
  ],
  onFinish: markGuideSeen,
  child: SpotlightGuideTarget(
    id: 'more-button',
    child: IconButton(
      icon: const Icon(Icons.more_horiz),
      onPressed: openMore,
    ),
  ),
)
```

## Multiple Hints In One Step

Use `SpotlightGuideStep(items: ...)` when several hints should appear together. A single item can also highlight several targets with `targetIds`.

```dart
SpotlightGuideStep(
  items: <SpotlightGuideStepItem>[
    SpotlightGuideStepItem(targetId: 'calendar', hintBuilder: buildCalendarHint),
    SpotlightGuideStepItem(targetId: 'more', hintBuilder: buildMoreHint),
  ],
)
```

## Repeated Target IDs

When several mounted `SpotlightGuideTarget` widgets use the same `id`, the
component treats them as one logical target group. All instances are highlighted
and the default placement anchor is the union of that group. The guide does not
pick the first or last mounted instance.

If the group should be highlighted but one instance should be the precise
anchor, set `anchorId` on that `SpotlightGuideTarget` and point
`anchorTargetId` at it. This keeps the target in the normal registration chain,
so insertion, removal, and active hint rebuilds continue to work.

```dart
SpotlightGuideTarget(
  id: 'summary-card-group',
  anchorId: 'summary-total-cost-anchor',
  child: totalCostCard,
)

SpotlightGuideStepItem(
  targetId: 'summary-card-group',
  anchorTargetId: 'summary-total-cost-anchor',
  hintBuilder: buildTotalCostHint,
)
```

For repeated list rows where only one row should be highlighted, use a unique id
such as `order-row-${order.id}` or use `targetKey`.

## Dynamic Or API-Driven Steps

For automatic guides, rebuild `steps` after data loads. A portal without an
external controller starts when `steps` first becomes non-empty.

```dart
SpotlightGuidePortal(
  steps: guideStepsFromServer,
  child: page,
)
```

For user-controlled or scenario-triggered guides, keep a controller and call
`showSteps`. `steps` can be omitted on the portal when all guide content comes
from an API or another runtime decision.

```dart
final controller = SpotlightGuidePortalController();

SpotlightGuidePortal(
  controller: controller,
  autoStart: false,
  missingTargetBehavior: SpotlightGuideMissingTargetBehavior.skip,
  child: page,
);

final List<SpotlightGuideStep> steps = buildGuideSteps(response);
if (steps.isEmpty) {
  controller.hide();
} else {
  controller.showSteps(steps);
}
```

When guide steps come from an API, set
`missingTargetBehavior: SpotlightGuideMissingTargetBehavior.skip` on the portal
so stale or inapplicable target ids do not leave a blank guide active. If one
specific item is expected to appear later, override that item back to `wait`.
Skipped unavailable steps are removed from the active sequence, so
`controller.total`, `controller.isLast`, and the same values in
`SpotlightGuideStepContext` update as if those steps had been removed from the
list.

Use `onStateChanged` when external state depends on dynamic target availability
or guide progress. It fires when a step is shown, hidden, when portal steps
change while active, and when targets register or unregister.

```dart
SpotlightGuidePortal(
  onStateChanged: (SpotlightGuideStateContext state) {
    debugPrint(
      'guide ${state.index + 1}/${state.total}, '
      'resolved=${state.resolvedItemCount}',
    );
  },
  steps: steps,
  child: page,
)
```

## Scroll And Lazy Targets

If a target is already built but outside a scrollable viewport, the default
`SpotlightGuideRevealOptions` calls `Scrollable.ensureVisible`. It does not
scroll when the target is already fully visible. Use
`scrollPolicy: SpotlightGuideRevealScrollPolicy.always` when a step should
always realign the target, or `visibilityPadding` when sticky headers or bottom
bars should count as unsafe space. During reveal scrolling, the default
presentation keeps the barrier visible and waits until scrolling/layout settles
before showing hints and spotlight holes. Use
`SpotlightGuideLiveRevealPresentationStrategy` when an app intentionally wants
resolved hints and holes to track animated scrolling.

When one hint highlights a large `targetIds` group, set `anchorTargetId` to the
main target. If the full group is too large to fit, default reveal prioritizes
the anchor, so an already visible anchor will not scroll the page just because
the larger highlighted area extends outside the viewport. Override
`scrollTargetPolicy` when a page needs different behavior.

```dart
SpotlightGuideRevealOptions(
  scrollTargetPolicy: SpotlightGuideRevealScrollTargetPolicy.anchorTarget,
)
```

If a target is not built yet, such as a lazy list row, use `onReveal` to scroll close to it, switch tabs, expand a section, or load data. After the callback completes, the portal waits for layout and then applies the default reveal behavior.

```dart
SpotlightGuideStepItem(
  targetId: 'order-row-50',
  onReveal: (SpotlightGuideRevealContext context) async {
    await context.scrollToIndex(
      controller: listController,
      index: 50,
      itemExtent: rowHeight,
      alignment: 0.2,
    );
  },
  revealOptions: const SpotlightGuideRevealOptions(
    alignment: 0.5,
    duration: Duration(milliseconds: 250),
  ),
  hintBuilder: buildHint,
)
```

For multiple items in the same step, `SpotlightGuideStepAutoScrollOptions` can briefly scroll to hidden later targets so users understand the whole introduced area. It is enabled by default and starts when a later target is not fully visible, or when a not-yet-built later target provides an `onReveal` hook. During the default auto-scroll transition, the outgoing hint is hidden before scrolling starts and the next hint appears after the target settles, so hints do not detach from moving or offscreen targets. Use `autoScrollOptions.onAutoScrollItemChanged` to react when that focused item changes. The callback receives [SpotlightGuideAutoScrollItemContext] with `itemIndex`, `itemTotal`, `highlightTargetIds`, and optional [SpotlightGuideStepItem.key]. Use one item with `targetIds` when a single hint should light several registered targets at once.

## Barrier Style

Configure the guide background with `SpotlightGuideBarrierStyle`. Color and
blur are clipped to the dimmed area, so highlighted targets keep their original
brightness and sharpness. Set it on `SpotlightGuidePortal` for a shared default;
set it on a `SpotlightGuideStep` to override only the fields that step needs.
Visual holes are clipped to the visible overlay before painting, so oversized
targets keep their rounded corners inside the screen.

```dart
SpotlightGuidePortal(
  barrier: const SpotlightGuideBarrierStyle(
    color: Color(0x99000000),
    blurSigma: 4,
  ),
  steps: <SpotlightGuideStep>[
    SpotlightGuideStep(
      // Keeps the portal blur, only changes the color for this step.
      barrier: const SpotlightGuideBarrierStyle(color: Color(0x66000000)),
      items: items,
    ),
  ],
  child: page,
)
```

## Barrier Taps

The dim barrier absorbs taps so they never reach the page behind the guide. By
default, tapping empty space does not close or advance the guide.

Use `barrierDismissBehavior` for common close behavior:

```dart
SpotlightGuidePortal(
  barrierDismissBehavior: SpotlightGuideBarrierDismissBehavior.onComplete,
  steps: steps,
  child: page,
)
```

`onComplete` only finishes after the last step is visible and any same-step
auto-scroll sequence has reached its final item. Use `anytime` when the product
intentionally allows closing mid-flow.

Provide `onBarrierTap` for custom behavior such as tap-anywhere-to-continue.
The callback receives the active controller, so this works even without
supplying an external one.

```dart
SpotlightGuidePortal(
  onBarrierTap: (controller) => controller.next(),
  steps: steps,
  child: page,
)
```

## Tap The Highlighted Target

Set `allowTargetInteraction: true` on an item to let taps inside its spotlight
hole pass through to the real widget behind the guide. This is the "tap this
button to continue" pattern. The barrier keeps absorbing taps everywhere else.
Only the target rect itself passes through; the surrounding `targetPadding`
band stays absorbed so a neighbouring control is not hit by accident.

```dart
SpotlightGuideStep.item(
  SpotlightGuideStepItem(
    targetId: 'send-button',
    allowTargetInteraction: true,
    hintBuilder: (context, guide) => const Text('Tap send to continue'),
  ),
)
```

## Stepping Back And Jumping

The controller can start the portal-owned sequence with `showPortal()` or a
runtime sequence with `showSteps(steps)`. The controller and the `guide` context
inside a `hintBuilder` can both navigate or close the active guide with
`next()`, `previous()`, `goTo(index)`, `reset()`, `hide()`, and `finish()`.
`previous()` is a no-op on the first step, and `goTo` clamps the index.
`hide()` closes without `onFinish`; `finish()` closes and reports completion.

```dart
controller.showPortal();
controller.showSteps(steps);
controller.previous();
controller.goTo(2);
controller.hide();
```

## RTL And Anchors

Use `SpotlightGuideAnchorPosition.start`, `center`, or `end` for semantic alignment. `start` and `end` follow `Directionality`, so Arabic and other RTL layouts mirror correctly.

## Custom UI

`hintBuilder` may return:

- `SpotlightGuideBubbleHint` for a common bubble plus optional pointer image.
- `SpotlightGuideBubble` for a connected bubble arrow without pointer.
- Any custom widget, image composition, or app-specific guide UI.

The layout data is available through `SpotlightGuideStepContext`.
Use `guide.indicatorDirection` when a custom hint needs to know which physical
side the anchor is on. For example, a hint placed below a target has an
`up` indicator because the anchor sits on the bubble's top edge and points
toward the target. Path-based custom anchors can read the same resolved side
from `SpotlightGuideAnchorPathBuilder.direction` inside `addToPath`.

For the full API and built-in hint catalog, see `doc/reference.md`.
