# Spotlight Guide Examples

## Quick Text Hint

Use `SpotlightGuideTextHint` for ordinary title/message guides. It provides
progress text and Back/Next/Done buttons, while still using the same placement
and decoration rules as fully custom hints.

```dart
SpotlightGuideStep.item(
  SpotlightGuideStepItem(
    targetId: 'more-button',
    hintBuilder: (BuildContext context, SpotlightGuideStepContext guide) {
      return SpotlightGuideTextHint(
        guide: guide,
        title: 'More actions',
        message: 'Open this menu for advanced options.',
      );
    },
  ),
)
```

Hide the built-in actions when outside-tap behavior or a target interaction
should complete the flow instead:

```dart
SpotlightGuideTextHint(
  guide: guide,
  title: 'Tap outside to close',
  message: 'This hint has no buttons.',
  showActions: false,
)
```

## Built-In Tap Pointer

Use `SpotlightGuidePointer` when the guide needs a visual cue between the
target and bubble. The pointer child can be anything: `SpotlightGuideTapPointer`
for a simple built-in tap cue, `Image.asset`, a Lottie animation, an icon badge,
or custom paint.

With the default pointer chain, `pointerTargetPosition` chooses the target-side
point where the pointer is placed, and `anchorPointerPosition` chooses where
the bubble anchor attaches to the pointer. Use
`SpotlightGuidePointPosition.crossAxisOffset` when the pointer itself should
move away from or back toward the target, and `SpotlightGuideStepItem.gap` for
the pointer-to-bubble-anchor distance. Custom pointers can omit `size` to use
their child layout size, or provide `size` when an asset needs a stable slot.
`anchorTargetPosition` and `anchorPointerPosition` use the one-dimensional
`SpotlightGuideAnchorPosition`. `pointerTargetPosition` uses
`SpotlightGuidePointPosition`, which also accepts an optional second value for
target-side cross-axis adjustment.

Configure pointers on `SpotlightGuideStepItem.pointer`. The portal can then
reserve the pointer target position, fixed pointer `size`, and
pointer-to-bubble `gap` before automatic reveal scrolling decides whether the
hint can fit.

For image pointers, use a stable slot. Flutter images that only specify width
or height can change layout after the image decodes, so set
`SpotlightGuidePointer.size` and give the image matching dimensions, or wrap
the image in another tight layout when the dimensions are known. If the asset is
much larger than its display size, pass `cacheWidth` and `cacheHeight` to
`Image` so Flutter decodes a more appropriate bitmap size.
Without `size`, the pointer still uses its natural child layout, but automatic
reveal scrolling cannot reserve the final pointer extent until the hint has
rendered.

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

When the height should remain natural, wrap the image in
`SpotlightGuidePaintGate(requireNonEmptySize: true)`. The guide keeps the target
hole and hint hidden until that child has a non-empty laid-out size:

```dart
SpotlightGuidePaintGate(
  requireNonEmptySize: true,
  child: Image.asset(
    'assets/guide_pointer.png',
    width: 68,
  ),
)
```

When the pointer artwork has direction, use `builder` instead of hard-coding a
side. The original `child` is still passed in, and the builder receives the
resolved `SpotlightGuidePointerContext`.

```dart
SpotlightGuideStepItem(
  targetId: 'more-button',
  gap: 10,
  pointer: SpotlightGuidePointer.tap(
    pointerTargetPosition: const SpotlightGuidePointPosition.center(2),
    builder: (
      BuildContext context,
      SpotlightGuidePointerContext pointer,
      Widget child,
    ) {
      return Transform.rotate(
        angle: pointer.rotationToTarget(),
        child: child,
      );
    },
  ),
  decoration: const SpotlightGuideBubbleDecoration(
    anchor: SpotlightGuideNoAnchor(),
  ),
  hintBuilder: (BuildContext context, SpotlightGuideStepContext guide) {
    return SpotlightGuideTextHint(
      guide: guide,
      title: 'Tap here',
      message: 'The pointer aligns with the resolved target anchor.',
    );
  },
)
```

If your pointer asset does not naturally point up, describe that source pose
instead of writing a placement switch. `up()` is the default source pose;
`upRight()` describes a northeast-facing asset, and `upRight(0)` is identical to
`upRight()`. The angle example below assumes `import 'dart:math' as math;`; the
final rotation still resolves against the current target side, so opposite
sides mirror the turn automatically.

```dart
Transform.rotate(
  angle: pointer.rotationToTarget(
    from: SpotlightGuidePointerDirection.right(math.pi / 2),
  ),
  child: child,
)
```

## Saving More Button Guide

This mirrors the saving page pattern: the real more button is highlighted by the barrier hole, while the pointer image and bubble are custom guide UI.

```dart
SpotlightGuidePortal(
  enabled: model.showMoreGuide,
  barrier: const SpotlightGuideBarrierStyle(blurSigma: 4),
  steps: <SpotlightGuideStep>[
    SpotlightGuideStep.item(
      SpotlightGuideStepItem(
        targetId: SavingGuideTargets.more,
        placement: SpotlightGuidePlacement.bottom,
        decoration: const SpotlightGuideBubbleDecoration(
          borderRadius: 8,
          anchor: SpotlightGuideTriangleAnchor(
            size: Size(24, 16),
            tipArcAngle: 0.35,
          ),
        ),
        pointer: SpotlightGuidePointer(
          child: Image.asset('assets/guide_pointer.png'),
          size: const Size(70, 54),
          pointerTargetPosition: const SpotlightGuidePointPosition.end(14),
          bubbleOffset: 100,
        ),
        hintBuilder: (BuildContext context, SpotlightGuideStepContext guide) {
          return SpotlightGuideBubbleHint(
            guide: guide,
            child: TextButton(
              onPressed: guide.finish,
              child: const Text('I know'),
            ),
          );
        },
      ),
    ),
  ],
  onFinish: controller.markMoreGuideSeen,
  child: SpotlightGuideTarget(
    id: SavingGuideTargets.more,
    child: IconButton(
      icon: const Icon(Icons.more_horiz),
      onPressed: openMoreActions,
    ),
  ),
)
```

## API-Driven Steps

When automatic display is allowed, rebuild the portal with the returned steps.
The first non-empty list starts when no external controller is supplied.

```dart
SpotlightGuidePortal(
  enabled: userAllowsAutoGuide,
  steps: buildGuideSteps(remoteGuideConfig),
  onFinish: markGuideSeen,
  child: page,
)
```

When the user disables automatic guides, or when a guide should appear after a
later scenario, keep a controller and show the runtime steps directly.

```dart
final SpotlightGuidePortalController guideController =
    SpotlightGuidePortalController();

SpotlightGuidePortal(
  controller: guideController,
  autoStart: false,
  missingTargetBehavior: SpotlightGuideMissingTargetBehavior.skip,
  onStateChanged: (SpotlightGuideStateDetails state) {
    trackGuideState(
      index: state.index,
      total: state.total,
      resolvedItemCount: state.resolvedItemCount,
      reason: state.reason,
    );
  },
  child: page,
);

Future<void> maybeShowGuide() async {
  final RemoteGuideConfig config = await api.fetchGuideConfig();
  final List<SpotlightGuideStep> steps = <SpotlightGuideStep>[
    if (config.showAnalyse)
      SpotlightGuideStep.item(
        SpotlightGuideStepItem(
          targetId: 'saving-analyse',
          hintBuilder: buildAnalyseHint,
        ),
      ),
    if (config.showMore)
      SpotlightGuideStep.item(
        SpotlightGuideStepItem(
          targetId: 'saving-more',
          hintBuilder: buildMoreHint,
        ),
      ),
  ];

  if (steps.isEmpty) {
    guideController.hide();
  } else {
    guideController.showSteps(steps);
  }
}
```

If one of the returned steps points at a target that is not present in the
current page state, the portal-level `skip` behavior removes it from the active
sequence. That means progress state updates as if the step were never returned:
`2 / 3` can become `2 / 2` and the current hint rebuilds with `isLast == true`.
For a lazy or conditionally inserted target that should be allowed to appear
later, override the item:

```dart
SpotlightGuideStepItem(
  targetId: 'lazy-row',
  missingTargetBehavior: SpotlightGuideMissingTargetBehavior.wait,
  onReveal: revealLazyRow,
  hintBuilder: buildLazyRowHint,
)
```

## Empty-Space Dismiss

The dim barrier absorbs taps by default. Opt in when empty-space taps should
close the guide:

```dart
SpotlightGuidePortal(
  barrierDismissBehavior: SpotlightGuideDismissBehavior.onComplete,
  steps: steps,
  child: page,
)
```

Use `onComplete` when outside taps should work only after the last step or final
same-step item is visible. Use `anytime` for lightweight introductions where the
user may dismiss immediately:

```dart
SpotlightGuidePortal(
  barrierDismissBehavior: SpotlightGuideDismissBehavior.anytime,
  steps: steps,
  child: page,
)
```

## Lazy List Row

Use `onReveal` when the row may not be mounted.

```dart
SpotlightGuideStepItem(
  targetId: 'history-row-40',
  onReveal: (SpotlightGuideRevealContext context) async {
    await context.scrollToIndex(
      controller: historyScrollController,
      index: 40,
      itemExtent: rowExtent,
      alignment: 0.2,
    );
  },
  revealOptions: const SpotlightGuideRevealOptions(
    alignment: 0.5,
    duration: SpotlightGuideRevealOptions.defaultDuration,
    curve: SpotlightGuideRevealOptions.defaultCurve,
  ),
  hintBuilder: buildHistoryHint,
)
```

The default reveal scrolls only if the mounted target is outside the visible
viewport. If a product deliberately wants every reveal to recenter the target,
set `scrollPolicy: SpotlightGuideRevealScrollPolicy.always`.
Scroll timing follows Flutter's `duration` and `curve` pattern. Use a longer
duration for nested lazy scrolling, or `Duration.zero` when setup should jump
instantly.

For one hint that lights a large group but should point at one important card,
set `anchorTargetId`. The default reveal scroll target policy uses the full
group when it can fit, then falls back to the anchor when the group is too
large:

```dart
SpotlightGuideStepItem(
  targetIds: const <Object>['summary-row', 'summary-cost'],
  anchorTargetId: 'summary-cost',
  revealOptions: const SpotlightGuideRevealOptions(
    targetPolicy:
        SpotlightGuideRevealTargetPolicy.highlightedAreaIfFits,
  ),
  hintBuilder: buildCostHint,
)
```

## Same Step With Distant Targets

The default `SpotlightGuideAutoScrollOptions` scrolls to later hidden mounted items after a short interval. Override it only when the step should remain static.

```dart
SpotlightGuideStep(
  autoScrollOptions: SpotlightGuideAutoScrollOptions(
    interval: const Duration(milliseconds: 900),
    onItemChanged: (SpotlightGuideAutoScrollDetails details) {
      final String progress =
          '${details.itemIndex + 1} / ${details.itemTotal}';
      final Object? analyticsKey = details.key ?? details.primaryTargetId;
      // details.highlightTargetIds lists every id lit by the focused item
    },
  ),
  items: <SpotlightGuideStepItem>[
    SpotlightGuideStepItem(targetId: 'top-filter', hintBuilder: buildFilterHint),
    SpotlightGuideStepItem(targetId: 'bottom-submit', hintBuilder: buildSubmitHint),
  ],
)
```

Disable the aid:

```dart
SpotlightGuideStep(
  autoScrollOptions: const SpotlightGuideAutoScrollOptions(enabled: false),
  items: items,
)
```

## Same-Step Layout Patterns

| Goal | Configuration |
| --- | --- |
| One hint, multiple areas lit together | One [SpotlightGuideStepItem] with `targetIds` (optional `anchorTargetId`) |
| Highlight every mounted instance of the same kind | Reuse one `SpotlightGuideTarget.id`; the instances become one target group |
| Highlight a repeated group but point at one chosen instance | Set `SpotlightGuideTarget.anchorId` on that instance and use `anchorTargetId` |
| Several hints at once (all on screen) | Multiple items in one step; auto scroll stays off when nothing is hidden |
| Several distant areas, explained one by one | Multiple items + default `autoScrollOptions`; use `onItemChanged` for copy/analytics |
| Stable business label independent of target id | `SpotlightGuideStepItem(key: 'your-key', targetId: 'widget-id', ...)` |
| Scroll to a lazy row, then highlight it | Later item `onReveal` + default auto scroll (deferred until its turn) |

```dart
// One hint, two registered targets
SpotlightGuideStepItem(
  key: 'save-group',
  targetIds: const <Object>['save-button', 'save-caption'],
  anchorTargetId: 'save-button',
  hintBuilder: buildSaveGroupHint,
)

// Repeated id group, with one explicit anchor target.
SpotlightGuideTarget(
  id: 'summary-card-group',
  anchorId: 'summary-cost-anchor',
  child: totalCostCard,
)

SpotlightGuideStepItem(
  targetId: 'summary-card-group',
  anchorTargetId: 'summary-cost-anchor',
  hintBuilder: buildCostHint,
)

// Progress copy + analytics in auto scroll
onItemChanged: (SpotlightGuideAutoScrollDetails details) {
  if (details.highlightsWholePortalChild) {
    return;
  }
  track('guide_focus', details.key ?? details.highlightTargetIds);
}
```

## Tap The Highlighted Button To Continue

Let the user press the real highlighted control to advance, instead of dimming
it out. Taps inside the hole reach the page; the rest of the barrier still
absorbs.

```dart
SpotlightGuideStep.item(
  SpotlightGuideStepItem(
    targetId: 'send-button',
    allowTargetInteraction: true,
    placement: SpotlightGuidePlacement.top,
    hintBuilder: (BuildContext context, SpotlightGuideStepContext guide) {
      return SpotlightGuideBubbleHint(
        guide: guide,
        child: const Text('Tap send to continue'),
      );
    },
  ),
)
```

## Target Hole Decoration

Use `targetDecoration` for hole padding, rounded shape, glow, and layered
borders. Rings, glows, dashed outlines, and shadows are painted by the overlay,
not by the target widget. Translucent rings create a crisp border-style halo;
glow layers create a blurred soft halo.

```dart
SpotlightGuideStep.item(
  SpotlightGuideStepItem(
    targetId: 'total-price-card',
    placement: SpotlightGuidePlacement.verticalAuto,
    targetDecoration: const SpotlightGuideTargetDecoration(
      padding: EdgeInsets.all(8),
      shape: SpotlightGuideRoundedRectShape(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      layers: <SpotlightGuideTargetLayer>[
        SpotlightGuideTargetRingLayer(color: Color(0x1AFFFFFF), width: 16),
        SpotlightGuideTargetRingLayer(color: Color(0x33FFFFFF), width: 8),
      ],
    ),
    hintBuilder: (BuildContext context, SpotlightGuideStepContext guide) {
      return SpotlightGuideBubbleHint(
        guide: guide,
        child: const Text('Layered rings can emphasize important targets.'),
      );
    },
  ),
)
```

Use an oval shape for circular controls or avatars:

```dart
targetDecoration: const SpotlightGuideTargetDecoration(
  padding: EdgeInsets.all(10),
  shape: SpotlightGuideOvalShape(),
  layers: <SpotlightGuideTargetLayer>[
    SpotlightGuideTargetGlowLayer(
      color: Color(0x99FFC107),
      blurRadius: 22,
      spreadRadius: 4,
    ),
    SpotlightGuideTargetRingLayer(color: Color(0xFFFFC107), width: 3),
  ],
)
```

Use a dashed outline when a highlighted target should look selected, reviewed,
or temporarily marked:

```dart
targetDecoration: const SpotlightGuideTargetDecoration(
  padding: EdgeInsets.all(6),
  shape: SpotlightGuideRoundedRectShape(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  ),
  layers: <SpotlightGuideTargetLayer>[
    SpotlightGuideTargetOutlineLayer(
      color: Colors.white,
      width: 3,
      dashLength: 10,
      gapLength: 6,
      outset: 8,
    ),
  ],
)
```

## Stepping Back And Jumping

```dart
// From a hint button:
hintBuilder: (context, guide) => Row(
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    TextButton(onPressed: guide.previous, child: const Text('Back')),
    TextButton(onPressed: guide.next, child: const Text('Next')),
  ],
);

// Or directly through the controller:
controller.goTo(0);
```
