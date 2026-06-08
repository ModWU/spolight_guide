# Spotlight Guide Reference

This reference combines public API relationships and the built-in hint catalog. Read it when a new feature feels like it needs another positioning, scrolling, or hint parameter.

## Step Structure

```text
SpotlightGuidePortal
  steps: List<SpotlightGuideStep> = []
    items: List<SpotlightGuideStepItem>
      targetId / targetIds / targetKey
      hintBuilder
```

- Use multiple `SpotlightGuideStep`s for sequential guide moments.
- Use multiple `SpotlightGuideStepItem`s in one step when several hints should appear together.
- Use one item with `targetIds` when one hint should highlight multiple target areas.
- For API-driven steps, rebuild `steps` for automatic display, or call
  `SpotlightGuidePortalController.showSteps(steps)` for a scenario-triggered
  runtime sequence.

## Target Selection

| Parameter | Owner | Meaning |
| --- | --- | --- |
| `targetId` | `SpotlightGuideStepItem` | Points to one `SpotlightGuideTarget.id`. Multiple mounted targets with the same id are treated as one group. |
| `targetIds` | `SpotlightGuideStepItem` | Highlights several ids for one hint. |
| `anchorId` | `SpotlightGuideTarget` | Optional id for selecting this mounted target as an anchor while its `id` still participates in group highlighting. |
| `anchorTargetId` | `SpotlightGuideStepItem` | Chooses which highlighted id or `SpotlightGuideTarget.anchorId` drives hint placement. Without it, the union rect drives placement. |
| `targetKey` | `SpotlightGuideStepItem` | Points directly to a `GlobalKey` target and is mutually exclusive with id-based targeting. |
| `missingTargetBehavior` | `SpotlightGuidePortal` / `SpotlightGuideStepItem` | Controls unresolved targets after reveal preparation. Portal default is `wait`; item value overrides it. Use `skip` for API-driven guides with optional targets. |
| `allowTargetInteraction` | `SpotlightGuideStepItem` | When true, taps over this item's target rect pass through to the real widget behind the guide instead of being absorbed by the barrier. Only the unpadded target rect passes through; the `targetPadding` band stays absorbed. Default false. |

When an item provides none of `targetId`, `targetIds`, or `targetKey`, the
whole `SpotlightGuidePortal.child` rect becomes the target. This is useful for a
full-area introduction hint, but reveal scrolling does not apply because there
is no specific target context to make visible.

Repeated target ids are intentional group semantics. If three mounted
`SpotlightGuideTarget(id: 'feature')` widgets exist, `targetId: 'feature'`
highlights all three and uses their union rect for placement. Do not rely on
mount order to choose one instance. Set `anchorId` on the instance that should
drive the bubble anchor, then pass that value to `anchorTargetId`.

If `anchorTargetId` points at an id that has multiple mounted targets, those
targets are treated as an anchor group. If it does not match a highlighted id,
the resolver looks for a highlighted `SpotlightGuideTarget.anchorId` with that
value. Unknown anchors fall back to the highlighted group's union rect.

When a targeted item cannot resolve its target after `onReveal` and default
reveal preparation, `SpotlightGuideMissingTargetBehavior.wait` keeps the guide
active so the target can appear later. `skip` drops that unresolved item. If all
items in the current step are skipped, the portal advances to the next step or
closes without firing `onFinish` when no guide content was shown.

For `skip`, unavailable steps without a reveal path are removed from the active
sequence, including future steps. If step 3's target is removed while step 2 is
visible, step 2 rebuilds and reports `total == 2` and `isLast == true`.
`onStateChanged` fires with `targetsChanged` so outside state can react.

When `targetIds` and `anchorTargetId` are used together, every id contributes a
spotlight hole. Overlapping or nested holes are merged before the barrier is
painted, so a child target inside a larger highlighted area stays clear instead
of becoming dim again. Placement uses `anchorTargetId` or the matching
`anchorId`; reveal scrolling uses
`SpotlightGuideRevealOptions.scrollTargetPolicy` to decide whether the
highlighted area or the anchor target drives visibility. This supports cases
such as highlighting a whole summary row while aiming the bubble anchor at the
center card in that row.

## Controller Navigation

`SpotlightGuidePortalController` exposes the commands below. Commands issued
before the portal mounts are queued and replayed once it attaches.

`SpotlightGuideStepContext` mirrors the active-guide commands used inside a
hint: `next`, `previous`, `goTo`, `reset`, `hide`, and `finish`.

| Method | Meaning |
| --- | --- |
| `next()` | Advance to the next step; finishes the guide on the last step. |
| `previous()` | Step back one. No-op on the first step; never finishes. |
| `goTo(index)` | Jump to a step. The index is clamped to the valid range, and the guide is shown if it was hidden. |
| `reset()` | Restart from the first step and show the guide. |
| `showPortal(index: 0)` | Show `SpotlightGuidePortal.steps` through the controller. Useful when auto-start is disabled but the portal owns the steps. |
| `showSteps(steps, index: 0)` | Replace the current runtime sequence with `steps` and show it. Useful after an API response or a user action. Empty steps close the active runtime guide without firing `onFinish`. |
| `hide()` | Close the guide without firing `onFinish`. |
| `finish()` | Close the guide and fire `onFinish` when a guide was active. |

Runtime steps supplied by `showSteps` take priority over
`SpotlightGuidePortal.steps` for that controller until another `showSteps`
replaces them or `showPortal` switches back to portal steps. Navigation
commands such as `next`, `previous`, `goTo`, and `reset` operate on the active
sequence.

## Portal Callbacks

| Parameter | Owner | Meaning |
| --- | --- | --- |
| `onStepWillShow` | `SpotlightGuidePortal` | Page-level async preparation before a step is revealed. |
| `autoStart` | `SpotlightGuidePortal` | Controls startup. By default, a portal without an external controller auto-starts, and a portal with an external controller waits for controller commands. Set true to auto-start even with a controller, or false to show only through controller commands. |
| `onStateChanged` | `SpotlightGuidePortal` | Fires after a step is shown, after the guide hides, after active portal steps change, and after targets register or unregister while the guide is active. The callback receives `index`, `total`, `isFirst`, `isLast`, `isShowing`, and `resolvedItemCount`. |
| `onFinish` | `SpotlightGuidePortal` | Called once when the guide finishes through `next` on the last step, `finish`, or when the steps become empty while active. Not called when `enabled` is toggled off. |
| `barrierDismissBehavior` | `SpotlightGuidePortal` | Built-in empty-space close behavior. Defaults to `disabled`; `onComplete` finishes only after the last step/final same-step item is presented; `anytime` finishes even mid-flow. |
| `onBarrierTap` | `SpotlightGuidePortal` | Custom barrier tap reaction. The barrier absorbs taps everywhere except over targets with `allowTargetInteraction`; this hook can implement `(controller) => controller.next()` for "tap anywhere to continue" and takes precedence over `barrierDismissBehavior`. |

## Barrier Style

| Parameter | Owner | Meaning |
| --- | --- | --- |
| `barrier` | `SpotlightGuidePortal` | Shared default background style inherited by every step. |
| `barrier` | `SpotlightGuideStep` | Step-level background override. Null fields inherit from the portal style, then the built-in fallback. |
| `color` | `SpotlightGuideBarrierStyle` | Color painted over the non-highlighted area. Null means inherit. |
| `blurSigma` | `SpotlightGuideBarrierStyle` | Background blur applied only to the non-highlighted area. Target holes stay clear and unblurred. Null means inherit. |

Barrier style on the portal describes the common atmosphere for the whole guide. Barrier style on a step describes that one onboarding moment and only overrides the fields it sets. Target hole padding, radius, and pass-through interaction stay on `SpotlightGuideStepItem` because different highlighted widgets may need different holes.

Target holes are clipped to the visible overlay before the barrier is painted.
This keeps rounded hole corners visible when a target is wider or taller than
the screen, while placement and pass-through interaction still use the
unclipped target geometry.

Effective barrier style is resolved in this order:

```text
built-in fallback -> SpotlightGuidePortal.barrier -> SpotlightGuideStep.barrier
```

## Placement And Anchor

| Parameter | Owner | Meaning |
| --- | --- | --- |
| `placement` | `SpotlightGuideStepItem` | Preferred hint side. Default is `verticalAuto`. |
| `targetAnchorPosition` | `SpotlightGuideStepItem` | Semantic anchor on the target. It drives the pointer position when a pointer is present, otherwise it drives the visual anchor directly. |
| `gap` | `SpotlightGuideStepItem` | Main-axis distance between target and hint rect. |
| `margin` | `SpotlightGuideStepItem` | Screen edge margin used by hint placement and min/max constraints. |

`SpotlightGuidePlacement.auto` may choose top, bottom, left, or right based on available space around the target. Auto placement uses the full overlay visible area because hints are painted in that overlay; a target's nearest scrollable viewport is used for reveal scrolling, not for choosing the hint side. The automatic side with the largest usable directional space wins, and after the hint is measured a side that can fit the measured hint is preferred.

`SpotlightGuidePlacement.verticalAuto` chooses top or bottom. This is the default because most guides are vertical.

`SpotlightGuidePlacement.horizontalAuto` chooses the physical left or right side with more available space.

`SpotlightGuideAnchorPosition.start` and `end` are semantic. In RTL, start means right and end means left on horizontal axes.

`SpotlightGuidePlacement.left` and `right` are physical screen sides. Use `SpotlightGuidePlacement.start` or `end` when the side should follow `Directionality`; in RTL, `start` resolves to physical right and `end` resolves to physical left.

`SpotlightGuideIndicatorDirection.up/down/left/right` is physical screen direction. It is not mirrored by RTL; semantic side placement is represented by `SpotlightGuidePlacement.start` and `end`.

## Pointer And Anchor

| Parameter | Owner | Meaning |
| --- | --- | --- |
| `pointer` | `SpotlightGuideBubbleHint` | Optional visual pointer, such as a hand image. |
| `pointerAnchorPosition` | `SpotlightGuideBubbleHint` | Anchor from pointer to bubble anchor, not from target to bubble anchor. Ignored when `pointer` is null. |
| `targetAnchorPosition` | `SpotlightGuideStepItem` | Target to pointer anchor when pointer exists; target to bubble anchor when pointer is null. |
| `decoration` | `SpotlightGuideStepItem` | Owns the built-in bubble shape, padding, border, shadow and visual anchor metadata. |
| `SpotlightGuideBubbleDecoration.anchor` | `SpotlightGuideBubbleDecoration` | Defaults to `SpotlightGuideTriangleAnchor`. Use `SpotlightGuideNoAnchor()` for no anchor, or provide a custom `SpotlightGuideBubbleAnchor`. |
| `SpotlightGuideTriangleAnchor.size` | `SpotlightGuideTriangleAnchor` | Triangle base width and height. |
| `SpotlightGuideTriangleAnchor.tipArcAngle` | `SpotlightGuideTriangleAnchor` | Rounds the triangle tip. Zero keeps a sharp point. |
| `SpotlightGuidePathAnchor` | `SpotlightGuideBubbleDecoration.anchor` | Generic path-driven anchor for custom Bezier arrows and non-triangle shapes. |
| `SpotlightGuidePathAnchorShape.connectionHalfExtent` | `SpotlightGuidePathAnchorShape` | Half of the bubble-edge opening. Keep this small for a pointed base. |
| `SpotlightGuidePathAnchorShape.visualHalfExtent` | `SpotlightGuidePathAnchorShape` | Half of the visual drawing range. This may be wider than the connection, so an arrow can have a narrow base and a broad head. |
| `SpotlightGuideAnchorPathBuilder` | `SpotlightGuidePathAnchorShape.addToPath` | Converts normalized side/outward coordinates into the current physical anchor direction, exposes that side through `direction`, and provides line/cubic helpers. |
| `SpotlightGuideProxyDecoration` | `SpotlightGuideStepItem.decoration` | Lets a regular Flutter `Decoration` participate in guide layout. Use the built-in bubble decoration when the anchor must visually connect to the body. |

Anchor chain:

```text
targetAnchorPosition -> pointer visual anchor -> pointerAnchorPosition -> bubble anchor
```

Without pointer:

```text
targetAnchorPosition -> bubble anchor
```

## Size Constraints

| Parameter | Owner | Meaning |
| --- | --- | --- |
| `minWidth` / `minHeight` | `SpotlightGuideStepItem` | Minimum hint size after margin and available space are considered. |
| `maxWidth` / `maxHeight` | `SpotlightGuideStepItem` | Maximum hint size after margin and available space are considered. |

If max width or height is `double.infinity`, the hint expands to the maximum available space on that axis. Otherwise the hint wraps content until it reaches the resolved max size.

Margins reduce the available space before min/max constraints are applied.

## Reveal And Scroll

| Parameter | Owner | Meaning |
| --- | --- | --- |
| `onStepWillShow` | `SpotlightGuidePortal` | Page-level preparation hook before reveal. |
| `revealPresentationStrategy` | `SpotlightGuidePortal` | Controls whether hints/holes are hidden or kept live while reveal scrolling prepares a target. The default hides content until scrolling/layout settles. |
| `onReveal` | `SpotlightGuideStep` | Step-level preparation, such as switching tabs or jumping close to a lazy list target. |
| `onReveal` | `SpotlightGuideStepItem` | Item-level preparation before default ensureVisible. For the first item it runs during step preparation; for later items in an auto-scroll step it is deferred until that item's auto-scroll turn. |
| `revealOptions` | `SpotlightGuideStep` | Default reveal behavior inherited by items. |
| `revealOptions` | `SpotlightGuideStepItem` | Item-specific reveal behavior. |
| `scrollPolicy` | `SpotlightGuideRevealOptions` | `onlyIfNeeded` by default, so default reveal scrolls only when a mounted target is outside the padded visible viewport. `always` calls `Scrollable.ensureVisible` every time. |
| `scrollTargetPolicy` | `SpotlightGuideRevealOptions` | Which area drives reveal scrolling: the full highlighted area, the anchor target, or the default anchor fallback when the highlighted area is too large to fit. |
| `visibilityPadding` | `SpotlightGuideRevealOptions` | Insets applied to the viewport before the `onlyIfNeeded` visibility check. Use it for sticky headers, bottom bars, or visual edge padding. |
| `autoScrollOptions` | `SpotlightGuideStep` | Same-step multi-item viewing aid for later hidden targets. |
| `autoScrollOptions.onAutoScrollItemChanged` | `SpotlightGuideStepAutoScrollOptions` | Fires with [SpotlightGuideAutoScrollItemContext] when sequential auto scroll focuses a new item (`itemIndex` starts at `0`). Exposes `highlightTargetIds`, `primaryHighlightTargetId`, and optional [SpotlightGuideStepItem.key]. Not called when every item is already on screen. |
| `key` | `SpotlightGuideStepItem` | Optional stable item label for copy or analytics. Not the same as [SpotlightGuideTarget.id]. |
| `highlightTargetIds` | `SpotlightGuideStepItem` | Read-only view of the registered target ids highlighted by the item (`targetId` or `targetIds`). |

Default reveal uses `Scrollable.ensureVisible` for already mounted targets only
when the target is not fully visible under `onlyIfNeeded`. The default
`SpotlightGuideDeferredRevealPresentationStrategy` shows only the barrier while
reveal scrolling or lazy-target preparation runs, then paints hints and holes
after layout settles. Use `SpotlightGuideLiveRevealPresentationStrategy`, or a
custom `SpotlightGuideRevealPresentationStrategy`, to keep resolved overlay
content live during reveal movement.
For an item with `targetIds` and `anchorTargetId`, `onlyIfNeeded` first tries to
keep the whole highlighted group visible when that group can fit in the padded
viewport. If the group is too large to fit, it uses the anchor target as the
visibility priority; a fully visible anchor will not scroll just because the
larger highlighted area extends outside the viewport.

`SpotlightGuideRevealScrollTargetPolicy.highlightedArea` keeps the highlighted
area as the reveal subject. `anchorTarget` uses the anchor target whenever it is
available in the current highlighted item. If `anchorTargetId` is missing or
does not belong to the item, reveal falls back to the highlighted area.
`anchorTargetWhenHighlightedAreaCannotFit` is the default, balancing complete
context for compact groups with stable anchor-first behavior for large groups.
Even with `highlightedArea`, an oversized target cannot become fully visible;
prefer the default or `anchorTarget` when the anchor is the important visual
focus.

For lazy list items that do not exist yet, use `onReveal` to scroll or load
until the target is built. `SpotlightGuideRevealContext` provides helpers for
common lazy-list preparation:

| Helper | Meaning |
| --- | --- |
| `scrollToOffset(controller, offset, ...)` | Jump or animate a `ScrollController` to an offset, clamp to scroll extents by default, then wait for layout. |
| `scrollToIndex(controller, index, itemExtent, ...)` | Convenience wrapper for fixed-extent lazy lists. |
| `waitForLayout(frames: 1)` | Wait for one or more layout frames before the portal resolves targets again. |

Same-step auto scroll is enabled by default. It starts when a later item is not fully visible, including a not-yet-built later item that provides an `onReveal` hook. For later items, `onReveal` runs at auto-scroll time (after the configured interval) instead of during initial preparation, so the first hint is seen before the guide scrolls on and a lazy target is only built when it is about to be revealed.

With the default reveal presentation strategy, a same-step auto-scroll overlay hides the outgoing hint before scrolling starts and shows the next hint only after that target settles. With live reveal presentation, the overlay renders only the items whose targets have resolved and currently overlap the viewport. When a later item is still hidden, only the highest renderable `itemIndex` is shown so users see one hint at a time. When every item is already on screen, all hints render together. Unresolved targets and targets that are entirely off-screen are skipped until auto scroll brings any part of them into view, so a hint is not clamped onto the screen while its target is elsewhere. (Overlap, not full containment, is used so a target larger than the viewport still shows its hint.) `SpotlightGuideStepContext.itemTotal` always reports the full step item count, even while only a subset is on screen.

## Built-In Hint Types

This component does not force one fixed guide UI. `SpotlightGuideStepItem.hintBuilder` can return any widget. The files under `src/hints/` are only built-in convenience implementations.

```text
src/hints/bubble.dart
  SpotlightGuideBubble
  A connected rounded rectangle plus arrow. Use this when no pointer image is needed.

src/hints/bubble_hint.dart
  SpotlightGuideBubbleHint
  A higher-level hint that combines an optional pointer image with SpotlightGuideBubble.

src/hints/bubble_decoration.dart
  SpotlightGuideBubbleDecoration
  Low-level Decoration for custom containers that still need the connected bubble-arrow shape.
```

Use `SpotlightGuideBubbleHint` when the hint needs a pointer image or pointer-to-arrow alignment.

Use `SpotlightGuideBubble` when the hint is only a bubble with arrow.

Use `SpotlightGuideBubbleDecoration` when you want a custom widget tree but still need the same connected bubble path.

Return a custom widget from `hintBuilder` when the guide is image-based, product-specific, animated, or does not look like a bubble.

Use `SpotlightGuideStepContext.indicatorDirection` when a fully custom hint
needs to draw differently for top, bottom, left, or right anchors. Use
`SpotlightGuideAnchorPathBuilder.direction` inside
`SpotlightGuidePathAnchorShape.addToPath` when only the bubble anchor shape
needs that side-specific logic. Both values are the final physical side after
auto placement and semantic `start`/`end` placement have resolved.

When adding a reusable built-in hint:

- Add it under `src/hints/`.
- Do not add business-specific copy or assets.
- Accept `SpotlightGuideStepContext` when the hint needs placement, arrow, or controller data.
- Preserve RTL semantics by using `SpotlightGuideAnchorPosition` instead of hard-coded left/right behavior.
- Add examples and tests.
