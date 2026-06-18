# Spotlight Guide Troubleshooting

Use this when a guide looks wrong in a product screen.

## Hint Does Not Show

Check:

- `SpotlightGuidePortal.enabled` is true.
- `steps` is not empty.
- If `autoStart` is false, or an external controller is supplied without
  `autoStart: true`, call `controller.showPortal()`,
  `controller.showSteps(steps)`, `controller.reset()`, or
  `controller.goTo(index)` after the steps are ready.
- The active item uses at most one of `targetId`, `targetIds`, or `targetKey` (they are mutually exclusive). Providing none of them highlights the whole `SpotlightGuidePortal.child`.
- The target is mounted and laid out.
- For lazy lists, add `SpotlightGuideStep.onReveal` or `SpotlightGuideStepItem.onReveal` to scroll close to the target first.
- For API-driven optional targets, use
  `missingTargetBehavior: SpotlightGuideMissingTargetBehavior.skip` so a stale
  target id is skipped instead of waiting forever.

Related tests:

```sh
flutter test --no-pub test/spotlight_guide/spotlight_guide_targets_test.dart
flutter test --no-pub test/spotlight_guide/spotlight_guide_reveal_test.dart
```

## API-Driven Guide Does Not Start After The Request

For automatic display, rebuild the portal with a non-empty `steps` list and keep
`enabled` true. A portal without an external controller starts automatically
when steps first become available. If a controller is supplied, set
`autoStart: true` or manually call `controller.showSteps(steps)`.

For user-triggered display, prefer:

```dart
final List<SpotlightGuideStep> steps = buildGuideSteps(response);
if (steps.isEmpty) {
  controller.hide();
} else {
  controller.showSteps(steps);
}
```

`hide()` closes the current guide without calling `onFinish`.

If the response may include targets that are not available in this page state,
set the portal default to skip:

```dart
SpotlightGuidePortal(
  missingTargetBehavior: SpotlightGuideMissingTargetBehavior.skip,
  child: page,
)
```

If another part of the page needs to know that optional targets changed, use
`onStateChanged`. Target insertion/removal fires with
`SpotlightGuideStateChangeReason.targetsChanged`, and
`resolvedItemCount` reports how many items in the active step can currently be
drawn.

Skipped unavailable steps are removed from the active sequence. If a future
target disappears while the current hint is visible, the current hint rebuilds
with the new `total` and `isLast`, and `onStateChanged` fires with
`targetsChanged`.

Related tests:

```sh
flutter test --no-pub test/spotlight_guide/spotlight_guide_controller_test.dart
```

## Target Is Dimmed Instead Of Cut Out

The target must be inside `SpotlightGuidePortal.child` and wrapped by `SpotlightGuideTarget`, or referenced by a valid `GlobalKey`.

If the real widget is replaced by an image in the hint, the barrier cannot cut out the real button. Keep the real widget in the page and put only decorative pointer/bubble UI in `hintBuilder`.

## Oversized Hole Corners Look Cut Off

The barrier clips visual holes to the visible overlay before painting. If a
target is wider than the screen, the clipped hole keeps its rounded corners
inside the screen instead of letting them disappear offscreen. Placement still
uses the target or anchor rect expanded by `targetDecoration.padding`, and
`allowTargetInteraction` still uses the unpadded real target rect.

## A Live Reveal Leaves Only The Spotlight Hole

The default reveal presentation hides hints and holes until scrolling settles.
When `SpotlightGuideLiveReveal` is used, the portal rebuilds
while the target scrolls so the hole tracks the moving widget. The hint
measurement cache must survive those geometry-only updates; otherwise the
barrier can keep painting while the visible hint waits forever for a size that
was already measured. If this regresses, run the reveal tests below.

Related tests:

```sh
flutter test --no-pub test/spotlight_guide/spotlight_guide_reveal_test.dart
```

## Anchor And Bubble Look Split

Use `SpotlightGuideBubble` or `SpotlightGuideBubbleHint` with `SpotlightGuideBubbleDecoration`. The built-in decoration paints the bubble and triangle anchor as one path.

If the anchor is near a rounded corner, set the bubble radius and anchor on the decoration. Layout uses the anchor connection range plus the radius to keep the connection away from the unsafe corner area:

```dart
decoration: const SpotlightGuideBubbleDecoration(
  borderRadius: 8,
  anchor: SpotlightGuideTriangleAnchor(size: Size(24, 16)),
)
```

Related tests:

```sh
flutter test --no-pub test/spotlight_guide/spotlight_guide_layout_test.dart
```

## Anchor Is Not Aligned With Pointer

Remember the anchor chain:

```text
pointerTargetPosition(mainAxisOffset, crossAxisOffset) -> pointer layout slot -> anchorPointerPosition -> gap -> bubble anchor tip
```

If there is no pointer, `anchorTargetPosition` resolves on the target directly
and the bubble anchor points to that target point.

With the default pointer chain, `pointerTargetPosition` chooses the target-side
point and aligns the pointer's matching start, center, or end point to it.
`anchorPointerPosition` chooses where the bubble anchor attaches to the
pointer. Use
`SpotlightGuidePointPosition.crossAxisOffset` for the pointer's distance from
the target side and `SpotlightGuideStepItem.gap` for the
pointer-to-bubble-anchor distance. If the bubble has no anchor, the hint edge
is treated as the anchor tip. Without a pointer, `anchorTargetPosition`
resolves on the target directly and `gap` is the target-to-bubble distance.

Use `pointerTargetPosition` with a main-axis and optional cross-axis offset,
such as `SpotlightGuidePointPosition.center(-30, -8)`, when the pointer itself
should sit away from the target contact point. Most cases should use `center()`,
`center(x)`, `start(x)`, or `end(x)`.

For `start` and `end`, positive values are insets from the referenced edge and
negative values move outward beyond that edge. For example, `end(16)` aligns
the pointer end edge to a target point 16px inward from the target end edge,
while `end(-16)` aligns it 16px outward beyond that edge. `anchorTargetPosition`
and `anchorPointerPosition` use the same signed edge rule, but they only move
the anchor point, not the target or pointer widget.

The pointer's layout slot is the source of truth. If the child is wrapped in a
red `Container`, that full red rectangle is the pointer. If an image has
transparent padding and the visible fingertip should align instead, crop the
asset, adjust the `size` or wrapper, or use `pointerTargetPosition` offsets to
align the intended visual point.

If a pointer is present but should not become part of the anchor chain, set
`SpotlightGuidePointer(anchorMode: SpotlightGuidePointerAnchorMode.target,
...)`. The pointer still renders, but the bubble anchor stays aligned directly
with the target and `gap` stays the target-to-bubble distance.

Related tests:

```sh
flutter test --no-pub test/spotlight_guide/spotlight_guide_pointer_test.dart
flutter test --no-pub test/spotlight_guide/spotlight_guide_safe_area_test.dart
```

## Pointer Image Jumps On First Display

Configure pointers on `SpotlightGuideStepItem.pointer` and give image pointers
a stable layout slot. Item-level pointer metadata lets the default reveal logic
reserve pointer space before the hint is built. Flutter images that specify
only width or only height can report a transient zero size on the other axis
before decode, then relayout after the image dimensions are known. When the
dimensions are known, prefer:

```dart
SpotlightGuidePointer(
  size: const Size(68, 103),
  child: Image.asset(
    'assets/guide_pointer.png',
    width: 68,
    height: 103,
    cacheWidth: 136,
    cacheHeight: 206,
    fit: BoxFit.contain,
  ),
)
```

For large pointer images, set `cacheWidth` and `cacheHeight` near the displayed
pixel size so Flutter decodes a smaller bitmap. This improves memory use
without changing the guide layout slot.

If `SpotlightGuidePointer.size` is omitted, the pointer can still use its
natural child size, but automatic reveal scrolling cannot reserve that final
pointer width or height before the hint render pass.

When the height should stay natural and the app only knows the width, wrap the
image in a paint gate instead of guessing the height:

```dart
SpotlightGuidePaintGate(
  requireNonEmptySize: true,
  child: Image.asset(
    'assets/guide_pointer.png',
    width: 68,
  ),
)
```

`SpotlightGuideBubbleHint` also guards against this internally: if a pointer
uses natural child size and the pointer child reports a transient zero width or
height, that intermediate frame is not painted or hit tested, and the target
hole is not exposed ahead of the hint. Once the child has a valid laid-out
size, the target hole, pointer, and bubble are shown from the same stable
layout. If a custom pointer is intentionally zero-sized, remove the pointer or
provide an explicit `size` for the desired anchor slot.

Related tests:

```sh
flutter test --no-pub test/spotlight_guide/spotlight_guide_pointer_test.dart
```

## Repeated Target ID Picks The Wrong Anchor

If several mounted `SpotlightGuideTarget` widgets share the same id, the guide
does not choose one of them. It highlights all of them as one group and uses the
group union for placement. If `anchorTargetId` points at a repeated id, that
anchor is also a group.

When the product wants to highlight the group but point at one chosen widget,
set `anchorId` on that `SpotlightGuideTarget` and use it as the anchor:

```dart
SpotlightGuideTarget(
  id: 'feature-card-group',
  anchorId: 'feature-card-anchor',
  child: card,
)

SpotlightGuideStepItem(
  targetId: 'feature-card-group',
  anchorTargetId: 'feature-card-anchor',
  hintBuilder: buildHint,
)
```

For one specific item in a repeated list, prefer a unique id such as
`row-${item.id}` or use `targetKey`.

## Offset Works In LTR But Not RTL

Use `SpotlightGuideAnchorPosition.start`, `center`, or `end` instead of
hard-coded left/right logic. `start` and `end` mirror in RTL on horizontal axes.
Positive edge offsets move inward and negative edge offsets move outward.

Related tests:

```sh
flutter test --no-pub test/spotlight_guide/spotlight_guide_layout_test.dart
```

## Scroll Does Not Move To A Lazy List Target

`Scrollable.ensureVisible` only works for mounted targets. If a list row has not
been built yet, first scroll to the approximate row position in `onReveal`.
`context.scrollToIndex` and `context.scrollToOffset` use the same default
duration and curve as built-in reveal scrolling; pass `Duration.zero` when the
setup should jump instantly.

```dart
SpotlightGuideStepItem(
  targetId: 'row-60',
  onReveal: (SpotlightGuideRevealContext context) async {
    await context.scrollToIndex(
      controller: scrollController,
      index: 60,
      itemExtent: rowExtent,
      alignment: 0.2,
    );
  },
  hintBuilder: buildHint,
)
```

Use `context.scrollToOffset` when the page can compute an offset but not a fixed
row index. After the helper returns, the portal waits for layout and resolves
the target again.

## Target Is Already Visible But The Page Still Scrolls

The default reveal policy is
`SpotlightGuideRevealScrollPolicy.onlyIfNeeded`, so a fully visible target
should not move. If it still scrolls, check whether the target is only partially
visible after sticky headers, bottom bars, or desired visual padding are
considered. Set `visibilityPadding` to describe that unsafe area.

For a large `targetIds` group, set `anchorTargetId` to the most important target.
When the whole highlighted group is too large to fit in the viewport, the
default policy treats that anchor as the visibility priority. If the anchor is
already fully visible, the page should not scroll just because the larger
highlighted group extends off-screen.

If the product really wants the large highlighted area to drive scrolling, set:

```dart
revealOptions: const SpotlightGuideRevealOptions(
  targetPolicy: SpotlightGuideRevealTargetPolicy.highlightedArea,
)
```

Use `scrollPolicy: SpotlightGuideRevealScrollPolicy.always` only when a product
intentionally wants each step to realign the target.

## A Late Target Is Skipped

If the portal uses `SpotlightGuideMissingTargetBehavior.skip`, an unresolved
target is skipped after reveal preparation. For a target that is expected to
mount later, override the item:

```dart
SpotlightGuideStepItem(
  targetId: 'late-target',
  missingTargetBehavior: SpotlightGuideMissingTargetBehavior.wait,
  hintBuilder: buildHint,
)
```

## Same-Step Multi-Item Scroll Does Not Happen

Same-step scroll starts only when:

- `SpotlightGuideStep.items.length > 1`.
- `autoScrollOptions.enabled` is true.
- A later item has mounted target contexts, or has an `onReveal` hook that can
  build a not-yet-mounted target.
- That later item is not fully visible, unless `skipVisibleItems` is false.
- The item reveal options are enabled.

A later item whose rect is exactly flush to the viewport edge counts as fully
visible, so it does not trigger auto scroll. This is intentional and keeps the
component from leaving a pending interval timer for items that are already on
screen.

A later item's `onReveal` runs at its auto-scroll turn (after the interval), not
during initial step preparation, so it cannot scroll away from the first hint.

## A Later Same-Step Hint Does Not Appear

A same-step scroll overlay renders each item whose target has resolved and
overlaps the viewport when live reveal presentation is used. With the default
presentation, the outgoing hint is hidden before scrolling starts and the later
hint appears after scrolling settles. It skips unresolved targets and targets
that are entirely off-screen so a hint is not clamped onto the screen while its
target is elsewhere. The later hint appears once scroll brings any part of
its target into view (a target larger than the viewport counts as soon as it
overlaps). If a later
hint never appears, check that the item either keeps its target mounted or
provides an `onReveal` that scrolls or expands the target into the tree. For the
smoothest sequencing, keep the earlier targets mounted (such as in a fixed
header) so they stay visible while the later one is scrolled in.

## Disabling The Portal Or Clearing Steps

Toggling `enabled` to false or rebuilding with an empty `steps` list while the
guide is visible closes the overlay safely. The hint stops painting immediately,
and the overlay hide is deferred when Flutter is in the build phase.

Related tests:

```sh
flutter test --no-pub test/spotlight_guide/spotlight_guide_controller_test.dart
```

## onFinish Does Not Fire When Steps Are Cleared

Clearing the `steps` list while the guide is active finishes the guide and calls
`onFinish`. Make sure the rebuild still passes the same `onFinish`, since the
portal reads the current widget when it notifies. Disabling the portal with
`enabled: false` hides the guide without calling `onFinish` by design.

Related tests:

```sh
flutter test --no-pub test/spotlight_guide/spotlight_guide_controller_test.dart
```

## Tapping Outside The Bubble Does Nothing

This is intentional. The barrier absorbs taps so they cannot reach the page
behind the guide. If you want a tap on the dim area to close the guide only
after the flow is complete, set
`barrierDismissBehavior: SpotlightGuideDismissBehavior.onComplete`.
Use `SpotlightGuideDismissBehavior.anytime` only when closing mid-flow is
intentional.

For custom behavior such as tap-anywhere-to-continue, set
`SpotlightGuidePortal.onBarrierTap`. It receives the active controller, so call
`(controller) => controller.next()` or `(controller) => controller.finish()`
from it. No external controller is required.

Related tests:

```sh
flutter test --no-pub test/spotlight_guide/spotlight_guide_controller_test.dart
```

## Tapping The Highlighted Target Does Nothing

By default the barrier absorbs taps over the spotlight hole too. To let the user
press the real highlighted widget, set `allowTargetInteraction: true` on that
item. If it still does not work, confirm the overlay wrapper is a
`MaterialType.transparency` `Material`: a default `Material` (canvas, card, or
button type) absorbs pointer events and silently blocks the pass-through even
though the barrier correctly punches the hole.

Related tests:

```sh
flutter test --no-pub test/spotlight_guide/spotlight_guide_hint_test.dart
```

## Hot Reload Or Rebuild Resets State

Controller replacement should absorb active state. If this regresses, run:

```sh
flutter test --no-pub test/spotlight_guide/spotlight_guide_controller_test.dart
```
